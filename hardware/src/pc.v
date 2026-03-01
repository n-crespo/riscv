`timescale 1ns / 1ps
// the program counter that tracks the current instruction address
module pc (
    input clk,
    input reset,
    output reg [7:0] pc_out
);

  // increment the program counter or reset it to zero
  always @(posedge clk) begin
    if (reset) begin
      pc_out <= 8'b0;
    end else begin
      pc_out <= pc_out + 1'b1;
    end
  end

endmodule

