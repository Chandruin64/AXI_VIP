# AXI3 Verification IP using SystemVerilog and UVM

## Overview

This project implements a reusable **AXI3 Verification IP (VIP)** using **SystemVerilog and UVM**. The verification environment is designed to verify AXI3 protocol transactions across all five independent AXI channels and supports configurable burst transfers, constrained-random stimulus, protocol assertions, functional coverage, and self-checking through a UVM scoreboard.

The VIP consists of configurable **Master and Slave UVM agents**, a **virtual sequencer**, **virtual sequences**, protocol-aware monitors, drivers, a scoreboard based on **TLM Analysis FIFOs**, and functional coverage models.

The environment currently supports the following AXI3 burst types:

* FIXED Burst
* INCR Burst
* WRAP Burst

---

## Features

* Reusable UVM-based AXI3 Verification IP
* Configurable Master and Slave agents
* Active and passive agent support through UVM configuration objects
* Support for all five AXI3 channels:

  * Write Address (AW)
  * Write Data (W)
  * Write Response (B)
  * Read Address (AR)
  * Read Data (R)
* Support for FIXED, INCR, and WRAP burst transfers
* Constrained-random transaction generation
* Virtual sequencer and virtual sequences for coordinated test execution
* Channel dependency synchronization using semaphores
* Transaction collection using protocol-aware monitors
* TLM Analysis FIFO-based scoreboard
* Self-checking transaction comparison
* Functional coverage for burst configurations and data/strobe combinations
* SystemVerilog Assertions (SVA) for AXI protocol checks
* Functional, assertion, and code coverage support
* Waveform generation using Questa WLF and VCS/Verdi FSDB
* Support for both Siemens Questa and Synopsys VCS
* Reproducible simulations using fixed random seeds

---

## AXI3 Channels

The verification environment supports the complete AXI3 channel architecture.

### Write Address Channel

| Signal  | Description          |
| ------- | -------------------- |
| AWID    | Write transaction ID |
| AWADDR  | Write address        |
| AWLEN   | Burst length         |
| AWSIZE  | Burst size           |
| AWBURST | Burst type           |
| AWVALID | Write address valid  |
| AWREADY | Write address ready  |

### Write Data Channel

| Signal | Description                     |
| ------ | ------------------------------- |
| WID    | Write data ID                   |
| WDATA  | Write data                      |
| WSTRB  | Write data byte strobes         |
| WLAST  | Indicates final write data beat |
| WVALID | Write data valid                |
| WREADY | Write data ready                |

### Write Response Channel

| Signal | Description             |
| ------ | ----------------------- |
| BID    | Response transaction ID |
| BRESP  | Write response          |
| BVALID | Write response valid    |
| BREADY | Write response ready    |

### Read Address Channel

| Signal  | Description         |
| ------- | ------------------- |
| ARID    | Read transaction ID |
| ARADDR  | Read address        |
| ARLEN   | Burst length        |
| ARSIZE  | Burst size          |
| ARBURST | Burst type          |
| ARVALID | Read address valid  |
| ARREADY | Read address ready  |

### Read Data Channel

| Signal | Description                    |
| ------ | ------------------------------ |
| RID    | Read transaction ID            |
| RDATA  | Read data                      |
| RRESP  | Read response                  |
| RLAST  | Indicates final read data beat |
| RVALID | Read data valid                |
| RREADY | Read data ready                |

---

## UVM Testbench Architecture

```text
                              +----------------------+
                              |      UVM TEST        |
                              +----------+-----------+
                                         |
                                         v
                              +----------------------+
                              |     ENVIRONMENT      |
                              |                      |
                              |  +----------------+  |
                              |  | Virtual        |  |
                              |  | Sequencer      |  |
                              |  +----------------+  |
                              +----------+-----------+
                                         |
                    +--------------------+--------------------+
                    |                    |                    |
                    v                    v                    v
           +----------------+    +----------------+    +----------------+
           | Master Agent   |    | Slave Agent    |    | Scoreboard     |
           |                |    |                |    |                |
           | Sequencer      |    | Driver         |    | Master FIFO    |
           | Driver         |    | Monitor        |    | Slave FIFO     |
           | Monitor        |    |                |    | Compare        |
           +-------+--------+    +-------+--------+    +----------------+
                   |                     |
                   |                     |
                   +----------+----------+
                              |
                              v
                    +----------------------+
                    |      AXI3 Interface  |
                    |                      |
                    | AW | W | B | AR | R  |
                    +----------------------+
```

The **Master agent** generates AXI3 stimulus using its sequencer and driver.

The **Slave agent** does not contain a sequencer or sequences. Its driver provides the required slave-side responses, while its monitor observes and collects slave-side AXI3 transactions.

The **virtual sequencer** therefore contains only the Master sequencer handle.

---

## Project Structure

```text
AXI3_UVM_VIP/
│
├── rtl/
│   └── axi_if.sv
│
├── test/
│   ├── test.sv
│   └── pkg.sv
│
├── tb/
│   ├── env.sv
│   ├── axi_xtn.sv
│   ├── env_config.sv
│   ├── scoreboard.sv
│   ├── virtual_sequencer.sv
│   └── virtual_seqs.sv
│
├── master/
│   ├── mst_config.sv
│   ├── mst_seqs.sv
│   ├── mst_sequencer.sv
│   ├── mst_driver.sv
│   ├── mst_monitor.sv
│   ├── mst_agent.sv
│   └── mst_agt_top.sv
│
├── slave/
│   ├── slv_config.sv
│   ├── slv_driver.sv
│   ├── slv_monitor.sv
│   ├── slv_agent.sv
│   └── slv_agt_top.sv
│
├── sim/
│   └── Makefile
│
└── README.md
```

---

## UVM Components

### Master Agent

The Master agent is responsible for generating and driving AXI3 transactions. It consists of:

* Master sequencer
* Master driver
* Master monitor
* Master configuration object

The Master sequences generate transactions for different burst types and drive them through the AXI interface.

---

### Slave Agent

The Slave agent consists of:

* Slave driver
* Slave monitor
* Slave configuration object

The Slave agent does **not** contain a sequencer or sequence classes.

The Slave driver is responsible for providing the required AXI3 slave-side responses based on the transactions received from the Master side.

The Slave monitor independently observes AXI channel activity and uses synchronization mechanisms to associate dependent channels.

The following dependencies are handled:

```text
Write Address → Write Data → Write Response

Read Address → Read Data
```

Semaphores and transaction queues are used to synchronize address, data, and response collection.

---

## Virtual Sequencer

The virtual sequencer provides a centralized control point for coordinating the Master-side stimulus.

Since the Slave agent does not contain a sequencer, the virtual sequencer maintains only the Master sequencer handle.

```systemverilog
mst_sequencer mst_seqr;
```

Virtual sequences obtain the Master sequencer handle from the virtual sequencer and start the required Master sequences.

---

## Supported Testcases

### 1. Fixed Burst Test

Test name:

```text
fixed_test
```

Virtual sequence:

```text
fixed_vseq
```

Master sequence:

```text
mst_fixed_seq
```

Verifies AXI FIXED burst transfers where the address remains unchanged for each transfer in the burst.

---

### 2. Incrementing Burst Test

Test name:

```text
incr_test
```

Virtual sequence:

```text
incr_vseq
```

Master sequence:

```text
mst_incr_seq
```

Verifies AXI INCR burst transfers where the address increments according to the transfer size.

---

### 3. Wrapping Burst Test

Test name:

```text
wrap_test
```

Virtual sequence:

```text
wrap_vseq
```

Master sequence:

```text
mst_wrap_seq
```

Verifies AXI WRAP burst transfers where the address wraps around a defined address boundary.

---

## Scoreboard

The scoreboard receives monitored transactions from both the Master and Slave agents through UVM TLM Analysis FIFOs.

```systemverilog
uvm_tlm_analysis_fifo #(axi_xtn) mst_fifo;
uvm_tlm_analysis_fifo #(axi_xtn) slv_fifo;
```

The transaction flow is:

```text
Master Monitor ───► Master Analysis FIFO ──┐
                                           ├──► Scoreboard Comparison
Slave Monitor ────► Slave Analysis FIFO ───┘
```

The scoreboard:

1. Receives transactions from both agents.
2. Compares Master and Slave transactions.
3. Reports successful matches and mismatches.
4. Samples functional coverage for valid transactions.
5. Reports packet statistics at the end of simulation.

The scoreboard is connected to the **Master and Slave monitors through the environment**, maintaining the standard UVM environment-level connectivity.

---

## Functional Coverage

The functional coverage model includes coverage for important AXI burst configurations.

### Write Coverage

Coverage is collected for:

* Write address
* Write burst type
* Write burst length
* Write transfer size
* Write response
* Write data
* Write strobes

A cross coverage model is used for:

```text
AWBURST × AWSIZE × AWLEN
```

### Read Coverage

Coverage is collected for:

* Read address
* Read burst type
* Read burst length
* Read transfer size
* Read data
* Read response

A cross coverage model is used for:

```text
ARBURST × ARSIZE × ARLEN
```

---

## Protocol Assertions

SystemVerilog Assertions are implemented in the AXI interface to verify important protocol rules.

The assertions check:

* Write address control signals remain stable while `AWVALID` is asserted and `AWREADY` is low.
* Write data signals remain stable while `WVALID` is asserted and `WREADY` is low.
* Read address control signals remain stable while `ARVALID` is asserted and `ARREADY` is low.
* Write response signals remain stable until the `BREADY` handshake.
* Read data and response signals remain stable until the `RREADY` handshake.
* `AWVALID` remains asserted until the address handshake completes.
* `WVALID` remains asserted until the data handshake completes.
* `ARVALID` remains asserted until the read address handshake completes.
* `BVALID` remains asserted until the write response handshake completes.
* `RVALID` remains asserted until the read data handshake completes.
* WRAP burst addresses satisfy alignment requirements.
* Burst transfer sizes remain within the supported range.

---

## Simulation

The project supports both **Siemens Questa** and **Synopsys VCS**.

The simulator can be selected in the Makefile:

```makefile
SIMULATOR = Questa
```

or:

```makefile
SIMULATOR = VCS
```

---

## Makefile Commands

### Compile

```bash
make sv_cmp
```

### Run FIXED Burst Test

```bash
make run_test
```

### Run INCR Burst Test

```bash
make run_test1
```

### Run WRAP Burst Test

```bash
make run_test2
```

### Run All Testcases

```bash
make regress
```

### Generate Merged Coverage Report

```bash
make report
```

### Open Coverage Report

```bash
make cov
```

### View Waveforms

For FIXED burst:

```bash
make view_wave1
```

For INCR burst:

```bash
make view_wave2
```

For WRAP burst:

```bash
make view_wave3
```

### Clean Generated Files

```bash
make clean
```

---

## Random Seed Control

Fixed random seeds are used to make constrained-random simulations reproducible.

### Questa

The Makefile uses:

```text
-sv_seed <seed_value>
```

### VCS

The Makefile uses:

```text
+ntb_random_seed=<seed_value>
```

This allows a failing randomized test to be reproduced using the same seed.

Example:

```text
Fixed Burst : 2969046076
INCR Burst  : 3981970915
WRAP Burst  : 4017622352
```

---

## Waveform Support

### Questa

Waveforms are generated in WLF format:

```text
wave_file1.wlf
wave_file2.wlf
wave_file3.wlf
```

They can be viewed using Questa.

### VCS

Waveforms are generated in FSDB format:

```text
wave1.fsdb
wave2.fsdb
wave3.fsdb
```

They can be viewed using Verdi.

---

## Technologies Used

* Verilog
* SystemVerilog
* Universal Verification Methodology (UVM)
* SystemVerilog Assertions (SVA)
* Functional Coverage
* Constrained-Random Verification
* Siemens Questa
* Synopsys VCS
* Verdi
* Linux
* Make

---

## Key Verification Concepts Demonstrated

* UVM factory registration
* UVM configuration database
* Active and passive agents
* Sequencer-driver communication
* Virtual sequencer architecture
* Virtual sequences
* Constrained-random stimulus
* Semaphore-based synchronization
* Transaction queues
* Analysis ports
* TLM Analysis FIFOs
* Scoreboard-based checking
* Functional coverage and cross coverage
* SystemVerilog Assertions
* Random seed control and simulation reproducibility
* Multi-simulator verification flow
* Environment-level component connectivity

---

## Future Enhancements

Potential improvements for the VIP include:

* More extensive constrained-random regression tests
* Additional AXI response error scenarios
* Improved transaction matching based on transaction IDs
* More robust out-of-order transaction handling
* Enhanced scoreboard matching for independently arriving AXI channels
* Additional protocol assertions
* Expanded functional coverage and coverage closure
* Support for configurable data and address widths
* Automated regression scripting

---

## Author

**Chandirapriyan K**  
Design Verification | RTL Design

**Skills:** SystemVerilog, UVM, AXI3, SVA, Functional Coverage, Constrained-Random Verification, TLM, QuestaSim, Synopsys VCS, Linux
