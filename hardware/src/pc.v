`timescale 1ns / 1ps
// the program counter that tracks the current instruction address
module pc (
    input clk,
    input reset,

    input       take_jump,  // control signal to load a new address
    input [7:0] target_pc,  // the calculated destination address

    output reg [7:0] pc_out  // final location of the program counter
);

  // increment the program counter, reset it to zero, or load a jump address
  always @(posedge clk) begin
    if (reset) begin
      pc_out <= 8'b0;
    end else if (take_jump) begin
      pc_out <= target_pc;
    end else begin
      pc_out <= pc_out + 1'b1;
    end
  end

endmodule

