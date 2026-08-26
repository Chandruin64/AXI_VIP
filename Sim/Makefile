# =============================================================================
# Makefile for UVM Testbench
#
# Supported Simulators:
#   - Questa : Siemens Questa / Mentor QuestaSim
#   - VCS    : Synopsys VCS
# =============================================================================

SIMULATOR = Questa


# -----------------------------------------------------------------------------
# Tool and Environment Configuration
# -----------------------------------------------------------------------------

FSDB_PATH = /home/cad/eda/SYNOPSYS/verdi_vX-2025.06/verdi/X-2025.06/share/PLI/VCS/LINUX64

RTL = ../rtl/*
work = work

SVTB1 = ../tb/top.sv
SVTB2 = ../test/pkg.sv

INC = +incdir+../tb +incdir+../test +incdir+../master +incdir+../slave


# -----------------------------------------------------------------------------
# Questa Simulation Options
# -----------------------------------------------------------------------------

VSIMOPT     = -vopt -voptargs=+acc
VSIMCOV     = -coverage -sva

VSIMBATCH1  = -c -do "log -r /* ;coverage save -onexit mem_cov1;run -all; exit"
VSIMBATCH2  = -c -do "log -r /* ;coverage save -onexit mem_cov2;run -all; exit"
VSIMBATCH3  = -c -do "log -r /* ;coverage save -onexit mem_cov3;run -all; exit"


# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------

help:
	@echo =============================================================================================================
	@echo "! USAGE          --  make target                                                                                 !"
	@echo "! clean          =>  clean the earlier log and intermediate files.                                               !"
	@echo "! sv_cmp        =>  Create library and compile the code.                                                        !"
	@echo "! run_test       =>  clean, compile & run the simulation for fixed_test in batch mode.                           !"
	@echo "! run_test1      =>  clean, compile & run the simulation for incr_test in batch mode.                            !"
	@echo "! run_test2      =>  clean, compile & run the simulation for wrap_test in batch mode.                            !"
	@echo "! view_wave1     =>  To view the waveform of fixed_test                                                          !"
	@echo "! view_wave2     =>  To view the waveform of incr_test                                                           !"
	@echo "! view_wave3     =>  To view the waveform of wrap_test                                                           !"
	@echo "! regress        =>  clean, compile and run all testcases in batch mode.                                         !"
	@echo "! report         =>  To merge coverage reports for all testcases and convert to html format.                     !"
	@echo "! cov            =>  To open merged coverage report in html format.                                             !"
	@echo =============================================================================================================


# -----------------------------------------------------------------------------
# Generic Targets
# -----------------------------------------------------------------------------

clean     : clean_$(SIMULATOR)
sv_cmp    : sv_cmp_$(SIMULATOR)

run_test  : run_test_$(SIMULATOR)
run_test1 : run_test1_$(SIMULATOR)
run_test2 : run_test2_$(SIMULATOR)

view_wave1 : view_wave1_$(SIMULATOR)
view_wave2 : view_wave2_$(SIMULATOR)
view_wave3 : view_wave3_$(SIMULATOR)

regress : regress_$(SIMULATOR)
report  : report_$(SIMULATOR)
cov     : cov_$(SIMULATOR)


# =============================================================================
# Questa-Specific Targets
# =============================================================================

sv_cmp_Questa:
	vlib $(work)
	vmap work $(work)
	vlog -work $(work) $(RTL) $(INC) $(SVTB2) $(SVTB1)


# -----------------------------------------------------------------------------
# Fixed Burst Test
# -----------------------------------------------------------------------------

run_test_Questa: sv_cmp
	vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH1) -wlf wave_file1.wlf -l test1.log -sv_seed 2969046076 work.top +UVM_TESTNAME=fixed_test

	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov1

# Seed: 2969046076


# -----------------------------------------------------------------------------
# Incrementing Burst Test
# -----------------------------------------------------------------------------

run_test1_Questa: sv_cmp
	vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH2) -wlf wave_file2.wlf -l test2.log -sv_seed 3981970915 work.top +UVM_TESTNAME=incr_test

	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov2


# -----------------------------------------------------------------------------
# Wrapping Burst Test
# -----------------------------------------------------------------------------

run_test2_Questa: sv_cmp
	vsim -cvgperinstance $(VSIMOPT) $(VSIMCOV) $(VSIMBATCH3) -wlf wave_file3.wlf -l test3.log -sv_seed 4017622352 work.top +UVM_TESTNAME=wrap_test

	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov3


# -----------------------------------------------------------------------------
# Questa Waveform Viewing
# -----------------------------------------------------------------------------

view_wave1_Questa:
	vsim -view wave_file1.wlf

view_wave2_Questa:
	vsim -view wave_file2.wlf

view_wave3_Questa:
	vsim -view wave_file3.wlf


# -----------------------------------------------------------------------------
# Questa Coverage Report
# -----------------------------------------------------------------------------

report_Questa:
	vcover merge mem_cov mem_cov1 mem_cov2 mem_cov3
	vcover report -cvg -details -nocompactcrossbins -codeAll -assert -directive -html mem_cov


# -----------------------------------------------------------------------------
# Questa Regression
# -----------------------------------------------------------------------------

regress_Questa: clean_Questa run_test_Questa run_test1_Questa run_test2_Questa report_Questa cov_Questa


# -----------------------------------------------------------------------------
# Open Coverage Report
# -----------------------------------------------------------------------------

cov_Questa:
	firefox covhtmlreport/index.html&


# -----------------------------------------------------------------------------
# Questa Cleanup
# -----------------------------------------------------------------------------

clean_Questa:
	rm -rf transcript* *log* fcover* covhtml* mem_cov* *.wlf modelsim.ini work wlf* *.vstf
	clear


# =============================================================================
# VCS-Specific Targets
# =============================================================================

sv_cmp_VCS:
	vcs -l vcs.log -timescale=1ns/1ps -sverilog -ntb_opts uvm -debug_access+all -full64 -kdb -lca -P $(FSDB_PATH)/novas.tab $(FSDB_PATH)/pli.a $(RTL) $(INC) $(SVTB2) $(SVTB1)


# -----------------------------------------------------------------------------
# Fixed Burst Test
# -----------------------------------------------------------------------------

run_test_VCS: sv_cmp
	./simv -a vcs.log +fsdbfile+wave1.fsdb -cm_dir ./mem_cov1 +ntb_random_seed=2969046076 +UVM_TESTNAME=fixed_test

	urg -dir mem_cov1.vdb -format both -report urgReport1


# -----------------------------------------------------------------------------
# Incrementing Burst Test
# -----------------------------------------------------------------------------

run_test1_VCS: sv_cmp
	./simv -a vcs.log +fsdbfile+wave2.fsdb -cm_dir ./mem_cov2 +ntb_random_seed=3981970915 +UVM_TESTNAME=incr_test

	urg -dir mem_cov2.vdb -format both -report urgReport2


# -----------------------------------------------------------------------------
# Wrapping Burst Test
# -----------------------------------------------------------------------------

run_test2_VCS: sv_cmp
	./simv -a vcs.log +fsdbfile+wave3.fsdb -cm_dir ./mem_cov3 +ntb_random_seed=4017622352 +UVM_TESTNAME=wrap_test

	urg -dir mem_cov3.vdb -format both -report urgReport3


# -----------------------------------------------------------------------------
# VCS Waveform Viewing
# -----------------------------------------------------------------------------

view_wave1_VCS:
	verdi -ssf wave1.fsdb

view_wave2_VCS:
	verdi -ssf wave2.fsdb

view_wave3_VCS:
	verdi -ssf wave3.fsdb


# -----------------------------------------------------------------------------
# VCS Coverage Report
# -----------------------------------------------------------------------------

report_VCS:
	urg -dir mem_cov1.vdb mem_cov2.vdb mem_cov3.vdb -dbname merged_dir/merged_test -format both -report urgReport


# -----------------------------------------------------------------------------
# VCS Regression
# -----------------------------------------------------------------------------

regress_VCS: clean_VCS sv_cmp_VCS run_test_VCS run_test1_VCS run_test2_VCS report_VCS


# -----------------------------------------------------------------------------
# VCS Coverage
# -----------------------------------------------------------------------------

cov_VCS:
	verdi -cov -covdir merged_dir.vdb


# -----------------------------------------------------------------------------
# VCS Cleanup
# -----------------------------------------------------------------------------

clean_VCS:
	rm -rf simv* csrc* *.tmp *.vpd *.vdb *.key *.log *hdrs.h urgReport* *.fsdb novas* verdi* *report *.ini *.wlf *.vstf work mem*
	clear

# =============================================================================
# End of Makefile
# =============================================================================
