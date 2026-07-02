module tb;

    logic clk = 0;
    logic rst = 1;

    top_module dut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        #10 rst = 0;
        #20000 $finish;
    end

endmodule