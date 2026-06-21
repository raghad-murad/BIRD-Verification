`ifndef BIRD_MONITOR_SV
`define BIRD_MONITOR_SV

// Monitors input interface, broadcasts transactions to scoreboard/coverage
class bird_in_monitor extends uvm_monitor;
    
    `uvm_component_utils(bird_in_monitor)

    virtual bird_if.monitor_mp vif;

    // Analysis port to scoreboard/coverage
    uvm_analysis_port #(bird_transaction) ap;

    function new(string name = "bird_in_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        
        super.build_phase(phase);
        
        ap = new("ap", this);
        
        if (!uvm_config_db #(virtual bird_if.monitor_mp)::get( this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get virtual interface")
    
    endfunction

    task run_phase(uvm_phase phase);
        
        // Wait for reset deassertion
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        forever begin
            collect_packet();
        end

    endtask

    // Collect one complete fragment transaction
    task collect_packet();

        bird_transaction pkt;
        byte unsigned stream[$];
        logic [31:0] captured_cfg;
        logic [7:0]  byte_val;
        bit first_byte;
        int expected_len;
        int total_bytes;                 // payload + 2 CRC bytes

        first_byte = 1;
        stream.delete();

        // Wait for first valid+ready beat with in_vld asserted
        @(vif.monitor_cb);
        
        while (!(vif.monitor_cb.in_vld === 1'b1 && vif.monitor_cb.in_rdy === 1'b1))
            @(vif.monitor_cb);

        // Capture cfg on first beat
        captured_cfg = vif.monitor_cb.cfg;

        // Decode cfg fields
        pkt = bird_transaction::type_id::create("mon_pkt");
        pkt.traffic_type = captured_cfg[0];
        pkt.rsvd_7_1     = captured_cfg[7:1];
        pkt.payload_len  = captured_cfg[15:8];
        pkt.frag_num     = captured_cfg[20:16];
        pkt.rsvd_23_21   = captured_cfg[23:21];
        pkt.seq_num      = captured_cfg[28:24];
        pkt.rsvd_31_29   = captured_cfg[31:29];

        // Floor to 3: PAYLOAD_LEN=0 is invalid but RX FSM still consumes 1 data + 2 CRC bytes
        total_bytes = (int'(pkt.payload_len) >= 1) ? int'(pkt.payload_len) : 3;

        // Collect byte stream; first byte already visible on this cycle
        stream.push_back(8'(vif.monitor_cb.data_in));
        @(vif.monitor_cb);

        while (stream.size() < total_bytes) begin
            if (vif.monitor_cb.in_vld === 1'b1 && vif.monitor_cb.in_rdy === 1'b1) begin
                stream.push_back(8'(vif.monitor_cb.data_in));
            end
            if (stream.size() < total_bytes)
                @(vif.monitor_cb);
        end

        // PAYLOAD_LEN=0 is invalid: skip payload/CRC extraction
        if (int'(pkt.payload_len) >= 2) begin

            pkt.payload = new[int'(pkt.payload_len) - 2];

            for (int i = 0; i < int'(pkt.payload_len) - 2; i++)
                pkt.payload[i] = stream[i];

            pkt.crc16 = {stream[int'(pkt.payload_len) - 2], stream[int'(pkt.payload_len) - 1]};
        
        end else begin
           
            pkt.payload = new[0];
        
        end

        `uvm_info(get_type_name(), $sformatf("Collected: %s", pkt.convert2string()), UVM_HIGH)

        ap.write(pkt);
    
    endtask

endclass : bird_in_monitor


// Container for observed output transactions
class bird_output_txn extends uvm_sequence_item;
    
    `uvm_object_utils(bird_output_txn)

    typedef enum {LOCAL_TXN, REMOTE_TXN} txn_type_e;

    txn_type_e       txn_type;
    byte unsigned    local_data[$];   // bytes observed on local output
    logic [31:0]     remote_data[$];  // 32-bit words on remote output
    logic [15:0]     drop_cnt_val;    // drop_cnt snapshot when last beat seen

    function new(string name = "bird_output_txn");
        super.new(name);
    endfunction

    function string convert2string();
        string s;
        
        if (txn_type == LOCAL_TXN) begin
            s = $sformatf("LOCAL_TXN: %0d bytes, drop_cnt=%0d", local_data.size(), drop_cnt_val);
        
        end else begin
            s = $sformatf("REMOTE_TXN: %0d words, drop_cnt=%0d", remote_data.size(), drop_cnt_val);
        end
        
        return s;
    
    endfunction

endclass : bird_output_txn

// Watches local and remote output interfaces in parallel
class bird_out_monitor extends uvm_monitor;
    
    `uvm_component_utils(bird_out_monitor)

    virtual bird_if.monitor_mp vif;

    // Analysis ports for local and remote outputs
    uvm_analysis_port #(bird_output_txn) local_ap;
    uvm_analysis_port #(bird_output_txn) remote_ap;

    function new(string name = "bird_out_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        
        super.build_phase(phase);
        
        local_ap  = new("local_ap",  this);
        remote_ap = new("remote_ap", this);
        
        if (!uvm_config_db #(virtual bird_if.monitor_mp)::get( this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get virtual interface")

    endfunction

    task run_phase(uvm_phase phase);

        // Wait for reset deassertion
        @(posedge vif.clk iff vif.rst_n === 1'b1);

        // Monitor local and remote in parallel
        fork
            monitor_local();
            monitor_remote();
        join_none

    endtask

    task monitor_local();

        bird_output_txn txn;

        forever begin

            @(vif.monitor_cb);

            if (vif.monitor_cb.local_vld === 1'b1 &&
                vif.monitor_cb.local_rdy === 1'b1) begin
                txn = bird_output_txn::type_id::create("local_txn");
                txn.txn_type = bird_output_txn::LOCAL_TXN;
                txn.local_data.push_back(8'(vif.monitor_cb.data_local));
                txn.drop_cnt_val = vif.monitor_cb.drop_cnt;

                // Continue collecting while local_vld stays high
                @(vif.monitor_cb);
                while (vif.monitor_cb.local_vld === 1'b1) begin
                    if (vif.monitor_cb.local_rdy === 1'b1)
                        txn.local_data.push_back(8'(vif.monitor_cb.data_local));
                    @(vif.monitor_cb);
                end

                `uvm_info(get_type_name(),
                    $sformatf("Local: %s", txn.convert2string()), UVM_MEDIUM)
                local_ap.write(txn);
            end

        end

    endtask

    task monitor_remote();

        bird_output_txn txn;

        forever begin

            @(vif.monitor_cb);
            if (vif.monitor_cb.remote_vld === 1'b1 &&
                vif.monitor_cb.remote_rdy === 1'b1) begin
                txn = bird_output_txn::type_id::create("remote_txn");
                txn.txn_type = bird_output_txn::REMOTE_TXN;
                txn.drop_cnt_val = vif.monitor_cb.drop_cnt;

                // word[0] is visible for two clocks (NB assignment); advance once to count it once
                @(vif.monitor_cb);
                while (vif.monitor_cb.remote_vld === 1'b1) begin
                    if (vif.monitor_cb.remote_rdy === 1'b1)
                        txn.remote_data.push_back(vif.monitor_cb.data_remote);
                    @(vif.monitor_cb);
                end

                `uvm_info(get_type_name(),
                    $sformatf("Remote: %s", txn.convert2string()), UVM_MEDIUM)
                remote_ap.write(txn);
            end

        end

    endtask

endclass : bird_out_monitor


`endif
