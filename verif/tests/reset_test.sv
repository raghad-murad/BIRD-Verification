`ifndef RESET_TEST_SV
`define RESET_TEST_SV

// ============================================================
// reset_test.sv — TP_RST_01..TP_RST_04
// Each test makes its own explicit pass/fail determination
// against the exact wording of its TP's Expected Result column
// and against spec Section 9 (Reset Behavior). None of these
// rely solely on the scoreboard/checker catching a violation
// implicitly.
// ============================================================

// ------------------------------------------------------------
// TP_RST_01 — Power-On Reset
// Spec Section 9: while rst_n=0, all valid outputs deasserted
// and drop_cnt=0. Polls throughout the initial reset window
// (same poll-on-posedge pattern bird_checker already uses).
// ------------------------------------------------------------
class power_on_reset_test extends bird_base_test;
    `uvm_component_utils(power_on_reset_test)

    function new(string name = "power_on_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        bit fail = 0;
        phase.raise_objection(this);

        // Let the design's own async-reset response settle for at least one
        // clock edge before sampling anything - otherwise outputs simply
        // haven't been driven yet (read as X), which is not a spec
        // violation, just simulation startup. Mirrors bird_checker's
        // existing run_phase pattern.
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

// ------------------------------------------------------------
// TP_RST_02 — Reset During Local Packet
// Spec Section 9: any packet in progress is discarded on
// reset, and local_vld must deassert. Drives a long local
// packet, interrupts it mid-payload with rst_n, then confirms
// no local output ever appeared for that packet.
//
// CONFIRMED DUT BUG (do not fix here, do not work around):
// design/bird.sv's output-driving always_ff block (the one
// commented "Drive outputs + pop on handshake") assigns
// local_vld/data_local with BLOCKING (=) assignment in its
// normal-operation branch, but with NON-BLOCKING (<=)
// assignment in its reset branch, on the same signal in the
// same edge-sensitive block. When posedge clk and negedge rst_n
// coincide, the blocking assignment in the normal-operation
// path can execute after the non-blocking reset write is
// scheduled, overriding it and leaving local_vld=1 - so bytes
// already queued in local_q before reset leak out instead of
// being discarded. Spec Section 9 requires local_vld=0 while
// rst_n=0. This test is intentionally left FAILING to surface
// that defect; see bird_checker's independent "RESET VIOLATION:
// local_vld is not deasserted during rst_n=0" for corroboration.
// ------------------------------------------------------------
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

// ------------------------------------------------------------
// TP_RST_03 — Reset During Remote Reassembly
// Spec Section 9: buffers/fragment state cleared, no remote
// output, drop_cnt=0. Also probes that fragment state was
// actually cleared (not silently reused) by sending only the
// withheld 3rd fragment afterward and confirming it alone
// cannot complete a (stale) merge.
// ------------------------------------------------------------
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

        // Stale-state probe: send only the withheld fragment 3 of 3. If
        // fragment state was genuinely cleared, this lone fragment cannot
        // complete a merge (positions 1,2 are missing) and remote_vld must
        // never assert for it.
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

// ------------------------------------------------------------
// TP_RST_04 — Normal Operation After Reset
// Reuses local_basic_seq (same stimulus as local_basic_test)
// but gives it its own traceable name/verdict mapped 1:1 to
// this TP, with an explicit confirmation that local output was
// actually observed (in addition to the scoreboard's automatic
// byte-for-byte check, which remains connected and active).
// ------------------------------------------------------------
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

`endif // RESET_TEST_SV
