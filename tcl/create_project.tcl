# read command line arguments
set project_name [lindex $argv 0]
set top_module [lindex $argv 1]
set build_dir [lindex $argv 2]
set src_dir [lindex $argv 3]

# create the vivado project targeting the basys3 part
create_project $project_name $build_dir -part xc7a35tcpg236-1 -force

# add all verilog and constraint files
add_files [glob -nocomplain $src_dir/*.v]
add_files -fileset constrs_1 [glob -nocomplain constraints/*.xdc]

# set the top level module
set_property top $top_module [current_fileset]
update_compile_order -fileset sources_1

# save and close
close_project
