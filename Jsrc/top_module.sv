package pipeline_pkg;

    typedef struct packed {
        logic [1:0] pc_sel;     // needed in EX, 00 PC + 4, 01 jal_en (PC + imm), 10 branch_en (PC + imm), 11 jalr_en (rs1 + imm)
        logic       alu_src;    // needed in EX, rs2 vs immediate for operand2
        logic [1:0] alu_op;     // needed in EX, 00 add, 01 subtract, 10 Normal, 11 RND
        logic       auipc_en;   // needed in EX, Set operand1 to PC
        logic       ram_read;   // needed in MEM
        logic       ram_write;  // needed in MEM
        logic       reg_write;  // needed in WB
        logic [1:0] wb_sel;     // needed in WB, 00 alu_result (ADD SUB), 01 data (LOAD), 10 pc + 4 (JAL JALR), 11 immediate_out (LUI)
    } id_ex_ctrl_t;

    typedef struct packed {
        logic       ram_read;   // needed in MEM
        logic       ram_write;  // needed in MEM
        logic       reg_write;  // needed in WB
        logic [1:0] wb_sel;     // needed in WB
    } ex_mem_ctrl_t;

    typedef struct packed {
        logic       reg_write;  // needed in WB
        logic [1:0] wb_sel;     // needed in WB
    } mem_wb_ctrl_t;

endpackage

import pipeline_pkg::*;

module top_module (
    input  logic clk,
    input  logic [1:0] btn,

    output logic [3:0] D0_AN,
    output logic [7:0] D0_SEG,

    output logic [3:0] D1_AN,
    output logic [7:0] D1_SEG
);  
    //IO
    logic rst;
    assign rst = btn[0];
    assign freeze = btn[1];
    
    logic [31:0] x9_out;
    logic [31:0] x10_out;
    logic [3:0] hit_d0, hit_d1, hit_d2, hit_d3;
    logic [3:0] sample_d0, sample_d1, sample_d2, sample_d3;
    logic [3:0] current_sample_digit;
    logic [3:0] current_hit_digit;
    logic [2:0] scan_counter;
    logic [16:0] refresh_counter;
    assign hit_d0 = x9_out % 10;
    assign hit_d1 = (x9_out / 10) % 10;
    assign hit_d2 = (x9_out / 100) % 10;
    assign hit_d3 = (x9_out / 1000) % 10;
    assign sample_d0 = x10_out % 10;
    assign sample_d1 = (x10_out / 10) % 10;
    assign sample_d2 = (x10_out / 100) % 10;
    assign sample_d3 = (x10_out / 1000) % 10;
    
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    
    assign scan_counter = refresh_counter[16:14];
    
    always_comb begin
    D0_AN = 4'b1111;
    D1_AN = 4'b1111;
    current_sample_digit = 4'd0;
    current_hit_digit = 4'd0;

    case(scan_counter)
        3'd0: begin
            current_sample_digit = sample_d0;
            D0_AN = 4'b1110;
        end
    
        3'd1: begin
            current_sample_digit = (x10_out < 10)   ? 4'd15 : sample_d1;
            D0_AN = 4'b1101;
        end
    
        3'd2: begin
            current_sample_digit = (x10_out < 100)  ? 4'd15 : sample_d2;
            D0_AN = 4'b1011;
        end
    
        3'd3: begin
            current_sample_digit = (x10_out < 1000) ? 4'd15 : sample_d3;
            D0_AN = 4'b0111;
        end
    
        // hits display (D1)
        3'd4: begin
            current_hit_digit = hit_d0;
            D1_AN = 4'b1110;
        end
    
        3'd5: begin
            current_hit_digit = (x9_out < 10)   ? 4'd15 : hit_d1;
            D1_AN = 4'b1101;
        end
    
        3'd6: begin
            current_hit_digit = (x9_out < 100)  ? 4'd15 : hit_d2;
            D1_AN = 4'b1011;
        end
    
        3'd7: begin
            current_hit_digit = (x9_out < 1000) ? 4'd15 : hit_d3;
            D1_AN = 4'b0111;
        end
    endcase
end
    // GLOBAL
    logic [1:0] forward_a;
    logic [1:0] forward_b;
    logic hazard_stall;
    logic pipeline_flush;

    // IF declaration
    logic [31:0] if_pc;
    logic [31:0] if_pc_next;
    logic [31:0] if_instruction;

    // IF/ID declaration
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instruction;
    // ID declaration
    logic [4:0]  id_rs1;
    logic [4:0]  id_rs2;
    logic [6:0]  id_opcode;
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [31:0] id_imm;
    id_ex_ctrl_t id_control; // Multiplexed from opcode case statements

    // ID/EX declaration
    logic [31:0] id_ex_pc;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;
    logic [6:0]  id_ex_opcode;
    logic [4:0]  id_ex_rs1;
    logic [4:0]  id_ex_rs2;
    logic [4:0]  id_ex_rd;
    logic [6:0]  id_ex_funct7;
    logic [2:0]  id_ex_funct3;
    id_ex_ctrl_t id_ex_control;
    logic [1:0]  id_ex_alu_op; // Extra wire for passing struct data through port
    // EX declaration
    logic [31:0] ex_alu_result;
    logic [31:0] ex_operand1;
    logic [31:0] ex_operand2;
    logic [31:0] ex_rs1_value; //Multiplexer middleman for forwarding
    logic [31:0] ex_rs2_value; //Multiplexer middleman for forwarding
    logic ex_zero_flag;
    logic ex_less_than;
    logic ex_branch_condition_met;

    // EX/MEM declaration
    logic [31:0]  ex_mem_pc;
    logic [31:0]  ex_mem_alu_result;
    logic [31:0]  ex_mem_rs2_data;
    logic [31:0]  ex_mem_imm;
    logic [4:0]   ex_mem_rd;
    logic [2:0]   ex_mem_funct3;
    ex_mem_ctrl_t ex_mem_control;
    logic ex_mem_ram_read_en; // Extra wire for passing struct data through port
    logic ex_mem_ram_write_en; // Extra wire for passing struct data through port

    // MEM/WB declaration
    logic [31:0]  mem_wb_pc;
    logic [31:0]  mem_wb_alu_result;
    logic [31:0]  mem_wb_read_data; // From data memory read
    logic [31:0]  mem_wb_imm;
    logic [4:0]   mem_wb_rd;
    mem_wb_ctrl_t mem_wb_control;
    logic mem_wb_reg_write_en; // Extra wire for passing struct data through port
    // WB declaration
    logic [31:0] wb_rd_data;

    // Extra wires so that I don't have to pass struct data directly through port
    assign mem_wb_reg_write_en = mem_wb_control.reg_write;
    assign ex_mem_ram_read_en  = ex_mem_control.ram_read;
    assign ex_mem_ram_write_en = ex_mem_control.ram_write;
    assign id_ex_alu_op = id_ex_control.alu_op;


    assign id_rs2 = if_id_instruction[24:20];  // Needed early for load hazard detection
    assign id_rs1 = if_id_instruction[19:15];  // Needed early for load hazard detection
    assign id_opcode = if_id_instruction[6:0];

    // Selection of writeback data
    assign wb_rd_data =
        (mem_wb_control.wb_sel == 2'b00) ? mem_wb_alu_result :
        (mem_wb_control.wb_sel == 2'b01) ? mem_wb_read_data :
        (mem_wb_control.wb_sel == 2'b10) ? mem_wb_pc + 4 :
        (mem_wb_control.wb_sel == 2'b11) ? mem_wb_imm :
        32'b0; // load alu_result (ADD SUB), data (LOAD), pc + 4 (JAL JALR), or immediate_out (LUI)
    
    // Next PC selection
    always_comb begin
        case (id_ex_control.pc_sel)
            2'b00: if_pc_next = if_pc + 4; //NORMAL
            2'b01: if_pc_next = id_ex_pc + id_ex_imm; // JAL
            2'b10: begin //BRANCH
                if (ex_branch_condition_met)
                    if_pc_next = id_ex_pc + id_ex_imm;
                else
                    if_pc_next = if_pc + 4;
            end
            2'b11: if_pc_next = (ex_rs1_value + id_ex_imm) & ~32'h1; // JALR alignment
            default: if_pc_next = if_pc + 4;
        endcase
    end

    // Forwarding unit rs1
    always_comb begin
        forward_a = 2'b00;

        // EX to EX
        if (ex_mem_control.reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end
        // MEM to EX
        else if (mem_wb_control.reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
    end

    // Forwarding unit rs2
    always_comb begin
        forward_b = 2'b00;

        // EX to EX
        if (ex_mem_control.reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
        // MEM to EX
        else if (mem_wb_control.reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end
    end

    // Stalling flag
    always_comb begin
        hazard_stall = 1'b0;

        // First stall
        if (id_ex_control.ram_read && (id_ex_rd != 5'b0) && ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2))) begin
            hazard_stall = 1'b1;
        end

        // Second stall
        else if (ex_mem_control.ram_read && (ex_mem_rd != 5'b0) && ((ex_mem_rd == id_rs1) || (ex_mem_rd == id_rs2))) begin
            hazard_stall = 1'b1;
        end
    end

    // Flush flag
    always_comb begin
        pipeline_flush = 1'b0; 
        
        case (id_ex_control.pc_sel)
            2'b01:   pipeline_flush = 1'b1; // JAL
            2'b11:   pipeline_flush = 1'b1; // JALR
            2'b10:   pipeline_flush = ex_branch_condition_met; // BRANCH
            default: pipeline_flush = 1'b0; // Normal
        endcase
    end

    // MUX for choosing correct rs1 data
    always_comb begin
        case (forward_a)
            2'b01:   ex_rs1_value = ex_mem_alu_result;
            2'b10:   ex_rs1_value = wb_rd_data;
            default: ex_rs1_value = id_ex_rs1_data;
        endcase
    end

    // MUX for choosing correct rs2 data
    always_comb begin
        case (forward_b)
            2'b01:   ex_rs2_value = ex_mem_alu_result;
            2'b10:   ex_rs2_value = wb_rd_data;
            default: ex_rs2_value = id_ex_rs2_data;
        endcase
    end

    // Operand selection
    assign ex_operand1 = id_ex_control.auipc_en ? id_ex_pc : ex_rs1_value; //pc for AUIPC, otherwise it'll rs1
    assign ex_operand2 = id_ex_control.alu_src ? id_ex_imm : ex_rs2_value; //rs2 or immediate into ALU calculation

    // IF/ID flip flops
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc          <= 32'b0;
            if_id_instruction <= 32'h00000013;
        end
        else if (pipeline_flush) begin 
            // Flush ID/EX
            if_id_pc          <= 32'b0;
            if_id_instruction <= 32'h00000013; // Inject NOP
        end
        else if (!hazard_stall) begin
            if_id_pc          <= if_pc; // From program counter
            if_id_instruction <= if_instruction; // From instruction memory
        end
    end

    // ID/EX flip flops
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_pc         <= 32'b0;
            id_ex_rs1_data   <= 32'b0;
            id_ex_rs2_data   <= 32'b0;
            id_ex_opcode     <= 7'b0;
            id_ex_imm        <= 32'b0;
            id_ex_rs1        <= 5'b0;
            id_ex_rs2        <= 5'b0;
            id_ex_rd         <= 5'b0;
            id_ex_funct7     <= 7'b0;
            id_ex_funct3     <= 3'b0;
            id_ex_control    <= '0;
        end
        else if (hazard_stall || pipeline_flush) begin
            // NOP injected for load stall or flushing
            id_ex_pc         <= 32'b0;
            id_ex_rs1_data   <= 32'b0;
            id_ex_rs2_data   <= 32'b0;
            id_ex_opcode     <= 7'b0;
            id_ex_imm        <= 32'b0;
            id_ex_rs1        <= 5'b0;
            id_ex_rs2        <= 5'b0;
            id_ex_rd         <= 5'b0;
            id_ex_funct7     <= 7'b0;
            id_ex_funct3     <= 3'b0;
            id_ex_control    <= '0;
        end
        else begin
            id_ex_pc         <= if_id_pc;
            id_ex_rs1_data   <= id_rs1_data; // From register file
            id_ex_rs2_data   <= id_rs2_data; // From register file
            id_ex_opcode     <= id_opcode;
            id_ex_imm        <= id_imm;  // From immediate generator
            id_ex_rs1        <= id_rs1;
            id_ex_rs2        <= id_rs2;
            id_ex_rd         <= if_id_instruction[11:7];
            id_ex_funct7     <= if_id_instruction[31:25];
            id_ex_funct3     <= if_id_instruction[14:12];
            id_ex_control    <= id_control; // From control unit
        end
    end

    // EX/MEM flip flops
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_pc         <= 32'b0;
            ex_mem_alu_result <= 32'b0;
            ex_mem_rs2_data   <= 32'b0;
            ex_mem_imm        <= 32'b0;
            ex_mem_rd         <= 5'b0;
            ex_mem_funct3     <= 3'b0;
            ex_mem_control    <= '0;
        end
        else begin
            ex_mem_pc         <= id_ex_pc;
            ex_mem_alu_result <= ex_alu_result; // From alu
            ex_mem_rs2_data   <= ex_rs2_value; // Maintain possible forwarded value
            ex_mem_imm        <= id_ex_imm;
            ex_mem_rd         <= id_ex_rd;
            ex_mem_funct3     <= id_ex_funct3;
            
            ex_mem_control.ram_read  <= id_ex_control.ram_read;
            ex_mem_control.ram_write <= id_ex_control.ram_write;
            ex_mem_control.reg_write <= id_ex_control.reg_write;
            ex_mem_control.wb_sel    <= id_ex_control.wb_sel;
        end
    end

    // MEM/WB flip flops
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_pc         <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_imm        <= 32'b0;
            mem_wb_rd         <= 5'b0;
            mem_wb_control    <= '0;
        end
        else begin
            mem_wb_pc         <= ex_mem_pc;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_imm        <= ex_mem_imm;
            mem_wb_rd         <= ex_mem_rd;
            
            mem_wb_control.reg_write <= ex_mem_control.reg_write;
            mem_wb_control.wb_sel    <= ex_mem_control.wb_sel;
        end
    end

    program_counter f1 (
        .clk(clk),
        .rst(rst),
        .if_pc_next(if_pc_next),
        .hazard_stall(hazard_stall),
        .freeze(freeze),

        .if_pc(if_pc)
    );

    instruction_memory f2(
        .if_pc(if_pc),

        .if_instruction(if_instruction)
    );

    control_unit f3 (
        .id_opcode(id_opcode),

        .id_control(id_control)
    );

    data_memory f4 (
        .clk(clk),
        .ex_mem_alu_result(ex_mem_alu_result), //Address
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_funct3(ex_mem_funct3),
        .ex_mem_ram_read_en(ex_mem_ram_read_en),
        .ex_mem_ram_write_en(ex_mem_ram_write_en),

        .mem_wb_read_data(mem_wb_read_data)
    );

    register_file f5 (
        .clk(clk),
        .rst(rst),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .mem_wb_rd(mem_wb_rd),
        .wb_rd_data(wb_rd_data),
        .mem_wb_reg_write_en(mem_wb_reg_write_en),

        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .x9_out(x9_out),
        .x10_out(x10_out)
    );

    alu f6 (
        .clk(clk),
        .rst(rst),
        .id_ex_alu_op(id_ex_alu_op),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_funct7(id_ex_funct7),
        .ex_operand1(ex_operand1),
        .ex_operand2(ex_operand2),
        .id_ex_opcode(id_ex_opcode),
        .refresh_counter(refresh_counter),

        .ex_alu_result(ex_alu_result),
        .ex_zero_flag(ex_zero_flag),
        .ex_less_than(ex_less_than),
        .ex_branch_condition_met(ex_branch_condition_met)
    );

    immediate_generator f7 (
        .if_id_instruction(if_id_instruction),

        .id_imm(id_imm)
    );
    
    segment_decoder f8 (
        .current_sample_digit(current_sample_digit),
        .current_hit_digit(current_hit_digit),
        
        .sample_seg(D0_SEG),
        .hit_seg(D1_SEG)
    );
endmodule
