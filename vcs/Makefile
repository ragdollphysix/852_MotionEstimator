# Makefile for vcs simulation
RTL= ./top.v
TB = ./top_tb.v
SEED = 1

default: test 

test: compile run

run:
	./simv -l simv.log +ntb_random_seed=$(SEED)

compile:
	vcs -l vcs.log -kdb -sverilog -debug_access+all -full64 $(TB) $(RTL)

dve:
	dve -vpd vcdplus.vpd &
  
debug:
	./simv -l simv.log -verdi -tbug +ntb_random_seed=$(SEED)

clean:
	rm -rf simv* csrc* *.tmp *.vpd *.key *.log *hdrs.h *fsdb nova*

nuke: clean
	rm -rf *.v* *.sv include .*.lock .*.old verdi* *.tcl *.h
	cp .orig/* .

verdi:
	verdi -ssf novas.fsdb & 
  
help:
	@echo ==========================================================================
	@echo  " 								       "
	@echo  " USAGE: make target <SEED=xxx>                                         "
	@echo  " 								       "
	@echo  " ------------------------- Test TARGETS ------------------------------ "
	@echo  " test       => Compile TB and DUT files, runs the simulation.          "
	@echo  " compile    => Compile the TB and DUT.                                 "
	@echo  " run        => Run the simulation.                                     "
	@echo  " dve        => Run dve in post-processing mode                         "
	@echo  " debug      => Runs simulation interactively with dve                  "
	@echo  " clean      => Remove all intermediate simv and log files.             "
	@echo  " verdi      => Run Verdi.						"
	@echo  "                                                                       "
	@echo  " -------------------- ADMINISTRATIVE TARGETS ------------------------- "
	@echo  " help       => Displays this message.                                  "
	@echo  " nuke       => Erase all changes. Put all files back to original state "
	@echo  "								       "
	@echo ==========================================================================

