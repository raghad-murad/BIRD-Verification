VCS      := vcs
SIMV     := ./simv
URG      := urg
VCSFLAGS := -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
            +incdir+verif/tb \
            -l compile.log

# Code coverage metrics: line, condition, branch, toggle, FSM.
# Functional coverage (SV covergroups) is captured automatically
# whenever -cm is enabled; urg's "group" metric extracts it.
CMFLAGS  := -cm line+cond+branch+tgl+fsm
CMDIR    := cm.vdb

SRCS := verif/if/bird_if.sv \
        verif/cfg/bird_pkg.sv \
        verif/tb/tb_top.sv \
        design/bird.sv

.PHONY: all compile compile_cov sim_local sim_local_multi sim_multi_frag_drop sim_remote sim_remote_ooo sim_backpressure sim_drop sim_rand sim_coverage sim_drop_while_active sim_drop_cnt_wrap sim_power_on_reset sim_reset_during_local sim_reset_during_remote sim_normal_after_reset sim_reset_clears_drop_cnt sim_interleaved sim_interleaved_mix sim_mixed_random sim_remote_back_to_back sim_cfg_change_ignored sim_transfer_rule sim_stability_rule sim_local_backpressure sim_remote_backpressure sim_backpressure_last_byte sim_fragments_same_seq sim_mismatched_seq sim_frag1_while_incomplete sim_missing_fragment sim_one_remote_packet_at_a_time sim_two_frags_ooo sim_three_frags_ooo sim_five_frags_random sim_diff_payload_len sim_max_frags_reord sim_payload_len_boundary sim_all sim_all_cov coverage_report clean

all: compile

compile: $(SRCS)
	$(VCS) $(VCSFLAGS) $(SRCS) -o simv

compile_cov: $(SRCS)
	rm -rf $(CMDIR) simv simv.daidir csrc
	$(VCS) $(VCSFLAGS) $(CMFLAGS) -cm_dir $(CMDIR) $(SRCS) -o simv

sim_local: simv
	$(SIMV) +UVM_TESTNAME=local_basic_test +UVM_VERBOSITY=UVM_LOW -l sim_local.log

# TP_CNT_03
sim_local_multi: simv
	$(SIMV) +UVM_TESTNAME=local_multi_test +UVM_VERBOSITY=UVM_LOW -l sim_local_multi.log

sim_remote: simv
	$(SIMV) +UVM_TESTNAME=remote_basic_test +UVM_VERBOSITY=UVM_LOW -l sim_remote.log

sim_remote_ooo: simv
	$(SIMV) +UVM_TESTNAME=remote_outoforder_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_ooo.log

# TP_MIX_03
sim_remote_back_to_back: simv
	$(SIMV) +UVM_TESTNAME=remote_back_to_back_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_back_to_back.log

sim_backpressure: simv
	$(SIMV) +UVM_TESTNAME=backpressure_test +UVM_VERBOSITY=UVM_LOW -l sim_backpressure.log

sim_drop: simv
	$(SIMV) +UVM_TESTNAME=drop_conditions_test +UVM_VERBOSITY=UVM_LOW -l sim_drop.log

# TP_CNT_04
sim_multi_frag_drop: simv
	$(SIMV) +UVM_TESTNAME=multi_frag_drop_once_test +UVM_VERBOSITY=UVM_LOW -l sim_multi_frag_drop.log

sim_rand: simv
	$(SIMV) +UVM_TESTNAME=rand_test +UVM_VERBOSITY=UVM_LOW -l sim_rand.log

# TP_MIX_02
sim_mixed_random: simv
	$(SIMV) +UVM_TESTNAME=mixed_random_test +UVM_VERBOSITY=UVM_LOW -l sim_mixed_random.log

sim_coverage: simv
	$(SIMV) +UVM_TESTNAME=coverage_test +UVM_VERBOSITY=UVM_LOW -l sim_coverage.log

sim_drop_while_active: simv
	$(SIMV) +UVM_TESTNAME=drop_while_active_test +UVM_VERBOSITY=UVM_LOW -l sim_drop_while_active.log

# TP-030: drop_cnt 16-bit wraparound (65536 drops). Standalone target —
# not part of sim_all/sim_all_cov since it streams a large packet count
# and the DUT's per-cycle debug $display output would bloat regression logs.
sim_drop_cnt_wrap: simv
	$(SIMV) +UVM_TESTNAME=drop_cnt_wraparound_test +UVM_VERBOSITY=UVM_LOW -l sim_drop_cnt_wrap.log

# TP_RST_01..TP_RST_04
sim_power_on_reset: simv
	$(SIMV) +UVM_TESTNAME=power_on_reset_test +UVM_VERBOSITY=UVM_LOW -l sim_power_on_reset.log

sim_reset_during_local: simv
	$(SIMV) +UVM_TESTNAME=reset_during_local_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_during_local.log

sim_reset_during_remote: simv
	$(SIMV) +UVM_TESTNAME=reset_during_remote_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_during_remote.log

sim_normal_after_reset: simv
	$(SIMV) +UVM_TESTNAME=normal_after_reset_test +UVM_VERBOSITY=UVM_LOW -l sim_normal_after_reset.log

# TP_CNT_06
sim_reset_clears_drop_cnt: simv
	$(SIMV) +UVM_TESTNAME=reset_clears_drop_cnt_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_clears_drop_cnt.log

# TP_CLS_03, TP_SMPL_02
sim_interleaved: simv
	$(SIMV) +UVM_TESTNAME=interleaved_local_remote_test +UVM_VERBOSITY=UVM_LOW -l sim_interleaved.log

sim_cfg_change_ignored: simv
	$(SIMV) +UVM_TESTNAME=cfg_change_ignored_test +UVM_VERBOSITY=UVM_LOW -l sim_cfg_change_ignored.log

# TP_MIX_01
sim_interleaved_mix: simv
	$(SIMV) +UVM_TESTNAME=interleaved_mix_test +UVM_VERBOSITY=UVM_LOW -l sim_interleaved_mix.log

# TP_HS_01..TP_HS_05
sim_transfer_rule: simv
	$(SIMV) +UVM_TESTNAME=transfer_rule_test +UVM_VERBOSITY=UVM_LOW -l sim_transfer_rule.log

sim_stability_rule: simv
	$(SIMV) +UVM_TESTNAME=stability_rule_test +UVM_VERBOSITY=UVM_LOW -l sim_stability_rule.log

sim_local_backpressure: simv
	$(SIMV) +UVM_TESTNAME=local_backpressure_test +UVM_VERBOSITY=UVM_LOW -l sim_local_backpressure.log

sim_remote_backpressure: simv
	$(SIMV) +UVM_TESTNAME=remote_backpressure_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_backpressure.log

sim_backpressure_last_byte: simv
	$(SIMV) +UVM_TESTNAME=backpressure_last_byte_test +UVM_VERBOSITY=UVM_LOW -l sim_backpressure_last_byte.log

# TP_SEQ_01..TP_SEQ_04
sim_fragments_same_seq: simv
	$(SIMV) +UVM_TESTNAME=fragments_same_seq_test +UVM_VERBOSITY=UVM_LOW -l sim_fragments_same_seq.log

sim_mismatched_seq: simv
	$(SIMV) +UVM_TESTNAME=mismatched_seq_test +UVM_VERBOSITY=UVM_LOW -l sim_mismatched_seq.log

sim_frag1_while_incomplete: simv
	$(SIMV) +UVM_TESTNAME=frag1_while_incomplete_test +UVM_VERBOSITY=UVM_LOW -l sim_frag1_while_incomplete.log

sim_missing_fragment: simv
	$(SIMV) +UVM_TESTNAME=missing_fragment_test +UVM_VERBOSITY=UVM_LOW -l sim_missing_fragment.log

# TP_REM_01
sim_one_remote_packet_at_a_time: simv
	$(SIMV) +UVM_TESTNAME=one_remote_packet_at_a_time_test +UVM_VERBOSITY=UVM_LOW -l sim_one_remote_packet_at_a_time.log

# TP_REORD_01..TP_REORD_05
sim_two_frags_ooo: simv
	$(SIMV) +UVM_TESTNAME=two_frags_ooo_test +UVM_VERBOSITY=UVM_LOW -l sim_two_frags_ooo.log

sim_three_frags_ooo: simv
	$(SIMV) +UVM_TESTNAME=three_frags_ooo_test +UVM_VERBOSITY=UVM_LOW -l sim_three_frags_ooo.log

sim_five_frags_random: simv
	$(SIMV) +UVM_TESTNAME=five_frags_random_test +UVM_VERBOSITY=UVM_LOW -l sim_five_frags_random.log

sim_diff_payload_len: simv
	$(SIMV) +UVM_TESTNAME=diff_payload_len_test +UVM_VERBOSITY=UVM_LOW -l sim_diff_payload_len.log

sim_max_frags_reord: simv
	$(SIMV) +UVM_TESTNAME=max_frags_test +UVM_VERBOSITY=UVM_LOW -l sim_max_frags_reord.log

# TP_CFG_10
sim_payload_len_boundary: simv
	$(SIMV) +UVM_TESTNAME=payload_len_boundary_test +UVM_VERBOSITY=UVM_LOW -l sim_payload_len_boundary.log

sim_all: simv
	$(SIMV) +UVM_TESTNAME=local_basic_test    +UVM_VERBOSITY=UVM_LOW -l sim_local.log
	$(SIMV) +UVM_TESTNAME=remote_basic_test   +UVM_VERBOSITY=UVM_LOW -l sim_remote.log
	$(SIMV) +UVM_TESTNAME=remote_outoforder_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_ooo.log
	$(SIMV) +UVM_TESTNAME=backpressure_test   +UVM_VERBOSITY=UVM_LOW -l sim_backpressure.log
	$(SIMV) +UVM_TESTNAME=drop_conditions_test +UVM_VERBOSITY=UVM_LOW -l sim_drop.log
	$(SIMV) +UVM_TESTNAME=rand_test           +UVM_VERBOSITY=UVM_LOW -l sim_rand.log
	$(SIMV) +UVM_TESTNAME=coverage_test       +UVM_VERBOSITY=UVM_LOW -l sim_coverage.log
	$(SIMV) +UVM_TESTNAME=drop_while_active_test +UVM_VERBOSITY=UVM_LOW -l sim_drop_while_active.log
	$(SIMV) +UVM_TESTNAME=power_on_reset_test +UVM_VERBOSITY=UVM_LOW -l sim_power_on_reset.log
	$(SIMV) +UVM_TESTNAME=reset_during_local_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_during_local.log
	$(SIMV) +UVM_TESTNAME=reset_during_remote_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_during_remote.log
	$(SIMV) +UVM_TESTNAME=normal_after_reset_test +UVM_VERBOSITY=UVM_LOW -l sim_normal_after_reset.log
	$(SIMV) +UVM_TESTNAME=reset_clears_drop_cnt_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_clears_drop_cnt.log
	$(SIMV) +UVM_TESTNAME=interleaved_local_remote_test +UVM_VERBOSITY=UVM_LOW -l sim_interleaved.log
	$(SIMV) +UVM_TESTNAME=cfg_change_ignored_test +UVM_VERBOSITY=UVM_LOW -l sim_cfg_change_ignored.log
	$(SIMV) +UVM_TESTNAME=interleaved_mix_test +UVM_VERBOSITY=UVM_LOW -l sim_interleaved_mix.log
	$(SIMV) +UVM_TESTNAME=mixed_random_test +UVM_VERBOSITY=UVM_LOW -l sim_mixed_random.log
	$(SIMV) +UVM_TESTNAME=remote_back_to_back_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_back_to_back.log
	$(SIMV) +UVM_TESTNAME=local_multi_test +UVM_VERBOSITY=UVM_LOW -l sim_local_multi.log
	$(SIMV) +UVM_TESTNAME=multi_frag_drop_once_test +UVM_VERBOSITY=UVM_LOW -l sim_multi_frag_drop.log

# Run every test with coverage enabled, accumulating into one $(CMDIR)
sim_all_cov: compile_cov
	$(SIMV) $(CMFLAGS) -cm_name local_basic_test       -cm_dir $(CMDIR) +UVM_TESTNAME=local_basic_test       +UVM_VERBOSITY=UVM_LOW -l sim_local.log
	$(SIMV) $(CMFLAGS) -cm_name remote_basic_test       -cm_dir $(CMDIR) +UVM_TESTNAME=remote_basic_test      +UVM_VERBOSITY=UVM_LOW -l sim_remote.log
	$(SIMV) $(CMFLAGS) -cm_name remote_outoforder_test  -cm_dir $(CMDIR) +UVM_TESTNAME=remote_outoforder_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_ooo.log
	$(SIMV) $(CMFLAGS) -cm_name backpressure_test       -cm_dir $(CMDIR) +UVM_TESTNAME=backpressure_test      +UVM_VERBOSITY=UVM_LOW -l sim_backpressure.log
	$(SIMV) $(CMFLAGS) -cm_name drop_conditions_test    -cm_dir $(CMDIR) +UVM_TESTNAME=drop_conditions_test   +UVM_VERBOSITY=UVM_LOW -l sim_drop.log
	$(SIMV) $(CMFLAGS) -cm_name rand_test               -cm_dir $(CMDIR) +UVM_TESTNAME=rand_test              +UVM_VERBOSITY=UVM_LOW -l sim_rand.log
	$(SIMV) $(CMFLAGS) -cm_name coverage_test           -cm_dir $(CMDIR) +UVM_TESTNAME=coverage_test          +UVM_VERBOSITY=UVM_LOW -l sim_coverage.log
	$(SIMV) $(CMFLAGS) -cm_name drop_while_active_test  -cm_dir $(CMDIR) +UVM_TESTNAME=drop_while_active_test +UVM_VERBOSITY=UVM_LOW -l sim_drop_while_active.log
	$(SIMV) $(CMFLAGS) -cm_name power_on_reset_test     -cm_dir $(CMDIR) +UVM_TESTNAME=power_on_reset_test    +UVM_VERBOSITY=UVM_LOW -l sim_power_on_reset.log
	$(SIMV) $(CMFLAGS) -cm_name reset_during_local_test -cm_dir $(CMDIR) +UVM_TESTNAME=reset_during_local_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_during_local.log
	$(SIMV) $(CMFLAGS) -cm_name reset_during_remote_test -cm_dir $(CMDIR) +UVM_TESTNAME=reset_during_remote_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_during_remote.log
	$(SIMV) $(CMFLAGS) -cm_name normal_after_reset_test -cm_dir $(CMDIR) +UVM_TESTNAME=normal_after_reset_test +UVM_VERBOSITY=UVM_LOW -l sim_normal_after_reset.log
	$(SIMV) $(CMFLAGS) -cm_name local_multi_test        -cm_dir $(CMDIR) +UVM_TESTNAME=local_multi_test        +UVM_VERBOSITY=UVM_LOW -l sim_local_multi.log
	$(SIMV) $(CMFLAGS) -cm_name transfer_rule_test      -cm_dir $(CMDIR) +UVM_TESTNAME=transfer_rule_test      +UVM_VERBOSITY=UVM_LOW -l sim_transfer_rule.log
	$(SIMV) $(CMFLAGS) -cm_name stability_rule_test     -cm_dir $(CMDIR) +UVM_TESTNAME=stability_rule_test     +UVM_VERBOSITY=UVM_LOW -l sim_stability_rule.log
	$(SIMV) $(CMFLAGS) -cm_name local_backpressure_test -cm_dir $(CMDIR) +UVM_TESTNAME=local_backpressure_test +UVM_VERBOSITY=UVM_LOW -l sim_local_backpressure.log
	$(SIMV) $(CMFLAGS) -cm_name remote_backpressure_test -cm_dir $(CMDIR) +UVM_TESTNAME=remote_backpressure_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_backpressure.log
	$(SIMV) $(CMFLAGS) -cm_name backpressure_last_byte_test -cm_dir $(CMDIR) +UVM_TESTNAME=backpressure_last_byte_test +UVM_VERBOSITY=UVM_LOW -l sim_backpressure_last_byte.log
	$(SIMV) $(CMFLAGS) -cm_name cfg_change_ignored_test -cm_dir $(CMDIR) +UVM_TESTNAME=cfg_change_ignored_test +UVM_VERBOSITY=UVM_LOW -l sim_cfg_change_ignored.log
	$(SIMV) $(CMFLAGS) -cm_name payload_len_boundary_test -cm_dir $(CMDIR) +UVM_TESTNAME=payload_len_boundary_test +UVM_VERBOSITY=UVM_LOW -l sim_payload_len_boundary.log
	$(SIMV) $(CMFLAGS) -cm_name fragments_same_seq_test -cm_dir $(CMDIR) +UVM_TESTNAME=fragments_same_seq_test +UVM_VERBOSITY=UVM_LOW -l sim_fragments_same_seq.log
	$(SIMV) $(CMFLAGS) -cm_name mismatched_seq_test     -cm_dir $(CMDIR) +UVM_TESTNAME=mismatched_seq_test     +UVM_VERBOSITY=UVM_LOW -l sim_mismatched_seq.log
	$(SIMV) $(CMFLAGS) -cm_name frag1_while_incomplete_test -cm_dir $(CMDIR) +UVM_TESTNAME=frag1_while_incomplete_test +UVM_VERBOSITY=UVM_LOW -l sim_frag1_while_incomplete.log
	$(SIMV) $(CMFLAGS) -cm_name missing_fragment_test   -cm_dir $(CMDIR) +UVM_TESTNAME=missing_fragment_test   +UVM_VERBOSITY=UVM_LOW -l sim_missing_fragment.log
	$(SIMV) $(CMFLAGS) -cm_name two_frags_ooo_test      -cm_dir $(CMDIR) +UVM_TESTNAME=two_frags_ooo_test      +UVM_VERBOSITY=UVM_LOW -l sim_two_frags_ooo.log
	$(SIMV) $(CMFLAGS) -cm_name three_frags_ooo_test    -cm_dir $(CMDIR) +UVM_TESTNAME=three_frags_ooo_test    +UVM_VERBOSITY=UVM_LOW -l sim_three_frags_ooo.log
	$(SIMV) $(CMFLAGS) -cm_name five_frags_random_test  -cm_dir $(CMDIR) +UVM_TESTNAME=five_frags_random_test  +UVM_VERBOSITY=UVM_LOW -l sim_five_frags_random.log
	$(SIMV) $(CMFLAGS) -cm_name diff_payload_len_test   -cm_dir $(CMDIR) +UVM_TESTNAME=diff_payload_len_test   +UVM_VERBOSITY=UVM_LOW -l sim_diff_payload_len.log
	$(SIMV) $(CMFLAGS) -cm_name max_frags_test          -cm_dir $(CMDIR) +UVM_TESTNAME=max_frags_test          +UVM_VERBOSITY=UVM_LOW -l sim_max_frags_reord.log
	$(SIMV) $(CMFLAGS) -cm_name interleaved_mix_test    -cm_dir $(CMDIR) +UVM_TESTNAME=interleaved_mix_test    +UVM_VERBOSITY=UVM_LOW -l sim_interleaved_mix.log
	$(SIMV) $(CMFLAGS) -cm_name mixed_random_test       -cm_dir $(CMDIR) +UVM_TESTNAME=mixed_random_test       +UVM_VERBOSITY=UVM_LOW -l sim_mixed_random.log
	$(SIMV) $(CMFLAGS) -cm_name remote_back_to_back_test -cm_dir $(CMDIR) +UVM_TESTNAME=remote_back_to_back_test +UVM_VERBOSITY=UVM_LOW -l sim_remote_back_to_back.log
	$(SIMV) $(CMFLAGS) -cm_name one_remote_packet_at_a_time_test -cm_dir $(CMDIR) +UVM_TESTNAME=one_remote_packet_at_a_time_test +UVM_VERBOSITY=UVM_LOW -l sim_one_remote_packet_at_a_time.log
	$(SIMV) $(CMFLAGS) -cm_name multi_frag_drop_once_test -cm_dir $(CMDIR) +UVM_TESTNAME=multi_frag_drop_once_test +UVM_VERBOSITY=UVM_LOW -l sim_multi_frag_drop.log
	$(SIMV) $(CMFLAGS) -cm_name reset_clears_drop_cnt_test -cm_dir $(CMDIR) +UVM_TESTNAME=reset_clears_drop_cnt_test +UVM_VERBOSITY=UVM_LOW -l sim_reset_clears_drop_cnt.log

# Generate code coverage (line/cond/branch/toggle/fsm) and functional
# coverage (covergroup "group" metric) reports from the merged $(CMDIR)
coverage_report:
	rm -rf report/code_coverage report/func_coverage
	mkdir -p report/code_coverage report/func_coverage
	$(URG) -dir $(CMDIR) -metric line+cond+branch+tgl+fsm -report report/code_coverage
	$(URG) -dir $(CMDIR) -metric group                    -report report/func_coverage

clean:
	rm -rf simv simv.daidir csrc *.log ucli.key *.vcd DVEfiles $(CMDIR) urgReport
