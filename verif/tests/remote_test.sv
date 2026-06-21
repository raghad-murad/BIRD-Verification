`ifndef REMOTE_TEST_SV
`define REMOTE_TEST_SV

class remote_basic_test extends bird_base_test;
    `uvm_component_utils(remote_basic_test)
    function new(string name = "remote_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        remote_inorder_seq seq = remote_inorder_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #5000;
        phase.drop_objection(this);
    endtask
endclass : remote_basic_test

class remote_outoforder_test extends bird_base_test;
    `uvm_component_utils(remote_outoforder_test)
    function new(string name = "remote_outoforder_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        remote_outoforder_seq seq = remote_outoforder_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #5000;
        phase.drop_objection(this);
    endtask
endclass : remote_outoforder_test

// TP_MIX_03: two back-to-back multi-fragment remote packets; counts remote_vld rising edges to confirm exactly 2 separate bursts
class remote_back_to_back_test extends bird_base_test;
    `uvm_component_utils(remote_back_to_back_test)

    function new(string name = "remote_back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        remote_back_to_back_seq seq = remote_back_to_back_seq::type_id::create("seq");
        int unsigned remote_vld_rising_edges = 0;
        bit remote_vld_prev = 0;
        phase.raise_objection(this);

        fork
            forever begin
                @(posedge vif.clk);
                if (vif.remote_vld === 1'b1 && remote_vld_prev !== 1'b1)
                    remote_vld_rising_edges++;
                remote_vld_prev = vif.remote_vld;
            end
        join_none

        seq.start(env.agent.sequencer);
        #5000;

        if (remote_vld_rising_edges == 2 && vif.drop_cnt === 16'h0)
            `uvm_info(get_type_name(),
                $sformatf("TP_MIX_03 PASS: 2 separate remote output bursts observed in order, drop_cnt=0 (byte-for-byte correctness cross-checked by bird_scoreboard)"),
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_MIX_03 FAIL: expected exactly 2 remote output bursts with drop_cnt=0, observed %0d bursts and drop_cnt=%0d",
                    remote_vld_rising_edges, vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : remote_back_to_back_test

`endif
