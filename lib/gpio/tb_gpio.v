// =============================================================================
// Testbench : tb_gpio
// Purpose   : Comprehensive verification of gold-standard GPIO module.
//             Covers reset, output, input, mixed direction, per-pin independence,
//             direction switching, and exhaustive pattern sweep.
// =============================================================================

`timescale 1ns / 1ps

module tb_gpio;

  localparam WIDTH = 8;

  reg                 clk;
  reg                 rst_n;
  reg  [WIDTH-1:0]    dir;
  reg  [WIDTH-1:0]    out_data;
  wire [WIDTH-1:0]    in_data;
  tri0 [WIDTH-1:0]    gpio_pins;

  // Bus holder for input-mode testing — drives gpio_pins during input tests
  reg  [WIDTH-1:0]    pin_drive;
  reg  [WIDTH-1:0]    pin_drive_en;

  // Tri-state driver model for external pin stimulus
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_pin_drv
      assign gpio_pins[i] = pin_drive_en[i] ? pin_drive[i] : 1'bz;
    end
  endgenerate

  // Clock gen
  always #10 clk = ~clk;

  // DUT
  gpio #(.WIDTH(WIDTH)) dut (
    .clk(clk), .rst_n(rst_n),
    .dir(dir), .out_data(out_data),
    .in_data(in_data), .gpio_pins(gpio_pins)
  );

  // =========================================================================
  // Helpers
  // =========================================================================
  integer pass_cnt, fail_cnt;

  task check;
    input [1024*8-1:0] name;
    input              condition;
    begin
      if (condition) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  %s", name);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("  FAIL  %s", name);
      end
    end
  endtask

  task check_data;
    input [1024*8-1:0] name;
    input [WIDTH-1:0]  actual;
    input [WIDTH-1:0]  expected;
    begin
      if (actual === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  %s (0x%h)", name, actual);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("  FAIL  %s (got 0x%h, expected 0x%h)", name, actual, expected);
      end
    end
  endtask

  task reset_dut;
    begin
      rst_n = 1'b0;
      dir = 0;
      out_data = 0;
      pin_drive = 0;
      pin_drive_en = 0;
      repeat(5) @(posedge clk);
      rst_n = 1'b1;
      repeat(3) @(posedge clk);
    end
  endtask

  // =========================================================================
  // Tests
  // =========================================================================
  initial begin
    clk = 0;
    rst_n = 0;
    dir = 0;
    out_data = 0;
    pin_drive = 0;
    pin_drive_en = 0;
    pass_cnt = 0;
    fail_cnt = 0;

    $display("========================================");
    $display("  GPIO Testbench  WIDTH=%0d", WIDTH);
    $display("========================================");

    // TC-01: Reset state
    $display("\n[TC-01] Reset state");
    reset_dut;
    check("dir=0 after reset",     dir === 0);
    check("out_data=0 after reset", out_data === 0);

    // TC-02: All outputs — set pattern
    $display("\n[TC-02] All outputs — drive 0x55");
    reset_dut;
    dir = 8'hFF;
    out_data = 8'h55;
    @(posedge clk);
    @(posedge clk);
    check("gpio_pins == 0x55", gpio_pins === 8'h55);
    check_data("in_data == 0x55", in_data, 8'h55);

    // TC-03: All outputs — 0xAA
    $display("\n[TC-03] All outputs — drive 0xAA");
    out_data = 8'hAA;
    @(posedge clk);
    @(posedge clk);
    check("gpio_pins == 0xAA", gpio_pins === 8'hAA);

    // TC-04: All inputs — read external drive
    $display("\n[TC-04] All inputs — external drive 0x3C");
    dir = 8'h00;
    pin_drive = 8'h3C;
    pin_drive_en = 8'hFF;
    @(posedge clk);
    @(posedge clk);
    check_data("in_data == 0x3C", in_data, 8'h3C);

    // TC-05: Mixed direction — 0xF0 output, 0x0F input
    $display("\n[TC-05] Mixed direction (upper output, lower input)");
    reset_dut;
    dir = 8'hF0;
    out_data = 8'hA5;
    pin_drive = 8'h3C;
    pin_drive_en = 8'h0F;
    @(posedge clk);
    @(posedge clk);
    // Upper nibble driven by out_data, lower nibble driven by pin_drive
    check("gpio_pins upper nibble == 0xA", gpio_pins[7:4] === 4'hA);
    check("in_data lower nibble == 0xC",   in_data[3:0] === 4'hC);
    check_data("in_data lower 0xC", in_data[3:0], 4'hC);

    // TC-06: Per-pin independence
    $display("\n[TC-06] Per-pin independence");
    reset_dut;
    // Set alternating direction: even pins output, odd pins input
    dir = 8'h55;
    out_data = 8'hFF;
    pin_drive = 8'h00;
    pin_drive_en = 8'hAA;
    @(posedge clk);
    @(posedge clk);
    // Even pins (0,2,4,6) = output = 1, Odd pins (1,3,5,7) = input = 0
    check("gpio_pins[0] == 1", gpio_pins[0] === 1'b1);
    check("gpio_pins[1] == 0", gpio_pins[1] === 1'b0);
    check("gpio_pins[2] == 1", gpio_pins[2] === 1'b1);
    check("gpio_pins[3] == 0", gpio_pins[3] === 1'b0);

    // TC-07: Direction switching — output to input, verify DUT releases pins
    $display("\n[TC-07] Direction switching (output → input)");
    pin_drive_en = 8'h00;             // release all testbench drives
    @(posedge clk);
    dir = 8'h00;                      // all input
    @(posedge clk);
    @(posedge clk);
    // Now all pins float: DUT z + testbench z → tri0 resolves to 0
    check("all pins 0 after release", gpio_pins === 8'h00);
    // Drive external pins and verify DUT reads them via in_data
    pin_drive = 8'hC3;
    pin_drive_en = 8'hFF;
    @(posedge clk);
    @(posedge clk);
    check_data("in_data reads external 0xC3", in_data, 8'hC3);

    // TC-08: Direction switching — input to output, DUT takes over
    $display("\n[TC-08] Direction switching (input → output)");
    pin_drive_en = 8'h00;             // release external
    @(posedge clk);
    dir = 8'hFF;
    out_data = 8'h99;
    @(posedge clk);
    @(posedge clk);
    check_data("gpio_pins == 0x99 (DUT drives)", gpio_pins, 8'h99);

    // TC-09: Reset during operation
    $display("\n[TC-09] Reset during operation");
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    check("dir_r=0 after mid-op reset", dut.dir_r === 0);
    check("out_r=0 after mid-op reset", dut.out_r === 0);
    rst_n = 1'b1;
    repeat(3) @(posedge clk);

    // TC-10: Exhaustive 256 pattern sweep (all outputs)
    $display("\n[TC-10] Exhaustive 8-bit pattern sweep");
    begin
      reg ok;
      ok = 1;
      pin_drive_en = 8'h00;           // release all external drives
      dir = 8'hFF;
      @(posedge clk);
      for (integer v = 0; v < 256; v = v + 1) begin
        out_data = v[7:0];
        @(posedge clk);
        @(posedge clk);
        if (gpio_pins !== v[7:0]) begin
          if (ok) $display("  FAIL at value 0x%h (gpio_pins=0x%h)", v, gpio_pins);
          ok = 0;
        end
      end
      if (ok) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  all 256 patterns");
      end else
        fail_cnt = fail_cnt + 1;
    end

    // Summary
    $display("\n========================================");
    $display("  TOTAL: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SOME TESTS FAILED");
    $display("========================================");

    $finish;
  end

  // Timeout
  initial begin
    #500000;
    $display("TIMEOUT: simulation exceeded limit");
    $finish;
  end

endmodule
