`ifndef BIRD_BASE_TEST_SV
`define BIRD_BASE_TEST_SV

class bird_base_test extends uvm_test;
    `uvm_component_utils(bird_base_test)

    bird_env env;

    // Direct rst_n/output access for reset tests (TP_RST_*), shared with scoreboard's vif_plain
    virtual bird_if vif;

    function new(string name = "bird_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = bird_env::type_id::create("env", this);
        if (!uvm_config_db #(virtual bird_if)::get(this, "", "vif_plain", vif))
            `uvm_fatal(get_type_name(), "Cannot get vif_plain")
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        #10;
        phase.drop_objection(this);
    endtask

    // Pass/fail banner for every test, based on UVM_ERROR/UVM_FATAL severity counts
    function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();
        int unsigned errors;
        super.report_phase(phase);
        errors = svr.get_severity_count(UVM_ERROR) + svr.get_severity_count(UVM_FATAL);
        if (errors == 0)
            `uvm_info(get_type_name(), $sformatf("*** %s PASSED ***", get_type_name()), UVM_NONE)
        else
            `uvm_error(get_type_name(),
                $sformatf("*** %s FAILED (%0d error/fatal) ***", get_type_name(), errors))
    endfunction
endclass : bird_base_test

`endif
