# CA-Practical-4042

Welcome to the **Computer Architecture Project** repository.


---

## 🚀 MIPS Pipelined Processor

The main project in this repository is the implementation of a **5-stage Pipelined MIPS Processor** using **Logisim Evolution**.

The primary focus of the project is the design and integration of a **Data Forwarding Unit** to efficiently handle data dependencies and minimize unnecessary pipeline stalls.

### ✨ Key Features

* **Comprehensive Data Forwarding Unit:** Resolves `EX` and `MEM` data hazards by creating forwarding paths from the `EX/MEM` and `MEM/WB` pipeline registers directly to the ALU inputs. In the event of simultaneous hazards, the hardware prioritizes the most recent data.

* **Load-Use Hazard Detection:** Detects dependencies involving data currently being loaded by a `lw` instruction. The pipeline automatically stalls for one cycle and injects a bubble (`NOP`) when necessary.

* **Early Branch Resolution:** Evaluates conditional (`beq`) and jump (`j`) instructions directly in the Instruction Decode (`ID`) stage, reducing the branch penalty.

* **Dedicated Branch Forwarding System:** Uses a separate forwarding mechanism to provide up-to-date operands directly to the branch equality comparator.

* **Store Forwarding:** Handles cases where a `sw` instruction requires data that has not yet been written back to the register file.

---

## 📁 Project Structure

The repository is organized into several components:

* **`Assembly Code`**: Contains MIPS assembly programs used to test and demonstrate the processor's functionality.

* **`Verilog Testbenches`**: Contains testbenches used to simulate and verify the processor under different instruction and hazard scenarios.

* **`Project CPU`**: Contains the complete implementation of the pipelined MIPS processor, including the forwarding and hazard detection logic.

* **`Stall CPU`**: Contains a baseline pipelined processor without data forwarding, allowing its behavior to be compared with the forwarding-based implementation.

---

## 🛠️ Tools & Environment

The project was developed and tested using:

* **Logisim Evolution** — Digital circuit design and simulation
* **Verilog** — Hardware description and testbench development
* **Icarus Verilog** — Verilog simulation
* **Python** — Supporting scripts and testing infrastructure
* **Docker** — Isolated testing environment

---

## ⚙️ Running the Project

The repository provides scripts for automatically synthesizing and testing the circuits.

### Option 1: Bare-metal

If the required dependencies are installed locally, the circuit can be synthesized and tested directly using the provided scripts.

For a circuit and its corresponding testbench:

```bash
./scripts/synth_valid.sh [circuit path] [testbench path]
```

The synthesis process generates the required Verilog representation, which is then passed to the testbench for verification.

### Option 2: Docker

The repository also provides a Docker-based environment for running the tests in an isolated environment.

First, build the Docker image:

```bash
chmod +x ./scripts/build.sh
./scripts/build.sh
```

Then run the desired test using:

```bash
./scripts/judge.sh [circuit path] [testbench path]
```

The Docker-based approach provides a consistent environment for running the testing infrastructure without requiring all dependencies to be installed directly on the host system.

---

## 🧪 Testing

The repository includes Verilog testbenches designed to verify the behavior of the processor and its handling of different pipeline scenarios.

The tests cover cases such as:

* Data dependencies
* `EX` and `MEM` hazards
* Load-use hazards
* Branch dependencies
* Store forwarding
* Pipeline stalls
* Forwarding paths

The testbenches can be used to validate the processor implementation and identify incorrect behavior in different pipeline conditions.

---

## 📊 Pipeline Architecture

The processor follows the classic **5-stage MIPS pipeline**:

```text
IF → ID → EX → MEM → WB
```

The forwarding and hazard detection mechanisms are integrated into this pipeline to reduce unnecessary stalls while maintaining correct program execution.

---

## 📌 Notes

The project is designed around **Logisim Evolution** for the hardware implementation, with Verilog-based simulation and testing used to verify the resulting circuit behavior.

The repository contains both the forwarding-based implementation and a stall-based implementation for comparison and evaluation.
