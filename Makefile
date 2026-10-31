#################################################
################# Makefile ######################
######## Author : Spoorthi Yadav Manjunath ######
#################################################

help:
	@echo ""
	@echo " make help                  : To print usage"
	@echo " make run                   : To run full flow with Fusion Compiler"
	@echo " make clean                 : To clean entire working area"
	@echo " make run_initial_syn       : To run initial_syn stage" 
	@echo " make clean_initial_syn     : To clean initial_syn working area"
	@echo " make run_compile_flow      : Run compile flow stage"
	@echo " make clean_compile_flow    : Clean Compile Flow stage"
	@echo " make run_manual_floorplan  : Run Manual FloorPlan"
	@echo " make clean_manual_floorplan: Clean FloorPlan Stage"
	@echo " make run_placement         : Run Placement Stage"
	@echo " make clean_placement       : Clean Placement Stage"
	@echo " make run_cts               : Run CTS Stage"
	@echo " make clean_cts             : Clean CTS Stage"
	@echo " make run_route             : Run route Stage"
	@echo " make clean_route           : Clean route Stage"
	@echo " make run_signoff           : Run signoff Stage"
	@echo " make clean_signoff         : Clean signoff Stage"
	@echo " make run_pt                : Run PT STA"  

	@echo ""

run: run_initial_syn run_compile_flow run_manual_floorplan run_placement run_cts run_route run_signoff	

clean:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/* results/* reports/*
run_initial_syn:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/initial_syn.tcl | tee ./logs/initial_syn.log
clean_initial_syn:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/* results/* reports/*
run_compile_flow:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/compile_flow.tcl | tee ./logs/compile_flow.log
clean_compile_flow:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/compile_flow* results/compile_flow* reports/compile_flow*
run_manual_floorplan:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/manual_floorplan_creation.tcl | tee ./logs/manual_floorplan_creation.log
clean_manual_floorplan: 
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/*floorplan* results/*floorplan* reports/*floorplan*
run_placement:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/place_opt.tcl | tee ./logs/place_opt.log
clean_placement:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/*place* results/*place* reports/*place*
run_cts:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/clock_opt.tcl | tee ./logs/clock_opt.log
clean_cts:
	 rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/*clock* results/*clock* reports/*clock*
run_route:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/route_opt.tcl | tee ./logs/route_opt.log
clean_route:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log logs/*route* results/*route* reports/*route*
run_signoff:
	test -d ./logs  || mkdir ./logs
	fc_shell  -no_log -f ./scripts/signoff.tcl | tee ./logs/signoff.log
clean_signoff:
	rm -rf default* *.dlib fc.log HDL* CLIBs fc* check* lm_command.log work* logs/*signoff* legalizer* fmax_LP* signoff* report/*finish* post*

run_pt:
	test -d ./pt_reports  || mkdir ./pt_reports
	test -d ./pt_session  || mkdir ./pt_session
	pt_shell -f ./scripts/sta_post_layout.tcl | tee ./logs/pt_sta.log
clean_pt:
	rm -rf ./pt_reports/* ./pt_session/* 
