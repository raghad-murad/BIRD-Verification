// Stimulus targeting code-coverage holes not hit by functional/drop/remote sequences

// Exercises every term combination of bird.sv's line-298 drop-while-active expression
class remote_drop_while_active_seq extends bird_base_seq;
    `uvm_object_utils(remote_drop_while_active_seq)

    function new(string name = "remote_drop_while_active_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;

        // Start 3-fragment remote packet; position=1 sets active_seq=1
        pkt = bird_transaction::type_id::create("start_frag");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 1;
            frag_num     == 3;
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        finish_item(pkt);

        // (0,1,1): LOCAL invalid frag matching active_seq; remote stays active (cfg[0]==1 term false)
        pkt = bird_transaction::type_id::create("local_invalid_match");
        start_item(pkt);
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 0;
            seq_num      == 1;
            frag_num     == 2;   // invalid: LOCAL requires frag_num==1
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);

        // (1,1,0): REMOTE invalid, position(2)!=active_seq(1) -> remote stays active
        pkt = bird_transaction::type_id::create("remote_invalid_nomatch");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 2;
            frag_num     == 3;
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.rsvd_7_1 = 7'h7f;   // force cfg_invalid()
        finish_item(pkt);

        // (1,1,1): REMOTE invalid, position(1)==active_seq(1) -> clears active remote accumulation
        pkt = bird_transaction::type_id::create("remote_invalid_match");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 1;
            frag_num     == 3;
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.rsvd_23_21 = 3'h7;  // force cfg_invalid()
        finish_item(pkt);

        `uvm_info(get_type_name(),
            "Exercised line-298 drop-while-active condition combinations", UVM_LOW)
    endtask
endclass : remote_drop_while_active_seq

// position(5)>total(3) keeps remote_active=0 through RX_PAYLOAD bytes (rx_seq>rx_frag term combo)
class remote_payload_inactive_seq extends bird_base_seq;
    `uvm_object_utils(remote_payload_inactive_seq)

    function new(string name = "remote_payload_inactive_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;

        pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        pkt.c_valid_seq_num.constraint_mode(0);
        pkt.c_valid_frag_num.constraint_mode(0);
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 5;
            frag_num     == 3;
            payload_len  inside {[8:32]};   // multi-byte payload -> RX_PAYLOAD entered
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);

        `uvm_info(get_type_name(),
            "Sent multi-byte remote frag with pos>total while inactive", UVM_LOW)
    endtask
endclass : remote_payload_inactive_seq
