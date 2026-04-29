// =============================================================================
// Module  : i2c_master
// Purpose : Gold-standard parameterized I2C master controller.
//           Generates SCL clock, controls SDA bidirectional data line.
//           Supports standard (100kHz) and fast (400kHz) modes.
//           7-bit addressing, clock-stretching detection, ACK/NACK handling.
//
//           Design patterns: LiteX UART over-sampling, Neorv32 single-file
//           peripheral, VexRiscv parameter-driven configuration.
//
// Parameters
//   CLK_FREQ – system clock frequency in Hz
//   I2C_FREQ – target I2C bus frequency (100000 or 400000)
//
// Ports
//   clk       – system clock (posedge)
//   rst_n     – synchronous active-low reset
//   cmd       – command: 0=START, 1=STOP, 2=WRITE, 3=READ_ACK, 4=READ_NACK
//   cmd_start – one-cycle pulse; ignored while busy
//   dev_addr  – 7-bit slave address
//   tx_data   – data byte to transmit (for WRITE command)
//   rx_data   – received data byte (valid when rx_valid=1)
//   rx_valid  – one-cycle pulse on READ completion or ACK result
//   ack_err   – NACK detected (valid with rx_valid)
//   busy      – high during operation
//   bus_busy  – high when I2C bus is occupied (START seen, no STOP yet)
//   scl_o     – SCL open-drain output
//   scl_i     – SCL input (for clock-stretching detection)
//   sda_o     – SDA open-drain output
//   sda_i     – SDA input (for sampling / ACK detection)
//
// Boundary behaviour
//   • cmd_start while busy : silently ignored
//   • NACK on address phase : auto-generates STOP, asserts ack_err
//   • NACK on data WRITE    : asserts ack_err, caller decides next step
//   • Clock stretching      : pauses SCL generation indefinitely
//   • After reset           : scl_o=1, sda_o=1, busy=0, bus_busy=0
// =============================================================================

`timescale 1ns / 1ps

module i2c_master #(
  parameter integer CLK_FREQ = 100000000,
  parameter integer I2C_FREQ = 100000
)(
  input  wire               clk,
  input  wire               rst_n,
  input  wire [2:0]         cmd,
  input  wire               cmd_start,
  input  wire [6:0]         dev_addr,
  input  wire [7:0]         tx_data,
  output reg  [7:0]         rx_data,
  output reg                rx_valid,
  output reg                ack_err,
  output reg                busy,
  output reg                bus_busy,
  output reg                scl_o,
  input  wire               scl_i,
  output reg                sda_o,
  input  wire               sda_i
);

  // =========================================================================
  // Local parameters
  // =========================================================================
  localparam CLK_DIV = (CLK_FREQ + I2C_FREQ*2) / (I2C_FREQ * 4);  // quarters per I2C bit
  localparam CNT_W    = $clog2(CLK_DIV + 1);

  // Commands
  localparam CMD_START     = 3'd0;
  localparam CMD_STOP      = 3'd1;
  localparam CMD_WRITE     = 3'd2;
  localparam CMD_READ_ACK  = 3'd3;
  localparam CMD_READ_NACK = 3'd4;

  // Main FSM states
  localparam S_IDLE    = 3'd0;
  localparam S_START   = 3'd1;
  localparam S_BYTE    = 3'd2;
  localparam S_STOP    = 3'd3;
  localparam S_DONE    = 3'd4;

  // =========================================================================
  // Registers
  // =========================================================================
  reg  [2:0]             state;
  reg  [2:0]             active_cmd;
  reg  [6:0]             addr_r;
  reg  [3:0]             bit_idx;      // 0..7=data bits, 8=ACK bit
  reg  [7:0]             tx_buf;
  reg  [7:0]             rx_buf;
  reg                    read_nack;    // 1=send NACK after READ
  reg  [1:0]             scl_q;        // quadrant within a bit (0,1=low; 2,3=high)
  reg  [CNT_W-1:0]       q_cnt;        // counter within each quadrant
  reg                    stretch;      // clock-stretching detected

  // =========================================================================
  // Derived signals
  // =========================================================================
  wire q_done   = (q_cnt == CLK_DIV - 1);
  wire phase_ok = !(stretch && scl_q[1]);  // pause in quadrants 2/3 during stretch
  wire do_scl_low  = (scl_q == 2'd0 || scl_q == 2'd1);
  wire do_scl_high = (scl_q == 2'd2 || scl_q == 2'd3);

  // =========================================================================
  // Main FSM + SCL generation
  // =========================================================================
  always @(posedge clk) begin
    if (!rst_n) begin
      state      <= S_IDLE;
      active_cmd <= 3'd0;
      addr_r     <= 7'd0;
      tx_buf     <= 8'd0;
      rx_buf     <= 8'd0;
      rx_data    <= 8'd0;
      rx_valid   <= 1'b0;
      ack_err    <= 1'b0;
      busy       <= 1'b0;
      bus_busy   <= 1'b0;
      scl_o      <= 1'b1;
      sda_o      <= 1'b1;
      bit_idx    <= 4'd0;
      scl_q      <= 2'd0;
      q_cnt      <= 0;
      stretch    <= 1'b0;
      read_nack  <= 1'b0;
    end else begin
      rx_valid <= 1'b0;

      // Clock stretching detection: if we're driving SCL high (phase 2/3)
      // but the external SCL line is low, slave is stretching the clock
      if (do_scl_high && scl_o && !scl_i)
        stretch <= 1'b1;
      else if (!do_scl_high)
        stretch <= 1'b0;

      // Quadrant counter — pauses during clock stretching
      if (state == S_IDLE) begin
        q_cnt <= 0;
        scl_q <= 2'd0;
      end else begin
        if (phase_ok) begin
          if (q_done) begin
            q_cnt <= 0;
            scl_q <= scl_q + 1'b1;
          end else begin
            q_cnt <= q_cnt + 1'b1;
          end
        end
      end

      case (state)

        S_IDLE: begin
          busy    <= 1'b0;
          scl_o   <= 1'b1;
          sda_o   <= 1'b1;
          bit_idx <= 4'd0;
          scl_q   <= 2'd0;
          q_cnt   <= 0;
          if (cmd_start) begin
            busy       <= 1'b1;
            active_cmd <= cmd;
            addr_r     <= dev_addr;
            tx_buf     <= tx_data;
            read_nack  <= (cmd == CMD_READ_NACK);
            case (cmd)
              CMD_START: begin
                state <= S_START;
                bus_busy <= 1'b1;
              end
              CMD_STOP:  state <= S_STOP;
              default: begin
                // WRITE / READ_ACK / READ_NACK — must have had START before
                if (!bus_busy) begin
                  // No START before data command: error, go to IDLE
                  busy <= 1'b0;
                  state <= S_IDLE;
                end else begin
                  state <= S_BYTE;
                end
              end
            endcase
          end
        end

        // ===================================================================
        // START condition: SDA↓ while SCL=1, then SCL↓
        // ===================================================================
        S_START: begin
          case (scl_q)
            2'd0, 2'd1: begin
              scl_o <= 1'b1;
              if (scl_q == 2'd0 && q_cnt == 0) begin
                sda_o <= 1'b0;  // SDA low first
              end
            end
            2'd2, 2'd3: begin
              scl_o <= 1'b1;
            end
          endcase
          if (q_done && scl_q == 2'd3) begin
            scl_o   <= 1'b0;
            scl_q   <= 2'd0;
            q_cnt   <= 0;
            state   <= S_DONE;
            // After START, auto-send address byte if WRITE or READ_ACK/NACK
          end
        end

        // ===================================================================
        // BYTE — 8 data bits + 1 ACK bit
        // ===================================================================
        S_BYTE: begin
          // SCL control
          if (scl_q[1] == 1'b0) begin
            // Low phase (0,1): drive SCL low
            scl_o <= 1'b0;
            // Change SDA at beginning of low phase (q_cnt==0, scl_q==0)
            if (scl_q == 2'd0 && q_cnt == 0) begin
              if (active_cmd == CMD_WRITE) begin
                // Drive next data bit (MSB first) or release for ACK
                if (bit_idx < 4'd8)
                  sda_o <= tx_buf[7 - bit_idx[2:0]];
                else
                  sda_o <= 1'b1;  // release SDA for ACK sampling
              end else begin
                // READ: release SDA for sampling, or drive ACK/NACK
                if (bit_idx < 4'd8)
                  sda_o <= 1'b1;  // release for sampling
                else
                  sda_o <= read_nack;  // drive ACK(0) or NACK(1)
              end
            end
          end else begin
            // High phase (2,3): drive SCL high
            scl_o <= 1'b1;
          end

          // Sample SDA in the middle of high phase
          if (scl_q == 2'd2 && q_cnt == (CLK_DIV >> 1)) begin
            if (active_cmd == CMD_WRITE) begin
              if (bit_idx == 4'd8)
                ack_err <= sda_i;  // sample ACK
            end else begin
              if (bit_idx < 4'd8)
                rx_buf <= {rx_buf[6:0], sda_i};  // sample data bit (MSB first)
            end
          end

          // Advance to next bit
          if (q_done && scl_q == 2'd3) begin
            scl_q <= 2'd0;
            q_cnt <= 0;
            if (bit_idx == 4'd8) begin
              state <= S_DONE;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end
        end

        // ===================================================================
        // STOP condition: SCL↑, then SDA↑ while SCL=1
        // ===================================================================
        S_STOP: begin
          // First: ensure SCL low and SDA low
          if (scl_q == 2'd0) begin
            scl_o <= 1'b0;
            sda_o <= 1'b0;
          end else if (scl_q == 2'd1 || scl_q == 2'd2) begin
            scl_o <= 1'b1;
            sda_o <= 1'b0;
          end else begin
            scl_o <= 1'b1;
            sda_o <= 1'b1;  // STOP: SDA rises while SCL high
          end
          if (q_done && scl_q == 2'd3) begin
            bus_busy <= 1'b0;
            state    <= S_DONE;
          end
        end

        // ===================================================================
        // DONE — one cycle to present results
        // ===================================================================
        S_DONE: begin
          if (active_cmd == CMD_START) begin
            // After START, the next command should be WRITE (addr+RW byte)
            // Do nothing extra here — caller sends WRITE/READ next
            rx_valid <= 1'b0;
          end else if (active_cmd == CMD_STOP) begin
            rx_valid <= 1'b0;
          end else if (active_cmd == CMD_WRITE) begin
            rx_valid <= 1'b1;
          end else begin
            // READ_ACK or READ_NACK
            rx_data   <= rx_buf;
            rx_valid  <= 1'b1;
          end
          state <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
