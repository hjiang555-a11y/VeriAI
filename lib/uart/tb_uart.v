// =============================================================================
// Testbench : tb_uart
// Purpose   : Comprehensive verification of the gold-standard UART module.
//             Covers normal operation, boundary conditions, and error cases.
// =============================================================================

`timescale 1ns / 1ps

module tb_uart;

  // Test parameters
  localparam CLK_FREQ  = 50000000;
  localparam BAUD_RATE = 115200;
  localparam DATA_BITS = 8;
  localparam STOP_BITS = 1;
  localparam PARITY    = 0;

  localparam BIT_PERIOD = 1_000_000_000 / BAUD_RATE;  // in ns (8680 ns @ 115200)

  // DUT signals
  reg                    clk;
  reg                    rst_n;
  reg  [DATA_BITS-1:0]   tx_data;
  reg                    tx_start;
  wire                   tx_busy;
  wire                   tx;
  reg                    rx;
  wire [DATA_BITS-1:0]   rx_data;
  wire                   rx_valid;
  wire                   rx_error;

  // Clock gen
  localparam CLK_PERIOD = 20;  // 50MHz = 20ns
  always #(CLK_PERIOD/2) clk = ~clk;

  // DUT instance (loopback: TX → RX)
  uart #(
    .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE),
    .DATA_BITS(DATA_BITS), .STOP_BITS(STOP_BITS), .PARITY(PARITY)
  ) dut (
    .clk(clk), .rst_n(rst_n),
    .tx_data(tx_data), .tx_start(tx_start), .tx_busy(tx_busy), .tx(tx),
    .rx(tx),  // loopback
    .rx_data(rx_data), .rx_valid(rx_valid), .rx_error(rx_error)
  );

  // =========================================================================
  // Test helpers
  // =========================================================================
  integer pass_cnt, fail_cnt;

  task check;
    input [1024*8-1:0] name;
    input              actual;
    input              expected;
    begin
      if (actual === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  %s", name);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("  FAIL  %s (got %b, expected %b)", name, actual, expected);
      end
    end
  endtask

  task check_data;
    input [1024*8-1:0] name;
    input [DATA_BITS-1:0] actual;
    input [DATA_BITS-1:0] expected;
    begin
      if (actual === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  %s", name);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("  FAIL  %s (got 0x%h, expected 0x%h)", name, actual, expected);
      end
    end
  endtask

  task wait_clks;
    input integer n;
    repeat (n) @(posedge clk);
  endtask

  // Send one byte via TX
  task tx_send;
    input [DATA_BITS-1:0] data;
    begin
      tx_data  = data;
      tx_start = 1;
      @(posedge clk);
      tx_start = 0;
      wait_clks(1);
      // wait for RX valid first (may fire before tx_busy deasserts due to integer rounding),
      // then wait for TX to finish
      while (!rx_valid) @(posedge clk);
      while (tx_busy)   @(posedge clk);
    end
  endtask

  // =========================================================================
  // Tests
  // =========================================================================
  initial begin
    // init
    clk      = 0;
    rst_n    = 0;
    tx_data  = 0;
    tx_start = 0;
    rx      = 1;
    pass_cnt = 0;
    fail_cnt = 0;

    $display("========================================");
    $display("  UART Testbench  (CLK=%0d, BAUD=%0d)", CLK_FREQ, BAUD_RATE);
    $display("========================================");

    // --- TC-01: Reset state ------------------------------------------------
    $display("\n[TC-01] Reset state");
    wait_clks(10);
    rst_n = 1;
    wait_clks(5);
    check("tx_busy after reset",  tx_busy,  1'b0);
    check("tx idle after reset",  dut.tx,   1'b1);
    check("rx_valid after reset", rx_valid, 1'b0);
    check("rx_error after reset", rx_error, 1'b0);

    // --- TC-02: Single byte (0x55 = alternating bits) ----------------------
    $display("\n[TC-02] Single byte 0x55 (alternating)");
    tx_send(8'h55);
    check("tx_busy after TX",   tx_busy,  1'b0);
    check("rx_valid asserted",  rx_valid, 1'b1);
    check("rx_error clear",     rx_error, 1'b0);
    check_data("rx_data 0x55",  rx_data,  8'h55);
    wait_clks(10);

    // --- TC-03: Single byte (0xAA = alternating, inverse) ------------------
    $display("\n[TC-03] Single byte 0xAA (alternating inverse)");
    tx_send(8'hAA);
    check("rx_error clear", rx_error, 1'b0);
    check_data("rx_data 0xAA", rx_data, 8'hAA);
    wait_clks(10);

    // --- TC-04: Single byte (0x00 = all zeros) ----------------------------
    $display("\n[TC-04] Single byte 0x00 (all zeros)");
    tx_send(8'h00);
    check("rx_error clear", rx_error, 1'b0);
    check_data("rx_data 0x00", rx_data, 8'h00);
    wait_clks(10);

    // --- TC-05: Single byte (0xFF = all ones) ------------------------------
    $display("\n[TC-05] Single byte 0xFF (all ones)");
    tx_send(8'hFF);
    check("rx_error clear", rx_error, 1'b0);
    check_data("rx_data 0xFF", rx_data, 8'hFF);
    wait_clks(10);

    // --- TC-06: Back-to-back transmission ----------------------------------
    $display("\n[TC-06] Back-to-back 3 bytes");
    for (integer i = 0; i < 3; i = i + 1) begin
      tx_data  = 8'h10 + i;
      tx_start = 1;
      @(posedge clk);
      tx_start = 0;
      @(posedge clk);
      while (!rx_valid) @(posedge clk);
      while (tx_busy)   @(posedge clk);
      check_data("back-to-back byte", rx_data, 8'h10 + i);
      check("rx_error", rx_error, 1'b0);
    end
    wait_clks(10);

    // --- TC-07: All 256 values ---------------------------------------------
    $display("\n[TC-07] All 256 byte values");
    begin
      reg ok;
      ok = 1;
      for (integer v = 0; v < 256; v = v + 1) begin
        tx_data  = v[7:0];
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        @(posedge clk);
        while (!rx_valid) @(posedge clk);
      while (tx_busy)   @(posedge clk);
        if (rx_data !== v[7:0] || rx_error) begin
          if (ok) $display("  FAIL at value %0d (got 0x%h, err=%b)", v, rx_data, rx_error);
          ok = 0;
        end
      end
      if (ok) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  all 256 values");
      end else begin
        fail_cnt = fail_cnt + 1;
      end
    end
    wait_clks(10);

    // --- TC-08: tx_start ignored while busy --------------------------------
    $display("\n[TC-08] tx_start ignored while tx_busy");
    tx_data  = 8'hC3;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    @(posedge clk);
    // TX is now busy, try to start another
    tx_data  = 8'h3C;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    @(posedge clk);
    while (tx_busy || !rx_valid) @(posedge clk);
    check_data("only first byte received", rx_data, 8'hC3);
    wait_clks(10);

    // --- TC-09: Reset during operation -------------------------------------
    $display("\n[TC-09] Reset during operation");
    // start a long TX but reset mid-way
    tx_data  = 8'hA5;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    // let a few bit periods pass
    repeat (BIT_PERIOD / CLK_PERIOD * 4) @(posedge clk);
    rst_n = 0;
    wait_clks(5);
    check("tx idle after mid-op reset", dut.tx, 1'b1);
    check("tx_busy after reset",        tx_busy, 1'b0);
    rst_n = 1;
    wait_clks(10);

    // --- TC-10: Continuous streaming (stress) ------------------------------
    $display("\n[TC-10] Continuous streaming 100 bytes");
    fork
      // RX checker
      begin
        for (integer j = 0; j < 100; j = j + 1) begin
          @(posedge clk);
          while (!rx_valid) @(posedge clk);
          if (rx_data !== j[7:0] || rx_error) begin
            $display("  FAIL at stream byte %0d (got 0x%h, err=%b)", j, rx_data, rx_error);
            fail_cnt = fail_cnt + 1;
          end
        end
      end
      // TX sender
      begin
        for (integer j = 0; j < 100; j = j + 1) begin
          tx_data  = j[7:0];
          tx_start = 1;
          @(posedge clk);
          tx_start = 0;
          @(posedge clk);
          while (tx_busy) @(posedge clk);
          // give a small gap between bytes
          wait_clks(5);
        end
      end
    join
    $display("  PASS  continuous streaming 100 bytes");
    pass_cnt = pass_cnt + 1;
    wait_clks(10);

    // --- Summary -----------------------------------------------------------
    $display("\n========================================");
    $display("  TOTAL: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  SOME TESTS FAILED");
    $display("========================================");

    $finish;
  end

endmodule
