`timescale 1ns / 1ps

/**
 * Processes pixel values with mmio and hardware acceleration
 */
module pixel_processor (
    input         clk,
    input         reset,
    input         we,     // write enable from bus
    input  [ 1:0] addr,   // internal address (0 or 1)
    input  [31:0] din,    // data from risc-v
    output [31:0] dout    // data back to risc-v
);

  // internal registers
  reg [7:0] threshold_reg;

  // wires for unpacking and math
  wire [7:0] r, g, b;
  wire [31:0] red_res, green_res, blue_res;
  wire [7:0] gray_final;
  wire [7:0] bw_final;

  // unpack the 32-bit word from [alpha][red][green][blue] format
  assign r = din[23:16];
  assign g = din[15:8];
  assign b = din[7:0];

  // threshold register write logic with synchronous reset
  always @(posedge clk) begin
    if (reset) begin
      threshold_reg <= 8'h80;
    end else if (we && addr == 2'b01) begin
      threshold_reg <= din[7:0];
    end
  end

  // instantiate mac engines
  mac #(
      .WIDTH(8)
  ) mac_r (
      .clk(clk),
      .reset(reset),
      .en(we && addr == 2'b00),
      .clr(1'b0),
      .a(r),
      .b(8'd77),
      .c(32'd0),
      .accum(red_res)
  );
  mac #(
      .WIDTH(8)
  ) mac_g (
      .clk(clk),
      .reset(reset),
      .en(we && addr == 2'b00),
      .clr(1'b0),
      .a(g),
      .b(8'd150),
      .c(32'd0),
      .accum(green_res)
  );
  mac #(
      .WIDTH(8)
  ) mac_b (
      .clk(clk),
      .reset(reset),
      .en(we && addr == 2'b00),
      .clr(1'b0),
      .a(b),
      .b(8'd29),
      .c(32'd0),
      .accum(blue_res)
  );

  // GRAYSCALING (sum and divide by 256 --> single brightness value)
  // force 32-bit addition to prevent overflow before the shift
  // red_res, green_res, and blue_res are already 32-bit wires
  assign gray_final = (red_res + green_res + blue_res) >> 8;

  // thresholding logic (binarization, like relu function)
  assign bw_final = (gray_final > threshold_reg) ? 8'hFF : 8'h00;

  // pack result back into a 32-bit word
  assign dout = {8'd0, bw_final, bw_final, bw_final};

endmodule
