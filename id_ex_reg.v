module id_ex_reg (
    input clk,
    input reset,
    input flush,
    input stall,

    // Control signals from ID
    input id_RegDst,
    input id_AluSrc,
    input id_MemtoReg,
    input id_RegWrite,
    input id_MemRead,
    input id_MemWrite,
    input id_Branch,
    input [1:0] id_AluOp,

    // Data from ID
    input [31:0] id_pc_plus_4,
    input [31:0] id_read_regdata1,
    input [31:0] id_read_regdata2,
    input [31:0] id_sext_imm,
    input [5:0] id_opcode,
    input [5:0] id_funct,
    input [4:0] id_rs,
    input [4:0] id_rt,
    input [4:0] id_rd,
    input [4:0] id_shamt,

    // Control signals to EX
    output reg ex_RegDst,
    output reg ex_AluSrc,
    output reg ex_MemtoReg,
    output reg ex_RegWrite,
    output reg ex_MemRead,
    output reg ex_MemWrite,
    output reg ex_Branch,
    output reg [1:0] ex_AluOp,

    // Data outputs to EX
    output reg [31:0] ex_pc_plus_4,
    output reg [31:0] ex_read_regdata1,
    output reg [31:0] ex_read_regdata2,
    output reg [31:0] ex_sext_imm,
    output reg [5:0] ex_opcode,
    output reg [5:0] ex_funct,
    output reg [4:0] ex_rs,
    output reg [4:0] ex_rt,
    output reg [4:0] ex_rd,
    output reg [4:0] ex_shamt
);

    always @(posedge clk) begin
        // Insert NOP if reset or flushed
        if (reset || flush) begin
            ex_RegDst <= 1'b0;
            ex_AluSrc <= 1'b0;
            ex_MemtoReg <= 1'b0;
            ex_RegWrite <= 1'b0;
            ex_MemRead <= 1'b0;
            ex_MemWrite <= 1'b0;
            ex_Branch <= 1'b0;
            ex_AluOp <= 2'b00;
            ex_pc_plus_4 <= 32'b0;
            ex_read_regdata1 <= 32'b0;
            ex_read_regdata2 <= 32'b0;
            ex_sext_imm <= 32'b0;
            ex_opcode <= 6'b0;
            ex_funct <= 6'b0;
            ex_rs <= 5'b0;
            ex_rt <= 5'b0;
            ex_rd <= 5'b0;
            ex_shamt <= 5'b0;
        end 
        else if (stall) begin
        end
        // else, pass the value to EX register
        else begin
            ex_RegDst <= id_RegDst;
            ex_AluSrc <= id_AluSrc;
            ex_MemtoReg <= id_MemtoReg;
            ex_RegWrite <= id_RegWrite;
            ex_MemRead <= id_MemRead;
            ex_MemWrite <= id_MemWrite;
            ex_Branch <= id_Branch;
            ex_AluOp <= id_AluOp;
            ex_pc_plus_4 <= id_pc_plus_4;
            ex_read_regdata1 <= id_read_regdata1;
            ex_read_regdata2 <= id_read_regdata2;
            ex_sext_imm <= id_sext_imm;
            ex_opcode <= id_opcode;
            ex_funct <= id_funct;
            ex_rs <= id_rs;
            ex_rt <= id_rt;
            ex_rd <= id_rd;
            ex_shamt <= id_shamt;
        end
    end
endmodule
