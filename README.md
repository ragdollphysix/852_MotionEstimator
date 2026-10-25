# ENGR 852: ASIC Implementation of Motion Estimator in 14nm CMOS

A block-matching motion estimator (16×16 reference block, 31×31 search window), taken from RTL through VCS simulation, Fusion Compiler synthesis and physical design, and PrimeTime post-layout STA on the SAED 14nm RVT library.

```
vcs/                     simulation: RTL, testbenches, test vectors, VCS Makefile
  top.v                  the design (also used by synthesis; see fc/common/rtl/verilog/top.v)
  mem_models.v           ROM_R / ROM_S memory models (testbench only, not synthesized)
  top_tb.v               random self-checking testbench
  top_tb_direct.v        file-based testbench (ref.txt / search.txt)
fc/                      Fusion Compiler + PrimeTime flow (tutorial-based)
  Makefile               run_initial_syn ... run_signoff, run_pt
  setup/  scripts/       flow setup and stage scripts
  common/sdc/top.sdc     design constraints
  common/rtl/verilog/top.v  -> symlink to ../../../../vcs/top.v
```

## Server setup (once per clone)

The repo must sit so that `fc/` and `vcs/` are siblings (the RTL symlink depends on it). On the class server, in csh:

```csh
csh
cd ~/engr852
git clone <repo-url> final_project
cd final_project/fc

# The PDK files are not in the repo (course license). Copy them from the course setup:
foreach d (gds liberty map ndm nxtgrd runsets tf tlup)
    cp -r /packages/synopsys/setup/Fusion_Compiler_setup/common/$d common/
end
mkdir -p logs reports results
```

## Every login

```csh
csh
cd ~/engr852/final_project/fc
source scripts/synopsys_setup.tcl     # VCS, Verdi, FC, PrimeTime, ICV
```

## Simulation

```csh
cd ~/engr852/final_project/vcs
make test SEED=1       # compile + run; result is at the end of simv.log
make verdi             # waveforms
```

## Implementation flow

From `fc/`, in order (each stage reads the previous stage's block from `results/top.dlib`):

```csh
make run_initial_syn
make run_compile_flow
make run_manual_floorplan
make run_placement
make run_cts
make run_route
make run_signoff
make run_pt            # PrimeTime, 3 corners -> pt_reports/
```

To rerun from scratch: `make clean_initial_syn`, then start again from `run_initial_syn`.

### Hold ECO (if PrimeTime reports hold violations)

```csh
pt_shell -f ./scripts/pt_eco_run.tcl | tee ./logs/pt_eco.log            # writes fc_eco.tcl
fc_shell -no_log -f ./scripts/fc_apply_eco.tcl | tee ./logs/fc_apply_eco.log
make clean_signoff && make run_signoff
make clean_pt && make run_pt
```

`pt_eco_run.tcl` restores the `nomTLU_25` session; edit it to target another corner.

## Changes from the tutorial setup

The first commit holds the files as provided (course zip + tutorial scripts). The second holds our changes; `git diff HEAD~1` shows them. In short:

- `top.v`: added `VDD`/`VSS` ports; ROM models moved to `mem_models.v`.
- `top.sdc`: 1.923 ns clock on `clock`, 0.2 ns uncertainty, 0.5 ns I/O delay (data ports only).
- Tutorial design and clock names (`i2c_master_top`, `wb_clk_i`) replaced in the scripts.
- `sta_post_layout.tcl`: each corner links its own library. The tutorial version links every corner to the fast library. It also converts FC's SDC 2.2 to the 2.1 that this PrimeTime accepts.
- `pt_eco_run.tcl`, `fc_apply_eco.tcl`: new; ECO cells are `dont_touch` so `route_opt` doesn't undo the fix.

## AI assistance disclosure

AI use is permitted for this project with disclosure. Claude (Anthropic) made the file changes in the second commit under review, ran the tool flow on the class server, and diagnosed the SDC, PrimeTime library-linking and ECO issues.
