module alu_control(
    input [1:0] alu_op,
    input [5:0] funct,
    input [5:0] opcode,
    output reg [3:0] ALUControl
);

    // 4-bit encoding for each ALU operation based on alu
    localparam ALU_AND = 4'b0000;
    localparam ALU_OR = 4'b0001;
    localparam ALU_NOR = 4'b0010;
    localparam ALU_ADD = 4'b0011;
    localparam ALU_SUB = 4'b0100;
    localparam ALU_MUL = 4'b0101;
    localparam ALU_SLL = 4'b0110;
    localparam ALU_SRL = 4'b0111;
    localparam ALU_SLT = 4'b1000;

    // mips opcode encoding
    localparam OP_ANDI = 6'b001100;
    localparam OP_ORI = 6'b001101;

    // mips funct encoding
    localparam FUNCT_AND = 6'b100100;
    localparam FUNCT_OR = 6'b100101;
    localparam FUNCT_NOR = 6'b100111;
    localparam FUNCT_ADD = 6'b100000;
    localparam FUNCT_SUB = 6'b100010;
    localparam FUNCT_MUL = 6'b011000;  //pseudocode
    localparam FUNCT_SLL = 6'b000000;
    localparam FUNCT_SRL = 6'b000010;
    localparam FUNCT_SLT = 6'b101010;
    localparam FUNCT_JR = 6'b001000;

    always @(*) begin
        case (alu_op)
            // For I-type instructions 
            2'b00: ALUControl = ALU_ADD;   // addi, lw, sw
            2'b01: ALUControl = ALU_SUB;   
            2'b11: begin
                case (opcode)
                    OP_ANDI: ALUControl = ALU_AND;
                    OP_ORI: ALUControl = ALU_OR;
                    default: ALUControl = 4'bxxxx;
                endcase
            end 
            // For R-type instructions
            2'b10: begin
                case (funct)    
                    FUNCT_ADD: ALUControl = ALU_ADD;
                    FUNCT_SUB: ALUControl = ALU_SUB;
                    FUNCT_AND: ALUControl = ALU_AND;
                    FUNCT_OR:  ALUControl = ALU_OR;
                    FUNCT_NOR: ALUControl = ALU_NOR;
                    FUNCT_SLL: ALUControl = ALU_SLL;
                    FUNCT_SRL: ALUControl = ALU_SRL;
                    FUNCT_MUL: ALUControl = ALU_MUL;
                    FUNCT_SLT: ALUControl = ALU_SLT;
                    FUNCT_JR: ALUControl = ALU_ADD; // jr uses add for PC calc 
                    default:   ALUControl = 4'bxxxx;
                endcase
            end
            default: ALUControl = 4'bxxxx;
        endcase
    end
endmodule