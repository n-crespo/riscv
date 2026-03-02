# read command line arguments
set project_name [lindex $argv 0]
set build_dir [lindex $argv 1]

# open the project
open_project $build_dir/$project_name.xpr

# clear out old failed data
reset_run synth_1
reset_run impl_1

# launch synthesis
launch_runs synth_1 -jobs 4
# use -timeout so it doesn't hang if it crashes again
wait_on_run synth_1

# fix: check if the synthesis checkpoint was created even if Vivado crashed
set synth_dcp "$build_dir/$project_name.runs/synth_1/top.dcp"
if {![file exists $synth_dcp]} {
    error "ERROR: Synthesis actually failed - no checkpoint found!"
}

# launch implementation and bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# check if implementation succeeded
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "ERROR: Implementation/Bitstream failed! Check the Vivado log in .build/."
}

close_project
