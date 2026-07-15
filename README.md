**Name:** Ethan Lee  
**Education:** University of Illinois Urbana-Champaign  
**Major:** Computer Engineering  
**Graduation Date:** May 2028

March 31, 2026

# ScatterV
ScatterV is a **custom pipelined RISC-V processor** implemented in SystemVerilog and **synthesized on FPGA**. It features the standard functionality of a RISC-V processor and **includes a custom instruction**, `RND`, which loads a pseudorandom number into a register using a linear feedback shift register (LFSR) to produce maximal-length sequences. I wanted to explore hardware-level random number generation for its applications in cryptography, simulations, and randomized algorithms.

This repository builds upon my previous work, [learningVerilog](https://github.com/LeeT27/learningVerilog), where I created a simple, single cycle processor to execute basic ALU, loads, stores, and jumps. ScatterV improves upon this through RISC-V compatibility, new complex instructions, pipelining, hazard detection, and hardware simulation. I separated the project into three major parts/milestones:
1. Single-cycle RISC-V core and RNG implementation
2. Pipeline architecture and hazard mitigation
3. FPGA Deployment
   
---

## Features
- **Instruction Set:** RV32I base instructions — R, I, U, S, B, J types
- **Custom `RND` instruction:** Writes a pseudorandom number that changes every clock cycle with 32-bit LFSR to register
- **Pipelined Architecture:** Multi-stage execution for maximum clock speeds — IF → ID → EX → MEM → WB
- **Hazard Protection:** Hazard protection using forwarding, stalling, flushing, and split memory
- **FPGA Deployment:** Deployed on Spartan-7 FPGA with Vivado's toolchain (synthesis, implementation, bitstream generation)  
- **I/O:** Seven-segment display peripheral, reset button, and PC freeze button
- **Demo:** Assembly program that utilizes the new `RND` instruction on FPGA

---

## Tools & Hardware
| Category | Component / Tool | Description / Role |
| :--- | :--- | :--- |
| **Target Hardware** | RealDigital Boolean Board | Features a Xilinx Spartan-7 FPGA (XC7S50) with Seven-Segment displays for demo |
| **Hardware Description Language** | SystemVerilog | Used to model the pipelined RISC-V core |
| **Development Environment** | Visual Studio Code | Primary IDE used for writing SystemVerilog |
| **Synthesis & Deployment** | Xilinx Vivado | Handled synthesis, implementation, and bitstream generation for the FPGA |
| **Simulation & Verification** | EDAPlayground | Used for compiling RTL and analyzing waveform outputs to verify logic |
| **Demo** | RISC-V Assembly | Created a custom demo assembly code that approximates pi using a Monte Carlo plotting simulation |

---
## Demo Program: Monte Carlo π Approximation

To verify correct processor behavior, I implemented a Monte Carlo simulation written entirely in RISC-V assembly that estimates π as the sample size converges to ∞. The main star of the show in this simulation is the custom `RND` instruction that constantly creates pseudorandom coordinates to be used in branch calculations to determine a hit or miss.

### Mathematical Principle
The program approximates π by generating random coordinate points $(x, y)$ within a square area bounded by (0,0) and (4095,4095) and determining the ratio of points that fall inside the shaded quarter circle using the following circle equation:

$$x^2 + y^2 \le 4095^2$$

<div align="center">
  <img src="https://github.com/user-attachments/assets/855c08f7-7e33-4f49-b01e-93e95c569be3" width="200px" alt="Monte Carlo">
</div>
<br><br>
An internal "hits" counter is incremented every time it lands inside the quarter circle and a total "samples counter" is incremented every time, independent of where it lands. The approximation of π is found through the ratio of points:

$$\pi \approx 4 \times \frac{\text{hits}}{\text{total samples}}$$

The ratio will converge to π as the sample size approaches ∞. For the sake of hardware, I stuck to displaying only hits and sample count on FPGA so that decimals don't need to be calculated. Here is the video demo of the working processor and program:

<p align="center">
  <a href="https://www.youtube.com/watch?v=04T320I4pu4">
    <img src="https://github.com/user-attachments/assets/0c46638d-2549-4b72-9456-93bbb868283e" alt="ScatterV 5-Stage RISC-V: Monte Carlo π Approximation on FPGA" width="70%">
  </a>
</p>

---
## Architecture Overview

| Module Name | Key Functionality |
| :--- | :--- |
| `top_module` | Contains struct definitions, signal declaration, multiplexing, pipelining logic, hazard units, and all the submodule instantiation |
| `program_counter` | Sets next instruction address |
| `instruction_memory`| Stores pre-loaded executable test program |
| `control_unit` | Parses opcode and generate control signals |
| `immediate_generator`| Parses opcode to format and extend immediate values |
| `register_file` | Holds 32 register bank with synchronous writes and asynchronous reads |
| `program_memory` | Holds 4 KB RAM with supporting `lb`, `lh`, `lw`, `sb`, `sh`, and `sw` operations |
| `alu` | Performs arithmetic, logic, shifts, RNG, flag conditions |
| `segment_decoder` (FPGA only) | Converts a decimal digit into the proper 7-segment signals |

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

| Instruction | `pc_sel` | `alu_src` | `alu_op` | `auipc_en` | `ram_read` | `ram_write` | `reg_write` | `wb_sel` |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **R-Type** | 00 | 0 | 10 | 0 | 0 | 0 | 1 | 00 |
| **ADDI** | 00 | 1 | 10 | 0 | 0 | 0 | 1 | 00 |
| **LOAD** | 00 | 1 | 00 | 0 | 1 | 0 | 1 | 01 |
| **STORE** | 00 | 1 | 00 | 0 | 0 | 1 | 0 | XX |
| **BRANCH** | 10 | 0 | 01 | 0 | 0 | 0 | 0 | XX |
| **LUI** | 00 | 1 | XX | 0 | 0 | 0 | 1 | 11 |
| **AUIPC** | 00 | 1 | 00 | 1 | 0 | 0 | 1 | 00 |
| **JAL** | 01 | 1 | XX | 0 | 0 | 0 | 1 | 10 |
| **JALR** | 11 | 1 | XX | 0 | 0 | 0 | 1 | 10 |
| **RND** | 00 | X | 11 | 0 | 0 | 0 | 1 | 00 |

* **pc_sel:** `00` = PC+4, `01` = JAL, `10` = Branch, `11` = JALR
* **alu_src:** `0` = rs2_value, `1` = immediate
* **alu_op:** `00` ADD, `01` SUB, `10` Normal, `11` RND
* **auipc_en:** `0` = rs1_value, `1` = PC
* **wb_sel:** `00` = ALU, `01` = read memory, `10` = PC+4, `11` = Immediate
  
---

## Part 1: Single-cycle RISC-V core and RNG implementation
When I finished designing my very [first processor](https://github.com/LeeT27/learningVerilog) around a year ago, I felt very thrilled that I created a custom ISA CPU that could perform simple arithmetic programs. Reflecting, I realized that my ISA was inefficient, slow, and lacking in instructions. I wanted to try again as I felt more inspired to take on more industry-level processors such as RISC-V, while also tackling pipeline theory. I chose RISC-V for its popularity in IoT, embedded systems, and operating systems. Finding that RISC-V is easily modifiable, I also wanted to create a custom instruction, `RND`, that could be used for demonstration because I found its real-world applications to be amusing. Here is the theory behind hardware RNG:

### 🎲 `RND` Instruction Implementation
The core of ScatterV's random number generation comes from the abstract algebra theory of primitive polynomials and its application on a linear feedback shift register (LFSR). To make sequences appear as random as possible every clock cycle, the amount of unique sequences before repeating the same pattern needs to be maximized. This is where the magic of primitive polynomials comes in. A primitive polynomial is a special type of irreducible polynomial, meaning that it cannot be factored into smaller polynomials. Another property is that a primitive polynomial of degree n has $(2^{n}-1)$ unique states before repeating to its old pattern (base will be 2 for digital logic). A good analogy is that if you have a deck of 52 cards, the shuffling mechanism of a primitive polynomial would go through all 52 cards before repeating the pattern rather than a smaller pattern of cycling through the same 8 cards. Here below is an example of a primitive polynomial of degree n = 3: 

### $x^{3} + x + 1$

($2^{3}-1 = 7$ unique states before repeating pattern)

To implement this theory into ScatterV, I used an LFSR to utilize primitive polynomials. An LFSR consists of a chain of flip-flops that use the output of an arbitrary amount of chosen flip-flops to determine the next incoming bit. The powers of the polynomial $x$ serve as a direct mapping to the register's state. Specifically, each term $x^n$ corresponds to the output of the $n^{th}$ flip-flop within the shift register chain. To maintain the mathematical identity of the primitive polynomial: $x^{3}$+x+1=0, the hardware must keep solving for the constant term. By XORing the $x^{3}$ and x term, we generate the feedback bit 1, thus constantly balancing the equation. All flip-flop bits perform a left bitwise shift and the feedback bit is fed into the LSB. Every clock cycle now generates a unique pattern! Here is a diagram I made of the flip-flops for n = 3:

<img src="https://github.com/user-attachments/assets/dcd47c8c-e1f9-4fc6-b67e-e26096d311a7" width="400">

Since RISC-V registers are 32 bits, a primitive polynomial of degree n = 32 will be used to produce 4,294,967,295 unique combinations! 
```systemverilog
    logic [31:0] lfsr_reg;
    logic        feedback_bit; //Gets fed into LSB

    // Shift left every cycle, feeding the feedback_bit into the LSB (bit 0)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg <= 32'hECEB; // Seed value
        end else begin
            lfsr_reg <= {lfsr_reg[30:0], feedback_bit}; // Drops bit 31, shifts everything left, places feedback in bit 0
        end
    end
    always_comb begin
        // XOR taps at bits 31, 21, 1, and 0, if result somehow becomes 0, inject a 1
        feedback_bit = (lfsr_reg == 32'b0) ? 1'b1 : (lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0]);
    end
```
### Testing (single-cycle) #1
For testing throughout this project, I just used a general testbench that outputs a reset and clock. Most of the verification when creating this is waveform analysis. Here is a program that performs a simple 1+1=2. Load 1 into x1, 1 into x2, add them together and save into x3. End the program by looping PC to never end:

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

<img width="500" alt="image" src="https://github.com/user-attachments/assets/22387364-5652-4ba4-980d-d7fb6f12d4c1" />

It worked! :) x3 successfully has the value 0x0002 at the end of the program. I forgot to append the LFSR signal, but the register is correctly outputting pseudorandom numbers every clock cycle.

### Testing (single-cycle) #2
Here is a second program that squares a random number between 1 and 8 and stores the value into x3:
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

<img width="500" alt="image" src="https://github.com/user-attachments/assets/60ea3478-94e5-40d5-8257-5a40829bc2e1" />

This one also worked! The random number masked between 0x0007 and the LFSR was 0x0003 (3 in decimal), added by 1, and then was squared to store the value 0x0010 (16 in decimal) into x3. It was very assuring seeing that the randomization system is correctly used in a program.

### Testing (single-cycle) #3
This final test program performs the monte carlo pi approximation as in the demo: stores # of hits into x9 and sample size into x10
```systemverilog
initial begin
        mem[0]  = 32'h00010337; // lui x6, 16
        mem[1]  = 32'hE0130313; // addi x6, x6, -511     (x6 = 65025 = 255^2, threshold)
        mem[2]  = 32'h0FF00593; // addi x11, x0, 255     (x11 = 0xFF mask)
        mem[3]  = 32'h000004B3; // add x9, x0, x0        (hits = 0)
        mem[4]  = 32'h00000533; // add x10, x0, x0       (samples = 0)
        // loop:
        mem[5]  = 32'h0000008B; // rnd x1                (x1 = random)
        mem[6]  = 32'h00B0F0B3; // and x1, x1, x11       (x1 = x scaled, 0-255)
        mem[7]  = 32'h0000010B; // rnd x2                (x2 = random)
        mem[8]  = 32'h00B17133; // and x2, x2, x11       (x2 = y scaled, 0-255)
        mem[9]  = 32'h000002B3; // add x5, x0, x0        (x^2 accumulator = 0)
        mem[10] = 32'h00000233; // add x4, x0, x0        (counter = 0)
        // sq1: square x
        mem[11] = 32'h00120863; // beq x4, x1, sq1_done
        mem[12] = 32'h001282B3; // add x5, x5, x1        (x^2 += x1)
        mem[13] = 32'h00120213; // addi x4, x4, 1
        mem[14] = 32'hFF5FF06F; // jal x0, sq1
        // sq1_done:
        mem[15] = 32'h000003B3; // add x7, x0, x0        (y^2 accumulator = 0)
        mem[16] = 32'h00000233; // add x4, x0, x0        (counter = 0)
        // sq2: square y
        mem[17] = 32'h00220863; // beq x4, x2, sq2_done
        mem[18] = 32'h002383B3; // add x7, x7, x2        (y^2 += x2)
        mem[19] = 32'h00120213; // addi x4, x4, 1
        mem[20] = 32'hFF5FF06F; // jal x0, sq2
        // sq2_done:
        mem[21] = 32'h00728433; // add x8, x5, x7        (sum = x^2 + y^2)
        mem[22] = 32'h00150513; // addi x10, x10, 1      (samples += 1, always)
        mem[23] = 32'h00834463; // blt x6, x8, skip_hit  (skip if threshold < sum, i.e. outside circle)
        mem[24] = 32'h00148493; // addi x9, x9, 1        (hits += 1, only if inside circle)
        // skip_hit:
        mem[25] = 32'hFB1FF06F; // jal x0, loop
        for (int i = 26; i < 64; i++) begin
            mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
        end
    end
```
<img width="500" alt="image" src="https://github.com/user-attachments/assets/db72ffdd-5fc8-4cce-9310-b30e35463949" />

Haha. Insanely large waveform. The first sample iteration loop took ~10,000 clock cycles, and EDAPlayground doesn't want to show more than 20,000 clock cycles. Moving forward, I will only stick with FPGA demos for this program because the abundance of data to be displayed on EDA. As I zoom in, the behaviour is working correctly for the one cycle, where it is correctly squared two random numbers between 0 and 255, added them to get 45370, and then correctly determined that the value is less than the threshold of 65025, counting as a hit. Therefore, both the sample count and hit count were incremented.

### Part 1 Reflection Notes
- It felt like a big jump going from my old custom ISA CPU to the official RISC-V ISA because of new instruction types such as branching, upper immediates, and JALR.
- Starting with the top module and control unit first helped me visualize the I/O of the other modules easily.
- New instruction types meant a lot more multiplexers in the top module to select next pc, writeback, operands, and more depending on the control signals.
- A lot of new control signals seemed difficult to track and sometimes a whole new signal was needed for a single instruction.
- One frustrating moment was when I had to implement funct7 extensions for SUB, SRA, and SRAI, since there were more than 8 arithmetic operations, where not only did I have to allow funct3 to only be passed in R and I type instructions, I had to specifically disable funct3 for ADDI so that the immediate value doesn't trigger an unintentional subtract.
- It was difficult implementing byte, half-word, and full word stores and loads because I had to manage offsets if the selected memory address wasn't a factor of 4.
- What helped me to debug these was working was constantly using EDAPlayground and appending register signals to test each individual instructions and making sure the correct control signals and multiplexer results had correct behaviour.

## Part 2: Pipeline architecture and hazard mitigation
This portion of the project is about pipelining my functional single-cycle RISC-V core in order to increase the maximum clock speed. A major issue with my first processor a year back was not only that it was a single-cycle, where each instruction needed to complete the 5 stages before the next instruction but also that heavy instructions such as `MULT` and `DIV` made the worst case propagation delay much longer. I pipelined ScatterV using the following 5-stage RISC-V pipeline model to minimize the worst case propagation delay:

1. **Instruction Fetch (IF):** Fetches the instruction from `instruction_memory`, using `if_pc` as a pointer
2. **Instruction Decode (ID):** Decodes the fetched instruction to pass control signals, generate immediates, and read combinationally read register
3. **Execute (EX):** Combinationally performs arithmetic, branches, jumps, RNG, and flag conditions
4. **Memory Access (MEM):** Sequentially reads or writes the program memory for loads/stores
5. **Write Back (WB):** Writes the final writeback value into a register if register writing is enabled

Here is a good visual that helped me understand the flow of instructions using single-cycle vs pipelining:

<img width="500" alt="image" src="https://github.com/user-attachments/assets/e86e4c30-aaab-4ef0-98cd-d5abffc16312" />

While pipelining has a slight latency when filling and emptying the pipeline, the minimized worst case propagation delay allows for a much higher maximum operating frequency, running programs more efficiently.

### Pipeline Registers
I replaced all the old registers in `top_module` with new completely new register groups that transfer data across stages. Double stage names (e.g., `id_ex`, `ex_mem`, `mem_wb`) represent pipeline registers that use flip-flops to pass data. Single stage names represent internal signal values within each stage, determined by combinational logic or slicing. Here is the new register table:

| Pipeline Stage | Main Registers / Signals |
| :--- | :--- |
| **IF** | `if_pc`, `if_pc_next`, `if_instruction` |
| **IF/ID** | `if_id_pc`, `if_id_instruction` |
| **ID** | `id_rs1`, `id_rs2`, `id_opcode`, `id_rs1_data`, `id_rs2_data`, `id_imm`, `id_control` |
| **ID/EX** | `id_ex_pc`, `id_ex_rs1_data`, `id_ex_rs2_data`, `id_ex_imm`, `id_ex_opcode`, `id_ex_rs1`, `id_ex_rs2`, `id_ex_rd`, `id_ex_funct7`, `id_ex_funct3`, `id_ex_control` |
| **EX** | `ex_alu_result`, `ex_operand1`, `ex_operand2`, `ex_rs1_value`, `ex_rs2_value`, `ex_zero_flag`, `ex_less_than`, `ex_branch_condition_met` |
| **EX/MEM** | `ex_mem_pc`, `ex_mem_alu_result`, `ex_mem_rs2_data`, `ex_mem_imm`, `ex_mem_rd`, `ex_mem_funct3`, `ex_mem_control` |
| **MEM/WB** | `mem_wb_pc`, `mem_wb_alu_result`, `mem_wb_read_data`, `mem_wb_imm`, `mem_wb_rd`, `mem_wb_control` |
| **WB** | `wb_rd_data` |

### Control Signal Optimization
In the pipelined model, I replaced the old system of individual control signals with packed struct passing. Without this, it was too unorganized trying to pass each individual signal through the pipeline register. Grouping the signals together as structs defined in `pipeline_pkg`, importing them to `top_module` and `control_unit`, and then passing the structs down the pipeline made the top module easier to read and debug.

| Struct | Control Members |
| :--- | :--- |
| `id_ex_ctrl_t` | `pc_sel`, `alu_src`, `alu_op`, `auipc_en`, `ram_read`, `ram_write`, `reg_write`, `wb_sel` |
| `ex_mem_ctrl_t` | `ram_read`, `ram_write`, `reg_write`, `wb_sel` |
| `mem_wb_ctrl_t` | `reg_write`, `wb_sel` |

### Data Hazards
When pipelining the processor, overlapping the execution of multiple instructions at once introduces data, control, and structural hazards that cause unexpected behaviour. Here are the 5 main hazards I mitigated:

### EX-to-EX Data 🔴
* An instruction in the EX stage requires an operand calculated by the immediate preceding instruction
  
**Forwarding unit:** For each ID_EX operand, check:
1. `ex_mem_control.reg_write == 1` (Writeback instructions only)
2. `ex_mem_rd != 0` (`NOP` or `x0` targets don't need forwarding)
3. `(ex_mem_rd == id_ex_rs1)' or '(ex_mem_rd == id_ex_rs2)` (The destination register must match a source register)
If all 3 of these conditions are satisfied for an operand, `ex_mem_rd' is routed as the new rs1 or rs2 value for the execution stage, corresponding to the operand with the matched address. Forwarding with minimal stalling allows the processor to keep the pipeline full, therefore bringing CPI (cycles per instruction) closer to its ideal value of 1.

### MEM-to-EX Data 🟡
* An instruction in the EX stage requires an operand calculated two cycles prior, or it follows a back-to-back memory load
  
**Forwarding unit:** For each ID_EX operand, check:
1. `mem_wb_control.reg_write == 1`
2. `ex_mem_rd != 0`
3. `(mem_wb_rd == id_ex_rs1)||mem_wb_rd == id_ex_rs2)`
Similar to EX-EX, if all 3 of these conditions are satisfied for an operand, `mem_wb_rd' is routed as the new rs1 or rs2 value for the execution stage, corresponding to the operand with the matched address.

**Stalling unit (first stall):** check:
1. `id_ex_control.ram_read == 1`
2. `id_ex_rd != 5'b0`
3. `(id_ex_rd == id_rs1)||id_ex_rd == id_rs2)`

**Stalling unit (second stall):** check:
1. `id_ex_control.ram_read == 1`
2. `id_ex_rd != 5'b0`
3. `(id_ex_rd == id_rs1)||id_ex_rd == id_rs2)`
When the stalling flag is raised, it will be up for two cycles. In each cycle, every register in ID/EX is latched to zero and the PC is frozen. After the two cycles, the MEM-EX forwarding unit routes `mem_wb_read_data` as the new rs1 or rs2 value for the execution stage, corresponding to the operand with the matched address. I tried hard to make it so the design only performed a single stall, but changing `data_memory` to be synchronous forced the read data to be ready a cycle later.

### WB-to-ID Data 🟢
* An instruction in the ID stage needs to combinationally read a register value that is currently being updated by an older instruction in the WB stage during the exact same clock cycle. 

Change register writing to trigger on `negedge clk` so that combinational reads in ID have time right after the write to prepare combinational values to be fed into the ID/EX flip-flop for the positive edge.

### Control 🔵
* If a branch or jump is taken, the instructions tagged along (contents in IF and ID) should no longer be in the pipeline.
  
**Flushing unit:** Create a `pipeline_flush` flag that is determined by `id_ex_control.pc_sel`. It will always be raised for `JAL` and `JALR` and raised for `BRANCH` if `ex_branch_condition_met` is true. When the pipeline_flush flag is raised, latch `if_id_instruction` to `32'h00000013` (NOP), `if_id_pc` to 0, and all ID/EX registers to 0. All the contents in IF/ID and ID/EX are successfully cleared, allowing for normal functionality as the new instructions enter the pipeline.

### Structural 🟣
* Two instructions try to read RAM in the same clock cycle when RAM only has one read
This is already solved because ScatterV uses splits memory modules. instruction_memory for instruction fetches, and program_memory for loading and reading

### Testing (pipelined) #1
Here is the program earlier that performs a simple 1+1=2. Load 1 into x1, 1 into x2, add them together and save into x3. End the program by looping PC to never end.

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

<img width="500" alt="image" src="https://github.com/user-attachments/assets/e8e8ce59-e897-40d6-9d51-4760b1ec1756" />

Success! :) Once again, x3 has the value 0x0002 after finishing. It was so reassuring to see that a program can actually run considering how much work I had to put into the new registers, timing, and hazard conditions. Like expected, this program took more clock cycles to run, but it makes sense considering how much efficiency the increased clock speed will provide for longer programs.

### Testing (pipelined) #2
Here is the same second program from earlier that squares a random number between 1 and 8 and stores the value into x3:
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

<img width="700" alt="image" src="https://github.com/user-attachments/assets/523cbb7f-60a8-4af3-8a8a-351891f9e6c8" />

Another success! The random number masked between 0x0007 and the LFSR was 0x0005 (5 in decimal), added by 1, and then was squared to store the value 0x0024 (36 in decimal) into x3. Now I get to move on to synthesizing the FPGA to simulate the monte carlo program.
### Part 2 Reflection Notes
- Pipelining the processor was honestly a lot more fun than part 1, where I had to implement the RISC-V ISA. This was because I got to work with a module structure that was already functional compared to nothing, therefore I was sure of every mistake in the pipelining, where it was a lot easier to track and isolate. Changing each register to its pipelined versions felt like a fun little puzzle, where I had to keep visualizing each different instruction going through the five stages and how the register values should change across the 5 stages.
- The register groups made the top module look a LOT more organized than in single-cycle, as I could now easily select a signal/register based on what stage it's in. When I initially attempted pipelining ScatterV, I would try to stick with only the double stage name registers like id_ex or mem_wb, but I found it to be a lot neater by separating the flip-flop outputs to the double stage names and the combinational outputs to the single stage names.
- I was surprised to find that there were so many different ways I could've designed this. A good example was when I was trying to extract `id_opcode` from the instruction. I could've either latched `if_instruction[6:0]` via a flip-flop to `id_opcode`, or I could've waited for `if_id_instruction` to come out of its flip-flop so that I could combinationally assign `if_id_instruction[6:0]` to `id_opcode`. I discovered that there are different minor benefits and tradeoffs to each approach: additional pipeline register vs more fanout.
- I did have to change the `data_memory` reads to be synchronous instead of asynchronous like in the single-cycle model. While many textbooks on pipelined RISC-V architecture utilize asynchronous reads, synthesis on the FPGA would cause problems as the asynchronous reads would prevent the memory from being inferred as BRAM. RAM would have to be built out of lookup tables (LUT), causing very large combinational paths → lower max clock speed. By making reading synchronous, the RAM can be mapped to the BRAM, leaving more space for LUTs to be used for other combinational logic. Because of this however, RAM read data is ready a clock cycle later, meaning that in the case of a load use hazard, an extra stall cycle on top of the first one is needed wait for the data to be read and forwarded. In future processor projects, I plan to find ways to mitigate the two cycle stall problem.
- At times it got a little confusing when I added the mem stage name registers because some of my control signals also started with "mem". For more than half this part of the project, I kept getting confused by the names, so I just renamed the control signals to be less ambiguous. For example, I changed the signal name of "mem_read" to "ram_read".
- To be honest, I feel like I didn't need the packed structs because I passed down each individual member of the struct anyway down the pipeline registers anyway, so I feel that I could've just used a bit-mapped vector to be more organized. Overall though it was nice learning how to define packed structs and how to import them into other files.
---

## Part 3: FPGA Deployment
Now that I had a fully functional pipelined processor, the last goal was to deploy the design onto FPGA and then use its peripherals to showcase program functionality. I used the RealDigital Boolean Board, which features the Xilinx Spartan-7 (xc7s50csga324-1), with [Vivado 2025.2](https://www.amd.com/en/support/downloads/adaptive-socs-and-fpgas/development-tools/2025-2.html):

<img width="400" alt="image" src="https://github.com/user-attachments/assets/64426395-34fc-4b6d-bfcd-862ac77036a9" />

### I/O constraints and Hardware Mapping
I used RealDigital's official [Boolean Board Constraint File](https://www.realdigital.org/hardware/boolean) to map the board's peripherals to the top module of my design.

I rerouted the original `rst` input in the top_module to a button and added a button that freezes the program counter:
- `btn[0]`: Assigned to `rst`
- `btn[1]`: Disables writes to `if_pc`

To display register data in decimal, I mapped output pins to drive the two 7-segment displays:
- `D0_AN[3:0]` and  `D1_AN[3:0]` choose which digits to rewrite (rewrites if bit is 0)
- `D0_SEG[7:0]` and  `D1_SEG[7:0]` lights up segments of selected digits (lights if bit is 0)

### Decoder Module and Software Clock
Since the 7-segment displays share segment lines across all digits, different numbers cannot be displayed without multiplexing. My solution to this was creating the `segment_decoder` module, which takes a decimal digit and then converts it into 8 bits corresponding to each segment with the correct lighting arrangement. 

Since the 7-segment display needs time to light up due to the nature of transistors, I had to slow down the switching speed of the LEDs. I did this by creating a software clock from a 100 MHz hardware clock that runs a tick every 16,384 cycles for a refresh rate of 763 Hz. The display is fast enough that the human eye cannot see the flickering and not too fast to the point the transistor can't switch. The software clock selects a different digit to write every software tick via a 3-to-8 decoder.

### Implementation Flow
Now that my constraints and I/O was properly configured, I just had to program device by running these 3 processes:
- Synthesis: Translate SystemVerilog into logic gates
- Implementation: Route the design by mapping into LUTs and BRAM
- Bitstream Generation: Converts full physical image and logic into a binary configuration file
After these, I clicked "Program Device", finally programming my FPGA board

### Final Demo
Just like in part 1, I ran the Monte Carlo program or the demo, but with the FPGA this time. I also mapped the decimal digits of registers x9 and x10 to the 7-segment display to display the sample counter on the left and the hit counter on the right. Upon reaching this part of the project and finally being able to simulate multiple iterations of plotted points, I had to make changes to the demo program:
- Changed to a 12 bit coordinate resolution instead of 8 to approximate much closer to π rather than 3.13
- Changed Y coordinate to be completely independent of X by shifting the LFSR to the right by 12 bits
   - This was a major problem before as Y would previously always be dependent on X since the repeated `RND` instruction was two clock cycles after the X, meaning Y was just X, but shifted to the left twice, varying up to 3
- Created a clock burner subroutine that wastes 66,666 cycles before branching back to `loop` so that simulation is easier to view

```systemverilog
initial begin
        mem[0]  = 32'h00FFE337; // lui x6, 4094         
        mem[1]  = 32'h00130313; // addi x6, x6, 1         x6 = threshold = 4095^2 = 16,769,025
        mem[2]  = 32'h000015B7; // lui x11, 1             x11 = 4096
        mem[3]  = 32'hFFF58593; // addi x11, x11, -1      x11 = 4095 = 0xFFF mask
        mem[4]  = 32'h000004B3; // add x9, x0, x0         hits = 0
        mem[5]  = 32'h00000533; // add x10, x0, x0        samples = 0
        // loop:
        mem[6]  = 32'h0000008B; // rnd x1                 x1 = rng
        mem[7]  = 32'h00C0D113; // srli x2, x1, 12        x2 = x1 >> 12, fresh bits new bits for y coor
        mem[8]  = 32'h00B0F0B3; // and x1, x1, x11        x1 = x coor, 0-4095, bits [11:0]
        mem[9]  = 32'h00B17133; // and x2, x2, x11        x2 = y coor, 0-4095, bits [23:12]
        mem[10] = 32'h000002B3; // add x5, x0, x0         x^2 sum = 0
        mem[11] = 32'h00000233; // add x4, x0, x0         counter = 0
        // sq1: square x
        mem[12] = 32'h00120863; // beq x4, x1, sq1_done
        mem[13] = 32'h001282B3; // add x5, x5, x1         x^2 += x1
        mem[14] = 32'h00120213; // addi x4, x4, 1
        mem[15] = 32'hFF5FF06F; // jal x0, sq1
        // sq1_done:
        mem[16] = 32'h000003B3; // add x7, x0, x0         y^2 sum = 0
        mem[17] = 32'h00000233; // add x4, x0, x0         counter = 0
        // sq2: square y
        mem[18] = 32'h00220863; // beq x4, x2, sq2_done
        mem[19] = 32'h002383B3; // add x7, x7, x2         y^2 += x2
        mem[20] = 32'h00120213; // addi x4, x4, 1
        mem[21] = 32'hFF5FF06F; // jal x0, sq2
        // sq2_done:
        mem[22] = 32'h00728433; // add x8, x5, x7         sum = x^2 + y^2
        mem[23] = 32'h00150513; // addi x10, x10, 1       samples += 1, always
        mem[24] = 32'h00834463; // blt x6, x8, skip_hit   skip if threshold < sum
        mem[25] = 32'h00148493; // addi x9, x9, 1         hits += 1 if inside circle
    
        // delay = 66,666 cycles (~1 sec @ 100 MHz)
        mem[26] = 32'h00010637; // lui  x12, 0x10
        mem[27] = 32'h46A60613; // addi x12, x12, 1130
    
        // delay loop:
        mem[28] = 32'hFFF60613; // addi x12, x12, -1
        mem[29] = 32'hFE061EE3; // bne  x12, x0, delay loop
    
        // return to Monte Carlo loop
        mem[30] = 32'hFA1FF06F; // jal x0, loop
    end
```
Again, here is the successful demo video:

<p align="center">
  <a href="https://www.youtube.com/watch?v=04T320I4pu4">
    <img src="https://github.com/user-attachments/assets/0c46638d-2549-4b72-9456-93bbb868283e" alt="ScatterV 5-Stage RISC-V: Monte Carlo π Approximation on FPGA" width="70%">
  </a>
</p>

### Performance Comparison
To evaluate the performance gains of the new pipelined design compared to the previous single-cycle design. Using a targetted clock speed of **100 MHz (10 ns period)**, I ran timing analysis in Vivado to find the worst negative slack (WNS) value to calculate the max clock frequency ($F_{\text{max}}$) of each model:

$$
F_{\text{max}} = \frac{1}{T_{\text{target}} - \text{WNS}}
$$

| Design Version | Slack (WNS) | Max Speed ($F_{\text{max}}$) |
| :--- | :--- | :--- |
| **Single-Cycle** | `[Insert, e.g., -8.50 ns]` | **`[Insert, e.g., 54.05 MHz]`** |
| **Pipelined** | `[Insert, e.g., +2.10 ns]` | **`[Insert, e.g., 126.58 MHz]`** |

Makes sense considering how the single-cycle processor has a way longer worst propagation path compared to the pipelined processor.
### Part 3 Reflection Notes
- Despite the thrill of successfully approximating π to three decimal digits, this part of the project didn't come without its frustrations. To be honest, this part of the project was overall frustrating, especially when I added Vivado to the project environment.
- When I opened Vivado, I quickly felt overwhelmed as it seemed like nonstop settings and configurations were just blasted at my face. There were so many configurations that I was scared of turning on or not turning on, fearing that it would possibly ruin the programming process of the FPGA.
- For a whole straight two hours, I found out that the reason my design wasn't implementing was because I chose the board, "AMD Spartan-7 SP701 FPGA Evaluation Platform" and not the part, "xc7s50csga324-1". Before that I was doing literally everything like changing clock speed, remapping the top module peripheral I/O, deleting constraints, and basically double checking every module for possible errors
- Another painfully long bug that took me 2 whole days to fix was that once I got the part name correct, the program kept approximating to ≈ 3.08 rather than 3.141592. I tried changing the clock speed again, simulating a full circle rather than quarter, changing the clock burner delay, even changing case statements for the digit printing. Eventually I found that the problem like mentioned in the demo changes above was that Y was dependent on X as it was the same value but shifted to the left by two with a possible difference of 3. After changing the resolution from 8 to 12 bits and shifting the LFSR by 12 bits to the right, the demo was finally fixed.

## Final Reflection
- Overall, this project was an amazing experience. I got to expand my knowledge of industry ISAs to cover vastly new types of instructions, implement the abstract theory of hardware randomization into my programs, pipeline my processor with hazard detection, and deploy my design onto an FPGA - all with no prior knowledge. It is honestly amazing how far I have come compared to when I first started learning Verilog.
- There were many roadblocks and frustrations along each part, the experience and skills I gained in computer architecture is something that will stick with me forever.
- There were overall many fun things about the project like creating the logic for certain RISC-V instructions, replacing all the old registers with pipelined registers, and having successful demos
- There were also many not so fun parts, like bit padding the load instructions, changing program memory to be synchronous, and configuring Vivado
- If I could do one main thing differently for a future digital design project, it would be to become more reliant on SVAs and UVM than the waveform, as more complex systems become involved such as OOP or AI processors, the waveform will become near-impossible to read.
- My next plan is to use the FPGA board to create a VGA rhythm game (stepmania) clone, using off chip memory interfacing to play stored audio and connecting a keyboard via PS/2 as an input device.
---
