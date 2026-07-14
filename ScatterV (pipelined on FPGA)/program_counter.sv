module program_counter(
    input clk,
    input rst,
    input [31:0] if_pc_next,
    input hazard_stall,
    input freeze,

    output reg [31:0] if_pc
);

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        if_pc <= 0;
    else if (!hazard_stall && !freeze) begin
        if_pc <= if_pc_next;
    end
end

endmodule
