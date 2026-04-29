// =============================================================================
// Module  : gpio
// Purpose : Gold-standard parameterized General-Purpose I/O module.
//           Each pin independently configurable as input or output.
//           Single-cycle read/write latency.
//
//           Design patterns: Neorv32 single-file peripheral, VexRiscv
//           parameter-driven config.
//
// Parameters
//   WIDTH – number of GPIO pins (default 32, range 1–128)
//
// Ports
//   clk       – system clock (posedge)
//   rst_n     – synchronous active-low reset
//   dir       – direction control: 1=output, 0=input
//   out_data  – output data, drives gpio_pins when dir=1
//   in_data   – input data, reads current gpio_pins level
//   gpio_pins – bidirectional physical pins (inout)
//
// Boundary behaviour
//   • After reset : dir=0 (all input), out_data=0, gpio_pins=high-Z
//   • dir 0→1     : output register value immediately driven on pin
//   • dir 1→0     : pin released to high-Z, external pull determines level
//   • Simultaneous dir+out_data change : out_data takes effect in same cycle
//     for pins where dir=1, in_data reflects gpio_pins level in same cycle
// =============================================================================

`timescale 1ns / 1ps

module gpio #(
  parameter integer WIDTH = 32
)(
  input  wire                clk,
  input  wire                rst_n,
  input  wire [WIDTH-1:0]    dir,
  input  wire [WIDTH-1:0]    out_data,
  output wire [WIDTH-1:0]    in_data,
  inout  wire [WIDTH-1:0]    gpio_pins
);

  reg [WIDTH-1:0] dir_r;
  reg [WIDTH-1:0] out_r;

  always @(posedge clk) begin
    if (!rst_n) begin
      dir_r  <= {WIDTH{1'b0}};
      out_r  <= {WIDTH{1'b0}};
    end else begin
      dir_r  <= dir;
      out_r  <= out_data;
    end
  end

  // Bidirectional pin control: drive when dir_r=1, otherwise high-Z
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_pin
      assign gpio_pins[i] = dir_r[i] ? out_r[i] : 1'bz;
    end
  endgenerate

  // Input read is combinational from pins
  assign in_data = gpio_pins;

endmodule
