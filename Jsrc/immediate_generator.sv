module immediate_generator (
    input  logic [31:0] if_id_instruction,
    output logic [31:0] id_imm
);

    always_comb begin
        case (if_id_instruction[6:0])
            // 1. I-type
            7'b0010011, 
            7'b0000011, 
            7'b1100111: begin
                id_imm = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
            end

            // 2. S-type
            7'b0100011: begin
                id_imm = {{20{if_id_instruction[31]}}, if_id_instruction[31:25], if_id_instruction[11:7]};
            end

            // 3. B-type
            7'b1100011: begin
                id_imm = {{19{if_id_instruction[31]}}, if_id_instruction[31], if_id_instruction[7], if_id_instruction[30:25], if_id_instruction[11:8], 1'b0};
            end

            // 4. U-type
            7'b0110111, 
            7'b0010111: begin
                id_imm = {if_id_instruction[31:12], 12'b0};
            end

            // 5. J-type
            7'b1101111: begin
                id_imm = {{12{if_id_instruction[31]}}, if_id_instruction[19:12], if_id_instruction[20], if_id_instruction[30:21], 1'b0};
            end

            // Default
            default: begin
                id_imm = 32'b0;
            end
        endcase
    end

endmodule
