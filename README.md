# Asynchronous FIFO with SystemVerilog Verification Environment

This repository contains the RTL design of an Asynchronous FIFO written in Verilog, along with a complete class-based SystemVerilog verification environment.

The project handles safe data transfer across two independent clock domains (read and write) and verifies the design against various stress and corner-case scenarios.

---

## Design Overview

The core design is a parameterized Asynchronous FIFO.

### Default Configuration

* **FIFO Depth:** 64
* **Data Width:** 32 bits

### Key Design Techniques

To safely manage data transfer between independent clock domains, the FIFO implements:

* **Gray Code Pointers**

  * Binary read and write pointers are converted to Gray code before crossing clock domains.
  * Since only one bit changes at a time in Gray code, this minimizes the possibility of invalid intermediate states during synchronization.

* **2-Stage Synchronizers**

  * Gray-coded pointers are passed through double flip-flop synchronizers in the destination clock domain.
  * This reduces metastability risks during clock-domain crossing (CDC).

* **Flag Logic**

  * `empty` flag is generated in the **read clock domain** by comparing:

    * local read pointer
    * synchronized write pointer
  * `full` flag is generated in the **write clock domain** by comparing:

    * local write pointer
    * synchronized read pointer
  * Full detection includes wrap-around checking logic.

---

## Verification Environment

The testbench is built entirely from scratch using a custom class-based SystemVerilog environment.

### Verification Architecture

#### Transactions

Defines randomized read/write operations, including:

* Data payloads
* Burst lengths
* Read/write control patterns

#### Drivers & Monitors

Separate components exist for both read and write domains.

* **Drivers**

  * Generate pin-level activity
  * Drive DUT interface signals

* **Monitors**

  * Passively observe DUT behavior
  * Capture transactions
  * Forward observed activity to:

    * Scoreboard
    * Reference model

#### Reference Model

A shadow FIFO implemented using a SystemVerilog queue predicts expected DUT behavior.

* Pushes incoming write data
* Pops expected read data
* Acts as the golden model for comparison

#### Scoreboard

Compares:

* Expected data from reference model
* Actual DUT output data

Any mismatch is immediately flagged.

#### Functional Coverage

Covergroups track:

* `full` flag behavior
* `empty` flag behavior
* Read/write enable toggles
* Burst operation scenarios
* Cross-coverage between flags and traffic conditions

This ensures:

* Back-to-back bursts are exercised
* Boundary conditions are verified
* Concurrent traffic scenarios are covered

---

## Test Scenarios

The environment includes multiple directed-random test sequences.

### Sanity Test

Basic write and read operations to verify:

* FIFO functionality
* Data integrity
* Correct ordering

### Stress Test

* Completely fills the FIFO
* Completely drains the FIFO
* Verifies full/empty transitions

### Concurrent Traffic Test

Simultaneous randomized:

* Read bursts
* Write bursts

Used to validate CDC robustness under heavy activity.

### Starvation / Slow Write Test

* Delayed writes with continuous reads
* Verifies:

  * Empty flag stability
  * Proper underflow handling

### Burst into Full Wall Test

Forces exact multi-beat bursts into the FIFO boundary to:

* Hit the 64-depth limit intentionally
* Verify:

  * Proper `full` assertion
  * No data corruption
  * No dropped transactions

---

## Simulation and Results

The design was simulated using:

* **EDA Playground**
* **ModelSim / QuestaSim**
* **EPWave**

All verification scenarios completed successfully with zero mismatches.

### Final Results

| Metric                | Result                |
| --------------------- | --------------------- |
| Transactions Checked  | **442 PASS / 0 FAIL** |
| Write Domain Coverage | **100.0%**            |
| Read Domain Coverage  | **100.0%**            |

---

## Waveforms and Logs

### Figure 1

EPWave waveform showing:

* Independent read/write clocks
* Data transfers
* Concurrent traffic behavior
* `full` and `empty` flag transitions

### Figure 2

Console output showing:

* Clean scoreboard pass summary
* Functional coverage report
* Final verification statistics

---

## How to Run

### 1. Clone the Repository

```bash
git clone [<repository_url>](https://github.com/RoshXplore/Design-of-Async-FIFO-with-UVM-Style-Verification)
cd Design-of-Async-FIFO-with-UVM-Style-Verification
```

### 2. Compile the Design

Load the following files into your simulator:

```text
async_fifo.sv
tb_top.sv
```

Supported simulators:

* QuestaSim
* ModelSim
* EDA Playground

### 3. Enable SystemVerilog Support

Ensure the simulator is configured with SystemVerilog enabled.

Example:

```bash
vlog -sv async_fifo.sv tb_top.sv
```

### 4. Run the Simulation

```bash
vsim tb_top
run -all
```

The testbench is fully self-checking and automatically prints:

* Pass/fail summary
* Scoreboard statistics
* Functional coverage report

at the end of simulation.

---

## Features Summary

* Parameterized asynchronous FIFO
* Independent read/write clock domains
* Gray-code pointer synchronization
* Full custom SystemVerilog verification environment
* Reference model + scoreboard architecture
* Functional coverage driven verification
* Directed-random stress testing
* Concurrent burst traffic verification
* 100% functional coverage achieved

---

## Future Improvements

Potential future extensions:

* SystemVerilog Assertions (SVA)
* Formal verification
* UVM-based environment migration
* Configurable almost-full / almost-empty flags
* AXI-stream wrapper integration
* Randomized clock frequency variation testing
