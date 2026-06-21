# BIRD Verification — Run Commands

## Compile

```bash
make compile        # standard compile without coverage
make compile_cov    # compile with coverage (required before sim_all_cov)
```

## Reset Tests

```bash
make sim_power_on_reset        # TP_RST_01 — power-on reset
make sim_reset_during_local    # TP_RST_02 — reset during local packet
make sim_reset_during_remote   # TP_RST_03 — reset during remote reassembly
make sim_normal_after_reset    # TP_RST_04 — normal operation after reset
make sim_reset_clears_drop_cnt # TP_CNT_06 — reset clears drop_cnt
```

## Local Traffic Tests

```bash
make sim_local        # TP_CLS_01, TP_CFG_01, TP_CRC_01 — local basic
make sim_local_multi  # TP_CNT_03 — multiple local packets
```

## Remote Traffic Tests

```bash
make sim_remote              # TP_CLS_02, TP_CFG_02 — remote basic
make sim_remote_ooo          # remote out-of-order (legacy)
make sim_remote_back_to_back # TP_MIX_03 — back-to-back remote packets
```

## Handshake Tests

```bash
make sim_transfer_rule          # TP_HS_01 — transfer rule
make sim_stability_rule         # TP_HS_02 — stability rule (input side)
make sim_local_backpressure     # TP_HS_03 — local output backpressure
make sim_remote_backpressure    # TP_HS_04 — remote output backpressure
make sim_backpressure_last_byte # TP_HS_05 — backpressure on last byte
make sim_backpressure           # legacy backpressure test
```

## CFG Sampling & Validation Tests

```bash
make sim_cfg_change_ignored   # TP_SMPL_02 — cfg change ignored after byte 0
make sim_payload_len_boundary # TP_CFG_10 — PAYLOAD_LEN boundary (0 vs 255)
```

## Drop Conditions Tests

```bash
make sim_drop               # TP_CFG_03..09, TP_CNT_01,02 — drop conditions
make sim_drop_while_active  # drop while remote packet is active
make sim_multi_frag_drop    # TP_CNT_04 — multi-fragment counted as one drop
make sim_drop_cnt_wrap      # TP_CNT_05 — drop_cnt wrap-around (65536 drops)
                            # WARNING: excluded from sim_all — takes long time
```

## SEQ/FRAG Handling Tests

```bash
make sim_fragments_same_seq          # TP_SEQ_01 — same SEQ_NUM assembled together
make sim_mismatched_seq              # TP_SEQ_02 — mismatched SEQ_NUM causes drop
make sim_frag1_while_incomplete      # TP_SEQ_03 — FRAG=1 arrives while packet incomplete
make sim_missing_fragment            # TP_SEQ_04 — missing fragment causes drop
make sim_one_remote_packet_at_a_time # TP_REM_01 — only one remote packet at a time
```

## Reordering Tests

```bash
make sim_two_frags_ooo      # TP_REORD_01 — 2 fragments out of order
make sim_three_frags_ooo    # TP_REORD_02 — 3 fragments out of order
make sim_five_frags_random  # TP_REORD_03 — 5 fragments random arrival order
make sim_diff_payload_len   # TP_REORD_04 — different PAYLOAD_LEN per fragment
make sim_max_frags_reord    # TP_REORD_05 — max 31 fragments
```

## Mixed & Random Tests

```bash
make sim_interleaved      # TP_CLS_03 — interleaved local and remote packets
make sim_interleaved_mix  # TP_MIX_01 — interleaved mix with explicit checks
make sim_mixed_random     # TP_MIX_02 — random valid/invalid mix
make sim_rand             # constrained random test
make sim_coverage         # coverage-focused test
```

## Run All + Coverage

```bash
make sim_all          # run all tests in sequence without coverage
make sim_all_cov      # run all tests with coverage collection
                      # NOTE: runs compile_cov automatically
make coverage_report  # generate reports after sim_all_cov
                      # output: report/code_coverage/
                      #         report/func_coverage/
```

## Cleanup

```bash
make clean  # remove simv, logs, coverage DB, and temp files
```

## Full Regression Order

```bash
make compile          # 1. compile without coverage
make sim_all          # 2. run all tests
make compile_cov      # 3. compile with coverage
make sim_all_cov      # 4. run all tests with coverage
make coverage_report  # 5. generate coverage reports
```