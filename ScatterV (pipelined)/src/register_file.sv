module register_file (
    input  logic        clk,
    input  logic        rst,
    input  logic [4:0]  if_id_rs1,
    input  logic [4:0]  if_id_rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] rd_data,
    input  logic        reg_write_en,

    output logic [31:0] id_rs1_data,
    output logic [31:0] id_rs2_data
);
    reg [31:0] registers [31:0];

    //Synchronous writes
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= 32'b0;
            end

        end else if (reg_write_en && (rd != 5'b00000)) begin
            // Write if address isn't x0
            registers[rd] <= rd_data;
        end
    end

    //Asynchronous reads, no read allowed if R0 selected
    assign id_rs1_data = (if_id_rs1 == 5'b00000) ? 32'b0 : registers[if_id_rs1];
    assign id_rs2_data = (if_id_rs2 == 5'b00000) ? 32'b0 : registers[if_id_rs2];
endmodule
