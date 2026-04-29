// =============================================================================
// Module  : spi_master
// Purpose : Gold-standard parameterized SPI master controller.
//           Supports all 4 CPOL/CPHA modes, MSB-first, simultaneous read/write.
//           Design patterns: parameter-driven config (VexRiscv), single-file
//           peripheral (Neorv32), documented boundary behaviour (LiteX).
//
// Parameters
//   DATA_WIDTH – bits per transfer (default 8, range 1-32)
//   CLK_DIV    – SCLK half-period in clk cycles (default 4 → SCLK = clk/8)
//   CPOL       – clock polarity: 0=idle low, 1=idle high
//   CPHA       – clock phase:  0=leading-edge capture, 1=trailing-edge capture
//
// Ports
//   clk       – system clock (posedge)
//   rst_n     – synchronous active-low reset
//   tx_data   – data to transmit, MSB first
//   tx_start  – one-cycle pulse; ignored while busy
//   rx_data   – received data, valid when rx_valid=1
//   rx_valid  – one-cycle pulse at transfer end
//   busy      – high during transfer
//   sclk      – SPI clock output
//   mosi      – Master Out Slave In
//   miso      – Master In Slave Out
//   cs_n      – Chip select, active low (asserted entire transfer)
//
// Boundary behaviour
//   • tx_start while busy : silently ignored
//   • after reset         : sclk=CPOL, cs_n=1, mosi=0, busy=0
// =============================================================================

`timescale 1ns / 1ps

module spi_master #(
  parameter integer DATA_WIDTH = 8,
  parameter integer CLK_DIV    = 4,
  parameter integer CPOL       = 0,
  parameter integer CPHA       = 0
)(
  input  wire                      clk,
  input  wire                      rst_n,
  input  wire [DATA_WIDTH-1:0]     tx_data,
  input  wire                      tx_start,
  output reg  [DATA_WIDTH-1:0]     rx_data,
  output reg                       rx_valid,
  output reg                       busy,
  output wire                      sclk,
  output reg                       mosi,
  input  wire                      miso,
  output reg                       cs_n
);

  localparam HP_W    = $clog2(CLK_DIV);
  localparam TOTAL_HP = 2 * DATA_WIDTH;
  localparam HP_IDX_W = $clog2(TOTAL_HP + 1);

  localparam S_IDLE  = 2'd0;
  localparam S_SHIFT = 2'd1;
  localparam S_DONE  = 2'd2;

  reg [1:0]            state;
  reg [HP_W-1:0]       hp_cnt;
  reg [HP_IDX_W-1:0]   hp_idx;
  reg [DATA_WIDTH-1:0] tx_shreg;
  reg [DATA_WIDTH-1:0] rx_shreg;
  reg                  sclk_int;   // internal toggle, sclk = sclk_int ^ CPOL

  wire is_leading  = ~hp_idx[0];   // even half-periods → leading edges
  wire do_capture  = is_leading ? (CPHA == 0) : (CPHA == 1);
  wire do_launch   = is_leading ? (CPHA == 1) : (CPHA == 0);

  always @(posedge clk) begin
    if (!rst_n) begin
      state    <= S_IDLE;
      busy     <= 1'b0;
      cs_n     <= 1'b1;
      sclk_int <= 1'b0;
      mosi     <= 1'b0;
      tx_shreg <= 0;
      rx_shreg <= 0;
      rx_data  <= 0;
      rx_valid <= 1'b0;
      hp_cnt   <= 0;
      hp_idx   <= 0;
    end else begin
      rx_valid <= 1'b0;

      case (state)

        S_IDLE: begin
          busy    <= 1'b0;
          cs_n    <= 1'b1;
          sclk_int <= 1'b0;
          mosi    <= 1'b0;
          hp_cnt  <= 0;
          hp_idx  <= 0;
          if (tx_start) begin
            busy     <= 1'b1;
            cs_n     <= 1'b0;
            tx_shreg <= tx_data;
            rx_shreg <= 0;
            hp_cnt   <= 0;
            hp_idx   <= 0;
            if (CPHA == 0)
              mosi <= tx_data[DATA_WIDTH-1];   // pre-drive MSB
            state <= S_SHIFT;
          end
        end

        S_SHIFT: begin
          if (hp_cnt == CLK_DIV - 1) begin
            hp_cnt <= 0;

            if (do_capture) begin
              rx_shreg <= {rx_shreg[DATA_WIDTH-2:0], miso};
            end

            if (do_launch) begin
              mosi     <= tx_shreg[DATA_WIDTH-1];
              tx_shreg <= {tx_shreg[DATA_WIDTH-2:0], 1'b0};
            end

            sclk_int <= ~sclk_int;

            if (hp_idx == TOTAL_HP - 1) begin
              state <= S_DONE;
            end else begin
              hp_idx <= hp_idx + 1;
            end
          end else begin
            hp_cnt <= hp_cnt + 1;
          end
        end

        S_DONE: begin
          rx_data  <= rx_shreg;
          rx_valid <= 1'b1;
          cs_n     <= 1'b1;
          busy     <= 1'b0;
          sclk_int <= 1'b0;
          state    <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

  // Drive sclk with correct polarity
  assign sclk = sclk_int ^ CPOL[0];

endmodule
