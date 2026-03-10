`timescale 1ns / 1ps

/**
 * The program counter that tracks the current instruction address
 */
module pc (
    input             clk,
    input             reset,
    input      [31:0] d,      // the calculated next address
    output reg [31:0] q       // the current address
);

  always @(posedge clk) begin
    if (reset) begin
      q <= 32'h0;
    end else begin
      q <= d;
    end
  end

endmodule
