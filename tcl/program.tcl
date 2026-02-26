# read command line arguments
set project_name [lindex $argv 0]
set top_module [lindex $argv 1]
set build_dir [lindex $argv 2]

# open hardware manager and connect to board
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

# set the bitstream file
set hw_device [lindex [get_hw_devices xc7a35t_0] 0]
set_property PROGRAM.FILE $build_dir/$project_name.runs/impl_1/$top_module.bit $hw_device

# program the fpga
program_hw_devices $hw_device
refresh_hw_device $hw_device

# clean up
close_hw_manager
