#####################################################################
#####   Apply PrimeTime ECO to the routed design (tutorial ch. 13) #####
#####################################################################

#### Sourcing common setup script
source -echo ./setup/fc_common_setup.tcl

#### Sourcing flow setup script
source -echo ./setup/fc_flow_setup.tcl

open_lib ${RESULTS_PATH}/${DESIGN_LIBRARY}
open_block ${DESIGN_NAME}/route_opt

# Insert the ECO cells, then re-route and re-check connectivity
source -echo ./fc_eco.tcl
# FC's own hold analysis passes this path, so route_opt would otherwise downsize the
# PrimeTime hold buffers (seen in ECO pass 1: BUF_S_16 -> BUF_U_0P5). Keep them as PrimeTime sized them.
set_dont_touch [get_cells -quiet U_PTECO_*] true
check_lvs
route_opt
check_lvs

save_block

# signoff.tcl copies route_opt -> signoff, so drop the old signoff block before re-running it
remove_blocks -force ${DESIGN_NAME}/signoff

list_blocks
save_lib
exit
