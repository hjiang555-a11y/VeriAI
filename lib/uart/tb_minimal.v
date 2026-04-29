`timescale 1ns / 1ps

module tb_minimal;
  reg clk, rst_n, tx_start;
  reg [7:0] tx_data;
  wire tx_busy, tx, rx_valid, rx_error;
  wire [7:0] rx_data;

  always #10 clk = ~clk;

  uart #(.CLK_FREQ(50000000), .BAUD_RATE(115200))
  dut (.clk(clk), .rst_n(rst_n), .tx_data(tx_data), .tx_start(tx_start),
       .tx_busy(tx_busy), .tx(tx), .rx(tx), .rx_data(rx_data),
       .rx_valid(rx_valid), .rx_error(rx_error));

  initial begin
    clk=0; rst_n=0; tx_data=0; tx_start=0;
    repeat(20) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    tx_data = 8'h55;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    @(posedge clk);

    repeat (1000000) begin
      @(posedge clk);
      if (rx_valid) begin
        $display("PASS: rx_data=0x%h, rx_error=%b", rx_data, rx_error);
        $finish;
      end
    end
    $display("FAIL: timeout");
    $finish;
  end
endmodule
