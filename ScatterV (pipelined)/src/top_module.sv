import pipeline_pkg::*;

module top_module (
    input clk,
    input rst
);

    // GLOBAL
    logic hazard_stall;

    // IF
    logic [31:0] if_pc;
    logic [31:0] if_pc_next;
    logic [31:0] if_instruction;
    //---------------------------------------------------------
    // 1. IF/ID Stage Registers
    //---------------------------------------------------------
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instruction;
    // ID
    logic [4:0]  id_rs1;
    logic [4:0]  id_rs2;
    logic [6:0]  id_opcode;
    logic [31:0] id_rs1_data;
    logic [31:0] id_rs2_data;
    logic [31:0] id_imm;
    id_ex_ctrl_t id_control;

    //---------------------------------------------------------
    // 2. ID/EX Stage Registers
    //---------------------------------------------------------
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
    id_ex_ctrl_t id_ex_control; // Using our packed struct type
    // EX
    logic [31:0] ex_alu_result;
    logic [31:0] ex_operand1;
    logic [31:0] ex_operand2;
    logic ex_zero_flag;
    logic ex_less_than;
    logic ex_branch_condition_met; //Branch conditions met
    logic [1:0] ex_pc_sel; // 00 PC + 4, 01 jal_en (PC + imm), 10 branch_en (PC + imm), 11 jalr_en (rs1 + imm)

    //---------------------------------------------------------
    // 3. EX/MEM Stage Registers
    //---------------------------------------------------------
    logic [31:0]  ex_mem_pc;
    logic [31:0]  ex_mem_alu_result;
    logic [31:0]  ex_mem_rs2_data;
    logic [31:0]  ex_mem_imm;
    logic [4:0]   ex_mem_rd;
    logic [2:0]   ex_mem_funct3;
    ex_mem_ctrl_t ex_mem_control; // Using our packed struct type
    // MEM
    logic [31:0] mem_read_data;

    //---------------------------------------------------------
    // 4. MEM/WB Stage Registers
    //---------------------------------------------------------
    logic [31:0]  mem_wb_pc;
    logic [31:0]  mem_wb_alu_result;
    logic [31:0]  mem_wb_mem_data;
    logic [31:0]  mem_wb_imm;
    logic [4:0]   mem_wb_rd;
    mem_wb_ctrl_t mem_wb_control; // Using our packed struct type

    // WB
    logic [31:0] wb_rd_data;

    assign id_rs1 = if_id_instruction[24:20];  // Needed early for load hazard detection
    assign id_rs2 = if_id_instruction[19:15];
    assign id_opcode = if_id_instruction[6:0];

    assign wb_rd_data =
        (mem_wb_control.wb_sel == 2'b00) ? mem_wb_alu_result :
        (mem_wb_control.wb_sel == 2'b01) ? mem_wb_mem_data :
        (mem_wb_control.wb_sel == 2'b10) ? mem_wb_pc + 4 :
        (mem_wb_control.wb_sel == 2'b11) ? mem_wb_imm :
        32'b0;
    //load alu_result (ADD SUB), data (LOAD), pc + 4 (JAL JALR), or immediate_out (LUI)

    assign ex_operand1 = id_ex_control.auipc_en ? id_ex_pc : id_ex_rs1_data; //pc for AUIPC, otherwise it'll be source register
    assign ex_operand2 = id_ex_control.alu_src ? id_ex_imm : id_ex_rs2_data; //rs2 or immediate into ALU calculation
    
always_comb begin
        case (ex_pc_sel)
            2'b00: if_pc_next = if_pc + 4; //NORMAL
            2'b01: if_pc_next = id_ex_pc + id_ex_imm; // JAL
            2'b10: begin //BRANCH
                if (ex_branch_condition_met)
                    if_pc_next = id_ex_pc + id_ex_imm;
                else
                    if_pc_next = id_ex_pc + 4;
            end
            2'b11: if_pc_next = (id_ex_rs1_data + id_ex_imm) & ~32'h1; // JALR alignment
            default: if_pc_next = if_pc + 4;
        endcase
    end


    // IF/ID Pipeline Register Stage
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        if_id_pc          <= 32'b0;
        if_id_instruction <= 32'h00000013;
    end
    else if (!hazard_stall) begin
        if_id_pc          <= if_pc;              // or pc_next, see note below
        if_id_instruction <= if_instruction;
    end
end

// ID/EX Pipeline Register Stage
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
        id_ex_control    <= '0; // Cleared control signals = NOP
    end
    else if (hazard_stall) begin
        // Inject a NOP into EX to handle the load hazard
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
        id_ex_control    <= '0; // Insert the bubble
    end
    else begin
        // Normal operation: capture decoded data and control configurations
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
        id_ex_control    <= id_control; // Packed control word from control unit
    end
end

// EX/MEM Pipeline Register Stage
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
        ex_mem_alu_result <= ex_alu_result;
        ex_mem_rs2_data   <= id_ex_rs2_data;
        ex_mem_imm        <= id_ex_imm;
        ex_mem_rd         <= id_ex_rd;
        ex_mem_funct3     <= id_ex_funct3;
        
        // Pass down: mem_read, mem_write, reg_write, wb_sel
        ex_mem_control    <= ex_mem_ctrl_t'(id_ex_control[4:0]);
    end
end

// MEM/WB Pipeline Register Stage
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        mem_wb_pc         <= 32'b0;
        mem_wb_alu_result <= 32'b0;
        mem_wb_mem_data   <= 32'b0;
        mem_wb_imm        <= 32'b0;
        mem_wb_rd         <= 5'b0;
        mem_wb_control    <= '0;
    end
    else begin
        mem_wb_pc         <= ex_mem_pc;
        mem_wb_alu_result <= ex_mem_alu_result;
        mem_wb_mem_data   <= mem_read_data; // From data memory
        mem_wb_imm        <= ex_mem_imm;
        mem_wb_rd         <= ex_mem_rd;
        
        // Pass down: reg_write, wb_sel
        mem_wb_control    <= mem_wb_ctrl_t'(ex_mem_control[2:0]);
    end
end

    program_counter f1 (
        .clk(clk),
        .rst(rst),
        .if_pc_next(if_pc_next),
        .hazard_stall(hazard_stall),

        .if_pc(if_pc)
    );

    instruction_memory f2(
        .if_pc(if_pc),

        .if_instruction(if_instruction)
    );

    control_unit f3 (
        .id_opcode(id_opcode),

        .id_control(id_control),
        .ex_pc_sel(ex_pc_sel)
    );

    data_memory f4 (
        .clk(clk),
        .ex_mem_alu_result(ex_mem_alu_result), //memory address
        .ex_mem_rs2_data(ex_mem_rs2_data),
        .ex_mem_funct3(ex_mem_funct3),
        .ram_read_en(ex_mem_control.ram_read_en),
        .ram_write_en(ex_mem_control.ram_write_en),

        .mem_read_data(mem_read_data)
    );

    register_file f5 (
        .clk(clk),
        .rst(rst),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .mem_wb_rd(mem_wb_rd),
        .wb_rd_data(wb_rd_data),
        .reg_write_en(mem_wb_control.reg_write_en),

        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data)
    );

    alu f6 (
        .clk(clk),
        .rst(rst),
        .alu_op(id_ex_control.alu_op),
        .id_ex_funct3(id_ex_funct3),
        .id_ex_funct7(id_ex_funct7),
        .ex_operand1(ex_operand1),
        .ex_operand2(ex_operand2),
        .id_ex_opcode(id_ex_opcode),

        .ex_alu_result(ex_alu_result),
        .ex_zero_flag(ex_zero_flag),
        .ex_less_than(ex_less_than),
        .ex_branch_condition_met(ex_branch_condition_met)
    );

    immediate_generator f7 (
        .if_id_instruction(if_id_instruction),

        .id_imm(id_imm)
    );
    
endmodule
