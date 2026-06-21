`ifndef RAND_TEST_SV
`define RAND_TEST_SV

class backpressure_test extends bird_base_test;
    `uvm_component_utils(backpressure_test)
    function new(string name = "backpressure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        backpressure_seq seq = backpressure_seq::type_id::create("seq");
        phase.raise_objection(this);
        // rdy stays asserted: the DUT drains output queues combinationally in zero sim time,
        // which the byte-by-byte output monitor can't represent under backpressure
        seq.start(env.agent.sequencer);
        #200;
        phase.drop_objection(this);
    endtask
endclass : backpressure_test

class rand_test extends bird_base_test;
    `uvm_component_utils(rand_test)
    function new(string name = "rand_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        rand_test_seq seq = rand_test_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #20000;
        phase.drop_objection(this);
    endtask
endclass : rand_test

// TP_MIX_02: rand_test_seq stimulus with a TP_MIX_02-tagged verdict on top of the scoreboard's own checks
class mixed_random_test extends bird_base_test;
    `uvm_component_utils(mixed_random_test)
    function new(string name = "mixed_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        rand_test_seq seq = rand_test_seq::type_id::create("seq");
        int unsigned observed_drop_cnt;
        phase.raise_objection(this);
        seq.num_pkts = 64;
        seq.start(env.agent.sequencer);
        #20000;

        // scoreboard.observed_drop_cnt is only set in check_phase (after run_phase), so read drop_cnt off vif directly
        observed_drop_cnt = vif.drop_cnt;

        if (env.scoreboard.checks_failed == 0 &&
            observed_drop_cnt == (env.scoreboard.expected_drop_cnt & 16'hFFFF))
            `uvm_info(get_type_name(),
                $sformatf("TP_MIX_02 PASS: drop_cnt matches expected count (expected=%0d, observed=%0d), %0d scoreboard checks passed",
                    env.scoreboard.expected_drop_cnt, observed_drop_cnt,
                    env.scoreboard.checks_passed), UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_MIX_02 FAIL: drop_cnt expected=%0d observed=%0d, %0d scoreboard checks failed",
                    env.scoreboard.expected_drop_cnt, observed_drop_cnt,
                    env.scoreboard.checks_failed));

        phase.drop_objection(this);
    endtask
endclass : mixed_random_test

`endif
