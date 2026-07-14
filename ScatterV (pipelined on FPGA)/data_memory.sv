module data_memory (
    input  logic        clk,
    input  logic [31:0] ex_mem_alu_result,
    input  logic [31:0] ex_mem_rs2_data,
    input  logic        ex_mem_ram_read_en,
    input  logic        ex_mem_ram_write_en,
    input  logic [2:0]  ex_mem_funct3,
    
    output logic [31:0] mem_wb_read_data
);
    logic [31:0] ram [0:1023];

    //Synchronous writes
    always_ff @(posedge clk) begin
        if (ex_mem_ram_write_en) begin
            case (ex_mem_funct3)
                3'b000: begin // SB
                    case (ex_mem_alu_result[1:0])
                        2'b00: ram[ex_mem_alu_result[11:2]][7:0]   <= ex_mem_rs2_data[7:0];
                        2'b01: ram[ex_mem_alu_result[11:2]][15:8]  <= ex_mem_rs2_data[7:0];
                        2'b10: ram[ex_mem_alu_result[11:2]][23:16] <= ex_mem_rs2_data[7:0];
                        2'b11: ram[ex_mem_alu_result[11:2]][31:24] <= ex_mem_rs2_data[7:0];
                    endcase
                end
                3'b001: begin // SH
                    if (ex_mem_alu_result[1] == 1'b0)
                        ram[ex_mem_alu_result[11:2]][15:0]  <= ex_mem_rs2_data[15:0];
                    else
                        ram[ex_mem_alu_result[11:2]][31:16] <= ex_mem_rs2_data[15:0];
                end
                3'b010: begin // SW
                    ram[ex_mem_alu_result[11:2]] <= ex_mem_rs2_data;
                end
                default: ram[ex_mem_alu_result[11:2]] <= ex_mem_rs2_data;
            endcase
        end
    end

    //Synchronous reads
    always_ff @(posedge clk) begin
        if (ex_mem_ram_read_en) begin
            case (ex_mem_funct3)
                3'b000: begin // LB
                    case (ex_mem_alu_result[1:0])
                        2'b00: mem_wb_read_data <= {{24{ram[ex_mem_alu_result[11:2]][7]}},  ram[ex_mem_alu_result[11:2]][7:0]};
                        2'b01: mem_wb_read_data <= {{24{ram[ex_mem_alu_result[11:2]][15]}}, ram[ex_mem_alu_result[11:2]][15:8]};
                        2'b10: mem_wb_read_data <= {{24{ram[ex_mem_alu_result[11:2]][23]}}, ram[ex_mem_alu_result[11:2]][23:16]};
                        2'b11: mem_wb_read_data <= {{24{ram[ex_mem_alu_result[11:2]][31]}}, ram[ex_mem_alu_result[11:2]][31:24]};
                    endcase
                end
                3'b001: begin // LH
                    if (ex_mem_alu_result[1] == 1'b0)
                        mem_wb_read_data <= {{16{ram[ex_mem_alu_result[11:2]][15]}}, ram[ex_mem_alu_result[11:2]][15:0]};
                    else
                        mem_wb_read_data <= {{16{ram[ex_mem_alu_result[11:2]][31]}}, ram[ex_mem_alu_result[11:2]][31:16]};
                end
                3'b010: begin // LW
                    mem_wb_read_data <= ram[ex_mem_alu_result[11:2]];
                end
                default: begin
                    mem_wb_read_data <= ram[ex_mem_alu_result[11:2]];
                end
            endcase
        end else begin
            mem_wb_read_data <= 32'b0; // Default state when memory isn't active
        end
    end

endmodule
