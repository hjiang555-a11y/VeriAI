// =============================================================================
// Module  : tb_sync_fifo
// Purpose : Gold-standard testbench for sync_fifo.
//           Covers: normal write/read, full-boundary write, empty-boundary read,
//           simultaneous read+write, reset during operation, sequential burst,
//           and pointer wrap-around.
//
// Usage   : iverilog -g2001 -o tb_sync_fifo.vvp tb_sync_fifo.v sync_fifo.v
//           vvp tb_sync_fifo.vvp
//
// Pass criteria: all PASS lines printed, no FAIL lines, simulation exits 0.
// =============================================================================

`timescale 1ns / 1ps

module tb_sync_fifo;

  // -------------------------------------------------------------------------
  // Parameters – small FIFO so boundary conditions trigger quickly
  // -------------------------------------------------------------------------
  parameter DEPTH = 8;
  parameter WIDTH = 8;

  // -------------------------------------------------------------------------
  // DUT signals
  // -------------------------------------------------------------------------
  reg                    clk;
  reg                    rst_n;
  reg                    wr_en;
  reg  [WIDTH-1:0]       wr_data;
  reg                    rd_en;
  wire [WIDTH-1:0]       rd_data;
  wire                   full;
  wire                   empty;
  wire [$clog2(DEPTH):0] data_count;

  // -------------------------------------------------------------------------
  // Instantiate DUT
  // -------------------------------------------------------------------------
  sync_fifo #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)
  ) dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .wr_en      (wr_en),
    .wr_data    (wr_data),
    .rd_en      (rd_en),
    .rd_data    (rd_data),
    .full       (full),
    .empty      (empty),
    .data_count (data_count)
  );

  // -------------------------------------------------------------------------
  // Clock: 10 ns period
  // -------------------------------------------------------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------
  integer pass_count;
  integer fail_count;

  task reset_dut;
    begin
      rst_n   = 1'b0;
      wr_en   = 1'b0;
      rd_en   = 1'b0;
      wr_data = {WIDTH{1'b0}};
      @(posedge clk); #1;
      @(posedge clk); #1;
      rst_n = 1'b1;
      @(posedge clk); #1;
    end
  endtask

  task write_word;
    input [WIDTH-1:0] data;
    begin
      wr_en   = 1'b1;
      wr_data = data;
      @(posedge clk); #1;
      wr_en   = 1'b0;
    end
  endtask

  task read_word;
    begin
      rd_en = 1'b1;
      @(posedge clk); #1;
      rd_en = 1'b0;
    end
  endtask

  task check;
    input [127:0] test_name;   // 16 characters, 1 byte each (128-bit packed string)
    input         condition;
    begin
      if (condition) begin
        $display("  PASS  %s", test_name);
        pass_count = pass_count + 1;
      end else begin
        $display("  FAIL  %s  (count=%0d full=%b empty=%b rd_data=%0d)",
                 test_name, data_count, full, empty, rd_data);
        fail_count = fail_count + 1;
      end
    end
  endtask

  // -------------------------------------------------------------------------
  // Test suite
  // -------------------------------------------------------------------------
  integer idx;
  reg [WIDTH-1:0] expected;

  initial begin
    pass_count = 0;
    fail_count = 0;

    // VCD dump for waveform viewing (make wave target)
    $dumpfile("tb_sync_fifo.vcd");
    $dumpvars(0, tb_sync_fifo);

    $display("========================================");
    $display("  sync_fifo Testbench  DEPTH=%0d WIDTH=%0d", DEPTH, WIDTH);
    $display("========================================");

    // ------------------------------------------------------------------
    // TC-01  Reset state
    // ------------------------------------------------------------------
    $display("\n[TC-01] Reset state");
    reset_dut;
    check("empty_after_reset ", empty         == 1'b1);
    check("full_after_reset  ", full          == 1'b0);
    check("count_after_reset ", data_count    == 0);

    // ------------------------------------------------------------------
    // TC-02  Normal single write then read
    // ------------------------------------------------------------------
    $display("\n[TC-02] Single write → read");
    reset_dut;
    write_word(8'hA5);
    check("not_empty_after_wr", empty         == 1'b0);
    check("count_1_after_wr  ", data_count    == 1);
    read_word;                         // rd_data valid next cycle
    @(posedge clk); #1;               // wait for rd_data to become valid (one-cycle latency)
    check("rd_data_A5        ", rd_data       == 8'hA5);
    check("empty_after_rd    ", empty         == 1'b1);
    check("count_0_after_rd  ", data_count    == 0);

    // ------------------------------------------------------------------
    // TC-03  Fill to full
    // ------------------------------------------------------------------
    $display("\n[TC-03] Fill to full");
    reset_dut;
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      write_word(idx[WIDTH-1:0]);
    check("full_flag_set     ", full          == 1'b1);
    check("not_empty_when_ful", empty         == 1'b0);
    check("count_eq_depth    ", data_count    == DEPTH);

    // ------------------------------------------------------------------
    // TC-04  Write when full (overflow guard)
    // ------------------------------------------------------------------
    $display("\n[TC-04] Write when full (dropped)");
    // FIFO is full from TC-03; attempt another write
    write_word(8'hFF);
    check("still_full        ", full          == 1'b1);
    check("count_unchanged   ", data_count    == DEPTH);

    // ------------------------------------------------------------------
    // TC-05  Read when empty (underflow guard)
    // ------------------------------------------------------------------
    $display("\n[TC-05] Read when empty (dropped)");
    reset_dut;
    read_word;                        // attempt read on empty FIFO
    check("still_empty       ", empty         == 1'b1);
    check("count_stays_0     ", data_count    == 0);

    // ------------------------------------------------------------------
    // TC-06  Sequential burst: write all, then read all, verify order
    // ------------------------------------------------------------------
    $display("\n[TC-06] Sequential burst write → read (FIFO order)");
    reset_dut;
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      write_word(idx[WIDTH-1:0] + 8'h10);

    for (idx = 0; idx < DEPTH; idx = idx + 1) begin
      read_word;
      @(posedge clk); #1;
      expected = idx[WIDTH-1:0] + 8'h10;
      check("fifo_order_check  ", rd_data == expected);
    end
    check("empty_after_burst ", empty == 1'b1);

    // ------------------------------------------------------------------
    // TC-07  Simultaneous read and write (count unchanged)
    // ------------------------------------------------------------------
    $display("\n[TC-07] Simultaneous read + write");
    reset_dut;
    // Pre-fill half
    for (idx = 0; idx < DEPTH/2; idx = idx + 1)
      write_word(idx[WIDTH-1:0]);

    begin : sim_rw
      reg [$clog2(DEPTH):0] cnt_before;
      cnt_before = data_count;
      wr_en   = 1'b1;
      rd_en   = 1'b1;
      wr_data = 8'hBB;
      @(posedge clk); #1;
      wr_en = 1'b0;
      rd_en = 1'b0;
      check("count_unchanged_rw", data_count == cnt_before);
    end

    // ------------------------------------------------------------------
    // TC-08  Reset during operation (mid-burst)
    // ------------------------------------------------------------------
    $display("\n[TC-08] Reset during operation");
    reset_dut;
    for (idx = 0; idx < DEPTH/2; idx = idx + 1)
      write_word(idx[WIDTH-1:0]);
    // Assert reset in the middle
    rst_n = 1'b0;
    @(posedge clk); #1;
    rst_n = 1'b1;
    @(posedge clk); #1;
    check("count_0_after_midr", data_count == 0);
    check("empty_after_midrst", empty      == 1'b1);
    check("full_clr_mid_rst  ", full       == 1'b0);

    // ------------------------------------------------------------------
    // TC-09  Pointer wrap-around (write > DEPTH entries total)
    // ------------------------------------------------------------------
    $display("\n[TC-09] Pointer wrap-around");
    reset_dut;
    // Write DEPTH entries, read DEPTH entries, write DEPTH entries again
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      write_word(idx[WIDTH-1:0]);
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      read_word;
    @(posedge clk); #1;
    check("empty_after_drain  ", empty      == 1'b1);
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      write_word(8'hC0 + idx[WIDTH-1:0]);
    check("full_after_rewrap  ", full       == 1'b1);
    check("count_depth_rewrap ", data_count == DEPTH);

    // ------------------------------------------------------------------
    // TC-10  Full-then-drain: read all from full FIFO
    // ------------------------------------------------------------------
    $display("\n[TC-10] Drain from full");
    reset_dut;
    for (idx = 0; idx < DEPTH; idx = idx + 1)
      write_word(8'h20 + idx[WIDTH-1:0]);
    for (idx = 0; idx < DEPTH; idx = idx + 1) begin
      read_word;
      @(posedge clk); #1;
      expected = 8'h20 + idx[WIDTH-1:0];
      check("drain_order_check  ", rd_data == expected);
    end
    check("empty_after_drain2 ", empty == 1'b1);

    // ------------------------------------------------------------------
    // Summary
    // ------------------------------------------------------------------
    $display("\n========================================");
    $display("  TOTAL: %0d PASS, %0d FAIL", pass_count, fail_count);
    $display("========================================");

    if (fail_count == 0)
      $display("  ALL TESTS PASSED");
    else
      $display("  *** FAILURES DETECTED – see FAIL lines above ***");

    $finish;
  end

  // -------------------------------------------------------------------------
  // Timeout watchdog (prevent infinite loop on hung simulation)
  // -------------------------------------------------------------------------
  initial begin
    #100000;
    $display("TIMEOUT: simulation exceeded 100 us");
    $finish;
  end

endmodule
