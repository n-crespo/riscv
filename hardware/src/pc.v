`timescale 1ns / 1ps
// the program counter that tracks the current instruction address
module pc (
    input clk,
    input reset,

    input             take_jump,  // control signal to load a new address
    input      [31:0] target_pc,  // the calculated destination address
    output reg [31:0] pc_out      // final location of the program counter
);

  // increment the program counter, reset it to zero, or load a jump address
  always @(posedge clk) begin
    if (reset) begin
      pc_out <= 32'b0;            // reset to 32-bit zero
    end else if (take_jump) begin
      pc_out <= target_pc;
    end else begin
      pc_out <= pc_out + 32'd4;    // increment by 4 bytes (1 word)
    end
  end

endmodule
