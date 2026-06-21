`ifndef CFG_TEST_SV
`define CFG_TEST_SV

// TP_CFG_10: PAYLOAD_LEN>255 is impossible (8-bit field); tests the only real boundary, 0 (invalid) vs 255 (valid max), driven directly via vif
class payload_len_boundary_test extends bird_base_test;
    `uvm_component_utils(payload_len_boundary_test)

    function new(string name = "payload_len_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned stream_max[];
        byte unsigned stream_zero[3];
        logic [31:0]  cfg_max, cfg_zero;
        bit           local_vld_seen_max;
        bit           local_vld_seen_zero;
        int unsigned  drop_cnt_before, drop_cnt_after_max, drop_cnt_after_zero;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        drop_cnt_before = vif.drop_cnt;

        // PAYLOAD_LEN=255 (valid max): local, SEQ_NUM=1, FRAG_NUM=1
        hs_build_stream(255, stream_max);
        cfg_max = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'd255);

        fork
            forever begin
                @(posedge vif.clk);
                if (vif.local_vld === 1'b1) local_vld_seen_max = 1'b1;
            end
        join_none

        hs_drive_fragment(vif, cfg_max, stream_max);
        #200;
        drop_cnt_after_max = vif.drop_cnt;

        // PAYLOAD_LEN=0 (the only invalid length): local, SEQ_NUM=1, FRAG_NUM=1
        stream_zero[0] = 8'h00;
        stream_zero[1] = 8'h00;
        stream_zero[2] = 8'h00;
        cfg_zero = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'd0);

        fork
            forever begin
                @(posedge vif.clk);
                if (vif.local_vld === 1'b1) local_vld_seen_zero = 1'b1;
            end
        join_none

        hs_drive_fragment(vif, cfg_zero, stream_zero);
        #200;
        drop_cnt_after_zero = vif.drop_cnt;

        if (local_vld_seen_max && (drop_cnt_after_max == drop_cnt_before) &&
            !local_vld_seen_zero && (drop_cnt_after_zero == drop_cnt_before + 1))
            `uvm_info(get_type_name(),
                $sformatf("TP_CFG_10 PASS: PAYLOAD_LEN=255 accepted (local_vld seen, drop_cnt unchanged at %0d); PAYLOAD_LEN=0 dropped (no local_vld, drop_cnt incremented by 1 to %0d)",
                    drop_cnt_after_max, drop_cnt_after_zero), UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_CFG_10 FAIL: PAYLOAD_LEN=255 -> local_vld_seen=%0b drop_cnt %0d->%0d (expected vld seen, no drop); PAYLOAD_LEN=0 -> local_vld_seen=%0b drop_cnt %0d->%0d (expected no vld, +1 drop)",
                    local_vld_seen_max, drop_cnt_before, drop_cnt_after_max,
                    local_vld_seen_zero, drop_cnt_after_max, drop_cnt_after_zero));

        phase.drop_objection(this);
    endtask
endclass : payload_len_boundary_test

`endif
