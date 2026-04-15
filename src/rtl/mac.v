`timescale 1ns / 1ps

/**
 * Multiply-accumulate unit with fixed pipeline timing
 */
module mac #(
    parameter WIDTH = 8
) (
    input                         clk,
    input                         reset,
    input                         en,     // enable multiplication
    input                         clr,    // clear accumulator
    input  signed     [WIDTH-1:0] a,      // multiplier
    input  signed     [WIDTH-1:0] b,      // multiplicand
    input  signed     [     31:0] c,      // addend
    output reg signed [     31:0] accum   // final result
);

  // internal register for the product
  reg signed [15:0] mult_reg;

  /* multiplication stage
       stores the product on the cycle en is high */
  always @(posedge clk) begin
    if (reset) begin
      mult_reg <= 16'd0;
    end else if (en) begin
      mult_reg <= a * b;
    end
  end

  /* accumulation stage
       updates every cycle to capture the piped product */
  always @(posedge clk) begin
    if (reset || clr) begin
      accum <= 32'd0;
    end else begin
      // removing the 'en' gate allows the result to propagate
      // to accum one cycle after multiplication starts
      accum <= mult_reg + c;
    end
  end

endmodule
