# project configuration
TOP_MODULE = top
PROJECT_NAME = riscv_uart_test
BUILD_DIR = .build
SRC_DIR = src
SIM_DIR = sim
TCL_DIR = ../tcl
TB_MODULE = tb

# toolchain path
VIVADO_PATH ?= C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat
VIVADO_BIN = $(dir $(VIVADO_PATH))

# riscv toolchain prefix
RV_PREFIX ?= riscv64-unknown-elf-

# set default args to just open the project
GUI_ARGS = $(BUILD_DIR)/$(PROJECT_NAME).xpr

.PHONY: all project bitstream program gui sim asm clean

all: project bitstream

project:
	@echo [INFO] Creating Project: $(PROJECT_NAME) -- Top: $(TOP_MODULE)
	"$(VIVADO_PATH)" -mode batch -notrace -source $(TCL_DIR)/create_project.tcl -tclargs $(PROJECT_NAME) $(TOP_MODULE) $(BUILD_DIR) $(SRC_DIR) $(SIM_DIR)

# compile assembly to hex
asm: $(SIM_DIR)/tb.hex

$(SIM_DIR)/tb.hex: $(SIM_DIR)/tb.s
	@echo [INFO] Assembling RISC-V code...
	$(RV_PREFIX)as -march=rv32i -mabi=ilp32 $< -o $(SIM_DIR)/tb.o
	$(RV_PREFIX)objcopy -O verilog --verilog-data-width=4 $(SIM_DIR)/tb.o $@

ifeq ($(OS),Windows_NT)
sim: asm
	@echo [INFO] Compiling Verilog...
	"$(VIVADO_BIN)xvlog.bat" $(SRC_DIR)/*.v $(SIM_DIR)/*.v
	@echo [INFO] Elaborating...
	"$(VIVADO_BIN)xelab.bat" tb -s my_sim_snapshot
	@echo [INFO] Running Simulation...
	"$(VIVADO_BIN)xsim.bat" my_sim_snapshot -R
else
sim: asm
	@echo [INFO] Compiling Verilog with Icarus...
	iverilog -o $(SIM_DIR)/my_sim_snapshot.vvp $(SRC_DIR)/*.v $(SIM_DIR)/*.v
	@echo [INFO] Running Simulation...
	vvp $(SIM_DIR)/my_sim_snapshot.vvp
endif

bitstream:
	@echo [INFO] Generating Bitstream...
	"$(VIVADO_PATH)" -mode batch -notrace -source $(TCL_DIR)/run_bitstream.tcl -tclargs $(PROJECT_NAME) $(BUILD_DIR)

program:
	@echo [INFO] Programming FPGA...
	"$(VIVADO_PATH)" -mode batch -notrace -source $(TCL_DIR)/program.tcl -tclargs $(PROJECT_NAME) $(TOP_MODULE) $(BUILD_DIR)

gui:
	"$(VIVADO_PATH)" -mode gui $(GUI_ARGS) &

clean:
	rm -rf $(BUILD_DIR) .Xil *.log *.jou *.pb xsim.dir $(SIM_DIR)/*.o $(SIM_DIR)/*.hex $(SIM_DIR)/*.vvp
