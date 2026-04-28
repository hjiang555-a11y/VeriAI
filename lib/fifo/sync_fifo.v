// =============================================================================
// Module  : sync_fifo
// Purpose : Gold-standard parameterized synchronous FIFO
//           Single clock, synchronous active-low reset.
//           Counter-based full/empty detection; one-cycle read latency.
//
// Parameters
//   DEPTH  – number of entries; must be a power of 2 (2, 4, 8, 16, …)
//            (not enforced in hardware; caller must satisfy this requirement)
//   WIDTH  – data bus width in bits
//
// Ports
//   clk       – clock (rising-edge triggered)
//   rst_n     – synchronous active-low reset
//   wr_en     – write enable  (ignored when full)
//   wr_data   – write data
//   rd_en     – read enable   (ignored when empty)
//   rd_data   – registered read data (valid one cycle after rd_en assertion)
//   full      – asserted when FIFO contains DEPTH entries
//   empty     – asserted when FIFO contains 0 entries
//   data_count– current number of valid entries
//
// Boundary behaviour
//   • Write while full  : write is silently dropped; pointers unchanged.
//   • Read while empty  : read is silently dropped; rd_data retains old value.
//   • Simultaneous wr+rd: both complete in the same cycle; count is unchanged
//     (unless FIFO was empty/full, in which case the respective flag is cleared).
//   • After reset       : wr_ptr=rd_ptr=data_count=0; full=0; empty=1.
// =============================================================================

`timescale 1ns / 1ps

module sync_fifo #(
  parameter integer DEPTH = 16,   // must be a power of 2
  parameter integer WIDTH = 8
)(
  input  wire               clk,
  input  wire               rst_n,

  // Write port
  input  wire               wr_en,
  input  wire [WIDTH-1:0]   wr_data,

  // Read port
  input  wire               rd_en,
  output reg  [WIDTH-1:0]   rd_data,

  // Status flags
  output wire               full,
  output wire               empty,
  output wire [$clog2(DEPTH):0] data_count
);

  // ---------------------------------------------------------------------------
  // Local parameters
  // ---------------------------------------------------------------------------
  localparam ADDR_W = $clog2(DEPTH);

  // ---------------------------------------------------------------------------
  // Storage array
  // ---------------------------------------------------------------------------
  reg [WIDTH-1:0] mem [0:DEPTH-1];

  // ---------------------------------------------------------------------------
  // Pointers and counter
  // ---------------------------------------------------------------------------
  reg [ADDR_W-1:0] wr_ptr;
  reg [ADDR_W-1:0] rd_ptr;
  reg [ADDR_W:0]   count;   // one extra bit to distinguish full from empty

  // ---------------------------------------------------------------------------
  // Derived flags
  // ---------------------------------------------------------------------------
  assign full       = (count == DEPTH[ADDR_W:0]);
  assign empty      = (count == {(ADDR_W+1){1'b0}});
  assign data_count = count;

  // ---------------------------------------------------------------------------
  // Effective enable signals (guard against overflow / underflow)
  // ---------------------------------------------------------------------------
  wire do_wr = wr_en && !full;
  wire do_rd = rd_en && !empty;

  // ---------------------------------------------------------------------------
  // Write path
  // ---------------------------------------------------------------------------
  integer i;
  always @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr <= {ADDR_W{1'b0}};
      // Optionally clear memory for clean simulation – omit for synthesis.
      // Non-blocking assignment (<=) is intentional: preserves correct
      // clocked-block semantics; all entries update at the clock edge.
      for (i = 0; i < DEPTH; i = i + 1)
        mem[i] <= {WIDTH{1'b0}};
    end else if (do_wr) begin
      mem[wr_ptr] <= wr_data;
      wr_ptr       <= wr_ptr + 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Read path  (registered output — 1-cycle read latency)
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      rd_ptr  <= {ADDR_W{1'b0}};
      rd_data <= {WIDTH{1'b0}};
    end else if (do_rd) begin
      rd_data <= mem[rd_ptr];
      rd_ptr  <= rd_ptr + 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Occupancy counter
  // ---------------------------------------------------------------------------
  always @(posedge clk) begin
    if (!rst_n) begin
      count <= {(ADDR_W+1){1'b0}};
    end else begin
      case ({do_wr, do_rd})
        2'b10:   count <= count + 1'b1;  // write only
        2'b01:   count <= count - 1'b1;  // read only
        default: count <= count;          // idle or simultaneous r+w
      endcase
    end
  end

endmodule
