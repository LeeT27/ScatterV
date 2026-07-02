**Name:** Ethan Lee  
**Education:** University of Illinois Urbana-Champaign  
**Major:** Computer Engineering  
**Graduation Date:** May 2028

March 31, 2026

# ScatterV
- BIG BULLET POINT
  
ScatterV is a **custom pipelined RISC-V processor** implemented in SystemVerilog and **synthesized on FPGA**. It features standard functionality of a RISC-V processor and includes a custom instruction, `RND`, which loads a pseudorandom number into a register using a linear feedback shift register (LFSR) to produce maximal-length sequences. Hardware level random number generation sets the foundation for applications such as cryptography, simulations, and randomized algorithms.

This repository builds upon my previous work, [learningVerilog](https://github.com/LeeT27/learningVerilog), where I created a simple, single cycle processor to execute basic ALU, loads, stores, and jumps. ScatterV improves upon this through RISC-V compatibility, new complex instructions, pipelining, and hardware simulation. I seperated the project into three major parts/milestones:
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
| **Target Hardware** | RealDigital Boolean Board | Features a Xilinx Spartan-7 FPGA (XC7S50) with Seven-Segment displays for demo |
| **Hardware Description Language** | SystemVerilog | Used to model the pipelined RISC-V core |
| **Development Environment** | Visual Studio Code | Primary IDE used for writing SystemVerilog |
| **Synthesis & Deployment** | Xilinx Vivado | Handled synthesis, implementation, and bitstream generation for the FPGA |
| **Simulation & Verification** | EDAPlayground | Used for compiling RTL and analyzing waveform outputs to verify logic |
| **Demo** | RISC-V Assembly | Created a custom demo assembly code that approximates closer to pi every second using a Monte Carlo plotting simulation |

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
An internal "hits" counter is incremented everytime it lands inside the quarter circle and a total "samples counter" is incremented everytime, independent of where it lands. The approximation of π is found through the ratio of points:

$$\pi \approx 4 \times \frac{\text{hits}}{\text{total samples}}$$

The ratio converges to π as the sample size approaches ∞, 

For the sake of hardware, I stuck to displaying only hits and sample count so that decimals don't need to be involved

[https://img.youtube.com/vi/kfW94tNMFkA/0.jpg](https://upload.wikimedia.org/wikipedia/commons/0/0b/RedDot_Burger.jpg)

---
## Architecture Overview

| Module Name | Key Functionality |
| :--- | :--- |
| `top_module` | Contains all sub-modules, multiplexing, and pipelining logic |
| `program_counter` | Manages the current instruction address |
| `instruction_memory`| Stores pre-loaded executable test program |
| `control_unit` | Parses opcode and generate control signals |
| `immediate_generator`| Formats and extends immediate values depending on instruction |
| `register_file` | Holds 32 registers bank with synchronous writes and asynchronous reads |
| `alu` | Performs arithmetic, logic, shifts and RNG |
| `program_memory` | Contains 4 kb RAM supporting `lb`, `lh`, `lw`, `sb`, `sh`, and `sw` operations |

---

### Instruction Set Architecture
| Instruction Type | Instructions | Opcode | funct3 | funct7 |
| :--- | :--- | :--- | :--- | :--- |
| **R-Type** | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | `0110011` | Selects ALU op | Differentiates SUB/SRA |
| **I-Type** | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | `0010011` | Selects ALU op | Differentiates SRAI |
| **Load** | LB, LH, LW | `0000011` | Sets data size | N/A |
| **Store** | SB, SH, SW | `0100011` | Sets data size | N/A |
| **Branch** | BEQ, BNE, BLT, BGE, BLTU, BGEU | `1100011` | Sets condition | N/A |
| **U-Type** | LUI | `0110111` | N/A | N/A |
| **U-Type** | AUIPC | `0010111` | N/A | N/A |
| **J-Type** | JAL | `1101111` | N/A | N/A |
| **I-Type** | JALR | `1100111` | `000` | N/A |
| **Custom** | RND | `0001011` | N/A | N/A |

<br><br>
<div align="center">
  <img width="1000" alt="image" src="https://github.com/user-attachments/assets/0081d60a-b194-4487-b2cc-d86e161800de" />
</div>

| Instruction Format | Bits 31:12 (20 bits) | Bits 11:7 (5 bits) | Bits 6:0 (7 bits) |
| :--- | :---: | :---: | :---: |
| **RND (Random)** | Unused | rd | opcode |

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
When I finished designing my very [first processor](https://github.com/LeeT27/learningVerilog) around a year ago, I felt very thrilled that I created a custom ISA CPU that could perform simple arithmetic programs. Reflecting, I realized that my ISA was inefficient, slow, and lacking in instructions, I felt more inspired to take on more industry level processors such as RISC-V, while also tackling pipeline theory. I chose RISC-V for its popularity in IoT, embedded systems, and operating systems. Finding that RISC-V is easily modifiable, I also wanted to create a custom instruction, `RND`, that could be used for demonstration. Here is the theory behind hardware RNG:

### 🎲 `RND` Instruction Implementation
The core of ScatterV's random number generation comes from the abstract algebra theory of primitive polynomials and its application on a linear feedback shift register (LFSR). To make sequences appear as random as possible every clock cycle, the amount of unique sequences before repeating the same pattern needs to be maximized. This is where the magic of primitive polynomials comes in. A primitive polynomial is a special type of irreducible polynomial, meaning that it cannot be factored into smaller polynomials. Another property is that a primitive polynomial of degree n has $(2^{n}-1)$ unique states before repeating to its old pattern (base will be 2 for digital logic). A good analogy is that if you have a deck of 52 cards, the shuffling mechanism of a primitive polynomial would go through all 52 cards before repeating the pattern rather than a smaller pattern of cycling through the same 8 cards. Here below is an example of a primitive polynomial of degree n = 3: 

### $x^{3} + x + 1$

($2^{3}-1 = 7$ unique states before repeating pattern)

To implement this theory into ScatterV, I used an LFSR to utilize primitive polynomials. An LFSR consists of a chain of flip flops that use the output of an arbitrary amount of chosen flip flops to determine the next incoming bit. The powers of the polynomial $x$ serve as a direct mapping to the register's state. Specifically, each term $x^n$ corresponds to the output of the $n^{th}$ flip-flop within the shift register chain. To maintain the mathematical identity of the primitive polynomial: $x^{3}$+x+1=0, the hardware must keep solving for the constant term. By XORing the $x^{3}$ and x term, we generate the feedback bit 1, thus constantly balancing the equation. All flip flop bits perform a left bitwise shift and the feedback bit is fed into the LSB. Every clock cycle now generates a unique pattern! Here is a diagram I made of the flip flops for n = 3:

<img src="https://github.com/user-attachments/assets/dcd47c8c-e1f9-4fc6-b67e-e26096d311a7" width="400">

Since RISC-V registers are 32 bits, a primitive polynomial of degree n = 32 will be used to produce 4,294,967,295 unique combinations! 
```systemverilog
//Custom 32-bit Random Number Generator
    logic [31:0] lfsr_reg;
    logic        feedback_bit; //Gets fed into LSB

    // Shift LEFT every cycle, feeding the XOR feedback into the LSB (bit 0)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg <= 32'hECEB; // Seed value
        end else begin
            lfsr_reg <= {lfsr_reg[30:0], feedback_bit}; // Drops bit 31, shifts everything left, places feedback in bit 0
        end
    end
```
### Testing #1
Here is a program that performs a simple 1+1=2. Load 1 into x1, 1 into x2, add them together and save into x3. End the program by looping PC to never end.

```systemverilog
initial begin
    mem[0] = 32'h00100093; // addi x1, x0, 1  (x1 = 1)
    mem[1] = 32'h00100113; // addi x2, x0, 1  (x2 = 1)
    mem[2] = 32'h002081B3; // add/ add x3, x1, x2 (rd = 5'b00011)
    mem[3] = 32'h0000006F; // j done (jump to current PC forever)
    for (int i = 4; i < 64; i++) begin
        mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
    end
end
```

<img width="700" alt="image" src="https://github.com/user-attachments/assets/22387364-5652-4ba4-980d-d7fb6f12d4c1" />

It worked! :) x3 successfully has the value 0x0002 at the end of the program. I forgot to append the LSFR signal, but the register is successfully outputting pseudorandom numbers every clock cycle.

### Testing #2
Here is a second program that squares a random number between 1 and 8 amd stores the value into x3
```systemverilog
initial begin
    mem[0]  = 32'h0000008B; // rnd x1              (x1 = fresh random 32-bit number)
    mem[1]  = 32'h0070F093; // andi x1, x1, 7       (x1 = x1 & 0x7, range 0-7)
    mem[2]  = 32'h00108093; // addi x1, x1, 1       (x1 = x1 + 1, range 1-8)
    mem[3]  = 32'h00000233; // add x4, x0, x0       (x4 = 0, running total)
    mem[4]  = 32'h000002B3; // add x5, x0, x0       (x5 = 0, loop counter)
    mem[5]  = 32'h00128863; // loop: beq x5, x1, done  (exit once counter == x1)
    mem[6]  = 32'h00120233; //   add x4, x4, x1     (total += x1)
    mem[7]  = 32'h00128293; //   addi x5, x5, 1     (counter += 1)
    mem[8]  = 32'hFF5FF06F; //   jal x0, loop       (jump back to loop)
    mem[9]  = 32'h000201B3; // done: add x3, x4, x0 (x3 = x1^2, final result)
    mem[10] = 32'h0000006F; // j done (jump to current PC forever)
    for (int i = 11; i < 64; i++) begin
        mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
    end
end
```

<img width="1000" alt="image" src="https://github.com/user-attachments/assets/60ea3478-94e5-40d5-8257-5a40829bc2e1" />

This one also worked! The random number masked between 0x0007 and the LSFR was 0x0003 (3 in decimal), added by 1, and then was squared to store the value 0x0010 (16 in decimal) into x3. It was very assuring seeing that the randomization system is correctly used in a program.

### Testing #3
This final test program performs the monte carlo pi approximation and then stores the value into x3
```systemverilog
initial begin
    mem[0]  = 32'h0000008B; // rnd x1              (x1 = fresh random 32-bit number)
    mem[1]  = 32'h0070F093; // andi x1, x1, 7       (x1 = x1 & 0x7, range 0-7)
    mem[2]  = 32'h00108093; // addi x1, x1, 1       (x1 = x1 + 1, range 1-8)
    mem[3]  = 32'h00000233; // add x4, x0, x0       (x4 = 0, running total)
    mem[4]  = 32'h000002B3; // add x5, x0, x0       (x5 = 0, loop counter)
    mem[5]  = 32'h00128863; // loop: beq x5, x1, done  (exit once counter == x1)
    mem[6]  = 32'h00120233; //   add x4, x4, x1     (total += x1)
    mem[7]  = 32'h00128293; //   addi x5, x5, 1     (counter += 1)
    mem[8]  = 32'hFF5FF06F; //   jal x0, loop       (jump back to loop)
    mem[9]  = 32'h000201B3; // done: add x3, x4, x0 (x3 = x1^2, final result)
    mem[10] = 32'h0000006F; // j done (jump to current PC forever)
    for (int i = 11; i < 64; i++) begin
        mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
    end
end
```
<img width="700" alt="image" src="https://github.com/user-attachments/assets/db72ffdd-5fc8-4cce-9310-b30e35463949" />

Haha. Insanely large waveform. The first sample iteration loop took ~10,000 clock cycles, and EDAPlayground doesn't want to show more than 20,000 clock cycles. Moving forward, I will only stick with FPGA demos for this program because the abundance of data to be displayed on EDA. As I zoom in, the behaviour is working correctly for the one cycle, where it is correctly squaring two random numbers between 0 and 255, adding them, and then correctly comparing the sum to the threshold of 65025 to setermine a hit or a miss.

### Part 1 Reflection Notes
- It felt like a big jump going from my old custom ISA CPU to the official RISC-V ISA because of new instruction types such as branching, upper intermediates, and JALR
- Starting with the top module and control unit first helped me visualize the I/O of the other modules easily
- New instruction types meant a lot more multiplexers in the top module to select next pc, writeback, operands, and more depending on the control signals
- A lot of new control signals seemed difficult to track and sometimes a whole new signal was needed for a single instruction
- One frustrating moment was when I had to implement func7 extensions for SUB, SRA, and SRAI, since there were more than 8 arithmetic operations, where not only did I have to allow func3 to only be passed in R and I type instructions, I had to specifically disable func3 for ADDI so that the immediate value doesn't trigger an unintentional subtract.
- It was difficult implementing byte, half word, and full word stores and loads because I had to manage offsets if the selected memory address wasn't a factor of 4
- What helped me to debug these was working was constantly using EDAPlayground and appending register signals to test each individual instructions and making sure the correct control signals and multiplexer results had correct behaviour

## Part 2: Pipeline architecture and hazard mitigation
This portion of the project is about pipelining my functional single cycle RISC-V core in order to increase the maximum clock speed. A major issue with my first processor a year back was not only that it was a single cycle, where each instruction needed to complete the 5 stages before the next instruction but also that heavy instructions such as `MULT` and `DIV` made the worst case propagation delay much longer. I pipelined scatterV using the following 5-stage RISC-V pipeline model to minimize the worst case propagation delay:

1. **Instruction Fetch (IF):** Fetches the instruction from `instruction_memory` based on the current PC value
2. **Instruction Decode (ID):** Decodes the fetched instruction to set control signals and multiplexer selection
3. **Execute (EX):** Performs arithmetic, branches, jumps, or reading `lfsr_reg` for the `RND` instruction
4. **Memory Access (MEM):** Reads/writes the program memory for loads/stores
5. **Write Back (WB):** Writes the final result, selected by wb_sel, into `rd`

Here is a good visual that helped me understand the flow of instructions using single-cycle vs pipelining:

<img width="500" alt="image" src="https://github.com/user-attachments/assets/e86e4c30-aaab-4ef0-98cd-d5abffc16312" />

While pipelining has a slight latency when filling and emptying the pipeline, the minimized worst case propagation delay allows for a much higher maximum operating frequency, running programs more efficiently

### Pipeline Registers
I replaced old registers with 4 new groups of hardware registers to transfer data between the 5 stages directly using synchronized `always_ff` blocks in `top_module`:

#### 1. IF/ID
* `if_id_pc`
* `if_id_instruction`

#### 2. ID/EX
* `id_ex_pc`
* `id_ex_rs1_data`
* `id_ex_rs2_data`
* `id_ex_imm`
* `id_ex_rs1`
* `id_ex_rs2`
* `id_ex_rd`
* `id_ex_control`: `alu_src`, `alu_op`, `rnd_sel`, `mem_read`, `mem_write`, `reg_write`, and `wb_sel`.

#### 3. EX/MEM
* `ex_mem_alu_result`
* `ex_mem_rs2_data`
* `ex_mem_rd`
* `ex_mem_control`: `mem_read`, `mem_write`, `reg_write`, and `wb_sel`.

#### 4. MEM/WB
* `mem_wb_alu_result`
* `mem_wb_mem_data`
* `mem_wb_rd`
* `mem_wb_control`: `reg_write` and `wb_sel`.

### Control Signal Optimization
In the pipelined model, I made single bit-vector value to represent all the control signals rather than a bunch of individual wires so that I could easily pass one value between pipeline register groups and then manually select bits to be passed per stage. This is the format of the control value:

| Bit Index | [7] | [6:5] | [4] | [3] | [2] | [1:0] |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Signal Name** | `reg_write` | `wb_sel` | `mem_write` | `mem_read` | `rnd_sel` | `alu_op` |

### Data Hazards
When pipelining the processesor, overlapping the execution of multiple instructions at once introduces data, control, and structural hazards that cause unexpected behaviour. Here are the 4 main hazards I mitigated:

### 🔴 EX-to-EX Data
* **The Hazard:** An instruction in the **EX** stage requires an operand calculated by the immediate preceding instruction, which is currently sitting in the **MEM** stage and hasn't been written back yet.
* **Solution:** Forwarding unit
**Forwarding unit:** For each `ID_EX` operand, check:
1. `ex_mem_reg_write == 1` (Writeback instructions only)
2. `ex_mem_rd != 0` (`NOP` or `x0` targets don't need forwarding)
3. `(ex_mem_rd == id_ex_rs1)||(ex_mem_rd == id_ex_rs2)` (The destination register must match a source register)
If all 3 of these conditions are satisfied for an operand, `ex_mem_rd' is routed into ALU input, corresponding to the operand with the matched address. Forwarding rather than stalling allows the processor to perform more efficiently

### 🟡 MEM-to-EX Data
* **The Hazard:** An instruction in the **EX stage** requires an operand calculated two cycles prior (currently sitting at the **WB stage** boundary), or it follows a back-to-back memory load (`LW`). The data isn't loaded until the end of the **MEM stage**
* **Solution:** Forwarding unit and stalling unit
**Forwarding unit:** For each `ID_EX` operand, check:
1. `ex_mem_reg_write == 1` (Writeback instructions only)
2. `ex_mem_rd != 0` (`NOP` or `x0` targets don't need forwarding)
3. `(mem_wb_rd == id_ex_rs1)||mem_wb_rd == id_ex_rs2)` (The destination register must match a source register)
If all 3 of these conditions are satisfied for an operand, `mem_wb_rd' is routed into ALU input, corresponding to the operand with the matched address.

**Stalling unit:** check:
1. `id_ex_mem_read == 1`





*   **For multi-cycle arithmetic dependencies:** The Forwarding Unit constantly tests if **`mem_wb_reg_write == 1`**, **`mem_wb_rd != 0`**, and a source register matches (**`mem_wb_rd == id_ex_rs1`** or **`mem_wb_rd == id_ex_rs2`**). If satisfied, **`mem_wb_data`** is routed straight into the corresponding **ALU input**.
*   **For load-use conflicts:** If the instruction in EX is a load (**`id_ex_mem_read == 1`**) and its destination matches a source (**`id_ex_rd == if_id_rs1`** or **`id_ex_rd == if_id_rs2`**), the Hazard Detection Unit forces a **1-cycle hardware stall**—freezing the PC/Fetch stage and injecting a `NOP` bubble into **ID/EX**—allowing the subsequent MEM-to-EX path to safely capture the data.

### 🟢 Control
* **The Hazard:** If a branch or jump is taken, the instructions tagged along after that instruction (contents in **IF** and **ID** stages) should no longer be in the pipeline.
* **Solution:** Perform a flush signal on the next clock edge that clears out the early pipeline registers to all zeros, converting the invalid instructions into hardware NOPs (`addi x0, x0, 0`)

### 🔵 Structural
* **The Hazard:** Two instructions try to read RAM in the same clock cycle when RAM only has one read (instruction fetch paired with load instruction).
* **Solution:** This is already solved because ScatterV uses splits memory modules. instruction_memory for instruction fetches, and program_memory for loading and reading

### Testing #1

### Part 2 Reflection Notes


---

## Part 3: Hardware synthesis and FPGA demo

## Overall Reflection

---
