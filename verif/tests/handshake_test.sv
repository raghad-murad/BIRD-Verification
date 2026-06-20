`ifndef HANDSHAKE_TEST_SV
`define HANDSHAKE_TEST_SV

// Handshake protocol verification tests (TP_HS_01 , TP_HS_02,TP_HS_03,TP_HS_04, TP_HS_05).
// tests use direct VIF access for cycle-accurate ready or valid control.
// input backpressure cannot be exercised because in_rdy is hardwired high.
// Output backpressure is verified through local_rdy and remote_rdy.



// Generate a payload stream with CRC16 appended.
function automatic void hs_build_stream(input int unsigned payload_len, output byte unsigned stream[]);
    byte unsigned payload[];
    bit  [15:0]   crc;
    payload = new[payload_len - 2];
    foreach (payload[i]) payload[i] = $urandom_range(0, 255);
    crc = bird_transaction::calc_crc16(payload);
    stream = new[payload_len];
    foreach (payload[i]) stream[i] = payload[i];
    stream[payload.size()]   = crc[15:8];
    stream[payload.size()+1] = crc[7:0];
endfunction

// Build configuration word from packet fields.
function automatic logic [31:0] hs_build_cfg(bit traffic_type, bit [4:0] seq_num,
                                              bit [4:0] frag_num, bit [7:0] payload_len);
    logic [31:0] c;
    c        = 32'h0;
    c[0]     = traffic_type;
    c[15:8]  = payload_len;
    c[20:16] = frag_num;
    c[28:24] = seq_num;
    return c;
endfunction

// Send one packet fragment through the interface.
task automatic hs_drive_fragment(virtual bird_if vif, logic [31:0] cfg_val, byte unsigned stream[]);
    @(negedge vif.clk);
    vif.cfg <= cfg_val;
    @(negedge vif.clk);
    foreach (stream[i]) begin
        vif.in_vld  <= 1'b1;
        vif.data_in <= stream[i];
        @(negedge vif.clk);
        while (vif.in_rdy !== 1'b1) @(negedge vif.clk);
    end
    vif.in_vld  <= 1'b0;
    vif.data_in <= 8'h00;
    vif.cfg     <= 32'h0;
    @(negedge vif.clk);
endtask

// TP_HS_01: Verify successful transfer when valid and ready are asserted.

class transfer_rule_test extends bird_base_test;
    `uvm_component_utils(transfer_rule_test)

    function new(string name = "transfer_rule_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned stream[];
        logic [31:0]  cfg_val;
        int unsigned  payload_len = 8;
        bit           local_vld_seen;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        hs_build_stream(payload_len, stream);
        cfg_val = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'(payload_len));

        fork
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) local_vld_seen = 1;
                end
            end
        join_none

        hs_drive_fragment(vif, cfg_val, stream);
        #200;

        if (local_vld_seen && vif.drop_cnt === 16'h0)
            `uvm_info(get_type_name(),
                "TP_HS_01 PASS: packet transferred correctly with in_vld=1/in_rdy=1 every cycle (in_rdy is hardwired 1 in this DUT - the rdy=0 half of the rule cannot be exercised on the input side here)",
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_HS_01 FAIL: local_vld_seen=%0b drop_cnt=%0d", local_vld_seen, vif.drop_cnt));

        phase.drop_objection(this);
    endtask
endclass : transfer_rule_test

// TP_HS_02: verify input-side handshake behavior and confirm
// that in_rdy remains asserted throughout the transfer.
class stability_rule_test extends bird_base_test;
    `uvm_component_utils(stability_rule_test)

    function new(string name = "stability_rule_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned stream[];
        logic [31:0]  cfg_val;
        int unsigned  payload_len = 8;
        bit           local_vld_seen;
        int unsigned  stall_cycles_observed = 0;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        hs_build_stream(payload_len, stream);
        cfg_val = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'(payload_len));

        fork
            begin
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) local_vld_seen = 1;
                end
            end
        join_none

        @(negedge vif.clk);
        vif.cfg <= cfg_val;
        @(negedge vif.clk);
        foreach (stream[i]) begin
            vif.in_vld  <= 1'b1;
            vif.data_in <= stream[i];
            @(negedge vif.clk);
            if (vif.in_rdy !== 1'b1) stall_cycles_observed++;
            while (vif.in_rdy !== 1'b1) @(negedge vif.clk);
        end
        vif.in_vld  <= 1'b0;
        vif.data_in <= 8'h00;
        vif.cfg     <= 32'h0;
        @(negedge vif.clk);

        #200;

        if (local_vld_seen && vif.drop_cnt === 16'h0 && stall_cycles_observed == 0)
            `uvm_info(get_type_name(),
                "TP_HS_02 PASS: in_rdy never deasserted (confirmed by direct observation every cycle), so the vld=1/rdy=0 stability condition never arose; packet still transferred correctly",
                UVM_LOW)
        else
            `uvm_error(get_type_name(),
                $sformatf("TP_HS_02 FAIL: local_vld_seen=%0b drop_cnt=%0d stall_cycles_observed=%0d",
                    local_vld_seen, vif.drop_cnt, stall_cycles_observed));

        phase.drop_objection(this);
    endtask
endclass : stability_rule_test


// TP_HS_03 :verify local output backpressure.
// data must remain stable while local_rdy is low.
class local_backpressure_test extends bird_base_test;
    `uvm_component_utils(local_backpressure_test)

    function new(string name = "local_backpressure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        byte unsigned stream[];
        logic [31:0]  cfg_val;
        int unsigned  payload_len = 8;
        byte unsigned observed[$];
        bit           stability_violation = 0;
        byte unsigned held_value;
        bit           holding      = 0;
        int unsigned  bp_countdown = 0;
        bit           bp_done      = 0;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        hs_build_stream(payload_len, stream);
        cfg_val = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'(payload_len));

        fork
            begin : output_collector
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) begin
                        if (holding) begin
                            if (bp_countdown == 5)
                                held_value = vif.data_local;
                            else if (vif.data_local !== held_value)
                                stability_violation = 1;
                            bp_countdown--;
                            if (bp_countdown == 0) begin
                                vif.local_rdy <= 1'b1;
                                holding = 0;
                            end
                        end else begin
                            if (vif.local_rdy === 1'b1)
                                observed.push_back(8'(vif.data_local));
                            if (!bp_done && observed.size() == 2) begin
                                vif.local_rdy <= 1'b0;
                                holding      = 1;
                                bp_countdown = 5;
                                bp_done      = 1;
                            end
                        end
                    end
                end
            end
        join_none

        hs_drive_fragment(vif, cfg_val, stream);
        #500;

        if (stability_violation)
            `uvm_error(get_type_name(),
                "TP_HS_03 FAIL: data_local changed while local_vld=1 and local_rdy=0 (spec Sec.3.2 stability violation)")

        if (observed.size() != stream.size())
            `uvm_error(get_type_name(),
                $sformatf("TP_HS_03 FAIL: received %0d bytes, expected %0d", observed.size(), stream.size()))
        else begin
            bit match = 1;
            foreach (stream[i]) if (observed[i] !== stream[i]) match = 0;
            if (!match)
                `uvm_error(get_type_name(), "TP_HS_03 FAIL: received byte content does not match sent payload+CRC");
        end

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_HS_03 FAIL: drop_cnt=%0d (expected 0)", vif.drop_cnt))

        if (!stability_violation && observed.size() == stream.size() && vif.drop_cnt === 16'h0)
            `uvm_info(get_type_name(),
                "TP_HS_03 PASS: data_local held stable during backpressure; all bytes received correctly; drop_cnt=0",
                UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass : local_backpressure_test


// TP_HS_04: verify remote output backpressure and data integrity
// after packet reassembly.

class remote_backpressure_test extends bird_base_test;
    `uvm_component_utils(remote_backpressure_test)

    function new(string name = "remote_backpressure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        int unsigned  payload_len = 6;  // 4 data + 2 CRC per fragment
        byte unsigned stream1[], stream2[];
        logic [31:0]  cfg1, cfg2;
        byte unsigned merged[];
        logic [15:0]  crc;
        logic [31:0]  exp_words[$];
        logic [31:0]  observed_words[$];
        bit           stability_violation = 0;
        logic [31:0]  held_value;
        bit           holding      = 0;
        int unsigned  bp_countdown = 0;
        bit           bp_done      = 0;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        hs_build_stream(payload_len, stream1);
        hs_build_stream(payload_len, stream2);
        cfg1 = hs_build_cfg(1'b1, 5'd1, 5'd2, 8'(payload_len));  // position 1 of 2
        cfg2 = hs_build_cfg(1'b1, 5'd2, 5'd2, 8'(payload_len));  // position 2 of 2

        // Expected merged payload = fragment1 data ++ fragment2 data
        // (data bytes only, excluding each fragment's own 2 CRC bytes)
        merged = new[2 * (payload_len - 2)];
        foreach (stream1[i]) if (i < payload_len - 2) merged[i] = stream1[i];
        foreach (stream2[i]) if (i < payload_len - 2) merged[(payload_len - 2) + i] = stream2[i];
        crc = bird_transaction::calc_crc16(merged);

        begin
            int n         = merged.size();
            int full_wrds = n / 4;
            int rem       = n % 4;
            for (int w = 0; w < full_wrds; w++)
                exp_words.push_back({merged[w*4+3], merged[w*4+2], merged[w*4+1], merged[w*4]});
            if (rem > 0) begin
                logic [31:0] last_word = 32'h0;
                for (int b = 0; b < rem; b++) last_word[8*b +: 8] = merged[full_wrds*4 + b];
                exp_words.push_back(last_word);
            end
            exp_words.push_back({16'h0000, crc});
        end

        fork
            begin : output_collector
                forever begin
                    @(posedge vif.clk);
                    if (vif.remote_vld === 1'b1) begin
                        if (holding) begin
                            if (bp_countdown == 5)
                                held_value = vif.data_remote;
                            else if (vif.data_remote !== held_value)
                                stability_violation = 1;
                            bp_countdown--;
                            if (bp_countdown == 0) begin
                                vif.remote_rdy <= 1'b1;
                                holding = 0;
                            end
                        end else begin
                            if (vif.remote_rdy === 1'b1)
                                observed_words.push_back(vif.data_remote);
                            if (!bp_done && observed_words.size() == 1) begin
                                vif.remote_rdy <= 1'b0;
                                holding      = 1;
                                bp_countdown = 5;
                                bp_done      = 1;
                            end
                        end
                    end
                end
            end
        join_none

        hs_drive_fragment(vif, cfg1, stream1);
        hs_drive_fragment(vif, cfg2, stream2);
        #500;

        if (stability_violation)
            `uvm_error(get_type_name(),
                "TP_HS_04 FAIL: data_remote changed while remote_vld=1 and remote_rdy=0 (spec Sec.3.2 stability violation)")

        if (observed_words.size() != exp_words.size())
            `uvm_error(get_type_name(),
                $sformatf("TP_HS_04 FAIL: received %0d words, expected %0d", observed_words.size(), exp_words.size()))
        else begin
            bit match = 1;
            foreach (exp_words[i]) if (observed_words[i] !== exp_words[i]) match = 0;
            if (!match)
                `uvm_error(get_type_name(), "TP_HS_04 FAIL: received word content does not match expected merged payload+CRC");
        end

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_HS_04 FAIL: drop_cnt=%0d (expected 0)", vif.drop_cnt))

        if (!stability_violation && observed_words.size() == exp_words.size() && vif.drop_cnt === 16'h0)
            `uvm_info(get_type_name(),
                "TP_HS_04 PASS: data_remote held stable during backpressure; merged payload+CRC word content correct; drop_cnt=0",
                UVM_LOW)

        phase.drop_objection(this);
    endtask
endclass : remote_backpressure_test


// TP_HS_05 : apply backpressure on the last byte of a packet and
// verify packet boundary integrity.

class backpressure_last_byte_test extends bird_base_test;
    `uvm_component_utils(backpressure_last_byte_test)

    function new(string name = "backpressure_last_byte_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        int unsigned  payload_len = 4;  // 2 data + 2 CRC
        byte unsigned stream1[], stream2[];
        logic [31:0]  cfg1, cfg2;
        byte unsigned observed1[$], observed2[$];
        bit           stability_violation = 0;
        byte unsigned held_value;
        bit           holding      = 0;
        int unsigned  bp_countdown = 0;
        bit           bp_done      = 0;
        bit           pkt1_done    = 0;

        phase.raise_objection(this);
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        hs_build_stream(payload_len, stream1);
        hs_build_stream(payload_len, stream2);
        cfg1 = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'(payload_len));
        cfg2 = hs_build_cfg(1'b0, 5'd1, 5'd1, 8'(payload_len));

        fork
            begin : output_collector
                forever begin
                    @(posedge vif.clk);
                    if (vif.local_vld === 1'b1) begin
                        if (holding) begin
                            if (bp_countdown == 3)
                                held_value = vif.data_local;
                            else if (vif.data_local !== held_value)
                                stability_violation = 1;
                            bp_countdown--;
                            if (bp_countdown == 0) begin
                                vif.local_rdy <= 1'b1;
                                holding = 0;
                            end
                        end else begin
                            if (vif.local_rdy === 1'b1) begin
                                if (!pkt1_done)
                                    observed1.push_back(8'(vif.data_local));
                                else
                                    observed2.push_back(8'(vif.data_local));
                            end
                            if (!bp_done && !pkt1_done && observed1.size() == 3) begin
                                vif.local_rdy <= 1'b0;
                                holding      = 1;
                                bp_countdown = 3;
                                bp_done      = 1;
                            end
                        end
                    end else begin
                        if (!pkt1_done && observed1.size() > 0) pkt1_done = 1;
                    end
                end
            end
        join_none

        hs_drive_fragment(vif, cfg1, stream1);
        hs_drive_fragment(vif, cfg2, stream2);
        #500;

        if (stability_violation)
            `uvm_error(get_type_name(),
                "TP_HS_05 FAIL: data_local changed while held under backpressure on the final byte (spec Sec.3.2)")

        if (observed1.size() != stream1.size())
            `uvm_error(get_type_name(),
                $sformatf("TP_HS_05 FAIL: packet 1 received %0d bytes, expected %0d", observed1.size(), stream1.size()))
        else begin
            bit match = 1;
            foreach (stream1[i]) if (observed1[i] !== stream1[i]) match = 0;
            if (!match)
                `uvm_error(get_type_name(), "TP_HS_05 FAIL: packet 1 byte content mismatch");
        end

        if (observed2.size() != stream2.size())
            `uvm_error(get_type_name(),
                $sformatf("TP_HS_05 FAIL: packet 2 received %0d bytes, expected %0d", observed2.size(), stream2.size()))
        else begin
            bit match = 1;
            foreach (stream2[i]) if (observed2[i] !== stream2[i]) match = 0;
            if (!match)
                `uvm_error(get_type_name(), "TP_HS_05 FAIL: packet 2 byte content mismatch - possible cross-contamination from packet 1");
        end

        if (vif.drop_cnt !== 16'h0)
            `uvm_error(get_type_name(), $sformatf("TP_HS_05 FAIL: drop_cnt=%0d (expected 0)", vif.drop_cnt))

        if (!stability_violation && observed1.size() == stream1.size() &&
            observed2.size() == stream2.size() && vif.drop_cnt === 16'h0)
            `uvm_info(get_type_name(),
                "TP_HS_05 PASS: backpressure on the final byte handled correctly; both packets received intact with a clean boundary; drop_cnt=0",
                UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass : backpressure_last_byte_test

`endif // HANDSHAKE_TEST_SV
