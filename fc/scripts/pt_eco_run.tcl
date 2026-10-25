#####################################################################
#####   PrimeTime ECO run (tutorial ch. 13): restore the failing   #####
#####   corner's session and generate fc_eco.tcl                   #####
#####################################################################

# nomTLU_25 (tt) has the worst hold slack; re-check all corners after the ECO
restore_session ./pt_session/top_nomTLU_25_session
source -echo ./scripts/pt_eco.tcl
exit
