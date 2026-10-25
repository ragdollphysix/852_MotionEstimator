#####################################################################
#####        Post-Layout STA using PrimeTime                    #####
#####################################################################

# Setup library paths
set search_path "./results/i2c_master_top.dlib \
                 ./common/ndm/saed14rvt_frame_timing.ndm"

set link_path "./common/liberty/saed14rvt_ff0p88v125c.db \
               ./common/liberty/saed14rvt_ss0p72vm40c.db \
               ./common/liberty/saed14rvt_tt0p8v25c.db"

# Read and link the design
read_verilog ./results/i2c_master_top.v
current_design i2c_master_top
link_design

# Read timing constraints
read_sdc ./results/i2c_master_top.sdc

# Define parasitic corners
set spefs {nomTLU_25 minTLU_125 maxTLU_-40}

# Run STA for each parasitic corner
foreach spef ${spefs} {

    # Read extracted parasitics and update timing
    read_parasitics ./results/i2c_master_top.spef.${spef}.spef
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
    save_session ./pt_session/i2c_master_top_${spef}_session

    # Remove parasitics before analyzing the next corner
    remove_annotated_parasitics
}

exit

