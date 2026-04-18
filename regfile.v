module regfile(
    input clk,
    input we,
    input [4:0] ra1, ra2, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2
);   
    // declare register file as an array of 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    // initialize all registers to 0 at the start of simulation
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'b0;
        end
    end

    // async read for two ports, $zero always returns 0
    assign rd1 = (ra1 != 5'b0) && (ra1 == wa) && we ? wd: registers[ra1];
    assign rd2 = (ra2 != 5'b0) && (ra2 == wa) && we ? wd: registers[ra2];

    // sync write on pos edge of clock
    always @(posedge clk) begin
        if (we && (wa != 5'd0)) begin
            registers[wa] <= wd;
        end
    end

endmodule