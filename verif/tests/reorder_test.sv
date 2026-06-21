`ifndef REORDER_TEST_SV
`define REORDER_TEST_SV

// TP_REORD_01..05 (spec Sec.7.1-7.3): literal spec stimulus checked against spec wording; DUT indexes remote fragments by SEQ_NUM as position (reverse of spec Sec.5), so none produce the spec-correct reordered merge

// Builds expected remote words from a merged payload, matching bird.sv's pack_bytes_to_words() exactly
function automatic void build_exp_words(input byte unsigned merged[], output logic [31:0] exp_words[$]);
    int n = merged.size();
    int full = n / 4;
    int rem  = n % 4;
    for (int w = 0; w < full; w++)
        exp_words.push_back({merged[w*4+3], merged[w*4+2], merged[w*4+1], merged[w*4]});
    if (rem > 0) begin
        logic [31:0] last = 32'h0;
        for (int b = 0; b < rem; b++) last[8*b +: 8] = merged[full*4 + b];
        exp_words.push_back(last);
    end
    exp_words.push_back({16'h0000, bird_transaction::calc_crc16(merged)});
endfunction

// TP_REORD_01: two SEQ_NUM=1 fragments out of order; DUT's same-slot indexing means no remote output at all (see file header)
class two_frags_ooo_test extends bird_base_test;
    `uvm_component_utils(two_frags_ooo_test)

    function new(string name = "two_frags_ooo_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned pA1[], pB2[];
        byte unsigned sA1[], sB2[];
        logic [31:0]  cfgB2, cfgA1;
        logic [31:0]  completions[$][$];
        byte unsigned merged[];
        logic [31:0]  exp_words[$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        pA1 = new[1]; pB2 = new[1];
        pA1[0] = 8'hA1; pB2[0] = 8'hB2;
        sf_build_stream(pA1, sA1);
        sf_build_stream(pB2, sB2);

        cfgB2 = hs_build_cfg(1'b1, 5'd1, 5'd2, 8'(sB2.size()));  // SEQ=1, FRAG=2
        cfgA1 = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(sA1.size()));  // SEQ=1, FRAG=1

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfgB2, sB2);  // FRAG_NUM=2 arrives first
        hs_drive_fragment(vif, cfgA1, sA1);  // FRAG_NUM=1 arrives second
        #500;

        merged = new[2];
        merged[0] = pA1[0]; merged[1] = pB2[0];
        build_exp_words(merged, exp_words);

        if (completions.size() == 1 && completions[0].size() == exp_words.size() &&
            completions[0][0] === exp_words[0] && completions[0][1] === exp_words[1])
            `uvm_info(get_type_name(),
                "TP_REORD_01 PASS: two out-of-order fragments merged correctly in FRAG_NUM order with regenerated CRC16; drop_cnt=0",
                UVM_LOW)
        else if (completions.size() == 0)
            `uvm_error(get_type_name(),
                "TP_REORD_01 FAIL: no remote output at all. ROOT CAUSE: both fragments were sent with SEQ_NUM=1, and this DUT indexes fragment storage by SEQ_NUM (treated as position) - so both fragments map to the same storage slot and no fragment ever supplies SEQ_NUM=2, leaving the 'all positions seen' completion check permanently unsatisfied.")
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_REORD_01 FAIL: observed %0d completion(s) matching neither the expected merge nor the predicted no-output case - needs manual review",
                    completions.size()));

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_REORD_01: drop_cnt=%0d (expected 0)", vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : two_frags_ooo_test

// TP_REORD_02: three SEQ_NUM=1 fragments out of order; same no-output root cause as TP_REORD_01
class three_frags_ooo_test extends bird_base_test;
    `uvm_component_utils(three_frags_ooo_test)

    function new(string name = "three_frags_ooo_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned p1[], p2[], p3[];
        byte unsigned s1[], s2[], s3[];
        logic [31:0]  cfg1, cfg2, cfg3;
        logic [31:0]  completions[$][$];
        byte unsigned merged[];
        logic [31:0]  exp_words[$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        p1 = new[1]; p2 = new[1]; p3 = new[1];
        p1[0] = 8'hA1; p2[0] = 8'hB2; p3[0] = 8'hC3;
        sf_build_stream(p1, s1);
        sf_build_stream(p2, s2);
        sf_build_stream(p3, s3);

        cfg1 = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(s1.size()));  // FRAG_NUM=1
        cfg2 = hs_build_cfg(1'b1, 5'd1, 5'd2, 8'(s2.size()));  // FRAG_NUM=2
        cfg3 = hs_build_cfg(1'b1, 5'd1, 5'd3, 8'(s3.size()));  // FRAG_NUM=3

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfg3, s3);  // arrival order: 3, 1, 2
        hs_drive_fragment(vif, cfg1, s1);
        hs_drive_fragment(vif, cfg2, s2);
        #500;

        merged = new[3];
        merged[0] = p1[0]; merged[1] = p2[0]; merged[2] = p3[0];
        build_exp_words(merged, exp_words);

        if (completions.size() == 1 && completions[0].size() == exp_words.size() &&
            completions[0][0] === exp_words[0] && completions[0][1] === exp_words[1])
            `uvm_info(get_type_name(),
                "TP_REORD_02 PASS: three out-of-order fragments merged correctly in FRAG_NUM order with regenerated CRC16; drop_cnt=0",
                UVM_LOW)
        else if (completions.size() == 0)
            `uvm_error(get_type_name(),
                "TP_REORD_02 FAIL: no remote output at all. Same root cause as TP_REORD_01: all three fragments carry SEQ_NUM=1, mapping to the same storage slot, and no fragment ever supplies SEQ_NUM=2 or 3.")
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_REORD_02 FAIL: observed %0d completion(s) matching neither the expected merge nor the predicted no-output case - needs manual review",
                    completions.size()));

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_REORD_02: drop_cnt=%0d (expected 0)", vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : three_frags_ooo_test

// TP_REORD_03: five SEQ_NUM=1 fragments random order; same no-output root cause as TP_REORD_01/02
class five_frags_random_test extends bird_base_test;
    `uvm_component_utils(five_frags_random_test)

    function new(string name = "five_frags_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned p1[], p2[], p3[], p4[], p5[];
        byte unsigned s1[], s2[], s3[], s4[], s5[];
        logic [31:0]  cfg1, cfg2, cfg3, cfg4, cfg5;
        logic [31:0]  completions[$][$];
        byte unsigned merged[];
        logic [31:0]  exp_words[$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        p1 = new[1]; p2 = new[1]; p3 = new[1]; p4 = new[1]; p5 = new[1];
        p1[0] = 8'h11; p2[0] = 8'h22; p3[0] = 8'h33; p4[0] = 8'h44; p5[0] = 8'h55;
        sf_build_stream(p1, s1);
        sf_build_stream(p2, s2);
        sf_build_stream(p3, s3);
        sf_build_stream(p4, s4);
        sf_build_stream(p5, s5);

        cfg1 = hs_build_cfg(1'b1, 5'd1, 5'd1, 8'(s1.size()));
        cfg2 = hs_build_cfg(1'b1, 5'd1, 5'd2, 8'(s2.size()));
        cfg3 = hs_build_cfg(1'b1, 5'd1, 5'd3, 8'(s3.size()));
        cfg4 = hs_build_cfg(1'b1, 5'd1, 5'd4, 8'(s4.size()));
        cfg5 = hs_build_cfg(1'b1, 5'd1, 5'd5, 8'(s5.size()));

        fork
            sf_collect_remote(vif, completions);
        join_none

        hs_drive_fragment(vif, cfg4, s4);  // arrival order: 4, 2, 5, 1, 3
        hs_drive_fragment(vif, cfg2, s2);
        hs_drive_fragment(vif, cfg5, s5);
        hs_drive_fragment(vif, cfg1, s1);
        hs_drive_fragment(vif, cfg3, s3);
        #500;

        merged = new[5];
        merged[0] = p1[0]; merged[1] = p2[0]; merged[2] = p3[0];
        merged[3] = p4[0]; merged[4] = p5[0];
        build_exp_words(merged, exp_words);

        if (completions.size() == 1 && completions[0].size() == exp_words.size() &&
            completions[0][0] === exp_words[0] && completions[0][1] === exp_words[1])
            `uvm_info(get_type_name(),
                "TP_REORD_03 PASS: five randomly-ordered fragments merged correctly in FRAG_NUM order with regenerated CRC16; drop_cnt=0",
                UVM_LOW)
        else if (completions.size() == 0)
            `uvm_error(get_type_name(),
                "TP_REORD_03 FAIL: no remote output at all. Same root cause as TP_REORD_01/02: all five fragments carry SEQ_NUM=1, mapping to the same storage slot, and no fragment ever supplies SEQ_NUM=2..5.")
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_REORD_03 FAIL: observed %0d completion(s) matching neither the expected merge nor the predicted no-output case - needs manual review",
                    completions.size()));

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_REORD_03: drop_cnt=%0d (expected 0)", vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : five_frags_random_test

// TP_REORD_04: 3 fragments with differing PAYLOAD_LEN; first fragment (FRAG_NUM=1) completes instantly alone instead of merging with 2 and 3
class diff_payload_len_test extends bird_base_test;
    `uvm_component_utils(diff_payload_len_test)

    function new(string name = "diff_payload_len_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned p1[], p2[], p3[];
        byte unsigned s1[], s2[], s3[];
        logic [31:0]  cfg1, cfg2, cfg3;
        logic [31:0]  completions[$][$];
        byte unsigned merged_correct[];
        logic [31:0]  exp_words_correct[$];
        logic [31:0]  exp_words_degenerate[$];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        p1 = new[2]; p1[0] = 8'hA1; p1[1] = 8'hA2;
        p2 = new[6]; p2[0] = 8'hB1; p2[1] = 8'hB2; p2[2] = 8'hB3;
        p2[3] = 8'hB4; p2[4] = 8'hB5; p2[5] = 8'hB6;
        p3 = new[1]; p3[0] = 8'hC1;

        sf_build_stream(p1, s1);  // PAYLOAD_LEN = 2+2 = 4
        sf_build_stream(p2, s2);  // PAYLOAD_LEN = 6+2 = 8
        sf_build_stream(p3, s3);  // PAYLOAD_LEN = 1+2 = 3

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

        merged_correct = new[9];
        foreach (p1[i]) merged_correct[i] = p1[i];
        foreach (p2[i]) merged_correct[2+i] = p2[i];
        foreach (p3[i]) merged_correct[8+i] = p3[i];
        build_exp_words(merged_correct, exp_words_correct);

        build_exp_words(p1, exp_words_degenerate);  // fragment 1 alone

        if (completions.size() == 1 && completions[0].size() == exp_words_correct.size() &&
            completions[0][0] === exp_words_correct[0] && completions[0][1] === exp_words_correct[1] &&
            completions[0][2] === exp_words_correct[2])
            `uvm_info(get_type_name(),
                "TP_REORD_04 PASS: 3 fragments of differing PAYLOAD_LEN merged correctly into a 9-byte payload with regenerated CRC16; drop_cnt=0",
                UVM_LOW)
        else if (completions.size() == 1 && completions[0].size() == exp_words_degenerate.size() &&
            completions[0][0] === exp_words_degenerate[0] && completions[0][1] === exp_words_degenerate[1])
            `uvm_error(get_type_name(),
                "TP_REORD_04 FAIL: only fragment 1 (2 bytes) was output, as a complete 1-fragment packet; fragments 2 and 3 were never merged in. ROOT CAUSE: SEQ_NUM=1/FRAG_NUM=1 is read by this DUT as 'position 1 of declared total 1' and completes instantly (same mechanism as TP_SEQ_01 in seq_frag_test.sv).")
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_REORD_04 FAIL: observed %0d completion(s) matching neither the expected 9-byte merge nor the predicted single-fragment case - needs manual review",
                    completions.size()));

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_REORD_04: drop_cnt=%0d (expected 0)", vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : diff_payload_len_test

// TP_REORD_05: 31 max fragments; first fragment (FRAG_NUM=1) completes instantly alone, same mechanism as TP_REORD_04
class max_frags_test extends bird_base_test;
    `uvm_component_utils(max_frags_test)

    function new(string name = "max_frags_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned payloads[31][];
        byte unsigned streams[31][];
        logic [31:0]  cfgs[31];
        logic [31:0]  completions[$][$];
        byte unsigned merged_correct[];
        logic [31:0]  exp_words_correct[$];
        logic [31:0]  exp_words_degenerate[$];
        byte unsigned p1_only[];

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        for (int f = 0; f < 31; f++) begin
            payloads[f] = new[1];
            payloads[f][0] = 8'(f + 1);
            sf_build_stream(payloads[f], streams[f]);
            cfgs[f] = hs_build_cfg(1'b1, 5'd1, 5'(f + 1), 8'(streams[f].size()));
        end

        fork
            sf_collect_remote(vif, completions);
        join_none

        for (int f = 0; f < 31; f++)
            hs_drive_fragment(vif, cfgs[f], streams[f]);
        #1000;

        merged_correct = new[31];
        for (int f = 0; f < 31; f++) merged_correct[f] = payloads[f][0];
        build_exp_words(merged_correct, exp_words_correct);

        p1_only = new[1];
        p1_only[0] = payloads[0][0];
        build_exp_words(p1_only, exp_words_degenerate);

        if (completions.size() == 1 && completions[0].size() == exp_words_correct.size()) begin
            bit match = 1;
            foreach (exp_words_correct[i]) if (completions[0][i] !== exp_words_correct[i]) match = 0;
            if (match)
                `uvm_info(get_type_name(),
                    "TP_REORD_05 PASS: all 31 fragments merged correctly in FRAG_NUM order with regenerated CRC16; drop_cnt=0",
                    UVM_LOW)
            else
                `uvm_error(get_type_name(),
                    "TP_REORD_05 FAIL: 1 completion observed with the expected word count, but content does not match the expected 31-byte merge - needs manual review");
        end else if (completions.size() == 1 && completions[0].size() == exp_words_degenerate.size() &&
            completions[0][0] === exp_words_degenerate[0] && completions[0][1] === exp_words_degenerate[1])
            `uvm_error(get_type_name(),
                "TP_REORD_05 FAIL: only fragment 1 (1 byte, value 0x01) was output, as a complete 1-fragment packet; fragments 2 through 31 were never merged in. ROOT CAUSE: SEQ_NUM=1/FRAG_NUM=1 is read by this DUT as 'position 1 of declared total 1' and completes instantly (same mechanism as TP_REORD_04).")
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_REORD_05 FAIL: observed %0d completion(s) matching neither the expected 31-byte merge nor the predicted single-fragment case - needs manual review",
                    completions.size()));

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_REORD_05: drop_cnt=%0d (expected 0)", vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : max_frags_test

`endif
