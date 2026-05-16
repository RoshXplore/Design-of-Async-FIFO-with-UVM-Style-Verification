# Async FIFO with SystemVerilog Verification Environment

A parameterized **Asynchronous FIFO** written in Verilog with a complete **class-based SystemVerilog verification environment**.

The design safely transfers data across independent read/write clock domains and is verified using randomized, stress, and corner-case test scenarios.



---

# Design Overview

The core design is a parameterized asynchronous FIFO.

## Default Configuration

| Parameter  | Value  |
| ---------- | ------ |
| FIFO Depth | 64     |
| Data Width | 32-bit |

## Key Design Techniques

### Gray Code Pointers

Binary read/write pointers are converted into Gray code before crossing clock domains.

Since only one bit changes at a time, Gray coding helps avoid invalid intermediate states during CDC synchronization.

### 2-Stage Synchronizers

Gray-coded pointers pass through double flip-flop synchronizers in the destination clock domain to reduce metastability risk.

### Full & Empty Flag Logic

* `empty` is generated in the read clock domain
* `full` is generated in the write clock domain
* Full detection includes wrap-around condition checking

---

# Verification Environment

The verification environment is built completely from scratch using a lightweight UVM-style architecture.

## Verification Components

### Transactions

Randomized transactions include:

* Read operations
* Write operations
* Burst transfers
* Data payload generation

### Drivers & Monitors

Separate driver and monitor components exist for both clock domains.

#### Drivers

* Generate DUT stimulus
* Drive interface-level signals

#### Monitors

* Observe DUT activity passively
* Capture transactions
* Forward data to:

  * Reference model
  * Scoreboard

### Reference Model

A queue-based shadow FIFO acts as the golden reference model.

It:

* Pushes incoming write data
* Pops expected read data
* Predicts expected DUT behavior

### Scoreboard

The scoreboard compares:

* Expected data from the reference model
* Actual DUT read data

Any mismatch is flagged immediately.

### Assertions (SVA)

Concurrent assertions are embedded directly inside the interface to detect protocol violations such as:

* Writes when FIFO is full
* Reads when FIFO is empty

This provides cycle-accurate protocol verification alongside functional checking.

### Functional Coverage

Coverage tracks:

* `full` and `empty` behavior
* Read/write enable activity
* Burst traffic
* Cross-coverage scenarios

This ensures:

* Boundary conditions are exercised
* Back-to-back bursts are verified
* Concurrent traffic scenarios are covered

---

# Test Scenarios

## Sanity Test

Basic read/write validation to verify:

* FIFO functionality
* Data integrity
* Correct ordering

## Stress Test

* Completely fills the FIFO
* Completely drains the FIFO
* Verifies proper `full` and `empty` transitions

## Concurrent Traffic Test

Randomized simultaneous:

* Read bursts
* Write bursts

Used to validate CDC robustness under heavy traffic.

## Starvation / Slow Write Test

* Delayed writes with continuous reads
* Verifies:

  * Empty flag stability
  * Underflow handling

## Burst Into Full-Wall Test

Targets FIFO boundary conditions by intentionally driving bursts into the full condition.

Checks:

* Correct `full` assertion
* No data corruption
* No dropped transactions
* Assertion correctness under saturation

---

# Simulation Results

Simulated using:

* EDA Playground
* QuestaSim / ModelSim compatible flow

## Final Results

| Metric                | Result                |
| --------------------- | --------------------- |
| Transactions Checked  | **820 PASS / 0 FAIL** |
| Write Domain Coverage | **100%**              |
| Read Domain Coverage  | **100%**              |
| Assertion Violations  | **0**                 |

---

# Running the Project

## 1. Clone the Repository

```bash
git clone https://github.com/RoshXplore/Design-of-Async-FIFO-with-UVM-Style-Verification
cd Design-of-Async-FIFO-with-UVM-Style-Verification
```

## 2. Compile

```bash
vlog -sv async_fifo.sv tb_top.sv
```

## 3. Run Simulation

```bash
vsim tb_top
run -all
```

The testbench is fully self-checking and automatically reports:

* Pass/fail summary
* Assertion status
* Coverage statistics
* Final scoreboard report

---

# Supported Simulators

* QuestaSim
* ModelSim
* Riviera-PRO
* EDA Playground

---

# Features

* Parameterized asynchronous FIFO
* Independent read/write clock domains
* Gray-code CDC synchronization
* 2-stage synchronizers
* Class-based SV verification environment
* Concurrent SVA protocol checks
* Reference model + scoreboard
* Functional coverage-driven verification
* Directed-random stress testing
* Concurrent burst verification
* 100% functional coverage

---

# Future Improvements

Possible future extensions:

* UVM migration
* Formal verification
* Almost-full / almost-empty flags
* AXI-Stream wrapper
* Randomized clock ratio testing
* Error injection testing
* CDC static analysis integration
