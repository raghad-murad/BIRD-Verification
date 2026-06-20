// code_cov_seq.sv — coverage-directed stimulus
// targets uncovered branches or conditions in bird.sv


// remote_drop_while_active_seq
// Exercises different combinations of remote-active conditions
// to cover drop logic in line-298 expression.

class remote_drop_while_active_seq extends bird_base_seq;
    `uvm_object_utils(remote_drop_while_active_seq)

    function new(string name = "remote_drop_while_active_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;

        // Start remote packet (3 fragments)

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
// local invalid fragment to keep remote active

        pkt = bird_transaction::type_id::create("local_invalid_match");
        start_item(pkt);
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 0;
            seq_num      == 1;
            frag_num     == 2;   
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);

        // remote invalid (no seq match)
        pkt = bird_transaction::type_id::create("remote_invalid_nomatch");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 2;
            frag_num     == 3;
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.rsvd_7_1 = 7'h7f;  

        // remote invalid (matches active sequence)
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

// remote_payload_inactive_seq
// Forces remote FSM into inactive state and exercises payload
// processing path when remote_active == 0.

class remote_payload_inactive_seq extends bird_base_seq;
    `uvm_object_utils(remote_payload_inactive_seq)

    function new(string name = "remote_payload_inactive_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;

       // remote packet with invalid position to keep FSM inactive

        pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        pkt.c_valid_seq_num.constraint_mode(0);
        pkt.c_valid_frag_num.constraint_mode(0);
        pkt.c_local_frag.constraint_mode(0);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 5;
            frag_num     == 3;
            payload_len  inside {[8:32]};   
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
        finish_item(pkt);

        `uvm_info(get_type_name(),
            "Sent multi-byte remote frag with pos>total while inactive", UVM_LOW)
    endtask
endclass : remote_payload_inactive_seq
