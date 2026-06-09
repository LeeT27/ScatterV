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
| **Demo** | RISC-V Assembly | Created a custom demo assembly code that approximates closer to pi every second using a Monte Carlo plotting simulation. |

---
## Demo Program: Monte Carlo $\pi$ Approximation

To verify correct processor behavior, I implemented a Monte Carlo simulation written entirely in RISC-V assembly. The main star of the show in this simulation is the custom `RND` instruction that constantly creates pseudorandom coordinates.

### Mathematical Principle
The program approximates $\pi$ by generating random coordinate points $(x, y)$ within a square area bounded by (0,0) and (1,1) every tenth of a second and determining the ratio of points that fall inside the shaded quarter circle, calculated using the following circle equation:

$$x^2 + y^2 \le 1$$

<div align="center">
  <img src="https://github.com/user-attachments/assets/855c08f7-7e33-4f49-b01e-93e95c569be3" width="200px" alt="Monte Carlo">
</div>
<br><br>
An internal "hits" counter is incremented everytime it lands inside the quarter circle and a total "samples counter" is incremented everytime, independent of where it lands. The approximation of $\pi$ is found through the ratio of points:

$$\pi \approx 4 \times \frac{\text{hits}}{\text{total samples}}$$

The ratio converges to π as the sample size approaches ∞, 

[https://img.youtube.com/vi/kfW94tNMFkA/0.jpg](https://upload.wikimedia.org/wikipedia/commons/0/0b/RedDot_Burger.jpg)

---
## Architecture Overview

| Module Name | Key Functionality |
| :--- | :--- |
| `top_module` | Contains all sub-modules, handling routing and signal selection. |
| `program_counter` | Manages the current instruction address. |
| `instruction_memory`| Stores pre-loaded executable test program. |
| `control_unit` | Parses opcode and generate control signals. |
| `immediate_generator`| Formats and extends immediate values depending on instruction. |
| `register_file` | Holds 32 registers bank with synchronous writes and asynchronous reads. |
| `alu` | Performs arithmetic, logic, shifts and RNG. |
| `program_memory` | Contains 4 kb RAM supporting `lb`, `lh`, `lw`, `sb`, `sh`, and `sw` operations. |

---

### Instruction Set Architecture
| Instruction Type | Instructions | Opcode | funct3 | funct7 |
| :--- | :--- | :--- | :--- | :--- |
| **R-Type** | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | `0110011` | Selects ALU op | Differentiates SUB/SRA |
| **I-Type** | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | `0010011` | Selects ALU op | N/A |
| **Load** | LB, LH, LW | `0000011` | Sets data size | N/A |
| **Store** | SB, SH, SW | `0100011` | Sets data size | N/A |
| **Branch** | BEQ, BNE, BLT, BGE, BLTU, BGEU | `1100011` | Sets condition | N/A |
| **U-Type** | LUI | `0110111` | N/A | N/A |
| **U-Type** | AUIPC | `0010111` | N/A | N/A |
| **J-Type** | JAL | `1101111` | N/A | N/A |
| **I-Type** | JALR | `1100111` | `000` | N/A |
| **Custom** | RND | `0001011` | N/A | N/A |
<div align="center">
  <img width="700" alt="image" src="https://github.com/user-attachments/assets/0081d60a-b194-4487-b2cc-d86e161800de" />
</div>

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

## Part 1: Single cycle RISC-V core and RNG implementation
When I finished designing my very [first processor](https://github.com/LeeT27/learningVerilog) around a year ago, I felt very thrilled that I created a custom ISA CPU that could perform simple arithmetic programs. Reflecting, I realized that my ISA was inefficient, slow, and lacking in instructions, thus, I felt more inspired to take on more industry level processors such as RISC-V, while also tackling pipeline theory. I chose RISC-V for its popularity in IoT, embedded systems, and operating systems. Finding that RISC-V is easily modifiable, I also wanted to create a custom instruction, `RND`, could be used for demonstration. Here is the theory behind hardware RNG:

### 🎲 `RND` Instruction Implementation
The core of ScatterV's random number generation comes from the abstract algebra theory of primitive polynomials and its application on a linear feedback shift register (LFSR). To make sequences appear as random as possible every clock cycle, the amount of unique sequences before repeating the same pattern needs to be maximized. This is where the magic of primitive polynomials comes in. A primitive polynomial is a special type of irreducible polynomial, meaning that it cannot be factored into smaller polynomials. Another property is that a primitive polynomial of degree n has $(2^{n}-1)$ unique states before repeating to its old pattern (base will be 2 for digital logic). A good analogy is that if you have a deck of 52 cards, the shuffling mechanism of a primitive polynomial would go through all 52 cards before repeating the pattern rather than a smaller pattern of cycling through the same 8 cards. Here below is an example of a primitive polynomial of degree n = 3: 

### $x^{3} + x + 1$

($2^{3}-1 = 7$ unique states before repeating pattern)

To implement this theory into ScatterV, I used an LFSR to utilize primitive polynomials. An LFSR consists of a chain of flip flops that use the output of an arbitrary amount of chosen flip flops to determine the next incoming bit. The powers of the polynomial $x$ serve as a direct mapping to the register's state. Specifically, each term $x^n$ corresponds to the output of the $n^{th}$ flip-flop within the shift register chain. To maintain the mathematical identity of the primitive polynomial: $x^{3}$+x+1=0, the hardware must keep solving for the constant term. By XORing the $x^{3}$ and x term, we generate the feedback bit 1, thus constantly balancing the equation. All flip flop bits perform a left bitwise shift and the feedback bit is fed into the LSB. Every clock cycle now generates a unique pattern! Here is a diagram I made of the flip flops for n = 3:

<img src="https://github.com/user-attachments/assets/dcd47c8c-e1f9-4fc6-b67e-e26096d311a7" width="400">

Since RISC-V registers are 32 bits, a primitive polynomial of degree n = 32 will be used to produce 4,294,967,295 unique combinations! 
<img width="600" alt="image" src="https://github.com/user-attachments/assets/8ebdb6de-3e92-4ba9-a2ea-fe4ef09c40d3" />

### Part 1 Reflection

## Part 2: Pipeline architecture and hazard mitigation

## Part 3: Hardware synthesis and FPGA demo

## Overall Reflection

---
