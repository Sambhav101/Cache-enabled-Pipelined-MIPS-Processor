module data_mem(
    input clk,
    input we,
    input req,
    input [31:0] addr,
    input [31:0] wd,
    output [31:0] rd,
    output reg mem_ready
);

    // declares a 128 word memory
    reg [31:0] mem [0:127];

    // initialize all memory to 0 at the start of simulation
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            mem[i] = i;
        end
    end

    // async read
    assign rd = (req && !we) ? mem[addr[8:2]] : 32'b0;

    always @(posedge clk) begin
        mem_ready <= req;
        if (req && we) mem[addr[8:2]] <= wd;
    end

endmodule