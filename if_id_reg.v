module if_id_reg (
    input clk,
    input reset,
    input stall,
    input flush,

    // inputs from IF
    input [31:0] if_pc_plus_4,
    input [31:0] if_instr,

    // outputs to IF
    output reg [31:0] id_pc_plus_4,
    output reg [31:0] id_instr
);

    always @(posedge clk) begin
        // Insert NOP when reset or flush
        if (reset || flush) begin
            id_pc_plus_4 <= 32'b0;
            id_instr <= 32'b0;
        end 
        // hold the current value when stalled, else update to ID reg
        else if (~stall) begin
            id_pc_plus_4 <= if_pc_plus_4;
            id_instr <= if_instr;
        end
    end
endmodule
