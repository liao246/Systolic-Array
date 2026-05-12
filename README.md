# AHB-Lite Systolic Array Co-Processor

**March 2026 - May 2026**

This repository contains the RTL implementation of an 8x8 weight-stationary systolic array co-processor, interfaced via the AMBA AHB-Lite protocol. The project was designed and validated by a 3-person team, focusing on high-performance inference execution with strict latency constraints.

## 🚀 Key Features

* **8x8 Weight-Stationary Systolic Array**: A high-throughput processing core designed for matrix multiplication operations, optimized for AI inference tasks.
* **AHB-Lite Subordinate Interface**: Fully AMBA-compliant system bus interface implemented in SystemVerilog, handling high-speed data transfers.
* **Memory-Mapped Control Registers**: Custom architecture for control and status registers (CSRs) to configure and monitor the co-processor.
* **Advanced Hazard Resolution**: Custom data forwarding logic implemented within the bus interface to elegantly resolve Read-After-Write (RAW) data hazards without unnecessary stalling.
* **Robust FSM Control**: State machine logic to enforce strict AMBA compliance, dynamically managing `HREADY` stalls and gracefully handling `HRESP` error responses.
* **Strict Latency Constraints**: Designed and verified to execute end-to-end inference within a strict 55-cycle maximum latency budget.

## 📁 Repository Structure

* **`/RTL/`**: Contains all the SystemVerilog source code for the co-processor.
  * `top_level.sv`: The top-level wrapper integrating the AHB interface, controller, and array.
  * `ahb.sv`: The AHB-Lite subordinate interface and memory-mapped register logic. *(My primary individual contribution)*
  * `ai_controller.sv`: State machine and control logic managing the inference execution.
  * `array.sv` & `array_cell.sv`: The 8x8 systolic processing element array.
  * `multiplier.sv`, `float_adder.sv`: Core arithmetic units used within the processing elements.
  * *Additional modules handling biases, activation functions, and control counters.*
* **`/python scripts/`**: Scripts used for generating test vectors, expected outputs, or processing results.

## 🛠️ Technologies & Tools

* **Hardware Description Language**: SystemVerilog
* **Bus Protocol**: AMBA AHB-Lite
* **Verification**: SystemVerilog Testbenches
* **Architecture**: Weight-Stationary Systolic Array

## 👥 Team

This project was a collaborative effort by a 3-person team. **I was personally responsible for designing and implementing the AHB-Lite subordinate interface (`ahb.sv`)**, which included architecting the memory-mapped control registers, creating custom data forwarding logic to resolve RAW bus hazards, and developing the FSM to enforce strict AMBA compliance.

The overall integration of the AHB interface, the central state controller, and the systolic processing array was achieved collectively through rigorous co-simulation and validation to ensure all components functioned seamlessly together under the strict 55-cycle maximum latency constraint.
