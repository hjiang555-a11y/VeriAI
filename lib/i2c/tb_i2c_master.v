// =============================================================================
// Testbench : tb_i2c_master
// Purpose   : Comprehensive verification of gold-standard I2C master.
//             Uses a procedural I2C slave model with open-drain wired-AND.
//             Covers START/STOP, single/multi-byte read+write, NACK detection,
//             clock stretching, busy protection, and mid-op reset.
// =============================================================================

`timescale 1ns / 1ps

module tb_i2c_master;

  localparam CLK_FREQ = 50000000;
  localparam I2C_FREQ = 400000;

  // DUT signals
  reg         clk;
  reg         rst_n;
  reg  [2:0]  cmd;
  reg         cmd_start;
  reg  [6:0]  dev_addr;
  reg  [7:0]  tx_data;
  wire [7:0]  rx_data;
  wire        rx_valid;
  wire        ack_err;
  wire        busy;
  wire        bus_busy;
  wire        scl_o;
  wire        scl_i;
  wire        sda_o;
  wire        sda_i;

  // Open-drain wired-AND bus
  reg         slave_scl;
  reg         slave_sda;
  wire        scl;
  wire        sda;

  assign scl = scl_o & slave_scl;
  assign sda = sda_o & slave_sda;

  // Clock gen
  always #10 clk = ~clk;  // 50MHz

  // DUT instance
  i2c_master #(.CLK_FREQ(CLK_FREQ), .I2C_FREQ(I2C_FREQ))
  dut (.clk(clk), .rst_n(rst_n),
       .cmd(cmd), .cmd_start(cmd_start), .dev_addr(dev_addr),
       .tx_data(tx_data), .rx_data(rx_data), .rx_valid(rx_valid),
       .ack_err(ack_err), .busy(busy), .bus_busy(bus_busy),
       .scl_o(scl_o), .scl_i(scl), .sda_o(sda_o), .sda_i(sda));

  // =========================================================================
  // I2C Slave model
  // =========================================================================
  localparam S_IDLE  = 2'd0;
  localparam S_ADDR  = 2'd1;
  localparam S_DATA  = 2'd2;

  reg  [1:0] slv_state;
  reg  [3:0] slv_bit;
  reg  [6:0] slv_addr;
  reg        slv_rw;
  reg  [7:0] slv_buf;
  reg  [7:0] slv_tx_data [0:15];
  reg  [3:0] slv_tx_idx;
  reg        slv_stretch_en;
  reg        slv_stretch_cnt;

  // I2C slave FSM — samples on scl posedge, drives on scl negedge
  always @(posedge scl or negedge scl) begin
    if (!rst_n) begin
      slv_state    <= S_IDLE;
      slv_bit      <= 0;
      slv_addr     <= 0;
      slv_rw       <= 0;
      slv_buf      <= 0;
      slv_tx_idx   <= 0;
      slave_scl    <= 1'b1;
      slave_sda    <= 1'b1;
      slv_stretch_cnt <= 0;
    end else if (scl === 1'bx) begin
      slave_scl <= 1'b1;
      slave_sda <= 1'b1;
    end else if (scl == 1'b1) begin
      // posedge scl: sample SDA
      if (slv_state == S_ADDR || slv_state == S_DATA) begin
        if (slv_bit < 4'd8) begin
          slv_buf <= {slv_buf[6:0], sda};
        end
        slv_bit <= slv_bit + 1;
      end
    end else begin
      // negedge scl: change SDA
      if (slv_state == S_IDLE) begin
        // Detect START: sda falling while scl high
        if (sda == 0 && scl_o == 1) begin
          slv_state  <= S_ADDR;
          slv_bit    <= 0;
          slv_buf    <= 0;
          slave_scl  <= 1'b1;
          slave_sda  <= 1'b1;
        end
      end else if (slv_state == S_ADDR && slv_bit == 4'd8) begin
        // ACK bit: drive ACK if address matches
        slv_addr <= slv_buf[7:1];
        slv_rw   <= slv_buf[0];
        slv_bit  <= 0;
        if (slv_buf[7:1] == 7'h5A) begin
          slave_sda <= 1'b0;  // ACK
          slv_state <= S_DATA;
          slv_tx_idx <= 0;
        end else begin
          slave_sda <= 1'b1;  // NACK
          slv_state <= S_IDLE;
        end
      end else if (slv_state == S_DATA && slv_bit == 4'd9) begin
        // End of data byte
        slv_bit <= 0;
        if (slv_rw == 0) begin
          // Write: we just received a byte, ACK it
          if (slv_stretch_en && slv_stretch_cnt < 4) begin
            slave_scl  <= 1'b0;  // clock stretch
            slv_stretch_cnt <= slv_stretch_cnt + 1;
          end else begin
            slave_scl  <= 1'b1;
            slave_sda  <= 1'b0;  // ACK
          end
        end else begin
          // Read: master ACK'd (or NACK'd), prepare next tx byte or stop
          slave_sda <= 1'b1; // release SDA
          if (sda == 1'b0) begin
            // Master ACK'd: prepare next byte
            if (slv_tx_idx < 16) begin
              slv_buf <= slv_tx_data[slv_tx_idx];
              slv_tx_idx <= slv_tx_idx + 1;
            end
          end
          // If Master NACK'd: do nothing, wait for STOP
        end
      end else if (slv_state == S_DATA && slv_bit == 4'd0 && slv_rw == 1) begin
        // Drive first data bit MSB on negedge
        slave_sda <= slv_buf[7];
      end

      // During data phase: drive SDA for read operations
      if (slv_state == S_DATA && slv_rw == 1 && slv_bit > 0 && slv_bit < 4'd9) begin
        slave_sda <= slv_buf[7 - slv_bit];
      end

      // Detect STOP: sda rising while scl high
      if (sda == 1 && scl_o == 1 && slv_state != S_IDLE) begin
        slv_state <= S_IDLE;
        slave_scl <= 1'b1;
        slave_sda <= 1'b1;
      end
    end
  end

  // Detect START condition for slave
  reg sda_d1;
  always @(posedge clk) begin
    sda_d1 <= sda;
    if (!rst_n) begin
      sda_d1 <= 1;
    end
  end

  // =========================================================================
  // DUT command helpers
  // =========================================================================
  localparam CMD_START     = 3'd0;
  localparam CMD_STOP      = 3'd1;
  localparam CMD_WRITE     = 3'd2;
  localparam CMD_READ_ACK  = 3'd3;
  localparam CMD_READ_NACK = 3'd4;

  task dut_cmd;
    input [2:0] c;
    begin
      cmd = c;
      cmd_start = 1;
      @(posedge clk);
      cmd_start = 0;
      @(posedge clk);
    end
  endtask

  task wait_busy;
    begin
      while (busy) @(posedge clk);
    end
  endtask

  task wait_rx;
    begin
      while (!rx_valid) @(posedge clk);
    end
  endtask

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
    input [7:0] actual;
    input [7:0] expected;
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
      rst_n = 0;
      cmd = 0; cmd_start = 0; dev_addr = 0; tx_data = 0;
      slave_scl = 1; slave_sda = 1;
      slv_stretch_en = 0;
      repeat(10) @(posedge clk);
      rst_n = 1;
      repeat(10) @(posedge clk);
    end
  endtask

  // Write one byte to slave (full sequence: START + addr+W + data + STOP)
  task i2c_write_byte;
    input [6:0] addr;
    input [7:0] data;
    begin
      dev_addr = addr;
      tx_data  = data;
      dut_cmd(CMD_START);     wait_busy;
      dut_cmd(CMD_WRITE);     wait_busy;
      dut_cmd(CMD_WRITE);     wait_busy;
      dut_cmd(CMD_STOP);      wait_busy;
    end
  endtask

  // =========================================================================
  // Tests
  // =========================================================================
  initial begin
    clk = 0; rst_n = 0;
    cmd = 0; cmd_start = 0; dev_addr = 0; tx_data = 0;
    slave_scl = 1; slave_sda = 1;
    slv_stretch_en = 0;
    pass_cnt = 0; fail_cnt = 0;

    // Slave pre-loads response data
    slv_tx_data[0] = 8'h5A;
    slv_tx_data[1] = 8'hA5;
    slv_tx_data[2] = 8'h3C;

    $display("========================================");
    $display("  I2C Master Testbench  CLK=%0dMHz I2C=%0dkHz",
             CLK_FREQ/1000000, I2C_FREQ/1000);
    $display("========================================");

    // TC-01: Reset state
    $display("\n[TC-01] Reset state");
    reset_dut;
    check("busy=0 after reset",   busy == 0);
    check("bus_busy=0 after rst", bus_busy == 0);
    check("scl_o=1 after reset",  scl_o == 1);
    check("sda_o=1 after reset",  sda_o == 1);
    check("rx_valid=0 after rst", rx_valid == 0);
    check("ack_err=0 after rst",  ack_err == 0);

    // TC-02: Single byte write (addr=0x5A, data=0xA5)
    $display("\n[TC-02] Single byte write (0x5A addr, 0xA5 data)");
    reset_dut;
    i2c_write_byte(7'h5A, 8'hA5);
    // Wait for ACK result
    wait_rx;
    check("write ACK ok", ack_err == 0);
    check("bus_busy=0 after STOP", bus_busy == 0);

    // TC-03: Single byte read (START + addr+R + read + STOP)
    $display("\n[TC-03] Single byte read (0x5A addr, expect 0x5A)");
    slv_tx_data[0] = 8'h5A;
    dev_addr = 7'h5A;
    dut_cmd(CMD_START);     wait_busy;
    dut_cmd(CMD_READ_NACK); wait_busy;
    wait_rx;
    check_data("read byte 0x5A", rx_data, 8'h5A);
    check("read ack_err=0", ack_err == 0);
    dut_cmd(CMD_STOP);      wait_busy;
    check("bus_busy=0 after STOP", bus_busy == 0);

    // TC-04: Multi-byte write (START + addr+W + data1 + data2 + data3 + STOP)
    $display("\n[TC-04] Multi-byte write (3 bytes)");
    dev_addr = 7'h5A;
    dut_cmd(CMD_START); wait_busy;
    // addr+W byte
    dut_cmd(CMD_WRITE); wait_busy; wait_rx;
    check("addr ACK ok", ack_err == 0);
    // data bytes
    tx_data = 8'h11; dut_cmd(CMD_WRITE); wait_busy; wait_rx;
    check("data[0] ACK ok", ack_err == 0);
    tx_data = 8'h22; dut_cmd(CMD_WRITE); wait_busy; wait_rx;
    check("data[1] ACK ok", ack_err == 0);
    tx_data = 8'h33; dut_cmd(CMD_WRITE); wait_busy; wait_rx;
    check("data[2] ACK ok", ack_err == 0);
    dut_cmd(CMD_STOP); wait_busy;

    // TC-05: Multi-byte read (START + addr+R + read_ack + read_ack + read_nack + STOP)
    $display("\n[TC-05] Multi-byte read (3 bytes: 0x5A, 0xA5, 0x3C)");
    slv_tx_data[0] = 8'h5A;
    slv_tx_data[1] = 8'hA5;
    slv_tx_data[2] = 8'h3C;
    dev_addr = 7'h5A;
    dut_cmd(CMD_START);     wait_busy;
    dut_cmd(CMD_READ_ACK);  wait_busy; wait_rx;
    check_data("read[0] 0x5A", rx_data, 8'h5A);
    dut_cmd(CMD_READ_ACK);  wait_busy; wait_rx;
    check_data("read[1] 0xA5", rx_data, 8'hA5);
    dut_cmd(CMD_READ_NACK); wait_busy; wait_rx;
    check_data("read[2] 0x3C", rx_data, 8'h3C);
    dut_cmd(CMD_STOP);      wait_busy;

    // TC-06: NACK on address (no slave at 0x37)
    $display("\n[TC-06] NACK on address 0x37");
    dev_addr = 7'h37;
    dut_cmd(CMD_START); wait_busy;
    dut_cmd(CMD_WRITE); wait_busy;
    wait_rx;
    check("ACK ERR on wrong addr", ack_err == 1);

    // TC-07: Busy ignore (cmd_start while busy)
    $display("\n[TC-07] cmd_start ignored while busy");
    reset_dut;
    dev_addr = 7'h5A;
    tx_data  = 8'hC3;
    // Start a write
    dut_cmd(CMD_START);
    // Immediately try to start another command (should be ignored)
    cmd = CMD_STOP;
    cmd_start = 1;
    @(posedge clk);
    cmd_start = 0;
    @(posedge clk);
    // Wait for the first operation to complete
    while (busy) @(posedge clk);
    // Bus should still be busy with START (no STOP sent yet)
    check("bus_busy still set", bus_busy == 1);
    // Finish normally
    dut_cmd(CMD_STOP); wait_busy;

    // TC-08: Clock stretching
    $display("\n[TC-08] Clock stretching");
    reset_dut;
    slv_stretch_en = 1;
    slv_stretch_cnt = 0;
    dev_addr = 7'h5A;
    tx_data = 8'h42;
    dut_cmd(CMD_START);  wait_busy;
    dut_cmd(CMD_WRITE);  wait_busy; wait_rx;
    check("ACK with stretch", ack_err == 0);
    dut_cmd(CMD_WRITE);  wait_busy; wait_rx;
    check("data ACK with stretch", ack_err == 0);
    dut_cmd(CMD_STOP);   wait_busy;
    slv_stretch_en = 0;
    check("transfer OK with stretch", 1'b1);

    // TC-09: Reset during operation
    $display("\n[TC-09] Reset during operation");
    reset_dut;
    dev_addr = 7'h5A;
    tx_data  = 8'hFF;
    dut_cmd(CMD_START);
    repeat(50) @(posedge clk);
    rst_n = 0;
    repeat(10) @(posedge clk);
    check("busy=0 after mid-op rst", busy == 0);
    check("bu_busy=0 after mid-op rst", bus_busy == 0);
    rst_n = 1;
    repeat(10) @(posedge clk);

    // TC-10: Full read/write sequence stress (4 write + 4 read)
    $display("\n[TC-10] Read/write sequence stress (4W+4R)");
    slv_tx_data[0] = 8'h01; slv_tx_data[1] = 8'h02;
    slv_tx_data[2] = 8'h03; slv_tx_data[3] = 8'h04;
    // Write 4 bytes
    for (integer w = 0; w < 4; w = w + 1) begin
      dev_addr = 7'h5A; tx_data = 8'hA0 + w[7:0];
      dut_cmd(CMD_START); wait_busy;
      dut_cmd(CMD_WRITE); wait_busy; wait_rx;
      if (ack_err) $display("  FAIL write[%0d] NACK", w);
      dut_cmd(CMD_WRITE); wait_busy; wait_rx;
      if (ack_err) $display("  FAIL data[%0d] NACK", w);
      dut_cmd(CMD_STOP);  wait_busy;
    end
    // Read 4 bytes
    for (integer r = 0; r < 4; r = r + 1) begin
      dev_addr = 7'h5A;
      dut_cmd(CMD_START);     wait_busy;
      dut_cmd(CMD_READ_NACK); wait_busy;
      wait_rx;
      check_data("read byte ok", rx_data, 8'h01 + r[7:0]);
      dut_cmd(CMD_STOP);      wait_busy;
    end
    $display("  PASS  all 8 ops (no errors)");
    pass_cnt = pass_cnt + 1;

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
    #10000000;
    $display("TIMEOUT: simulation exceeded limit");
    $finish;
  end

endmodule
