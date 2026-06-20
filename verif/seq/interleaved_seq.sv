// TP_CLS_03: interleaved local or remote traffic
// ensures correct routing with no cross-channel contamination

class interleaved_local_remote_seq extends bird_base_seq;
    `uvm_object_utils(interleaved_local_remote_seq)
    int unsigned num_pairs = 2;

    function new(string name = "interleaved_local_remote_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        repeat (num_pairs) begin
            // send one local packet
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

             // send one remote packet
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

             // allow DUT queues to settle before next pair
            #200;
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d interleaved local/remote packet pairs", num_pairs), UVM_LOW)
    endtask
endclass : interleaved_local_remote_seq
