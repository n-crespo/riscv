# read command line arguments
set project_name [lindex $argv 0]
set build_dir [lindex $argv 1]

# open the project
open_project $build_dir/$project_name.xpr

# launch synthesis and implementation
launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# save and close
close_project
