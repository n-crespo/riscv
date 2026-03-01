// Random access memory for storing variables and state during execution
module data_mem (
    input         clk,
    input         we,    // write enable from the control unit
    input  [ 7:0] addr,  // the memory address to access
    input  [31:0] wd,    // the data to save
    output [31:0] rd     // the data being read
);

  // 256 slots, each 32 bits wide
  reg [31:0] ram[0:255];

  // read asynchronously
  assign rd = ram[addr];

  // write synchronously on the clock edge
  always @(posedge clk) begin
    if (we) begin
      ram[addr] <= wd;
    end
  end

endmodule
