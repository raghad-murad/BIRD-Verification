`ifndef INTERLEAVED_TEST_SV
`define INTERLEAVED_TEST_SV

// TP_CLS_03: alternating local/remote packets; bird_scoreboard verifies no cross-contamination between interfaces
class interleaved_local_remote_test extends bird_base_test;
    `uvm_component_utils(interleaved_local_remote_test)

    function new(string name = "interleaved_local_remote_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        interleaved_local_remote_seq seq = interleaved_local_remote_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #2000;
        phase.drop_objection(this);
    endtask
endclass : interleaved_local_remote_test

// TP_MIX_01: reuses TP_CLS_03's interleaved stimulus but explicitly checks local_vld/remote_vld never assert together and drop_cnt stays 0
class interleaved_mix_test extends bird_base_test;
    `uvm_component_utils(interleaved_mix_test)

    function new(string name = "interleaved_mix_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        interleaved_local_remote_seq seq = interleaved_local_remote_seq::type_id::create("seq");
        bit cross_contam_seen = 0;
        bit local_vld_seen    = 0;
        bit remote_vld_seen   = 0;
        bit drop_cnt_violation = 0;
        phase.raise_objection(this);

        fork
            forever begin
                @(posedge vif.clk);
                if (vif.local_vld === 1'b1) local_vld_seen = 1;
                if (vif.remote_vld === 1'b1) remote_vld_seen = 1;
                if (vif.local_vld === 1'b1 && vif.remote_vld === 1'b1) begin
                    cross_contam_seen = 1;
                    `uvm_error(get_type_name(),
                        "TP_MIX_01 FAIL: local_vld and remote_vld asserted on the same cycle (cross-contamination between interfaces, spec Sec.6-7)")
                end
                if (vif.drop_cnt !== 16'h0) begin
                    drop_cnt_violation = 1;
                    `uvm_error(get_type_name(),
                        $sformatf("TP_MIX_01 FAIL: drop_cnt=%0d, expected 0 for valid interleaved traffic (spec Sec.6-7)",
                            vif.drop_cnt))
                end
            end
        join_none

        seq.start(env.agent.sequencer);
        #2000;

        if (!local_vld_seen)
            `uvm_error(get_type_name(), "TP_MIX_01 FAIL: no local output observed during interleaved traffic");
        if (!remote_vld_seen)
            `uvm_error(get_type_name(), "TP_MIX_01 FAIL: no remote output observed during interleaved traffic");

        if (!cross_contam_seen && !drop_cnt_violation && local_vld_seen && remote_vld_seen)
            `uvm_info(get_type_name(),
                "TP_MIX_01 PASS: local and remote packets each routed to their own interface with no cross-contamination, drop_cnt stayed 0 (byte-for-byte correctness cross-checked by bird_scoreboard)",
                UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass : interleaved_mix_test

`endif
