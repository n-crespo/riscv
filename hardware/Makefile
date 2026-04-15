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

.PHONY: all project bitstream program gui clean sim test test_fib

all: project bitstream

project:
	@echo [INFO] Creating Project: $(PROJECT_NAME) -- Top: $(TOP_MODULE)
	"$(VIVADO_PATH)" -mode batch -notrace -source $(TCL_DIR)/create_project.tcl -tclargs $(PROJECT_NAME) $(TOP_MODULE) $(BUILD_DIR) $(SRC_DIR) $(SIM_DIR)

# -------------------------------------------------------------------------
# Unified Assembly Rule
# -------------------------------------------------------------------------
#  'make sim/anyfile.hex' for any .s file
$(SIM_DIR)/%.hex: $(SIM_DIR)/%.s
	@echo [INFO] Assembling $< ...
	$(RV_PREFIX)as -march=rv32i -mabi=ilp32 $< -o $(SIM_DIR)/$*.o
	$(RV_PREFIX)objcopy -O verilog --verilog-data-width=4 $(SIM_DIR)/$*.o $@

# -------------------------------------------------------------------------
# Simulation Targets
# -------------------------------------------------------------------------

# Alias for backward compatibility
sim: test

test: $(SIM_DIR)/tb.hex
ifeq ($(OS),Windows_NT)
	@echo [INFO] Compiling Regression Test with Vivado...
	"$(VIVADO_BIN)xvlog.bat" $(SRC_DIR)/*.v $(SIM_DIR)/tb.v
	"$(VIVADO_BIN)xelab.bat" tb -s reg_sim
	"$(VIVADO_BIN)xsim.bat" reg_sim -R
else
	@echo [INFO] Compiling Regression Test with Icarus...
	iverilog -o $(SIM_DIR)/reg_sim.vvp $(SRC_DIR)/*.v $(SIM_DIR)/tb.v
	vvp $(SIM_DIR)/reg_sim.vvp
endif

test_fib: $(SIM_DIR)/fib.hex
ifeq ($(OS),Windows_NT)
	@echo [INFO] Compiling Fibonacci Test with Vivado...
	"$(VIVADO_BIN)xvlog.bat" $(SRC_DIR)/*.v $(SIM_DIR)/tb_fib.v
	"$(VIVADO_BIN)xelab.bat" tb_fib -s fib_sim
	"$(VIVADO_BIN)xsim.bat" fib_sim -R
else
	@echo [INFO] Compiling Fibonacci Test with Icarus...
	iverilog -o $(SIM_DIR)/fib_sim.vvp $(SRC_DIR)/*.v $(SIM_DIR)/tb_fib.v
	vvp $(SIM_DIR)/fib_sim.vvp
endif

# -------------------------------------------------------------------------
# FPGA Hardware Targets
# -------------------------------------------------------------------------

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
