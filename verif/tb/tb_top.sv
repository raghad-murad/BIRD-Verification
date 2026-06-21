`timescale 1ns/1ps
module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import bird_pkg::*;

    // Clock generation (100 MHz clock)
    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Interface instantiation
    bird_if dut_if (.clk(clk));

    // DUT instantiation - connect to interface signals
    bird dut (
        .clk         (clk),
        .rst_n       (dut_if.rst_n),
        .in_vld      (dut_if.in_vld),
        .in_rdy      (dut_if.in_rdy),
        .data_in     (dut_if.data_in),
        .cfg         (dut_if.cfg),
        .local_vld   (dut_if.local_vld),
        .local_rdy   (dut_if.local_rdy),
        .data_local  (dut_if.data_local),
        .remote_vld  (dut_if.remote_vld),
        .remote_rdy  (dut_if.remote_rdy),
        .data_remote (dut_if.data_remote),
        .drop_cnt    (dut_if.drop_cnt)
    );

    // Reset generation
    initial begin
        dut_if.in_vld     = 1'b0;
        dut_if.data_in    = 8'h00;
        dut_if.cfg        = 32'h00000000;
        dut_if.local_rdy  = 1'b1;
        dut_if.remote_rdy = 1'b1;

        // Reuse shared reset task
        dut_if.apply_reset(4);
        `uvm_info("tb_top", "Reset deasserted", UVM_LOW)
    end

    // Register interfaces
    initial begin

        // Use "uvm_test_top*" to match both test and descendants

        // Register driver_mp modport for driver
        uvm_config_db #(virtual bird_if.driver_mp)::set(
            null, "uvm_test_top*", "driver_mp", dut_if.driver_mp);

        // Register monitor_mp modport for monitors and coverage
        uvm_config_db #(virtual bird_if.monitor_mp)::set(
            null, "uvm_test_top*", "vif", dut_if.monitor_mp);

        // Plain interface for reset and final checks
        uvm_config_db #(virtual bird_if)::set(
            null, "uvm_test_top*", "vif_plain", dut_if);

        // Launch selected test
        run_test();
    end

    // 10 ms timeout for long-running tests
    initial begin
        #10_000_000;
        `uvm_fatal("tb_top", "Simulation timeout - possible hang detected")
    end

    // Wave dump
    initial begin
        if ($test$plusargs("WAVES")) begin
            $dumpfile("bird_tb.vcd");
            $dumpvars(0, tb_top);
        end
    end

endmodule : tb_top