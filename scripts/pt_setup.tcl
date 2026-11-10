#####################################################################
#####        Post-Layout STA using PrimeTime                    #####
#####################################################################

# Setup library paths
set search_path "./results/i2c_master_top.dlib \
                 ./common/ndm/saed14rvt_frame_timing.ndm"

set link_path "./common/liberty/saed14rvt_ff0p88v125c.db \
               ./common/liberty/saed14rvt_ss0p72vm40c.db \
               ./common/liberty/saed14rvt_tt0p8v25c.db"


set Design_name "i2c_master_top"	       
# Read and link the design
read_verilog ./results/${Design_name}.v
current_design ${Design_name}
link_design

# Read timing constraints
read_sdc ./results/${Design_name}.sdc

# Define parasitic corners
set spefs {nomTLU_25 minTLU_125 maxTLU_-40}

# Run STA for each parasitic corner
foreach spef ${spefs} {

    # Read extracted parasitics and update timing
    read_parasitics ./results/${Design_name}.spef.${spef}.spef
    update_timing

    # Generate timing reports
    redirect -file ./pt_reports/${spef}_report_global_timing.rpt {
        report_global_timing
    }

    redirect -file ./pt_reports/${spef}_report_timing_setup.rpt {
        report_timing -delay_type max
    }

    redirect -file ./pt_reports/${spef}_report_timing_hold.rpt {
        report_timing -delay_type min
    }

    # Save PrimeTime session
    save_session ./pt_session/${Design_name}_${spef}_session

    # Remove parasitics before analyzing the next corner
    remove_annotated_parasitics
}

exit

