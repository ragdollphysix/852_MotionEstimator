#####################################################################
#####        Post-Layout STA using PrimeTime                    #####
#####################################################################

# Setup library paths
set search_path "./results/top.dlib \
                 ./common/ndm/saed14rvt_frame_timing.ndm"

# Parasitic corner -> matching liberty, same pairing as setup/mcmm_setup.tcl
# (Fast = ff + minTLU, Typical = tt + nomTLU, Slow = ss + maxTLU)
set corners {
    nomTLU_25   saed14rvt_tt0p8v25c.db
    minTLU_125  saed14rvt_ff0p88v125c.db
    maxTLU_-40  saed14rvt_ss0p72vm40c.db
}

# Run STA for each corner, linking cells to the matching library only
foreach {spef lib} ${corners} {

    remove_design -all
    set link_path "* ./common/liberty/${lib}"

    # Read and link the design
    read_verilog ./results/top.v
    current_design top
    link_design

    # Read timing constraints, adapted from FC's SDC (written from FUNC_Slow) for this corner:
    #  - FC writes SDC 2.2; this PrimeTime release accepts up to 2.1 (all commands are 2.1-compatible)
    #  - drop set_operating_conditions so the linked library's own conditions apply
    #  - point library-qualified references (set_driving_cell) at this corner's library
    set libname [file rootname ${lib}]
    exec sed -e {s/^set sdc_version 2.2$/set sdc_version 2.1/} \
             -e {/^set_operating_conditions/,/[^\\]$/d} \
             -e "s/saed14rvt_ss0p72vm40c\\.db:saed14rvt_ss0p72vm40c/${libname}.db:${libname}/g" \
             ./results/top.sdc > ./results/top_pt_${spef}.sdc
    read_sdc ./results/top_pt_${spef}.sdc

    # Read extracted parasitics and update timing
    read_parasitics ./results/top.spef.${spef}.spef
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
    save_session ./pt_session/top_${spef}_session
}

exit
