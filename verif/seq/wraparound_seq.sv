// TP_CNT_05: 65536 guaranteed-drop LOCAL fragments wrap drop_cnt 0x0000->0xFFFF->0x0000
class drop_cnt_wraparound_seq extends bird_base_seq;
    `uvm_object_utils(drop_cnt_wraparound_seq)
    int unsigned num_pkts = 65536;

    function new(string name = "drop_cnt_wraparound_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        repeat (num_pkts) begin
            pkt = bird_transaction::type_id::create("pkt");
            start_item(pkt);
            // Disable local_frag so frag_num != 1 is allowed -> guaranteed drop
            pkt.c_local_frag.constraint_mode(0);
            if (!pkt.randomize() with {
                traffic_type == 0;
                seq_num      == 1;
                frag_num     == 2;   // != 1 -> guaranteed drop every fragment
                payload_len  == 4;   // minimal on-wire stream length
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            pkt.crc16 = bird_transaction::calc_crc16(pkt.payload);
            finish_item(pkt);
        end
        `uvm_info(get_type_name(),
            $sformatf("Sent %0d guaranteed-drop LOCAL packets to wrap drop_cnt back to 0x0000", num_pkts),
            UVM_LOW)
    endtask
endclass : drop_cnt_wraparound_seq
