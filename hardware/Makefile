# hardware/Makefile

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
VIVADO_CMD = "$(VIVADO_PATH)" -mode batch -notrace
VIVADO_BIN = $(dir $(VIVADO_PATH))

# set default args to just open the project
GUI_ARGS = $(BUILD_DIR)/$(PROJECT_NAME).xpr

.PHONY: all project bitstream program gui sim clean

all: project bitstream

project:
	@echo [INFO] Creating Project: $(PROJECT_NAME) -- Top: $(TOP_MODULE)
	$(VIVADO_CMD) -source $(TCL_DIR)/create_project.tcl -tclargs $(PROJECT_NAME) $(TOP_MODULE) $(BUILD_DIR) $(SRC_DIR) $(SIM_DIR)

sim:
	@echo [INFO] Running Simulation: $(TB_MODULE)
	$(VIVADO_CMD) -source $(TCL_DIR)/simulate.tcl -tclargs $(PROJECT_NAME) $(BUILD_DIR) $(TB_MODULE)

fast_sim:
	@echo [INFO] Compiling Verilog...
	"$(VIVADO_BIN)xvlog" $(SRC_DIR)/*.v $(SIM_DIR)/*.v
	@echo [INFO] Elaborating...
	"$(VIVADO_BIN)xelab" tb -s my_sim_snapshot
	@echo [INFO] Running Simulation...
	"$(VIVADO_BIN)xsim" my_sim_snapshot -R

bitstream:
	@echo [INFO] Generating Bitstream...
	$(VIVADO_CMD) -source $(TCL_DIR)/run_bitstream.tcl -tclargs $(PROJECT_NAME) $(BUILD_DIR)

program:
	@echo [INFO] Programming FPGA...
	$(VIVADO_CMD) -source $(TCL_DIR)/program.tcl -tclargs $(PROJECT_NAME) $(TOP_MODULE) $(BUILD_DIR)

gui:
	"$(VIVADO_PATH)" -mode gui $(GUI_ARGS) &

clean:
	rm -rf $(BUILD_DIR) .Xil *.log *.jou *.pb xsim.dir
