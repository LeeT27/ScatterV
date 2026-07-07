package pipeline_pkg;

    typedef struct packed {
        logic       alu_src;    //rs2 vs immediate for ALU
        logic [3:0] alu_op;     //00 always add LOAD STORE. 01 always subtract BRANCH. 10 Normal ALU. 11 RND
        logic       auipc_en;    // Set operand1 to PC
        logic       mem_read;   // needed in MEM
        logic       mem_write;  // needed in MEM
        logic       reg_write;  // needed in WB
        logic [1:0] wb_sel;     // needed in WB (e.g. 00=alu, 01=mem, 10=pc+4)
    } id_ex_ctrl_t;

    typedef struct packed {
        logic       mem_read;
        logic       mem_write;
        logic       reg_write;
        logic [1:0] wb_sel;
    } ex_mem_ctrl_t;

    typedef struct packed {
        logic       reg_write;
        logic [1:0] wb_sel;
    } mem_wb_ctrl_t;

endpackage

import pipeline_pkg::*;

module control_unit(
    input [6:0] opcode,        // instruction opcode

    output logic [1:0] ex_pc_sel,
    output id_ex_ctrl_t id_control
);

    always_comb begin
        id_control.alu_op    = 2'b00;
        id_control.alu_src   = 1'b0;
        id_control.mem_read  = 1'b0;
        id_control.mem_write = 1'b0;
        id_control.reg_write = 1'b0;
        id_control.wb_sel    = 2'b00;
        id_control.auipc_en  = 1'b0;
        ex_pc_sel            = 2'b00;

        case(opcode)
            7'b0110011: begin // R: ARITHMETIC
                id_control.alu_op    = 2'b10;
                id_control.reg_write = 1'b1;
            end

            7'b0010011: begin // I: IMMEDIATE ARITHMATIC
                id_control.alu_op    = 2'b10;
                id_control.alu_src   = 1'b1;
                id_control.reg_write = 1'b1;
            end

            7'b0000011: begin // I: LOAD
                id_control.alu_op    = 2'b00;   // address = rs1 + imm
                id_control.alu_src   = 1'b1;
                id_control.mem_read  = 1'b1;
                id_control.reg_write = 1'b1;
                id_control.wb_sel    = 2'b01;
            end

            7'b0100011: begin // STORE
                id_control.alu_op    = 2'b00;   // address = rs1 + imm
                id_control.alu_src   = 1'b1;
                id_control.mem_write = 1'b1;
            end

            7'b1100011: begin // BRANCH
                id_control.alu_op = 2'b01;   // subtraction for comparison
                ex_pc_sel             = 2'b10;
            end

            7'b0110111: begin // U: LUI
                id_control.alu_src   = 1'b1;
                id_control.reg_write = 1'b1;
                id_control.wb_sel    = 2'b11;
            end

            7'b0010111: begin // U: AUIPC
                id_control.alu_op    = 2'b00;
                id_control.alu_src   = 1'b1;
                id_control.reg_write = 1'b1;
                id_control.auipc_en  = 1'b1;
            end

            7'b1101111: begin // J: JAL
                id_control.alu_src   = 1'b1;
                id_control.reg_write = 1'b1; // write PC+4 into register
                ex_pc_sel            = 2'b01;
                id_control.wb_sel    = 2'b10;
            end

            7'b1100111: begin // JALR
                id_control.alu_src   = 1'b1;
                id_control.reg_write = 1'b1;
                ex_pc_sel                = 2'b11;
                id_control.wb_sel    = 2'b10;
            end

            7'b0001011: begin // RND
                id_control.alu_op    = 2'b11;
                id_control.reg_write = 1'b1;
            end

            default: begin // INVALID
                ex_pc_sel = 2'b00;
            end

        endcase
    end

endmodule
