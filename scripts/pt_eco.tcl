#####################################################################
#####              PrimeTime ECO Timing Fix                     #####
#####################################################################

# Fix setup timing violations
#fix_eco_timing -type setup -current_library -verbose

# Fix hold timing violations using ECO buffer cells
fix_eco_timing -type hold \
        -pba_mode exhaustive \
        -buffer_list {SAEDRVT14_BUF_ECO_1 \
                      SAEDRVT14_BUF_ECO_2 \
                      SAEDRVT14_BUF_ECO_3}

# Write the ECO changes for implementation in Fusion Compiler
write_changes -format icc2tcl -output fc_eco.tcl

