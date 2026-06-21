// TP_CLS_03: local and remote routing must not cross-contaminate outputs (spec Sec.6-7)
class interleaved_local_remote_seq extends bird_base_seq;
    `uvm_object_utils(interleaved_local_remote_seq)
    int unsigned num_pairs = 2;

    function new(string name = "interleaved_local_remote_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        repeat (num_pairs) begin
            // Complete local packet
            pkt = bird_transaction::type_id::create("local_pkt");
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 0;
                seq_num      == 1;
                frag_num     == 1;
                payload_len  inside {[4:32]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);

            // Complete single-fragment remote packet
            pkt = bird_transaction::type_id::create("remote_pkt");
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == 1;
                frag_num     == 1;
                payload_len  inside {[4:32]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);

            // Drain remote_vld before next packet (see payload_sweep_seq)
            #200;
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d interleaved local/remote packet pairs", num_pairs), UVM_LOW)
    endtask
endclass : interleaved_local_remote_seq
