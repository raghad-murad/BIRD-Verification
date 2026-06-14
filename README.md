# BIRD - Birzeit Integrated Router Design Verification

Verification environment for **BIRD (Birzeit Integrated Router Design)** developed as part of the **ENCS5337 – Chip Design Verification** course at Birzeit University.

---

## Table of Contents

* [Project Overview](#project-overview)
* [Verification Environment](#verification-environment)
* [Project Structure](#project-structure)
* [Team Members](#team-members)
* [Project Status](#project-status)
* [Course Information](#course-information)

---

## Project Overview

BIRD (Birzeit Integrated Router Design) is a packet-based routing block that routes incoming traffic to either a local or remote interface based on a configuration signal.

This project focuses on building a complete SystemVerilog verification environment capable of validating all functional requirements defined in the project specification, including packet routing, fragment reassembly, CRC handling, packet dropping conditions, protocol compliance, and coverage collection.

---

## Verification Environment

The verification environment is implemented using SystemVerilog and includes:

* Interface
* Driver
* Monitor
* Agent
* Environment
* Scoreboard / Checker
* Sequences
* Testbench Top
* Functional Coverage

---

## Project Structure

* design/bird.sv → BIRD router design (DUT)
* verif/cfg/bird_pkg.sv → Project package and shared definitions
* verif/if/bird_if.sv → Interface definition

* verif/env/
    * bird_agent.sv → Agent component
    * bird_driver.sv → Driver component
    * bird_monitor.sv → Monitor component
    * bird_checker.sv → Checker component
    * bird_coverage.sv → Functional coverage
    * bird_env.sv → Verification environment

* verif/seq/
    * bird_transaction.sv → Transaction class
    * bird_base_seq.sv → Base sequence
    * local_seq.sv → Local routing sequence
    * remote_seq.sv → Remote routing sequence

* verif/tests/
    * bird_base_test.sv → Base test
    * local_test.sv → Local routing test
    * remote_test.sv → Remote routing test
    * drop_test.sv → Packet drop test
    * rand_test.sv → Randomized test

* verif/tb/tb_top.sv → Top-level testbench
---

## Team Members

| Name | Student ID | Student Section |
| --------- | ---------- | ---------- |
| Raghad Murad Mahfouth Bouzia | 1212214 | 2 |
| Ahlam Hilmy Mustafa Abuqare | 1191612 | 1 |
| Qossay Mohammed Ahmed Abusondos |1221082 | 1 |
| Anwar Ghassan Ibraheem Atawna |1222275 | 2 |

---

## Project Status

* Repository created
* Project specification reviewed
* Verification test plan completed
* Verification project structure created
* Initial verification files added
* We are still working on the code implementation
* Code development in progress

---

## Course Information

**Course:** ENCS5337 – Chip Design Verification  
**University:** Birzeit University
