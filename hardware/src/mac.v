module mac #(
    parameter WIDTH = 8
) (
    input                  clk,
    input                  reset,
    input                  en,     // enable calculation
    input                  clr,    // clear accumulator
    input      [WIDTH-1:0] a,      // multiplier
    input      [WIDTH-1:0] b,      // multiplicand
    input      [     31:0] c,      // optional addend
    output reg [     31:0] accum   // final result
);

  // internal signal for the product register
  reg [15:0] mult_reg;

  /* multiplication stage
       stores the product in a register */
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      mult_reg <= 16'd0;
    end else if (en) begin
      mult_reg <= a * b;
    end
  end

  /* accumulation stage
       adds the product to the base value 'c' */
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      accum <= 32'd0;
    end else if (clr) begin
      accum <= 32'd0;
    end else if (en) begin
      accum <= mult_reg + c;
    end
  end

endmodule
