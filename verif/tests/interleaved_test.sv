`ifndef INTERLEAVED_TEST_SV
`define INTERLEAVED_TEST_SV

// Test interleaved local/remote traffic and verify correct routing.

class interleaved_local_remote_test extends bird_base_test;
    `uvm_component_utils(interleaved_local_remote_test)

    function new(string name = "interleaved_local_remote_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        interleaved_local_remote_seq seq = interleaved_local_remote_seq::type_id::create("seq");
        phase.raise_objection(this);
        seq.start(env.agent.sequencer);
        #2000;
        phase.drop_objection(this);
    endtask
endclass : interleaved_local_remote_test

`endif // INTERLEAVED_TEST_SV
