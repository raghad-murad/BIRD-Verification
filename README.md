# BIRD — Birzeit Integrated Router Design Verification

Verification environment for **BIRD (Birzeit Integrated Router Design)** developed as part of the **ENCS5337 – Chip Design Verification** course at Birzeit University.

---

## Table of Contents

- [BIRD — Birzeit Integrated Router Design Verification](#bird--birzeit-integrated-router-design-verification)
  - [Table of Contents](#table-of-contents)
  - [Project Overview](#project-overview)
  - [Team Members](#team-members)
  - [Project Structure](#project-structure)
  - [Verification Environment](#verification-environment)
  - [How to Run](#how-to-run)
  - [Conclusion](#conclusion)
  - [Course Information](#course-information)

---

## Project Overview

BIRD is a packet-based routing block that routes incoming traffic to either a **local** or **remote** interface based on a 32-bit configuration signal. Local packets are forwarded directly; remote fragments are accumulated, reordered, merged, and re-emitted with a new CRC16.

This project builds a complete UVM-based verification environment validating all functional requirements: packet routing, fragment reassembly, CRC handling, drop conditions, protocol compliance, and coverage collection.

---

## Team Members

| Name | Student ID | Section |
|------|-----------|---------|
| Ahlam Hilmy Mustafa Abuqare | 1191612 | 1 |
| Raghad Murad Mahfouth Bouzia | 1212214 | 2 |
| Qossay Mohammed Ahmed Abusondos | 1221082 | 1 |
| Anwar Ghassan Ibraheem Atawna | 1222275 | 2 |

---

## Project Structure

```
BIRD_1212214/
├── README.md
├── test_plan.xlsx
├── run_commands.md
├── Makefile
├── report/
│   ├── code_coverage/
│   └── func_coverage/
├── design/
│   └── bird.sv                  # BIRD DUT (behavioral model)
└── verif/
    ├── cfg/
    │   └── bird_pkg.sv          # Central package
    ├── if/
    │   └── bird_if.sv           # Interface + clocking blocks
    ├── env/
    │   ├── bird_agent.sv        # Agent (driver + monitor)
    │   ├── bird_driver.sv       # Drives input interface
    │   ├── bird_monitor.sv      # Observes input/output interfaces
    │   ├── bird_checker.sv      # Protocol + stability checker
    │   ├── bird_coverage.sv     # Functional covergroups
    │   ├── bird_scoreboard.sv   # Reference model + output checker
    │   └── bird_env.sv          # Top-level environment
    ├── seq/
    │   ├── bird_transaction.sv  # Fragment sequence item
    │   ├── bird_base_seq.sv     # Base sequence class
    │   ├── local_seq.sv         # Local traffic sequences
    │   ├── remote_seq.sv        # Remote traffic sequences
    │   ├── drop_seq.sv          # Drop condition sequences
    │   ├── reset_seq.sv         # Reset interrupt sequences
    │   ├── handshake_seq.sv     # Backpressure sequences
    │   └── coverage_seq.sv      # Coverage closure sequences
    ├── tb/
    │   └── tb_top.sv            # Clock/reset, DUT instantiation
    └── tests/
        ├── bird_base_test.sv    # Base test class
        ├── reset_test.sv        # TP_RST_01–04
        ├── local_test.sv        # TP_CLS_01, TP_CFG_01, TP_CRC_01
        ├── remote_test.sv       # TP_CLS_02, TP_CRC_02–04, TP_MIX_03
        ├── handshake_test.sv    # TP_HS_01–05
        ├── sampling_test.sv     # TP_SMPL_01–02
        ├── drop_test.sv         # TP_CFG_03–10, TP_CNT_01–06
        ├── seq_frag_test.sv     # TP_SEQ_01–04
        ├── reorder_test.sv      # TP_REORD_01–05
        └── rand_test.sv         # TP_MIX_01–02, TP_COV_01–02
```

---

## Verification Environment

Built using SystemVerilog + UVM-1.2:

| Component | Role |
|-----------|------|
| `bird_if` | Interface with clocking blocks and modports |
| `bird_driver` | Drives fragments byte-by-byte onto the DUT |
| `bird_monitor` | Observes input and output interfaces |
| `bird_scoreboard` | Reference model; compares expected vs actual output |
| `bird_checker` | Cycle-accurate protocol and stability checks |
| `bird_coverage` | 7 functional covergroups + cross coverage |
| `bird_agent` | Bundles driver, sequencer, and input monitor |
| `bird_env` | Connects all components together |

---

## How to Run

Full target list and per-test commands are in [run_commands.md](run_commands.md).

```bash
make compile          # compile without coverage
make sim_all          # run full regression
make compile_cov      # compile with coverage instrumentation
make sim_all_cov      # run full regression with coverage collection
make coverage_report  # generate HTML reports under report/
```

---

## Conclusion

A complete UVM verification environment was built for the BIRD DUT and exercised with a 35-test regression covering all features in the specification.

| Metric | Result |
|--------|--------|
| Tests passed | 32 |
| Tests failed | 17 |
| Functional coverage | **100%** across all 7 covergroups |
| Code coverage | **87.32%** (FSM: 100%) |

All 14 failures trace to 3 confirmed DUT defects: a `SEQ_NUM`/`FRAG_NUM` field reversal in remote reassembly (BUG-01), a blocking/non-blocking assignment mix causing output stability violations (BUG-02), and a non-synchronous reset clear for `drop_cnt` (BUG-03). The verification environment itself is correct and operating as intended.

---

## Course Information

| | |
|---|---|
| **Course** | ENCS5337 – Chip Design Verification |
| **University** | Birzeit University |
| **Department** | Electrical and Computer Engineering |
| **Instructor** | Elias Khalil |
