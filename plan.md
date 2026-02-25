# Plan (nicolas)

- [ ] **Custom Assembler (Python)**: Write a script that reads a text file
      containing custom RISC-V assembly, translates each line into a 32-bit binary
      instruction, and saves it as a binary or hex file.

- [ ] **UART Receiver (Verilog)**: Implement a serial receiver to capture 8-bit packets
      sent from your computer over the USB-serial connection.

- [ ] **Byte Stitcher & Memory Interface (Verilog)**: Build a state machine that collects
      four consecutive 8-bit UART packets, concatenates them into a 32-bit word, and
      writes that word into the FPGA's block RAM.

- [ ] **Peripheral Controllers (Verilog)**: Write the hardware drivers for the user
      interface. This includes a debouncer for the physical buttons (to step the clock
      or pause execution) and a multiplexer to drive the 4-digit 7-segment display.

- [ ] **Top-Level Module (Verilog)**: Create the master file that connects RAM,
      UART, and I/O controllers to Frank's simulated CPU core.
