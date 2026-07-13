module register_file (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  id_rs1,
    input  logic [4:0]  id_rs2,
    input  logic [4:0]  mem_wb_rd,
    input  logic [31:0] wb_rd_data,
    input  logic        mem_wb_reg_write_en,

    output logic [31:0] id_rs1_data,
    output logic [31:0] id_rs2_data,
    output logic [31:0] x9_out,
    output logic [31:0] x10_out
);
    reg [31:0] registers [31:0];
    
    assign x9_out = registers[9]; //Send to LED display
    assign x10_out = registers[10];
    //Synchronous writes
    always_ff @(negedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end

        end else if (mem_wb_reg_write_en && (mem_wb_rd != 5'b00000)) begin
            // Write if address isn't x0
            registers[mem_wb_rd] <= wb_rd_data;
        end
    end

    //Asynchronous reads, no read allowed if R0 selected
    assign id_rs1_data = (id_rs1 == 5'b00000) ? 32'b0 : registers[id_rs1];
    assign id_rs2_data = (id_rs2 == 5'b00000) ? 32'b0 : registers[id_rs2];
endmodule
