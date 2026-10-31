source /packages/synopsys/setup/synthesis.csh
source /packages/synopsys/setup/vcs_2024.csh
#source /packages/synopsys/setup/primetime.csh
source /packages/synopsys/setup/primetime_2022.csh
source /packages/synopsys/setup/prime_eco.csh
source /packages/synopsys/setup/icc2_2021.csh
source /packages/synopsys/setup/verdi_2024.csh
source /packages/synopsys/setup/fc.csh
source /packages/synopsys/setup/ic_validator_2024.csh

setenv VCS_HOME /packages/synopsys/vcs/W-2024.09-1/
setenv VERDI_HOME /packages/synopsys/verdi/W-2024.09-1/

set path = ( $VERDI_HOME/bin $path ) ; rehash
set path = ( $VCS_HOME/bin $path ) ; rehash

