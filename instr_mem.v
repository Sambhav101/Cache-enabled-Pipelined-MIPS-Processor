module instr_mem(
    input [31:0] addr,
    output [31:0] instr
);

    // Declare a 128-word instruction memory
    reg [31:0] mem [0:127];

    // initialize instruction memory to 0 at the start of simulation
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            mem[i] = 32'b0;
        end
    end

    // shift right the pc address by 2 to get the word index
    assign instr = mem[addr[8:2]]; 

endmodule