**Name:** Ethan Lee  
**Education:** University of Illinois Urbana-Champaign  
**Major:** Computer Engineering  
**Graduation Date:** May 2028

March 31, 2026

# ScatterV
ScatterV is a **custom pipelined RISC-V processor** implemented in SystemVerilog and **synthesized on FPGA**. It features standard functionality of a RISC-V processor and **includes a custom instruction**, `RND`, which loads a pseudorandom number into a register using a linear feedback shift register (LFSR) to produce maximal-length sequences. I wanted to explore hardware level random number generation for its applications in cryptography, simulations, and randomized algorithms.

This repository builds upon my previous work, [learningVerilog](https://github.com/LeeT27/learningVerilog), where I created a simple, single cycle processor to execute basic ALU, loads, stores, and jumps. ScatterV improves upon this through RISC-V compatibility, new complex instructions, pipelining, hazard detection, and hardware simulation. I seperated the project into three major parts/milestones:
1. Single cycle RISC-V core and RNG implementation
2. Pipeline architecture and hazard mitigation
3. Hardware synthesis and FPGA demo
   
---

## Features
- **Instruction Set:** RV32I base instructions — R, I, U, S, B, J types
- **Custom `RND` instruction:** Writes a pseudorandom number that changes every clock cycle with 32-bit LSFR to register
- **Pipelined Architecture:** Multi stage execution for maximum clock speeds — IF→ID→EX→MEM→WB
- **Hazard Protection:** Hazard protection using forwarding, stalling, flushing, and split memory
- **FPGA Deployment:** Deployed on Spartan-7 FPGA with Vivado's toolchain (synthesis, implementation, bitstream generation)  
- **Display Output:** Seven-segment display peripheral displays register values for demos
- **Demo:** Assembly program that utilizes the new `RND` instruction on FPGA, recorded on video

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
## Demo Program: Monte Carlo π Approximation

To verify correct processor behavior, I implemented a Monte Carlo simulation written entirely in RISC-V assembly that estimates π as the sample size converges to ∞. The main star of the show in this simulation is the custom `RND` instruction that constantly creates pseudorandom coordinates to be used in branch calculations to determine a hit or miss.

### Mathematical Principle
The program approximates π by generating random coordinate points $(x, y)$ within a square area bounded by (0,0) and (1,1) every tenth of a second and determining the ratio of points that fall inside the shaded quarter circle, calculated using the following circle equation:

$$x^2 + y^2 \le 1$$

<div align="center">
  <img src="https://github.com/user-attachments/assets/855c08f7-7e33-4f49-b01e-93e95c569be3" width="200px" alt="Monte Carlo">
</div>
<br><br>
An internal "hits" counter is incremented everytime it lands inside the quarter circle and a total "samples counter" is incremented everytime, independent of where it lands. The approximation of π is found through the ratio of points:

$$\pi \approx 4 \times \frac{\text{hits}}{\text{total samples}}$$

The ratio will converge to π as the sample size approaches ∞. For the sake of hardware, I stuck to displaying only hits and sample count on FPGA so that decimals don't need to be calculated. Here is the video demo of the working proccesor and program:

[https://img.youtube.com/vi/kfW94tNMFkA/0.jpg](https://upload.wikimedia.org/wikipedia/commons/0/0b/RedDot_Burger.jpg)

---
## Architecture Overview (Pipelined)

| Module Name | Key Functionality |
| :--- | :--- |
| `top_module` | Contains struct definitions, signal declaration, multiplexing, pipelining logic, hazard units, and all the submodule instantiation |
| `program_counter` | Sets next instruction address |
| `instruction_memory`| Stores pre-loaded executable test program |
| `control_unit` | Parses opcode and generate control signals |
| `immediate_generator`| Parses opcode to formats and extend immediate values |
| `register_file` | Holds 32 register bank with synchronous writes and asynchronous reads |
| `program_memory` | Holds 4 KB RAM with supporting `lb`, `lh`, `lw`, `sb`, `sh`, and `sw` operations |
| `alu` | Performs arithmetic, logic, shifts, RNG, flag conditions |
| `tb` | Contains basic testbench with reset + clock |

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

## Part 1: Single cycle RISC-V core and RNG implementation
When I finished designing my very [first processor](https://github.com/LeeT27/learningVerilog) around a year ago, I felt very thrilled that I created a custom ISA CPU that could perform simple arithmetic programs. Reflecting, I realized that my ISA was inefficient, slow, and lacking in instructions. I wanted to try again as I felt more inspired to take on more industry level processors such as RISC-V, while also tackling pipeline theory. I chose RISC-V for its popularity in IoT, embedded systems, and operating systems. Finding that RISC-V is easily modifiable, I also wanted to create a custom instruction, `RND`, that could be used for demonstration because I found its real world applications to be amusing. Here is the theory behind hardware RNG:

### 🎲 `RND` Instruction Implementation
The core of ScatterV's random number generation comes from the abstract algebra theory of primitive polynomials and its application on a linear feedback shift register (LFSR). To make sequences appear as random as possible every clock cycle, the amount of unique sequences before repeating the same pattern needs to be maximized. This is where the magic of primitive polynomials comes in. A primitive polynomial is a special type of irreducible polynomial, meaning that it cannot be factored into smaller polynomials. Another property is that a primitive polynomial of degree n has $(2^{n}-1)$ unique states before repeating to its old pattern (base will be 2 for digital logic). A good analogy is that if you have a deck of 52 cards, the shuffling mechanism of a primitive polynomial would go through all 52 cards before repeating the pattern rather than a smaller pattern of cycling through the same 8 cards. Here below is an example of a primitive polynomial of degree n = 3: 

### $x^{3} + x + 1$

($2^{3}-1 = 7$ unique states before repeating pattern)

To implement this theory into ScatterV, I used an LFSR to utilize primitive polynomials. An LFSR consists of a chain of flip flops that use the output of an arbitrary amount of chosen flip flops to determine the next incoming bit. The powers of the polynomial $x$ serve as a direct mapping to the register's state. Specifically, each term $x^n$ corresponds to the output of the $n^{th}$ flip-flop within the shift register chain. To maintain the mathematical identity of the primitive polynomial: $x^{3}$+x+1=0, the hardware must keep solving for the constant term. By XORing the $x^{3}$ and x term, we generate the feedback bit 1, thus constantly balancing the equation. All flip flop bits perform a left bitwise shift and the feedback bit is fed into the LSB. Every clock cycle now generates a unique pattern! Here is a diagram I made of the flip flops for n = 3:

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
### Testing #1
For testing throughout this project, I just used a general testbench that outputs a reset and clock. Most of the verification when creating this is waveform analysis. Here is a program that performs a simple 1+1=2. Load 1 into x1, 1 into x2, add them together and save into x3. End the program by looping PC to never end.

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

It worked! :) x3 successfully has the value 0x0002 at the end of the program. I forgot to append the LSFR signal, but the register is correctly outputting pseudorandom numbers every clock cycle.

### Testing #2
Here is a second program that squares a random number between 1 and 8 and stores the value into x3
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
<img width="1000" alt="image" src="https://github.com/user-attachments/assets/db72ffdd-5fc8-4cce-9310-b30e35463949" />

Haha. Insanely large waveform. The first sample iteration loop took ~10,000 clock cycles, and EDAPlayground doesn't want to show more than 20,000 clock cycles. Moving forward, I will only stick with FPGA demos for this program because the abundance of data to be displayed on EDA. As I zoom in, the behaviour is working correctly for the one cycle, where it is correctly squared two random numbers between 0 and 255, added them to get 45370, and then correctly determined that the value is less than the threshold of 65025, counting as a hit. Therefore, both the sample count and hit count were incremented.

### Part 1 Reflection Notes
- It felt like a big jump going from my old custom ISA CPU to the official RISC-V ISA because of new instruction types such as branching, upper intermediates, and JALR
- Starting with the top module and control unit first helped me visualize the I/O of the other modules easily
- New instruction types meant a lot more multiplexers in the top module to select next pc, writeback, operands, and more depending on the control signals
- A lot of new control signals seemed difficult to track and sometimes a whole new signal was needed for a single instruction
- One frustrating moment was when I had to implement funct7 extensions for SUB, SRA, and SRAI, since there were more than 8 arithmetic operations, where not only did I have to allow func3 to only be passed in R and I type instructions, I had to specifically disable funct3 for ADDI so that the immediate value doesn't trigger an unintentional subtract.
- It was difficult implementing byte, half word, and full word stores and loads because I had to manage offsets if the selected memory address wasn't a factor of 4
- What helped me to debug these was working was constantly using EDAPlayground and appending register signals to test each individual instructions and making sure the correct control signals and multiplexer results had correct behaviour

## Part 2: Pipeline architecture and hazard mitigation
This portion of the project is about pipelining my functional single cycle RISC-V core in order to increase the maximum clock speed. A major issue with my first processor a year back was not only that it was a single cycle, where each instruction needed to complete the 5 stages before the next instruction but also that heavy instructions such as `MULT` and `DIV` made the worst case propagation delay much longer. I pipelined scatterV using the following 5-stage RISC-V pipeline model to minimize the worst case propagation delay:

1. **Instruction Fetch (IF):** Fetches the instruction from `instruction_memory`, using `if_pc` as a pointer
2. **Instruction Decode (ID):** Decodes the fetched instruction to pass control signals, generate immediates, and read combinationally read register
3. **Execute (EX):** Combinationally performs arithmetic, branches, jumps, RNG, and flag conditions
4. **Memory Access (MEM):** Sequentially reads or writes the program memory for loads/stores
5. **Write Back (WB):** Writes the final writeback value into a register if register writing is enabled

Here is a good visual that helped me understand the flow of instructions using single-cycle vs pipelining:

<img width="500" alt="image" src="https://github.com/user-attachments/assets/e86e4c30-aaab-4ef0-98cd-d5abffc16312" />

While pipelining has a slight latency when filling and emptying the pipeline, the minimized worst case propagation delay allows for a much higher maximum operating frequency, running programs more efficiently.

### Pipeline Registers
I replaced all the old registers in `top_module` with new completely new register groups that transfer data across stages. Double stage names (e.g., `id_ex`, `ex_mem`, `mem_wb`) represent pipeline registers that use flip-flops to pass data. Single stage names represent internal signal values within each stage, determined by combinational logic. Here is the new register table:

| Pipeline Stage | Main Registers / Signals |
| :--- | :--- |
| **IF** | `if_pc`, `if_pc_next`, `if_instruction` |
| **IF/ID** | `if_id_pc`, `if_id_instruction` |
| **ID** | `id_rs1`, `id_rs2`, `id_opcode`, `id_rs1_data`, `id_rs2_data`, `id_imm`, `id_control` |
| **ID/EX** | `id_ex_pc`, `id_ex_rs1_data`, `id_ex_rs2_data`, `id_ex_imm`, `id_ex_opcode`, `id_ex_rs1`, `id_ex_rs2`, `id_ex_rd`, `id_ex_funct7`, `id_ex_funct3`, `id_ex_control` |
| **EX** | `ex_alu_result`, `ex_operand1`, `ex_operand2`, `ex_rs1_value`, `ex_rs2_value`, `ex_zero_flag`, `ex_less_than`, `ex_branch_condition_met` |
| **EX/MEM** | `ex_mem_pc`, `ex_mem_alu_result`, `ex_mem_rs2_data`, `ex_mem_imm`, `ex_mem_rd`, `ex_mem_funct3`, `ex_mem_control` |
| **MEM** | `ex_mem_ram_read_en`, `ex_mem_ram_write_en`, `mem_wb_read_data` |
| **MEM/WB** | `mem_wb_pc`, `mem_wb_alu_result`, `mem_wb_read_data`, `mem_wb_imm`, `mem_wb_rd`, `mem_wb_control` |
| **WB** | `wb_rd_data`, `mem_wb_reg_write_en` |

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
3. `(ex_mem_rd == id_ex_rs1)' or '(ex_mem_rd == id_ex_rs2)` (The destination register must match a source register)
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
2. `(mem_wb_rd == id_ex_rs1)||mem_wb_rd == id_ex_rs2)`

### 🟢 WB-to-ID Data (Register File Hazard)
* **The Hazard:** An instruction in the **ID stage** needs to combinationally read a register value that is currently being updated by an older instruction in the **WB stage** during the exact same clock cycle. 
* **Solution:** Half-cycle clocking (Falling-edge write) or Internal Register Bypass

**Option A: Falling-Edge Write Unit (The Structural Trick)**
Modify the Register File clocking architecture:
1. Force the Register File write logic to trigger strictly on `negedge clk`.

### 🔵 Control
* **The Hazard:** If a branch or jump is taken, the instructions tagged along after that instruction (contents in **IF** and **ID** stages) should no longer be in the pipeline.
* **Solution:** Flushing unit
  
**Flushing unit:** Perform a flush signal on the next clock edge that sets if_id_instruction to `32'h00000013` (NOP) and id_ex_control to `32'h00000000`, essential eliminating the upcoming instructions in the pipeline

### 🟣 Structural
* **The Hazard:** Two instructions try to read RAM in the same clock cycle when RAM only has one read (instruction fetch paired with load instruction).
* **Solution:** This is already solved because ScatterV uses splits memory modules. instruction_memory for instruction fetches, and program_memory for loading and reading

### Testing #1
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

<img width="700" alt="image" src="https://github.com/user-attachments/assets/e8e8ce59-e897-40d6-9d51-4760b1ec1756" />


Success! :) Once again, x3 has the value 0x0002 after finishing. It was so reassuring to see that a program can actually run considering how much work I had to put into the new registers, timing, and hazard conditions. Like expected, this program took more clock cycles to run, but it makes sense considering how much efficiency the increased clock speed will provide for longer programs.
### Part 2 Reflection Notes


---

## Part 3: Hardware synthesis and FPGA demo

## Overall Reflection

---
