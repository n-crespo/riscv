// Multiplexes two 32-bit inputs into one output based on a selector signal
module mux2 (
    input [31:0] d0,
    input [31:0] d1,
    input sel,
    output [31:0] out
);

  // assign output based on the selector
  assign out = sel ? d1 : d0;

endmodule
