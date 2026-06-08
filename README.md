**Name:** Ethan Lee  
**Education:** University of Illinois Urbana-Champaign  
**Major:** Computer Engineering  
**Graduation Date:** May 2028

March 31, 2026

# ScatterV
ScatterV is a custom pipelined RISC-V processor implemented in SystemVerilog and synthesized on FPGA. It features standard functionality of a RISC-V processor and includes a custom instruction, `RND`, which loads a pseudorandom number into a register using a linear feedback shift register (LFSR) to produce maximal-length sequences. Hardware level random number generation sets the foundation for applications such as cryptography, simulations, and randomized algorithms.

This repository builds upon my previous work, [learningVerilog](https://github.com/LeeT27/learningVerilog), where I created a simple, single cycle processor to execute basic ALU, loads, stores, and jumps. ScatterV improves upon this by through RISC-V compatibility, new complex instructions, pipelining, and hardware simulation. I seperated the project into three major parts/milestones:
1. Single cycle RISC-V core and RNG implementation
2. Pipeline architecture and hazard mitigation
3. Hardware synthesis and FPGA demo
   
---

## Features
- **Instruction Set:** RV32I base instructions — arithmetic, logic, loads, stores, branches, and jumps
- **Custom `RND` instruction:** Generates a pseudorandom number generation every clock cycle with 32-bit LSFR
- **Pipelined Architecture:** Multi stage execution for maximum clock speeds
- **Hazard Protection:** Hazard protection using forwarding, stalling, branch prediction, and seperate memory
- **FPGA Deployment:** Deployed on FPGA with Vivado's toolchain (synthesis, implementation, bitstream generation)  
- **Display Output:** Seven-segment display shows decimal numbers directly from the processor  
- **Demo:** Assembly program that utilizes counters and `RND` for FPGA demo  

---

## Tools & Hardware
| Category | Component / Tool | Description / Role |
| :--- | :--- | :--- |
| **Target Hardware** | RealDigital Boolean Board | Features a Xilinx Spartan-7 FPGA (XC7S50) with Seven-Segment displays for demo. |
| **Hardware Description Language** | SystemVerilog | Used to model the pipelined RISC-V core. |
| **Development Environment** | Visual Studio Code | Primary IDE used for writing SystemVerilog. |
| **Synthesis & Deployment** | Xilinx Vivado | Handled synthesis, implementation, and bitstream generation for the FPGA. |
| **Simulation & Verification** | Icarus Verilog + GTKWave | Used for compiling RTL and analyzing waveform outputs to verify logic. |
| **Verification Software** | RISC-V Assembly | Created a custom demo assembly code that approximates closer to pi every second using a Monte Carlo plotting simulation. |

---
## Demo Program: Monte Carlo $\pi$ Approximation
To verify the processor's capabilities, we implemented a Monte Carlo simulation in assembly. The program utilizes:
* **`RND` Instruction:** Generates pseudorandom coordinates to test the LFSR logic.
* **Arithmetic/Logic:** Performs coordinate squaring and comparison to determine points inside the unit circle.
* **Hardware Interface:** Uses the seven-segment display to output the calculated approximation of $\pi$ in real-time.
[![Watch the video](https://img.youtube.com/vi/kfW94tNMFkA/0.jpg)](https://www.youtube.com/watch?v=kfW94tNMFkA)

---

## Instruction Set Architecture
| Category | Instructions |
| :--- | :--- |
| **R-Type** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| **I-Type** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`, `LB`, `LH`, `LW`, `JALR` |
| **S-Type** | `SB`, `SH`, `SW` |
| **B-Type** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| **U-Type** | `LUI`, `AUIPC` |
| **J-Type** | `JAL` |
| **Custom** | `RND` |
<img width="500" alt="image" src="https://github.com/user-attachments/assets/0081d60a-b194-4487-b2cc-d86e161800de" />

---
## Instruction Encoding

| Instruction Format | Opcode | `funct3` / `funct7` Notes |
| :--- | :---: | :--- |
| **R-Type** (ADD, SUB, XOR, etc.) | `0110011` | `funct3` defines op; `funct7` distinguishes `SUB`/`SRA` |
| **I-Type** (ADDI, JALR, etc.) | `0010011` | `funct3` defines op |
| **Load** (LW, LH, LB) | `0000011` | `funct3` defines size |
| **Store** (SW, SH, SB) | `0100011` | `funct3` defines size |
| **Branch** (BEQ, BNE, etc.) | `1100011` | `funct3` defines condition |
| **U-Type** (LUI, AUIPC) | `0110111` | N/A |
| **J-Type** (JAL) | `1101111` | N/A |
| **Custom** (RND) | `0001011` | N/A |

---

## Control Signal Reference

| Instruction | `alu_op` | `alu_src` | `mem_read` | `mem_write` | `reg_write` | `wb_sel` | `pc_sel` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **R-Type** | 10 | 0 | 0 | 0 | 1 | 00 | 00 |
| **ADDI** | 10 | 1 | 0 | 0 | 1 | 00 | 00 |
| **LOAD** | 00 | 1 | 1 | 0 | 1 | 01 | 00 |
| **STORE** | 00 | 1 | 0 | 1 | 0 | XX | 00 |
| **BRANCH** | 01 | 0 | 0 | 0 | 0 | XX | 10 |
| **LUI** | XX | 1 | 0 | 0 | 1 | 11 | 00 |
| **AUIPC** | 00 | 1 | 0 | 0 | 1 | 00 | 00 |
| **JAL** | XX | 1 | 0 | 0 | 1 | 10 | 01 |
| **JALR** | XX | 1 | 0 | 0 | 1 | 10 | 11 |
| **RND** | 11 | X | 0 | 0 | 1 | 00 | 00 |

* **wb_sel:** `00` = ALU, `01` = DataMem, `10` = PC+4, `11` = Immediate.
* **pc_sel:** `00` = PC+4, `01` = JAL, `10` = Branch, `11` = JALR.
  
---

## Demo

---
## Deep Dive Notes
### 🏗️ RISC-V Architecture
RISC-V is an open source instruction set architecture that is popular in IoT, embedded systems, and operating systems. Programs written in RISC-V assembly can run sequential instructions that handle fundamental operations such as arithmetic, data transfer, and control flow. Two major benefits that make RISC-V special is its easy access to modify the instruction set and reduced complexity in hardware design. Typically, RISC-V has 32 bits per instruction, 32 general purpose registers, 8 bits per memory location, and stores the least significant byte at the lowest memory address (little endian). RV32, used for smaller embedded applications, has 32 bits per register while RV64, used for high performance computing, has 64 bits per register. ScatterV uses the RV32 architecture.

ScatterV utilitizes a 5-stage instruction pipeline to improve performance to allow parallel processing. Every instruction goes through the following stages:
- **Instruction Fetch (IF)**: The processor reads the instruction from memory using a program counter (PC). The selected instruction is composed of the bytes mem[PC], mem[PC+1], mem[PC+2], and mem[PC+3], where mem[PC] is the least significant byte and mem[PC+3] is the most significant byte. The PC is then incremented by 4 to point to the next instruction for the following cycle.
- **Instruction Decode (ID)**: The fetched instruction is decoded by the control unit to determine its opcode and operands. The processor also begins to read the values of source register chosen by the instruction.
- **Execute (EX)**: The ALU performs the operation specified by the instruction. Applies for arithmetic instructions and calculating branch logic.
- **Memory Access (MEM)**: Memory can be read and overwritten in this stage. Applies for loading and storing instructions.
- **Write Back (WB)**: The result values that are computed via ALU or loaded from memory are written into destination register.

Here is an overview of all the modules used in ScatterV:
- Top Module
  - Inputs: clk, rst, switches
  - Outputs: segments
  - Holds all the submodules
- **Program Counter (PC)**
  - Inputs: clk, rst, pc_next
  - Outputs: pc_out
  - Holds pointer to current instruction address and increments by 4 on every rising clock edge, or branches/jumps to a different target based on control signals
- **Instruction Memory**
  - Inputs: pc_out
  - Outputs: instruction
  - Takes current PC and outputs the 32-bit instruction at that address
- **Control Unit**
  - Inputs: opcode
  - Outputs: alu_op, alu_src, mem_read_en, mem_write_en, mem_to_reg, reg_write_en, jump_toggle
  - Decodes opcode of instruction and generates the control signals that correspond with the proper instruction
- **Program Memory**
  - Inputs: mem_address, alu_result, write_data, mem_read_en, mem_write_en
  - Outputs: read_data
  - Stores program data. Reads data during load instructions and writes data during store instructions
- **Register File**
  - Inputs: clk, rs1_addr, rs2_addr, rd_addr, rd_data, reg_write_en
  - Outputs: rs1_data, rs2_data
  - The register file contains 32 general purpose registers to store values for source and destination registers. There are two read ports to access source registers and a write port to update a destination register if reg_write is enabled
- **ALU**
  - Inputs: alu_op, operand1, operand2
  - Outputs: alu_result, zero_flag
  - The ALU takes two operands and performs an arithmetic or logical operation, decided by alu_op, and outputs a result along with a zero flag used for branch decisions
- **Immediate Generator**
  - Inputs: instruction
  - Outputs: immediate_out
  - The immediate generator extracts immediate values from instructions and outputs that value so it can be used for calculations. Different instruction types pick different ranges of bits from the instruction, so the module selects the correct logics accordingly
- **Seven-segment Decoder**
  - Inputs: clk, rst, regs[9], regs[10]
  - Outputs: segments_left [6:0], segments_right [6:0], 
  - The seven-segment decoder module converts binary values from registers 9 and 10 into segment control signals to be displayed on FPGA at all times.

Here is a diagram of the processor:

<img width="400" src="https://github.com/user-attachments/assets/c4e6a2ae-6fd2-4ed3-b591-65e0ef8ad2b2" />


<img width="1109" height="315" alt="image" src="https://github.com/user-attachments/assets/0081d60a-b194-4487-b2cc-d86e161800de" />

### 🎲 `RND` Instruction Implementation
The core of ScatterV's random number generation comes from the abstract algebra theory of primitive polynomials and its application on a linear feedback shift register (LFSR). To make sequences appear as random as possible every clock cycle, the amount of unique sequences before repeating the same pattern needs to be maximized. This is where the magic of primitive polynomials comes in. A primitive polynomial is a special type of irreducible polynomial, meaning that it cannot be factored into smaller polynomials. Another property is that a primitive polynomial of degree n has $(2^{n}-1)$ unique states before repeating to its old pattern (base will be 2 for digital logic). A good analogy is that if you have a deck of 52 cards, the shuffling mechanism of a primitive polynomial would go through all 52 cards before repeating the pattern rather than a smaller pattern of cycling through the same 8 cards. Here below is an example of a primitive polynomial of degree n = 3: 

### $x^{3} + x + 1$

($2^{3}-1 = 7$ unique states before repeating pattern)

To implement this theory into ScatterV, I used an LFSR to utilize primitive polynomials. An LFSR consists of a chain of flip flops that use the output of an arbitrary amount of chosen flip flops to determine the next incoming bit. The powers of the polynomial $x$ serve as a direct mapping to the register's state. Specifically, each term $x^n$ corresponds to the output of the $n^{th}$ flip-flop within the shift register chain. To maintain the mathematical identity of the primitive polynomial: $x^{3}$+x+1=0, the hardware must keep solving for the constant term. By XORing the $x^{3}$ and x term, we generate the feedback bit 1, thus constantly balancing the equation. All flip flop bits perform a left bitwise shift and the feedback bit is fed into the LSB. Every clock cycle now generates a unique pattern! Here is a diagram I made of the flip flops for n = 3:

<img src="https://github.com/user-attachments/assets/dcd47c8c-e1f9-4fc6-b67e-e26096d311a7" width="400">

Since RISC-V registers are 32 bits, a primitive polynomial of degree n = 32 will be used to produce 4,294,967,295 unique combinations! (Talk about how new instruction is added)

### 🚧 Pipeline Hazards
hullo
### ✅ RTL Verification
hullo
### ⚙️ FPGA Synthesis
hullo
### 💡 Seven-Segment Digit Display
Throughout the running process, a 32 bit register value is stored in binary, but needs to be shown on the FPGA peripheral as a human-readable decimal number. 
### 📜 RISC-V Assembly


---

## Challenges and Fixes

---
## Reflection

---
