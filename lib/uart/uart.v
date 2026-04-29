// =============================================================================
// Module  : uart
// Purpose : Gold-standard parameterized UART transmitter and receiver.
//           Single clock domain, synchronous active-low reset.
//           Design patterns: LiteX CSR parameterization + Neorv32 single-file
//           peripheral organization + VexRiscv configuration-through-parameters.
//
// Parameters
//   CLK_FREQ  – system clock frequency in Hz
//   BAUD_RATE – target baud rate (default 115200)
//   DATA_BITS – data bits per frame, 5-8 (default 8)
//   STOP_BITS – stop bits, 1 or 2 (default 1)
//   PARITY    – 0=none, 1=even, 2=odd (default 0)
//
// Ports
//   clk       – system clock (posedge)
//   rst_n     – synchronous active-low reset
//
//   tx_data   – data to transmit (LSB first)
//   tx_start  – one-cycle pulse to start TX (ignored while tx_busy)
//   tx_busy   – high while TX in progress
//   tx        – serial TX output (idle = 1)
//
//   rx        – serial RX input
//   rx_data   – received data, valid when rx_valid = 1
//   rx_valid  – one-cycle pulse when new byte received
//   rx_error  – asserted with rx_valid on frame or parity error
//
// Boundary behaviour
//   • tx_start while tx_busy  : ignored silently
//   • false start on RX       : receiver resets to idle
//   • framing error (stop=0)  : rx_valid=1, rx_error=1, rx_data contains data
//   • parity error            : rx_valid=1, rx_error=1, rx_data contains data
//   • after reset             : tx=1, tx_busy=0, rx_valid=0, rx_error=0
// =============================================================================

`timescale 1ns / 1ps

module uart #(
  parameter integer CLK_FREQ  = 50000000,
  parameter integer BAUD_RATE = 115200,
  parameter integer DATA_BITS = 8,
  parameter integer STOP_BITS = 1,
  parameter integer PARITY    = 0   // 0=none, 1=even, 2=odd
)(
  input  wire                   clk,
  input  wire                   rst_n,
  input  wire [DATA_BITS-1:0]   tx_data,
  input  wire                   tx_start,
  output wire                   tx_busy,
  output reg                    tx,
  input  wire                   rx,
  output reg  [DATA_BITS-1:0]   rx_data,
  output reg                    rx_valid,
  output reg                    rx_error
);

  // =========================================================================
  // Local parameters
  // =========================================================================
  localparam CLKS_PER_BIT = (CLK_FREQ + BAUD_RATE/2) / BAUD_RATE;

  // =========================================================================
  // TX — bit-bang state machine
  // =========================================================================
  localparam TX_BITS_D = DATA_BITS;
  localparam TX_BITS_P = (PARITY > 0) ? 1 : 0;
  localparam TX_BITS_S = STOP_BITS;
  localparam TX_TOTAL  = 1 + TX_BITS_D + TX_BITS_P + TX_BITS_S;

  reg  [$clog2(TX_TOTAL):0] tx_bit;
  reg  [$clog2(CLKS_PER_BIT):0] tx_cnt;
  reg  [DATA_BITS-1:0]       tx_buf;

  assign tx_busy = (tx_bit < TX_TOTAL);

  always @(posedge clk) begin
    if (!rst_n) begin
      tx      <= 1'b1;
      tx_bit  <= TX_TOTAL;  // idle
      tx_cnt  <= 0;
      tx_buf  <= 0;
    end else begin
      if (tx_bit == TX_TOTAL) begin
        // idle
        tx <= 1'b1;
        tx_cnt <= 0;
        if (tx_start) begin
          tx_bit <= 0;
          tx_buf <= tx_data;
        end
      end else begin
        if (tx_cnt == 0) begin
          // drive next bit
          if (tx_bit == 0)
            tx <= 1'b0;  // start bit
          else if (tx_bit <= TX_BITS_D)
            tx <= tx_buf[tx_bit - 1];  // data LSB first
          else if (PARITY > 0 && tx_bit == TX_BITS_D + 1)
            tx <= (PARITY == 1) ? (^tx_buf) : ~(^tx_buf);  // parity
          else
            tx <= 1'b1;  // stop bit(s)
        end

        if (tx_cnt == CLKS_PER_BIT - 1) begin
          tx_cnt <= 0;
          tx_bit <= tx_bit + 1;  // advance, wraps to idle at TX_TOTAL
        end else begin
          tx_cnt <= tx_cnt + 1;
        end
      end
    end
  end

  // =========================================================================
  // RX — 8x oversampling with triple-sample majority vote
  // =========================================================================
  localparam OV_RATE  = 8;
  localparam CLKS_OV  = CLKS_PER_BIT / OV_RATE;  // derive from TX to match baud rate exactly
  localparam RX_BITS  = 1 + DATA_BITS + TX_BITS_P + STOP_BITS;  // total bits to receive

  reg  [1:0]                    rx_sync;
  reg  [$clog2(CLKS_OV):0]      rx_cnt;
  reg  [3:0]                    rx_phase;  // 0..OV_RATE-1 per bit
  reg  [$clog2(RX_BITS):0]      rx_bit;
  reg  [DATA_BITS-1:0]          rx_buf;
  reg  [1:0]                    rx_votes;  // running sum of 3 samples
  reg                           rx_parity_expected;
  reg                           rx_parity_received;
  reg                           bit_val;

  always @(posedge clk) begin
    if (!rst_n) begin
      rx_sync             <= 2'b11;
      rx_cnt              <= 0;
      rx_phase            <= 0;
      rx_bit              <= RX_BITS;  // idle
      rx_buf              <= 0;
      rx_data             <= 0;
      rx_valid            <= 0;
      rx_error            <= 0;
      rx_votes            <= 0;
      rx_parity_expected  <= 0;
      rx_parity_received  <= 0;
    end else begin
      rx_valid <= 0;  // default: pulse only

      // double-flop synchronizer
      rx_sync <= {rx_sync[0], rx};

      if (rx_bit == RX_BITS) begin
        // IDLE: wait for falling edge
        rx_cnt   <= 0;
        rx_phase <= 0;
        rx_votes <= 0;
        if (rx_sync[1] == 0) begin
          rx_bit   <= 0;
          rx_error <= 0;
          rx_parity_expected <= (PARITY == 1) ? 0 : (PARITY == 2) ? 1 : 0;
          rx_parity_received <= 0;
        end
      end else begin
        // oversample counter
        if (rx_cnt == CLKS_OV - 1) begin
          rx_cnt   <= 0;
          rx_phase <= rx_phase + 1;

          // sample in phases 3,4,5 (center third of bit)
          if (rx_phase == 3 || rx_phase == 4 || rx_phase == 5)
            rx_votes <= rx_votes + {1'b0, rx_sync[1]};

          // end of bit
          if (rx_phase == OV_RATE - 1) begin
            reg bit_val;
            bit_val = (rx_votes >= 2'd2);

            // 1. Validate start bit
            if (rx_bit == 0 && bit_val != 0) begin
              rx_bit <= RX_BITS;  // false start → back to idle
            end else begin
              // 2. Data bits
              if (rx_bit >= 1 && rx_bit <= DATA_BITS) begin
                rx_buf[rx_bit - 1] <= bit_val;
                if (PARITY > 0)
                  rx_parity_expected <= rx_parity_expected ^ bit_val;
              end
              // 3. Parity bit
              if (PARITY > 0 && rx_bit == DATA_BITS + 1)
                rx_parity_received <= bit_val;
              // 4. First stop bit
              if (rx_bit == DATA_BITS + TX_BITS_P + 1) begin
                rx_bit   <= RX_BITS;  // done
                rx_valid <= 1;
                rx_data  <= rx_buf;

                // compute parity error
                if (PARITY > 0 && (rx_parity_expected != rx_parity_received))
                  rx_error <= 1;
                else if (bit_val != 1'b1)
                  rx_error <= 1;  // framing error
                else
                  rx_error <= 0;
              end else begin
                rx_bit <= rx_bit + 1;
              end
            end
            rx_votes <= 0;
          end
        end else begin
          rx_cnt <= rx_cnt + 1;
        end
      end
    end
  end

endmodule
