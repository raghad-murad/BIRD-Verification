`ifndef DROP_TEST_SV
`define DROP_TEST_SV

class drop_conditions_test extends bird_base_test;
    `uvm_component_utils(drop_conditions_test)
    function new(string name = "drop_conditions_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        drop_seq_num_zero_seq    s1 = drop_seq_num_zero_seq::type_id::create("s1");
        drop_frag_num_zero_seq   s2 = drop_frag_num_zero_seq::type_id::create("s2");
        drop_reserved_bits_seq   s3 = drop_reserved_bits_seq::type_id::create("s3");
        drop_mismatch_seq_num_seq s4 = drop_mismatch_seq_num_seq::type_id::create("s4");
        drop_reserved_bits_23_21_seq s5 = drop_reserved_bits_23_21_seq::type_id::create("s5");
        drop_reserved_bits_31_29_seq s6 = drop_reserved_bits_31_29_seq::type_id::create("s6");
        drop_local_frag_num_not_one_seq s7 = drop_local_frag_num_not_one_seq::type_id::create("s7");
        phase.raise_objection(this);
        s1.start(env.agent.sequencer);
        s2.start(env.agent.sequencer);
        s3.start(env.agent.sequencer);
        s4.start(env.agent.sequencer);
        s5.start(env.agent.sequencer);
        s6.start(env.agent.sequencer);
        s7.start(env.agent.sequencer);
        #200;
        phase.drop_objection(this);
    endtask
endclass : drop_conditions_test

// TP_CNT_04 (spec Sec.8.2): a dropped multi-fragment packet must count as exactly one drop, checked directly off vif
class multi_frag_drop_once_test extends bird_base_test;
    `uvm_component_utils(multi_frag_drop_once_test)

    function new(string name = "multi_frag_drop_once_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        multi_frag_drop_once_seq seq = multi_frag_drop_once_seq::type_id::create("seq");
        logic [15:0] drop_cnt_before;
        logic [15:0] drop_cnt_after;
        phase.raise_objection(this);

        @(posedge vif.clk iff vif.rst_n === 1'b1);
        drop_cnt_before = vif.drop_cnt;

        seq.start(env.agent.sequencer);
        #50;

        drop_cnt_after = vif.drop_cnt;

        if (drop_cnt_after == (drop_cnt_before + 16'd1))
            `uvm_info(get_type_name(),
                $sformatf("TP_CNT_04 PASS: drop_cnt incremented by exactly 1 (before=%0d, after=%0d) for a 5-fragment dropped packet",
                    drop_cnt_before, drop_cnt_after), UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_CNT_04 FAIL: drop_cnt expected to increment by exactly 1 (before=%0d), but observed after=%0d (delta=%0d, spec Sec.8.2: multi-fragment drop must count once)",
                    drop_cnt_before, drop_cnt_after, drop_cnt_after - drop_cnt_before));

        #50;
        phase.drop_objection(this);
    endtask
endclass : multi_frag_drop_once_test

`endif
