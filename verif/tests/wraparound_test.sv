`ifndef WRAPAROUND_TEST_SV
`define WRAPAROUND_TEST_SV

// TP_CNT_05 (spec Sec.8.2): drives 65536 guaranteed drops from 0 so drop_cnt wraps exactly once; checks vif directly alongside the scoreboard's modulo check
class drop_cnt_wraparound_test extends bird_base_test;
    `uvm_component_utils(drop_cnt_wraparound_test)
    function new(string name = "drop_cnt_wraparound_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        drop_cnt_wraparound_seq s1 = drop_cnt_wraparound_seq::type_id::create("s1");
        logic [15:0] drop_cnt_before;
        logic [15:0] drop_cnt_after;
        phase.raise_objection(this);

        // Snapshot drop_cnt before the sequence runs (must be 0x0000 coming out of reset)
        @(posedge vif.clk iff vif.rst_n === 1'b1);
        drop_cnt_before = vif.drop_cnt;

        // Send 65536 guaranteed-drop packets so the counter wraps exactly once
        s1.start(env.agent.sequencer);
        #200;

        // Snapshot drop_cnt again after all 65536 drops have landed.
        drop_cnt_after = vif.drop_cnt;

        // Verdict: both snapshots must read 0x0000 for the wrap to be correct.
        if (drop_cnt_before == 16'h0000 && drop_cnt_after == 16'h0000)
            `uvm_info(get_type_name(),
                $sformatf("TP_CNT_05 PASS: drop_cnt wrapped modulo 2^16 back to 0x0000 (before=0x%04h, after=0x%04h)",
                    drop_cnt_before, drop_cnt_after), UVM_LOW)
        else
            // Mismatch means the counter didn't wrap correctly or never started from 0x0000 (spec Sec.8.2)
            `uvm_error(get_type_name(),
                $sformatf("TP_CNT_05 FAIL: expected drop_cnt to wrap back to 0x0000 after 65536 drops (before=0x%04h), but observed after=0x%04h",
                    drop_cnt_before, drop_cnt_after));

        #50;
        phase.drop_objection(this);
    endtask
endclass : drop_cnt_wraparound_test

`endif
