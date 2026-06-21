interface bird_if (input logic clk);

    // DUT signals
    logic        rst_n;

    // Input channel
    logic        in_vld;
    logic        in_rdy;
    logic [7:0]  data_in;
    logic [31:0] cfg;

    // Local output channel
    logic        local_vld;
    logic        local_rdy;
    logic [7:0]  data_local;

    // Remote output channel
    logic        remote_vld;
    logic        remote_rdy;
    logic [31:0] data_remote;

    // Status
    logic [15:0] drop_cnt;

    // Drives inputs, samples outputs at posedge clk
    clocking driver_cb @(posedge clk);
        default input  #1step;
        default output #1ns;

        // Driven by driver
        output in_vld;
        output data_in;
        output cfg;
        output local_rdy;
        output remote_rdy;

        // Sampled by driver
        input  in_rdy;
        input  local_vld;
        input  data_local;
        input  remote_vld;
        input  data_remote;
        input  drop_cnt;
    endclocking : driver_cb

    // Pure observation, sampled at posedge
    clocking monitor_cb @(posedge clk);
        default input #1step;

        input in_vld;
        input in_rdy;
        input data_in;
        input cfg;

        input local_vld;
        input local_rdy;
        input data_local;

        input remote_vld;
        input remote_rdy;
        input data_remote;

        input drop_cnt;
    endclocking : monitor_cb

    // Modports
    modport driver_mp  (clocking driver_cb,  input clk, input rst_n);
    modport monitor_mp (clocking monitor_cb, input clk, input rst_n);

    // Reusable reset pulse for tb_top and tests
    task automatic apply_reset(int unsigned hold_cycles = 4);
        rst_n = 1'b0;
        repeat (hold_cycles) @(negedge clk);
        rst_n = 1'b1;
    endtask

endinterface : bird_if
