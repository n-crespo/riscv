# Toolchain prefix (common for Ubuntu/WSL installs)
CROSS_COMPILE = riscv64-unknown-elf-
AS      = $(CROSS_COMPILE)as
LD      = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

# Flags
# -march=rv32i: basic 32-bit integer instruction set
# -mabi=ilp32: 32-bit integer ABI
ASFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = -Ttext 0x0 -m elf32lriscv

# Files
TARGET = program
SRCS   = $(TARGET).s
OBJS   = $(TARGET).o
ELF    = $(TARGET).elf
BIN    = $(TARGET).bin

# Default target
all: $(BIN) dump

# 1. Assemble .s to .o
$(OBJS): $(SRCS)
	$(AS) $(ASFLAGS) -o $(OBJS) $(SRCS)

# 2. Link .o to .elf
$(ELF): $(OBJS)
	$(LD) $(LDFLAGS) -o $(ELF) $(OBJS)

# 3. Extract raw binary from .elf
$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

# Optional: Display the hex to compare with your custom assembler
dump: $(ELF)
	@echo "--- Disassembly and Hex View ---"
	$(OBJDUMP) -d $(ELF)

upload: program.bin
	python3 uploader.py

# Clean up build files
clean:
	rm -f $(OBJS) $(ELF) $(BIN)

.PHONY: all clean dump
