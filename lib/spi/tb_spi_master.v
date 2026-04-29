// =============================================================================
// Testbench : tb_spi_master
// Purpose   : Comprehensive verification of gold-standard SPI master.
//             Uses a procedural SPI slave model with direct sclk edge sampling.
// =============================================================================

`timescale 1ns / 1ps

module tb_spi_master;

  localparam DATA_WIDTH = 8;
  localparam CLK_DIV    = 4;

  // DUT signals
  reg  clk;
  reg  rst_n;
  reg  [DATA_WIDTH-1:0] tx_data;
  reg  tx_start;
  wire [DATA_WIDTH-1:0] rx_data;
  wire rx_valid;
  wire busy;
  wire sclk;
  wire mosi;
  reg  miso;
  wire cs_n;

  // SPI slave model registers
  reg  [DATA_WIDTH-1:0] slave_shift;
  reg  [DATA_WIDTH-1:0] slave_tx_data;
  reg  [DATA_WIDTH-1:0] slave_rx_data;
  reg  [3:0]            slave_bit_cnt;

  // Clock gen
  initial clk = 0;
  always #10 clk = ~clk;

  // DUT instance (CPOL=0, CPHA=0)
  spi_master #(.DATA_WIDTH(DATA_WIDTH), .CLK_DIV(CLK_DIV), .CPOL(0), .CPHA(0))
  dut00 (.clk(clk), .rst_n(rst_n), .tx_data(tx_data), .tx_start(tx_start),
         .rx_data(rx_data), .rx_valid(rx_valid), .busy(busy),
         .sclk(sclk), .mosi(mosi), .miso(miso), .cs_n(cs_n));

  // SPI slave model: samples MOSI on posedge sclk, drives MISO on negedge sclk
  // Pre-drives MISO MSB when cs_n asserts (CPHA=0 behavior)
  always @(negedge cs_n) begin
    slave_bit_cnt <= 0;
    miso <= slave_tx_data[DATA_WIDTH-1];  // pre-drive MSB
  end

  always @(posedge sclk) begin
    if (!cs_n) begin
      slave_shift <= {slave_shift[DATA_WIDTH-2:0], mosi};
      slave_bit_cnt <= slave_bit_cnt + 1;
    end
  end

  always @(negedge sclk) begin
    if (!cs_n) begin
      miso <= slave_tx_data[DATA_WIDTH-1 - slave_bit_cnt];
    end
  end

  always @(posedge cs_n) begin
    miso <= 1'b0;
  end

  // Helpers
  integer pass_cnt, fail_cnt;

  task check;
    input [128*8-1:0] name;
    input             condition;
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
    input [128*8-1:0] name;
    input [DATA_WIDTH-1:0] actual;
    input [DATA_WIDTH-1:0] expected;
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
      tx_data = 0;
      tx_start = 0;
      slave_tx_data = 0;
      repeat(5) @(posedge clk);
      rst_n = 1'b1;
      repeat(3) @(posedge clk);
    end
  endtask

  task send_byte;
    input [DATA_WIDTH-1:0] tx;
    input [DATA_WIDTH-1:0] slave_resp;
    begin
      slave_tx_data = slave_resp;
      @(posedge clk);
      tx_data = tx;
      tx_start = 1;
      @(posedge clk);
      tx_start = 0;
      @(posedge clk);
      while (busy) @(posedge clk);
      @(posedge clk);
    end
  endtask

  // Test suite
  integer idx;

  initial begin
    clk = 0;
    rst_n = 0;
    tx_data = 0;
    tx_start = 0;
    miso = 0;
    slave_tx_data = 0;
    pass_cnt = 0;
    fail_cnt = 0;

    $dumpfile("tb_spi_master.vcd");
    $dumpvars(0, tb_spi_master);

    $display("========================================");
    $display("  SPI Master Testbench  DATA=%0d CLK_DIV=%0d", DATA_WIDTH, CLK_DIV);
    $display("========================================");

    // TC-01: Reset state
    $display("\n[TC-01] Reset state");
    reset_dut;
    check("cs_n high after reset", cs_n == 1'b1);
    check("busy low after reset",  busy == 1'b0);
    check("sclk idle after reset", sclk == 1'b0);
    check("rx_valid low after rst", rx_valid == 1'b0);

    // TC-02: Single byte (slave responds 0x5A)
    $display("\n[TC-02] Single byte (0xA5->0x5A)");
    reset_dut;
    send_byte(8'hA5, 8'h5A);
    check_data("rx_data 0x5A", rx_data, 8'h5A);
    check("cs_n high after tx", cs_n == 1'b1);
    check("busy low after tx", busy == 1'b0);

    // TC-03: Single byte 0x55
    $display("\n[TC-03] Single byte 0x55 (alt bits)");
    send_byte(8'h55, 8'hAA);
    check_data("rx_data 0xAA", rx_data, 8'hAA);

    // TC-04: Single byte 0x00
    $display("\n[TC-04] Single byte 0x00");
    send_byte(8'h00, 8'h00);
    check_data("rx_data 0x00", rx_data, 8'h00);

    // TC-05: Single byte 0xFF
    $display("\n[TC-05] Single byte 0xFF");
    send_byte(8'hFF, 8'hFF);
    check_data("rx_data 0xFF", rx_data, 8'hFF);

    // TC-06: Back-to-back 3 bytes
    $display("\n[TC-06] Back-to-back 3 bytes");
    send_byte(8'h10, 8'hA0);
    check_data("byte 0: 0xA0", rx_data, 8'hA0);
    send_byte(8'h20, 8'hB0);
    check_data("byte 1: 0xB0", rx_data, 8'hB0);
    send_byte(8'h30, 8'hC0);
    check_data("byte 2: 0xC0", rx_data, 8'hC0);

    // TC-07: tx_start ignored while busy
    $display("\n[TC-07] tx_start ignored while busy");
    reset_dut;
    slave_tx_data = 8'h5A;
    tx_data = 8'hA5;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    @(posedge clk);
    tx_data = 8'h3C;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    @(posedge clk);
    while (busy) @(posedge clk);
    @(posedge clk);
    check_data("only first byte sent", rx_data, 8'h5A);

    // TC-08: Reset during transfer
    $display("\n[TC-08] Reset during transfer");
    reset_dut;
    slave_tx_data = 8'hCC;
    tx_data = 8'h33;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    repeat(20) @(posedge clk);
    rst_n = 1'b0;
    repeat(5) @(posedge clk);
    check("cs_n high after mid rst", cs_n == 1'b1);
    check("busy low after mid rst", busy == 1'b0);
    check("sclk idle after mid rst", sclk == 1'b0);
    rst_n = 1'b1;
    repeat(5) @(posedge clk);

    // TC-09: Continuous streaming 50 bytes
    $display("\n[TC-09] Continuous streaming 50 bytes");
    begin
      reg ok_flag;
      ok_flag = 1;
      for (idx = 0; idx < 50; idx = idx + 1) begin
        tx_data = idx[7:0];
        tx_start = 1;
        slave_tx_data = ~idx[7:0];
        @(posedge clk);
        tx_start = 0;
        @(posedge clk);
        while (busy) @(posedge clk);
        @(posedge clk);
        if (rx_data !== ~idx[7:0]) begin
          if (ok_flag) $display("  FAIL at byte %0d (got 0x%h, expected 0x%h)", idx, rx_data, ~idx[7:0]);
          ok_flag = 0;
        end
        repeat(2) @(posedge clk);
      end
      if (ok_flag) begin
        pass_cnt = pass_cnt + 1;
        $display("  PASS  all 50 bytes");
      end else
        fail_cnt = fail_cnt + 1;
    end

    // TC-10: Slave shift register verification
    $display("\n[TC-10] Slave capture verification");
    reset_dut;
    send_byte(8'hA5, 8'h00);
    repeat(5) @(posedge clk);
    check_data("slave received 0xA5", slave_shift, 8'hA5);

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
