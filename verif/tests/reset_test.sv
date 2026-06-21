`ifndef RESET_TEST_SV
`define RESET_TEST_SV

// TP_RST_01..04: each test verdicts explicitly against its TP's Expected Result and spec Sec.9 (Reset Behavior), not just via scoreboard/checker

// TP_RST_01: Power-On Reset (spec Sec.9) — polls that outputs stay deasserted and drop_cnt=0 throughout the initial reset window
class power_on_reset_test extends bird_base_test;
    `uvm_component_utils(power_on_reset_test)

    function new(string name = "power_on_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        bit fail = 0;
        phase.raise_objection(this);

        // Let the design's reset response settle one clock edge before sampling, else outputs read X (sim startup, not a violation)
        @(posedge vif.clk);
        while (vif.rst_n !== 1'b1) begin
            if (vif.local_vld !== 1'b0) begin
                `uvm_error(get_type_name(),
                    $sformatf("TP_RST_01 FAIL: local_vld=%0b during rst_n=0 (spec Sec.9)", vif.local_vld))
                fail = 1;
            end
            if (vif.remote_vld !== 1'b0) begin
                `uvm_error(get_type_name(),
                    $sformatf("TP_RST_01 FAIL: remote_vld=%0b during rst_n=0 (spec Sec.9)", vif.remote_vld))
                fail = 1;
            end
            if (vif.drop_cnt !== 16'h0) begin
                `uvm_error(get_type_name(),
                    $sformatf("TP_RST_01 FAIL: drop_cnt=%0d during rst_n=0 (spec Sec.9)", vif.drop_cnt))
                fail = 1;
            end
            @(posedge vif.clk);
        end

        if (!fail)
            `uvm_info(get_type_name(),
                "TP_RST_01 PASS: local_vld=0, remote_vld=0, drop_cnt=0 throughout power-on reset", UVM_LOW)

        #20;
        phase.drop_objection(this);
    endtask
endclass : power_on_reset_test

// TP_RST_02: Reset During Local Packet — DUT BUG: mixed blocking/non-blocking assignment in the output always_ff lets queued local_vld leak through reset on a coincident posedge clk/negedge rst_n; intentionally left failing to surface it
class reset_during_local_test extends bird_base_test;
    `uvm_component_utils(reset_during_local_test)

    function new(string name = "reset_during_local_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        reset_during_local_seq seq = reset_during_local_seq::type_id::create("seq");
        bit local_vld_seen = 0;
        phase.raise_objection(this);

        fork
            seq.start(env.agent.sequencer);  // driver aborts this early once rst_n drops
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) local_vld_seen = 1;
                end
            end
        join_none

        // Let the fragment get underway, then interrupt it mid-payload
        wait (vif.in_vld === 1'b1 && vif.in_rdy === 1'b1);
        repeat (5) @(posedge vif.clk);

        `uvm_info(get_type_name(), "Asserting rst_n mid-local-packet (TP_RST_02)", UVM_LOW)
        vif.apply_reset(4);
        `uvm_info(get_type_name(), "Reset deasserted - checking post-reset state", UVM_LOW)

        @(posedge vif.clk);
        if (vif.local_vld !== 1'b0)
            `uvm_error(get_type_name(),
                $sformatf("TP_RST_02 FAIL: local_vld=%0b immediately after reset (expected 0, spec Sec.9)",
                    vif.local_vld));

        if (local_vld_seen)
            `uvm_error(get_type_name(),
                "TP_RST_02 FAIL: local output WAS produced for the packet reset mid-transfer (spec Sec.9: in-progress packet must be discarded). DUT BUG: mixing blocking and non-blocking assignments in the same always_ff output block (design/bird.sv) causes local_vld to not deassert synchronously with reset when posedge clk and negedge rst_n coincide. Spec Section 9 requires local_vld=0 while rst_n=0.")
        else if (vif.local_vld === 1'b0)
            `uvm_info(get_type_name(),
                "TP_RST_02 PASS: no local output for the interrupted packet; local_vld=0 after reset", UVM_LOW);

        #50;
        phase.drop_objection(this);
    endtask
endclass : reset_during_local_test

// TP_RST_03: Reset During Remote Reassembly — confirms buffers/state clear and probes that a lone post-reset fragment can't complete a stale merge
class reset_during_remote_test extends bird_base_test;
    `uvm_component_utils(reset_during_remote_test)

    function new(string name = "reset_during_remote_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        reset_during_remote_seq      seq      = reset_during_remote_seq::type_id::create("seq");
        remote_lone_frag3_of3_seq    probe_seq = remote_lone_frag3_of3_seq::type_id::create("probe_seq");
        bit remote_vld_seen     = 0;
        bit remote_vld_seen_pa  = 0;  // post-reset stale-state probe
        phase.raise_objection(this);

        fork
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.remote_vld === 1'b1) remote_vld_seen = 1;
                end
            end
        join_none

        // Buffer fragments 1 and 2 of 3 (normal completion, no reset yet)
        seq.start(env.agent.sequencer);

        `uvm_info(get_type_name(), "Asserting rst_n during remote reassembly (TP_RST_03)", UVM_LOW)
        vif.apply_reset(4);
        `uvm_info(get_type_name(), "Reset deasserted - checking post-reset state", UVM_LOW)

        @(posedge vif.clk);
        if (vif.remote_vld !== 1'b0)
            `uvm_error(get_type_name(),
                $sformatf("TP_RST_03 FAIL: remote_vld=%0b immediately after reset (expected 0, spec Sec.9)",
                    vif.remote_vld));

        if (remote_vld_seen)
            `uvm_error(get_type_name(),
                "TP_RST_03 FAIL: remote output WAS produced from the partially-buffered packet (spec Sec.9: in-progress packet must be discarded)");

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(),
                $sformatf("TP_RST_03 FAIL: drop_cnt=%0d after reset (expected 0, spec Sec.9)", vif.drop_cnt));

        // Stale-state probe: a lone fragment 3 can't complete a merge unless pre-reset state was wrongly retained
        fork
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.remote_vld === 1'b1) remote_vld_seen_pa = 1;
                end
            end
        join_none

        probe_seq.start(env.agent.sequencer);
        #200;

        if (remote_vld_seen_pa)
            `uvm_error(get_type_name(),
                "TP_RST_03 FAIL: stale pre-reset fragment state was reused - a lone post-reset fragment produced remote output")
        else if (vif.remote_vld === 1'b0 && !remote_vld_seen && vif.drop_cnt === 16'h0)
            `uvm_info(get_type_name(),
                "TP_RST_03 PASS: no remote output, drop_cnt=0, and fragment state was not reused after reset", UVM_LOW);

        #50;
        phase.drop_objection(this);
    endtask
endclass : reset_during_remote_test

// TP_RST_04: Normal Operation After Reset — reuses local_basic_seq with an explicit local-output observation on top of the scoreboard's check
class normal_after_reset_test extends bird_base_test;
    `uvm_component_utils(normal_after_reset_test)

    function new(string name = "normal_after_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        local_basic_seq seq = local_basic_seq::type_id::create("seq");
        bit local_vld_seen = 0;
        phase.raise_objection(this);

        fork
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) local_vld_seen = 1;
                end
            end
        join_none

        seq.start(env.agent.sequencer);
        #100;

        if (local_vld_seen)
            `uvm_info(get_type_name(),
                "TP_RST_04 PASS: valid local packet sent after reset deassertion was forwarded on local output (byte-for-byte correctness cross-checked by bird_scoreboard)",
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                "TP_RST_04 FAIL: no local output observed for a valid local packet sent after reset deassertion");

        phase.drop_objection(this);
    endtask
endclass : normal_after_reset_test

// TP_CNT_06: Reset Clears Counter (spec Sec.9) — DUT BUG: drop_cnt's reset-clear isn't visible until a couple cycles into the reset-hold window, so this samples drop_cnt at the first post-rst_n=0 edge to catch it
class reset_clears_drop_cnt_test extends bird_base_test;
    `uvm_component_utils(reset_clears_drop_cnt_test)

    function new(string name = "reset_clears_drop_cnt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        drop_cnt_wraparound_seq seq = drop_cnt_wraparound_seq::type_id::create("seq");
        logic [15:0] drop_cnt_before_reset;
        logic [15:0] drop_cnt_immediately_after;
        logic [15:0] drop_cnt_after_full_hold;
        phase.raise_objection(this);

        @(posedge vif.clk iff vif.rst_n === 1'b1);

        // Reuse the wraparound sequence's guaranteed-drop stimulus with a small count
        seq.num_pkts = 5;
        seq.start(env.agent.sequencer);
        #100;

        drop_cnt_before_reset = vif.drop_cnt;
        if (drop_cnt_before_reset == 16'h0000)
            `uvm_error(get_type_name(),
                "TP_CNT_06 FAIL: drop_cnt is still 0x0000 before reset - drops were not registered, so this test cannot prove reset clears a non-zero counter");

        `uvm_info(get_type_name(),
            $sformatf("Asserting rst_n with drop_cnt=0x%04h (TP_CNT_06)", drop_cnt_before_reset), UVM_LOW)

        // Capture drop_cnt at the first clock edge while rst_n is already 0, per the literal "immediately" wording
        fork
            begin
                @(negedge vif.rst_n);
                @(posedge vif.clk);
                drop_cnt_immediately_after = vif.drop_cnt;
            end
            vif.apply_reset(4);
        join

        if (drop_cnt_immediately_after == 16'h0000)
            `uvm_info(get_type_name(),
                $sformatf("TP_CNT_06 PASS: drop_cnt cleared to 0x0000 immediately after reset (was 0x%04h before)",
                    drop_cnt_before_reset), UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_CNT_06 FAIL: drop_cnt=0x%04h at the first clock edge after rst_n=0 (expected 0x0000 IMMEDIATELY per spec Sec.9), before reset was 0x%04h. DUT BUG: drop_cnt does not clear synchronously with reset assertion (see bird_checker's independent RESET VIOLATION reports).",
                    drop_cnt_immediately_after, drop_cnt_before_reset));

        // Informational only: confirm it settles to 0 by the time reset deasserts
        drop_cnt_after_full_hold = vif.drop_cnt;
        `uvm_info(get_type_name(),
            $sformatf("drop_cnt=0x%04h once reset deasserts (informational)", drop_cnt_after_full_hold), UVM_LOW)

        #50;
        phase.drop_objection(this);
    endtask
endclass : reset_clears_drop_cnt_test

`endif
