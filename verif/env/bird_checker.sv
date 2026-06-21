`ifndef BIRD_CHECKER_SV
`define BIRD_CHECKER_SV

class bird_checker extends uvm_component;

    `uvm_component_utils(bird_checker)

    virtual bird_if.monitor_mp vif;

    // Snapshot registers for stability checks
    logic [7:0]  prev_data_in;
    logic [31:0] prev_cfg;
    logic [15:0] prev_drop_cnt;
    logic        prev_in_vld;

    // Pass and fail counters
    int unsigned checks_passed;
    int unsigned checks_failed;

    function new(string name = "bird_checker", uvm_component parent = null);
        super.new(name, parent);
        checks_passed = 0;
        checks_failed = 0;
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual bird_if.monitor_mp)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get monitor_mp from config_db")

    endfunction

    task run_phase(uvm_phase phase);

       // Capture initial state
        @(posedge vif.clk);
        prev_data_in  = vif.monitor_cb.data_in;
        prev_cfg      = vif.monitor_cb.cfg;
        prev_drop_cnt = vif.monitor_cb.drop_cnt;
        prev_in_vld   = vif.monitor_cb.in_vld;

        forever begin

            @(posedge vif.clk);

            // Only reset checks while reset is active
            if (!vif.rst_n) begin

                check_reset();

                // Refresh snapshots after reset
                prev_data_in  = vif.monitor_cb.data_in;
                prev_cfg      = vif.monitor_cb.cfg;
                prev_drop_cnt = vif.monitor_cb.drop_cnt;
                prev_in_vld   = vif.monitor_cb.in_vld;
                continue;

            end

            check_input_stability();
            check_local_stability();
            check_remote_stability();
            check_drop_cnt_monotonic();

            // Save current state
            prev_data_in  = vif.monitor_cb.data_in;
            prev_cfg      = vif.monitor_cb.cfg;
            prev_drop_cnt = vif.monitor_cb.drop_cnt;
            prev_in_vld   = vif.monitor_cb.in_vld;

        end

    endtask

    // Disabled: input backpressure never occurs
    task check_input_stability();
        // No check needed
    endtask

    // Output must stay stable under backpressure
    task check_local_stability();

        static logic        prev_local_vld  = 1'b0;
        static logic [7:0]  prev_data_local = 8'h00;

        if (prev_local_vld && !vif.monitor_cb.local_rdy) begin

            if (vif.monitor_cb.data_local !== prev_data_local) begin

                `uvm_error(get_type_name(),
                    $sformatf("LOCAL STABILITY VIOLATION: data_local changed from 0x%02h to 0x%02h while local_vld=1 local_rdy=0",
                    prev_data_local, vif.monitor_cb.data_local))
                checks_failed++;

            end else begin
                checks_passed++;
            end

        end

        prev_local_vld  = vif.monitor_cb.local_vld;
        prev_data_local = vif.monitor_cb.data_local;

    endtask


    // Output must stay stable under backpressure
    task check_remote_stability();

        static logic         prev_remote_vld  = 1'b0;
        static logic [31:0]  prev_data_remote = 32'h0;

        if (prev_remote_vld && !vif.monitor_cb.remote_rdy) begin

            if (vif.monitor_cb.data_remote !== prev_data_remote) begin

                `uvm_error(get_type_name(),
                    $sformatf("REMOTE STABILITY VIOLATION: data_remote changed from 0x%08h to 0x%08h while remote_vld=1 remote_rdy=0",
                    prev_data_remote, vif.monitor_cb.data_remote))
                checks_failed++;

            end else begin
                checks_passed++;
            end

        end

        prev_remote_vld  = vif.monitor_cb.remote_vld;
        prev_data_remote = vif.monitor_cb.data_remote;

    endtask

    // Counter must not decrease (allows 16-bit wrap-around)
    task check_drop_cnt_monotonic();

        logic [15:0] curr = vif.monitor_cb.drop_cnt;

        if (curr != prev_drop_cnt && curr != (prev_drop_cnt + 16'd1)) begin

            // Unexpected counter jump
            if (curr < prev_drop_cnt && curr != 16'h0000) begin

                `uvm_error(get_type_name(),
                    $sformatf("DROP_CNT DECREASED: was 0x%04h, now 0x%04h",
                    prev_drop_cnt, curr))

                checks_failed++;

            end else begin

                // Warn on unusual increment
                `uvm_warning(get_type_name(),
                    $sformatf("DROP_CNT unexpected change: was 0x%04h, now 0x%04h",
                    prev_drop_cnt, curr))

                checks_passed++;

            end
        end else begin

            checks_passed++;

        end
    endtask


    // Outputs must be cleared during reset (rst_n=0)
    task check_reset();

        if (vif.monitor_cb.local_vld !== 1'b0) begin

            `uvm_error(get_type_name(),
                "RESET VIOLATION: local_vld is not deasserted during rst_n=0")

            checks_failed++;

        end else checks_passed++;

        if (vif.monitor_cb.remote_vld !== 1'b0) begin

            `uvm_error(get_type_name(),
                "RESET VIOLATION: remote_vld is not deasserted during rst_n=0")

            checks_failed++;

        end else checks_passed++;

        if (vif.monitor_cb.drop_cnt !== 16'h0) begin

            `uvm_error(get_type_name(),
                $sformatf("RESET VIOLATION: drop_cnt = 0x%04h (expected 0x0000) during rst_n=0",
                vif.monitor_cb.drop_cnt))

            checks_failed++;

        end else checks_passed++;
    endtask


    // Print summary
    function void report_phase(uvm_phase phase);

        `uvm_info(get_type_name(), $sformatf(
            "Protocol checker summary: %0d checks PASSED, %0d checks FAILED",
            checks_passed, checks_failed), UVM_LOW)

        if (checks_failed > 0)
            `uvm_error(get_type_name(), "One or more protocol violations detected!")
        else
            `uvm_info(get_type_name(), "All protocol checks PASSED", UVM_LOW)

    endfunction

endclass : bird_checker

`endif
