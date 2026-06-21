`ifndef SEQ_FRAG_TEST_SV
`define SEQ_FRAG_TEST_SV

// TP_SEQ_01..04 (spec Sec.7.1,7.2,8.1): literal spec stimulus checked against spec wording; DUT indexes remote fragments by SEQ_NUM as position (reverse of spec Sec.5), so SEQ_NUM=1/FRAG_NUM=1 completes instantly instead of starting an accumulation

// Builds a payload+CRC stream from a given (not randomised) payload, for tests needing known content
function automatic void sf_build_stream(input byte unsigned payload[], output byte unsigned stream[]);
    bit [15:0] crc;
    crc = bird_transaction::calc_crc16(payload);
    stream = new[payload.size() + 2];
    foreach (payload[i]) stream[i] = payload[i];
    stream[payload.size()]   = crc[15:8];
    stream[payload.size()+1] = crc[7:0];
endfunction

// Collects one byte-queue per remote_vld completion so tests can count and inspect multiple/zero completions
task automatic sf_collect_remote(virtual bird_if vif, ref logic [31:0] completions[$][$]);
    vif.remote_rdy <= 1'b1;
    forever begin
        logic [31:0] words[$];
        @(posedge vif.clk iff vif.remote_vld === 1'b1);
        while (vif.remote_vld === 1'b1) begin
            if (vif.remote_rdy === 1'b1) words.push_back(vif.data_remote);
            @(posedge vif.clk);
        end
        completions.push_back(words);
    end
endtask

// TP_SEQ_01: 3 fragments sharing SEQ_NUM=1; DUT completes on fragment 1 alone instead of merging by FRAG_NUM
class fragments_same_seq_test extends bird_base_test;
    `uvm_component_utils(fragments_same_seq_test)

    function new(string name = "fragments_same_seq_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned p1[], p2[], p3[];
        byte unsigned s1[], s2[], s3[];
        logic [31:0]  cfg1, cfg2, cfg3;
        logic [31:0]  completions[$][$];
        byte unsigned merged[];
        logic [15:0]  exp_crc_correct;
        logic [31:0]  exp_words_correct[$];
        byte unsigned p1_only[];
        logic [15:0]  exp_crc_degenerate;
        logic [31:0]  exp_words_degenerate[$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        p1 = new[1]; p2 = new[1]; p3 = new[1]; merged = new[3]; p1_only = new[1];
        p1[0] = 8'hA1; p2[0] = 8'hB2; p3[0] = 8'hC3;
        sf_build_stream(p1, s1);
        sf_build_stream(p2, s2);
        sf_build_stream(p3, s3);

        cfg1 = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(s1.size()));
        cfg2 = hs_build_cfg(1'b1, 5'd1, 5'd2, 8'(s2.size()));
        cfg3 = hs_build_cfg(1'b1, 5'd1, 5'd3, 8'(s3.size()));

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfg1, s1);
        hs_drive_fragment(vif, cfg2, s2);
        hs_drive_fragment(vif, cfg3, s3);
        #500;

        // Spec-correct expectation: all 3 merged in FRAG_NUM order
        merged[0] = p1[0]; merged[1] = p2[0]; merged[2] = p3[0];
        exp_crc_correct = bird_transaction::calc_crc16(merged);
        exp_words_correct.push_back({8'h00, merged[2], merged[1], merged[0]});
        exp_words_correct.push_back({16'h0000, exp_crc_correct});

        // Predicted-actual: only fragment 1 alone, output as a complete 1-fragment packet (see file header)
        p1_only[0] = p1[0];
        exp_crc_degenerate = bird_transaction::calc_crc16(p1_only);
        exp_words_degenerate.push_back({24'h000000, p1[0]});
        exp_words_degenerate.push_back({16'h0000, exp_crc_degenerate});

        if (completions.size() == 1 && completions[0].size() == exp_words_correct.size() &&
            completions[0][0] === exp_words_correct[0] && completions[0][1] === exp_words_correct[1])
            `uvm_info(get_type_name(),
                "TP_SEQ_01 PASS: 3 fragments sharing SEQ_NUM=1 were correctly merged in FRAG_NUM order with regenerated CRC16; drop_cnt=0",
                UVM_LOW)
        else if (completions.size() == 1 && completions[0].size() == exp_words_degenerate.size() &&
            completions[0][0] === exp_words_degenerate[0] && completions[0][1] === exp_words_degenerate[1])
            `uvm_error(get_type_name(),
                "TP_SEQ_01 FAIL: only fragment 1 was output, as a complete 1-fragment packet; fragments 2 and 3 were never merged in. ROOT CAUSE: this DUT indexes remote-fragment storage by SEQ_NUM (cfg[28:24]) and treats it as fragment POSITION, with FRAG_NUM (cfg[20:16]) as the declared TOTAL - the reverse of spec Sec.5. SEQ_NUM=1/FRAG_NUM=1 is read as 'position 1 of total 1' and completes instantly.")
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_SEQ_01 FAIL: observed %0d remote completion(s) matching neither the spec-correct merge nor the predicted single-fragment case - needs manual review",
                    completions.size()));

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_SEQ_01: drop_cnt=%0d (expected 0)", vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : fragments_same_seq_test

// TP_SEQ_02: mismatched SEQ_NUM during accumulation; SEQ=1 completes instantly instead of being dropped
class mismatched_seq_test extends bird_base_test;
    `uvm_component_utils(mismatched_seq_test)

    function new(string name = "mismatched_seq_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned pA[], pB[];
        byte unsigned sA[], sB[];
        logic [31:0]  cfgA, cfgB;
        logic [31:0]  completions[$][$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        pA = new[1]; pB = new[1];
        pA[0] = 8'hAA; pB[0] = 8'hBB;
        sf_build_stream(pA, sA);
        sf_build_stream(pB, sB);

        cfgA = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(sA.size()));  // SEQ=1, FRAG=1
        cfgB = hs_build_cfg(1'b1, 5'd2, 5'd2, 8'(sB.size()));  // SEQ=2, FRAG=2

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfgA, sA);
        hs_drive_fragment(vif, cfgB, sB);
        #500;

        if (completions.size() == 0 && vif.drop_cnt >= 16'd1)
            `uvm_info(get_type_name(),
                "TP_SEQ_02 PASS: SEQ=1 was dropped when the mismatched fragment arrived; no remote output for it; drop_cnt>=1",
                UVM_LOW)
        else if (completions.size() >= 1)
            `uvm_error(get_type_name(),
                $sformatf("TP_SEQ_02 FAIL: SEQ=1 was NOT dropped - it was instead immediately output as a complete 1-fragment packet (%0d completion(s) observed), so the SEQ=2 mismatch never had anything to drop. drop_cnt=%0d (expected >=1). Same root cause as TP_SEQ_01: SEQ_NUM=1/FRAG_NUM=1 completes instantly on this DUT.",
                    completions.size(), vif.drop_cnt))
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_SEQ_02 FAIL: no remote output (consistent with SEQ=1 being dropped) but drop_cnt=%0d (expected >=1)",
                    vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : mismatched_seq_test

// TP_SEQ_03: FRAG_NUM=1 arrives while packet incomplete; fragment 1 completes instantly, fragment 3 mismatch double-drops instead of a single clean drop
class frag1_while_incomplete_test extends bird_base_test;
    `uvm_component_utils(frag1_while_incomplete_test)

    function new(string name = "frag1_while_incomplete_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned p1[], p2[], p3[];
        byte unsigned s1[], s2[], s3[];
        logic [31:0]  cfg1, cfg2, cfg3;
        logic [31:0]  completions[$][$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        p1 = new[1]; p2 = new[1]; p3 = new[1];
        p1[0] = 8'h11; p2[0] = 8'h22; p3[0] = 8'h33;
        sf_build_stream(p1, s1);
        sf_build_stream(p2, s2);
        sf_build_stream(p3, s3);

        cfg1 = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(s1.size()));  // SEQ=1, FRAG=1
        cfg2 = hs_build_cfg(1'b1, 5'd1, 5'd2, 8'(s2.size()));  // SEQ=1, FRAG=2
        cfg3 = hs_build_cfg(1'b1, 5'd2, 5'd1, 8'(s3.size()));  // SEQ=2, FRAG=1

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfg1, s1);
        hs_drive_fragment(vif, cfg2, s2);
        hs_drive_fragment(vif, cfg3, s3);
        #500;

        if (completions.size() == 0 && vif.drop_cnt === 16'd1)
            `uvm_info(get_type_name(),
                "TP_SEQ_03 PASS: SEQ=1 was dropped exactly once when SEQ=2/FRAG=1 arrived; drop_cnt=1",
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_SEQ_03 FAIL: observed %0d remote completion(s), drop_cnt=%0d (expected 0 completions, drop_cnt=1). Predicted actual: fragment 1 (SEQ=1/FRAG=1) completes instantly and is output on its own (same root cause as TP_SEQ_01); fragment 3's mismatch path drops BOTH the in-progress state and the incoming fragment itself, giving drop_cnt=2 not 1; SEQ=2 never starts a fresh accumulation at all.",
                    completions.size(), vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : frag1_while_incomplete_test

// TP_SEQ_04: missing fragment drop; fragment 1 completes instantly before the timeout-free DUT can later double-drop on the forcing fragment
class missing_fragment_test extends bird_base_test;
    `uvm_component_utils(missing_fragment_test)

    function new(string name = "missing_fragment_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned p1[], p3[], p4[];
        byte unsigned s1[], s3[], s4[];
        logic [31:0]  cfg1, cfg3, cfg4;
        logic [31:0]  completions[$][$];
        int unsigned  completions_after_step3;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        p1 = new[1]; p3 = new[1]; p4 = new[1];
        p1[0] = 8'hD1; p3[0] = 8'hD3; p4[0] = 8'hD4;
        sf_build_stream(p1, s1);
        sf_build_stream(p3, s3);
        sf_build_stream(p4, s4);

        cfg1 = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(s1.size()));  // SEQ=1, FRAG=1
        cfg3 = hs_build_cfg(1'b1, 5'd1, 5'd3, 8'(s3.size()));  // SEQ=1, FRAG=3 (FRAG=2 skipped)
        cfg4 = hs_build_cfg(1'b1, 5'd2, 5'd1, 8'(s4.size()));  // SEQ=2, FRAG=1 (forces the drop)

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfg1, s1);   // step 1
        hs_drive_fragment(vif, cfg3, s3);   // step 2
        repeat (20) @(posedge vif.clk);     // step 3

        completions_after_step3 = completions.size();
        if (completions_after_step3 == 0)
            `uvm_info(get_type_name(),
                "TP_SEQ_04: no remote output after steps 1-3, as spec expects", UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_SEQ_04 FAIL: %0d remote completion(s) already occurred after steps 1-3, before the forcing fragment was even sent (spec expects none). Predicted actual: fragment 1 (SEQ=1/FRAG=1) completed instantly on its own - same root cause as TP_SEQ_01.",
                    completions_after_step3));

        hs_drive_fragment(vif, cfg4, s4);   // step 4
        #500;

        if (vif.drop_cnt === 16'd1)
            `uvm_info(get_type_name(),
                "TP_SEQ_04 PASS: drop_cnt=1 after step 4", UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_SEQ_04 FAIL: drop_cnt=%0d after step 4 (expected 1). Predicted actual: this DUT has no timeout mechanism at all, so the missing-FRAG=2 state would stay incomplete indefinitely on its own; step 4's mismatch path drops BOTH the in-progress state and rejects the incoming fragment, giving drop_cnt=2.",
                    vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : missing_fragment_test

// TP_REM_01: one remote packet at a time; same SEQ_NUM-as-position root cause as TP_SEQ_01-04 means there's no "accumulating but incomplete" window to interrupt
class one_remote_packet_at_a_time_test extends bird_base_test;
    `uvm_component_utils(one_remote_packet_at_a_time_test)

    function new(string name = "one_remote_packet_at_a_time_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned pA[], pB[];
        byte unsigned sA[], sB[];
        logic [31:0]  cfgA, cfgB;
        logic [31:0]  completions[$][$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        pA = new[1]; pB = new[1];
        pA[0] = 8'h51; pB[0] = 8'h52;
        sf_build_stream(pA, sA);
        sf_build_stream(pB, sB);

        cfgA = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(sA.size()));  // SEQ_NUM=1, FRAG 1
        cfgB = hs_build_cfg(1'b1, 5'd2, 5'd2, 8'(sB.size()));  // SEQ_NUM=2, before SEQ_NUM=1 completes

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfgA, sA);
        hs_drive_fragment(vif, cfgB, sB);
        #500;

        if (completions.size() == 0 && vif.drop_cnt === 16'd1)
            `uvm_info(get_type_name(),
                "TP_REM_01 PASS: SEQ_NUM=1 was dropped (no remote output for it) when SEQ_NUM=2 arrived before it completed; drop_cnt incremented by exactly 1",
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_REM_01 FAIL: observed %0d remote completion(s), drop_cnt=%0d (expected 0 completions, drop_cnt=1). DUT BUG (same confirmed root cause as TP_SEQ_01/02/03/04): this DUT indexes remote-fragment storage by SEQ_NUM and treats it as fragment position with FRAG_NUM as the declared total - the reverse of spec Sec.5. SEQ_NUM=1/FRAG_NUM=1 is therefore read as 'position 1 of total 1' and completes and outputs INSTANTLY, so there is never a window where SEQ_NUM=1 is 'accumulating but incomplete' for a second SEQ_NUM to interrupt - this TP's literal premise cannot be set up on this DUT at all.",
                    completions.size(), vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : one_remote_packet_at_a_time_test

`endif
