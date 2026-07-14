module instruction_memory (
    input  logic [31:0] if_pc,
    output logic [31:0] if_instruction
);
    logic [31:0] mem [0:63];

    initial begin
        mem[0]  = 32'h00FFE337; // lui x6, 4094         
        mem[1]  = 32'h00130313; // addi x6, x6, 1         x6 = threshold = 4095^2 = 16,769,025
        mem[2]  = 32'h000015B7; // lui x11, 1             x11 = 4096)
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

    assign if_instruction = mem[if_pc[7:2]];
endmodule
