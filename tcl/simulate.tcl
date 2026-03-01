# Runs the simulation in Vivado batch mode.
set project_name [lindex $argv 0]
set build_dir [lindex $argv 1]
set tb_name [lindex $argv 2]

# open the project
open_project $build_dir/$project_name.xpr

# set the testbench as the top module for simulation
set_property top $tb_name [get_filesets sim_1]
set_property sim_mode behavioral [get_filesets sim_1]

# launch and run the simulation
launch_simulation
run all

# close the simulation
close_sim
