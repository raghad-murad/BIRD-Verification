// Remote packet, fragments sent in order
class remote_inorder_seq extends bird_base_seq;
    `uvm_object_utils(remote_inorder_seq)
    int unsigned num_frags = 4;

    function new(string name = "remote_inorder_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        // seq_num=fragment position(1..N), frag_num=total count(N)
        for (int f = 1; f <= num_frags; f++) begin
            pkt = bird_transaction::type_id::create($sformatf("pkt_f%0d", f));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == f;           // position: 1,2,...,N
                frag_num     == num_frags;   // total count N (fixed for all frags)
                payload_len  inside {[4:32]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d in-order remote frags (seq=pos, frag=total)", num_frags), UVM_LOW)
    endtask
endclass : remote_inorder_seq

// Remote packet, fragments sent out of order
class remote_outoforder_seq extends bird_base_seq;
    `uvm_object_utils(remote_outoforder_seq)
    int unsigned num_frags = 4;

    function new(string name = "remote_outoforder_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        int order[];

        // seq_num=position(1..N), frag_num=total(N); build shuffled order of all positions
        order = new[num_frags];
        foreach (order[i]) order[i] = i + 1;  // 1, 2, ..., num_frags
        // Fisher-Yates shuffle
        for (int i = num_frags - 1; i > 0; i--) begin
            int j = $urandom_range(0, i);
            int tmp = order[i];
            order[i] = order[j];
            order[j] = tmp;
        end

        // Send all fragments in shuffled order
        foreach (order[i]) begin
            pkt = bird_transaction::type_id::create($sformatf("pkt_pos%0d", order[i]));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == order[i];    // position (shuffled)
                frag_num     == num_frags;   // total count (fixed)
                payload_len  inside {[4:32]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d out-of-order remote frags (seq=shuffled pos, frag=total=%0d)",
                num_frags, num_frags), UVM_LOW)
    endtask
endclass : remote_outoforder_seq

// TP_MIX_03 support: two complete remote packets back-to-back with no gap between them
class remote_back_to_back_seq extends bird_base_seq;
    `uvm_object_utils(remote_back_to_back_seq)
    int unsigned num_frags = 3;

    function new(string name = "remote_back_to_back_seq");
        super.new(name);
    endfunction

    task send_one_packet(int unsigned tag);
        bird_transaction pkt;
        for (int f = 1; f <= num_frags; f++) begin
            pkt = bird_transaction::type_id::create($sformatf("pkt%0d_f%0d", tag, f));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == f;
                frag_num     == num_frags;
                payload_len  inside {[4:32]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);
        end
    endtask

    task body();
        send_one_packet(1);
        send_one_packet(2);
        `uvm_info(get_type_name(),
            $sformatf("Sent 2 complete remote packets back-to-back (%0d frags each, no gap)", num_frags),
            UVM_LOW)
    endtask
endclass : remote_back_to_back_seq

// Remote packet with exactly 1 fragment
class remote_single_frag_seq extends bird_base_seq;
    `uvm_object_utils(remote_single_frag_seq)

    function new(string name = "remote_single_frag_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 1;   // position 1 of 1
            frag_num     == 1;   // total = 1
            payload_len  inside {[1:64]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        finish_item(pkt);
        `uvm_info(get_type_name(), "Sent single-frag remote packet", UVM_LOW)
    endtask
endclass : remote_single_frag_seq

// Sends packets while consumer holds rdy=0
class backpressure_seq extends bird_base_seq;
    `uvm_object_utils(backpressure_seq)
    int unsigned num_pkts = 4;

    function new(string name = "backpressure_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        repeat (num_pkts) begin
            pkt = bird_transaction::type_id::create("pkt");
            start_item(pkt);
            if (!pkt.randomize() with { traffic_type == 0; })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d packets under backpressure conditions", num_pkts), UVM_LOW)
    endtask
endclass : backpressure_seq

// Fully randomised packet mix
class rand_test_seq extends bird_base_seq;
    `uvm_object_utils(rand_test_seq)
    int unsigned num_pkts = 32;

    function new(string name = "rand_test_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        repeat (num_pkts) begin
            pkt = bird_transaction::type_id::create("pkt");
            send_pkt(pkt);
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d fully-random packets", num_pkts), UVM_LOW)
    endtask
endclass : rand_test_seq
