// Directed sequences to close functional coverage gaps

// Sweeps local+remote packets across all payload_len coverage bins
class payload_sweep_seq extends bird_base_seq;
    `uvm_object_utils(payload_sweep_seq)

    function new(string name = "payload_sweep_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        int unsigned lens[4] = '{14, 100, 200, 255};

        foreach (lens[i]) begin
            pkt = bird_transaction::type_id::create($sformatf("loc_pkt%0d", i));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 0;
                seq_num      == 1;
                frag_num     == 1;
                payload_len  == lens[i];
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);

            pkt = bird_transaction::type_id::create($sformatf("rem_pkt%0d", i));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == 1;
                frag_num     == 1;
                payload_len  == lens[i];
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);
            // Drain remote_vld to 0 so the monitor can segment the next remote packet
            #1000;
        end
        `uvm_info(get_type_name(),
            "Sent payload-length sweep packets (sm/typical/lg/max bins)", UVM_LOW)
    endtask
endclass : payload_sweep_seq

// Remote packet with 31 in-order fragments (frag_6_31/seq_25_31/cx_type_frag bins)
class remote_maxfrag_seq extends remote_inorder_seq;
    `uvm_object_utils(remote_maxfrag_seq)

    function new(string name = "remote_maxfrag_seq");
        super.new(name);
        num_frags = 31;
    endfunction
endclass : remote_maxfrag_seq
