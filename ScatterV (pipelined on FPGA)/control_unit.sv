import pipeline_pkg::*;

module control_unit(
    input [6:0] id_opcode,

    output id_ex_ctrl_t id_control
);

    always_comb begin
        id_control.alu_op    = 2'b00;
        id_control.alu_src   = 1'b0;
        id_control.ram_read  = 1'b0;
        id_control.ram_write = 1'b0;
        id_control.reg_write = 1'b0;
        id_control.wb_sel    = 2'b00;
        id_control.auipc_en  = 1'b0;
        id_control.pc_sel    = 2'b00;

        case(id_opcode)
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
                id_control.ram_read  = 1'b1;
                id_control.reg_write = 1'b1;
                id_control.wb_sel    = 2'b01;
            end

            7'b0100011: begin // STORE
                id_control.alu_op    = 2'b00;   // address = rs1 + imm
                id_control.alu_src   = 1'b1;
                id_control.ram_write = 1'b1;
            end

            7'b1100011: begin // BRANCH
                id_control.alu_op = 2'b01;   // subtraction for comparison
                id_control.pc_sel = 2'b10;
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
                id_control.pc_sel    = 2'b01;
                id_control.wb_sel    = 2'b10;
            end

            7'b1100111: begin // JALR
                id_control.alu_src   = 1'b1;
                id_control.reg_write = 1'b1;
                id_control.pc_sel    = 2'b11;
                id_control.wb_sel    = 2'b10;
            end

            7'b0001011: begin // RND
                id_control.alu_op    = 2'b11;
                id_control.reg_write = 1'b1;
            end

            default: begin // INVALID
                id_control.pc_sel    = 2'b00;
            end

        endcase
    end

endmodule
