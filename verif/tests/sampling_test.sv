`ifndef SAMPLING_TEST_SV
`define SAMPLING_TEST_SV

// TP_SMPL_02 (spec Sec.2.3): cfg is sampled only on the first payload byte; drives vif directly to glitch cfg after byte 0 and relies on the scoreboard's byte-for-byte check against the original cfg
class cfg_change_ignored_test extends bird_base_test;
    `uvm_component_utils(cfg_change_ignored_test)

    function new(string name = "cfg_change_ignored_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        int unsigned payload_len = 20;  // on-wire bytes: 18 data + 2 CRC
        byte unsigned payload[];
        bit  [15:0]   crc;
        byte unsigned stream[];
        logic [31:0]  orig_cfg;
        logic [31:0]  glitch_cfg;
        bit           local_vld_seen;

        phase.raise_objection(this);

        // Wait for reset deassertion first, else the drive loop below starts mid-stream/mid-glitch
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        // Build a normal, fully valid local payload + CRC.
        payload = new[payload_len - 2];
        foreach (payload[i]) payload[i] = $urandom_range(0, 255);
        crc = bird_transaction::calc_crc16(payload);

        stream = new[payload_len];
        foreach (payload[i]) stream[i] = payload[i];
        stream[payload.size()]   = crc[15:8];
        stream[payload.size()+1] = crc[7:0];

        // Original cfg: valid LOCAL, SEQ_NUM=1, FRAG_NUM=1, this payload_len.
        orig_cfg          = 32'h0;
        orig_cfg[0]       = 1'b0;
        orig_cfg[15:8]    = 8'(payload_len);
        orig_cfg[20:16]   = 5'd1;
        orig_cfg[28:24]   = 5'd1;

        // Glitch cfg: PAYLOAD_LEN forced to 0; must be ignored once the fragment is underway (spec)
        glitch_cfg        = orig_cfg;
        glitch_cfg[15:8]  = 8'd0;

        fork
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) local_vld_seen = 1;
                end
            end
        join_none

        @(negedge vif.clk);
        vif.cfg <= orig_cfg;
        @(negedge vif.clk);

        foreach (stream[i]) begin
            vif.in_vld  <= 1'b1;
            vif.data_in <= stream[i];
            @(negedge vif.clk);
            while (vif.in_rdy !== 1'b1) @(negedge vif.clk);
            if (i == 0) begin
                `uvm_info(get_type_name(),
                    "Byte 0 sent with valid cfg - glitching cfg for cycle 1 onward (TP_SMPL_02)", UVM_LOW)
                vif.cfg <= glitch_cfg;
            end
        end

        vif.in_vld  <= 1'b0;
        vif.data_in <= 8'h00;
        vif.cfg     <= 32'h0;
        @(negedge vif.clk);

        #200;

        if (local_vld_seen)
            `uvm_info(get_type_name(),
                "TP_SMPL_02: local output was produced; byte-for-byte correctness against the original (first-sampled) cfg is checked by bird_scoreboard",
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                "TP_SMPL_02 FAIL: no local output observed at all for a fragment that was valid on its first byte");

        phase.drop_objection(this);
    endtask
endclass : cfg_change_ignored_test

`endif
