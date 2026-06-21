// SEQ_NUM=0 should trigger drop
class drop_seq_num_zero_seq extends bird_base_seq;
    `uvm_object_utils(drop_seq_num_zero_seq)

    function new(string name = "drop_seq_num_zero_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        // Disable the valid-seq constraint so seq_num==0 can be randomised
        pkt.c_valid_seq_num.constraint_mode(0);
        if (!pkt.randomize() with {
            seq_num == 0;
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);
        `uvm_info(get_type_name(), "Sent SEQ_NUM=0 packet (expect drop)", UVM_LOW)
    endtask
endclass : drop_seq_num_zero_seq

// FRAG_NUM=0 should trigger drop
class drop_frag_num_zero_seq extends bird_base_seq;
    `uvm_object_utils(drop_frag_num_zero_seq)

    function new(string name = "drop_frag_num_zero_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with { payload_len inside {[1:32]}; })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.frag_num = 0;
        pkt.crc16    = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);
        `uvm_info(get_type_name(), "Sent FRAG_NUM=0 packet (expect drop)", UVM_LOW)
    endtask
endclass : drop_frag_num_zero_seq

// Nonzero reserved bits should trigger drop
class drop_reserved_bits_seq extends bird_base_seq;
    `uvm_object_utils(drop_reserved_bits_seq)

    function new(string name = "drop_reserved_bits_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with {
            payload_len inside {[1:32]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        // Force at least one reserved field non-zero
        pkt.rsvd_7_1 = 7'h55;
        finish_item(pkt);
        `uvm_info(get_type_name(),
            "Sent packet with nonzero reserved bits (expect drop)", UVM_LOW)
    endtask
endclass : drop_reserved_bits_seq

// Nonzero rsvd[23:21] should trigger drop
class drop_reserved_bits_23_21_seq extends bird_base_seq;
    `uvm_object_utils(drop_reserved_bits_23_21_seq)

    function new(string name = "drop_reserved_bits_23_21_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with {
            payload_len inside {[1:32]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.rsvd_23_21 = 3'h5;
        finish_item(pkt);
        `uvm_info(get_type_name(),
            "Sent packet with nonzero rsvd[23:21] (expect drop)", UVM_LOW)
    endtask
endclass : drop_reserved_bits_23_21_seq

// Nonzero rsvd[31:29] should trigger drop
class drop_reserved_bits_31_29_seq extends bird_base_seq;
    `uvm_object_utils(drop_reserved_bits_31_29_seq)

    function new(string name = "drop_reserved_bits_31_29_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with {
            payload_len inside {[1:32]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.rsvd_31_29 = 3'h5;
        finish_item(pkt);
        `uvm_info(get_type_name(),
            "Sent packet with nonzero rsvd[31:29] (expect drop)", UVM_LOW)
    endtask
endclass : drop_reserved_bits_31_29_seq

// LOCAL with frag_num!=1 should drop (spec Sec.6, TP_CFG_09)
class drop_local_frag_num_not_one_seq extends bird_base_seq;
    `uvm_object_utils(drop_local_frag_num_not_one_seq)

    function new(string name = "drop_local_frag_num_not_one_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        // Disable the local_frag constraint so frag_num != 1 is allowed
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 0;   // LOCAL traffic
            seq_num      == 1;   // seq_num valid (only frag_num violates)
            frag_num     == 2;   // frag_num != 1 → drop condition (spec Sec.6)
            payload_len  inside {[1:32]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);
        `uvm_info(get_type_name(),
            "Sent LOCAL packet with frag_num=2, seq_num=1 (expect drop)", UVM_LOW)
    endtask
endclass : drop_local_frag_num_not_one_seq

// seq_num > frag_num triggers drop in DUT (rx_seq > rx_frag)
class drop_mismatch_seq_num_seq extends bird_base_seq;
    `uvm_object_utils(drop_mismatch_seq_num_seq)

    function new(string name = "drop_mismatch_seq_num_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;

        pkt = bird_transaction::type_id::create("pkt_drop");
        start_item(pkt);
        // Disable constraints that enforce seq_num <= frag_num
        pkt.c_valid_seq_num.constraint_mode(0);
        pkt.c_valid_frag_num.constraint_mode(0);
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 5;   // position = 5
            frag_num     == 3;   // total = 3 — position > total → drop
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);

        `uvm_info(get_type_name(),
            "Sent seq_num=5 frag_num=3 (pos>total → expect drop)", UVM_LOW)
    endtask
endclass : drop_mismatch_seq_num_seq

// TP_CNT_04: 5 buffered in-order frags of an incomplete 6-frag packet, then a mismatched
// trigger drops the whole accumulation as one drop
class multi_frag_drop_once_seq extends bird_base_seq;
    `uvm_object_utils(multi_frag_drop_once_seq)
    int unsigned num_frags = 5;
    int unsigned total_frags = 6;

    function new(string name = "multi_frag_drop_once_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;

        // Buffer 5 of 6 fragments — packet remains incomplete/active
        for (int f = 1; f <= num_frags; f++) begin
            pkt = bird_transaction::type_id::create($sformatf("pkt_f%0d", f));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == f;
                frag_num     == total_frags;
                payload_len  inside {[4:16]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
            finish_item(pkt);
        end

        // Mismatched trigger fragment (position>total) drops the whole accumulation as one drop
        pkt = bird_transaction::type_id::create("pkt_trigger");
        start_item(pkt);
        pkt.c_valid_seq_num.constraint_mode(0);
        pkt.c_valid_frag_num.constraint_mode(0);
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 10;
            frag_num     == 3;
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);

        `uvm_info(get_type_name(),
            $sformatf("Buffered %0d/%0d remote frags then sent mismatched trigger (expect single drop)",
                num_frags, total_frags), UVM_LOW)
    endtask
endclass : multi_frag_drop_once_seq
