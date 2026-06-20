// ============================================================
// reset_seq.sv — sequences supporting the TP_RST_* reset tests
// ============================================================

// ------------------------------------------------------------
// reset_during_local_seq — one long-payload local packet.
// payload_len is deliberately large so the fragment is still
// mid-stream several cycles after the first byte, giving the
// test a wide, deterministic window in which to assert rst_n.
// ------------------------------------------------------------
class reset_during_local_seq extends bird_base_seq;
    `uvm_object_utils(reset_during_local_seq)

    function new(string name = "reset_during_local_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 0;
            seq_num      == 1;
            frag_num     == 1;
            payload_len  inside {[32:64]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        finish_item(pkt);
        `uvm_info(get_type_name(),
            "Sent long local packet (intended to be interrupted by reset)", UVM_LOW)
    endtask
endclass : reset_during_local_seq

// ------------------------------------------------------------
// reset_during_remote_seq — sends fragments 1 and 2 of a
// declared 3-fragment remote packet (DUT protocol: seq_num =
// fragment position, frag_num = total count). Fragment 3 is
// deliberately withheld so accumulation can never complete on
// its own — the test resets while it is still in progress.
// ------------------------------------------------------------
class reset_during_remote_seq extends bird_base_seq;
    `uvm_object_utils(reset_during_remote_seq)

    function new(string name = "reset_during_remote_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt;
        for (int pos = 1; pos <= 2; pos++) begin
            pkt = bird_transaction::type_id::create($sformatf("pkt_pos%0d", pos));
            start_item(pkt);
            if (!pkt.randomize() with {
                traffic_type == 1;
                seq_num      == pos;
                frag_num     == 3;
                payload_len  inside {[4:16]};
            })
                `uvm_fatal(get_type_name(), "Randomisation failed")
            finish_item(pkt);
        end
        `uvm_info(get_type_name(),
            "Buffered fragments 1 and 2 of a declared 3-fragment remote packet (fragment 3 withheld)",
            UVM_LOW)
    endtask
endclass : reset_during_remote_seq

// ------------------------------------------------------------
// remote_lone_frag3_of3_seq — post-reset stale-state probe for
// TP_RST_03. Sends ONLY position 3 of a declared 3-fragment
// packet. Structurally this can never complete by itself
// (positions 1 and 2 are missing) UNLESS fragment state from a
// prior accumulation was wrongly left resident across reset, in
// which case the DUT could complete a (corrupted) merge using
// stale fragments 1/2 plus this new fragment 3.
// ------------------------------------------------------------
class remote_lone_frag3_of3_seq extends bird_base_seq;
    `uvm_object_utils(remote_lone_frag3_of3_seq)

    function new(string name = "remote_lone_frag3_of3_seq");
        super.new(name);
    endfunction

    task body();
        bird_transaction pkt = bird_transaction::type_id::create("pkt");
        start_item(pkt);
        if (!pkt.randomize() with {
            traffic_type == 1;
            seq_num      == 3;
            frag_num     == 3;
            payload_len  inside {[4:16]};
        })
            `uvm_fatal(get_type_name(), "Randomisation failed")
        finish_item(pkt);
        `uvm_info(get_type_name(),
            "Sent lone position=3/3 remote fragment (post-reset stale-state probe)", UVM_LOW)
    endtask
endclass : remote_lone_frag3_of3_seq
