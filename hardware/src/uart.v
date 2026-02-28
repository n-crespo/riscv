// Receives 8-bit serial data over a UART connection.
module uart_rx #(
    // assuming 100MHz Basys3 clock and 9600 baud rate (100,000,000 / 9600 = 10416)
    parameter CLKS_PER_BIT = 10416
) (
    input clk,
    input rx_serial,
    output reg rx_dv,
    output reg [7:0] rx_byte
);

  // state definitions
  localparam IDLE = 3'b000;
  localparam START_BIT = 3'b001;
  localparam DATA_BITS = 3'b010;
  localparam STOP_BIT = 3'b011;
  localparam CLEANUP = 3'b100;

  reg [ 2:0] state_reg = IDLE;
  reg [13:0] clock_count = 0;
  reg [ 2:0] bit_index = 0;

  always @(posedge clk) begin
    case (state_reg)
      // the default state, nothing is happening
      IDLE: begin
        rx_dv <= 0;
        clock_count <= 0;
        bit_index <= 0;

        // this bit is zero when nothing is happening, 1 when receiving
        if (rx_serial == 1'b0) begin
          state_reg <= START_BIT;  // WE ARE RECEIVING, start!
        end else begin
          state_reg <= IDLE;  // nothing is happening, use idle state @ next clock cycle
        end
      end

      // this verifies that received signals aren't noise and should actually be considered
      START_BIT: begin
        // wait half a bit period to sample directly in the middle of the pulse
        if (clock_count == (CLKS_PER_BIT - 1) / 2) begin
          // verify it is still a valid start bit
          if (rx_serial == 1'b0) begin  // 1 means we are still receiving
            clock_count <= 0;
            state_reg   <= DATA_BITS;  // we are good to consider this valid data
          end else begin  // we are no longer receiving, this was noise
            state_reg <= IDLE;
          end
        end else begin
          clock_count <= clock_count + 1;  // increment clock
          state_reg   <= START_BIT;  // try to start again
        end
      end

      // read the bits we are receiving
      DATA_BITS: begin
        // always wait one full bit period before sampling
        if (clock_count < CLKS_PER_BIT - 1) begin
          // increment the clock and wait
          clock_count <= clock_count + 1;
          state_reg   <= DATA_BITS;
        end else begin
          clock_count <= 0;
          // sample the current data bit
          rx_byte[bit_index] <= rx_serial;  // start filling up the rx_byte

          // once we received all 8 bits, stop
          if (bit_index < 7) begin
            bit_index <= bit_index + 1;
            state_reg <= DATA_BITS;
          end else begin
            bit_index <= 0;
            state_reg <= STOP_BIT;
          end
        end
      end

      // mark that we are done processing, time to cleanup
      STOP_BIT: begin
        // wait one full bit period for the stop bit to finish
        if (clock_count < CLKS_PER_BIT - 1) begin
          clock_count <= clock_count + 1;
          state_reg   <= STOP_BIT;
        end else begin
          // flag that a full byte is ready to be read
          rx_dv <= 1;
          clock_count <= 0;
          state_reg <= CLEANUP;
        end
      end

      // go back to idle
      CLEANUP: begin
        // pulse the valid signal for exactly one clock cycle
        rx_dv <= 0;  // set this back to zero to mark end of bit collection
        state_reg <= IDLE;
      end

      default: state_reg <= IDLE;
    endcase
  end
endmodule
