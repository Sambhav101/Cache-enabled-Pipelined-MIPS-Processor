module control_unit(
    input [5:0] opcode,
    input [5:0] funct,
    output reg [1:0] alu_op,
    output reg MemtoReg,
    output reg MemWrite,
    output reg MemRead,
    output reg ALUSrc,
    output reg RegDst,
    output reg RegWrite,
    output reg Branch,
    output reg Jump,
    output reg Jal,
    output reg Jr
);

    // Opcodes
    localparam OP_RTYPE = 6'b000000;
    localparam OP_ADDI = 6'b001000;
    localparam OP_ANDI = 6'b001100;
    localparam OP_ORI = 6'b001101;
    localparam OP_LW = 6'b100011;
    localparam OP_SW = 6'b101011;
    localparam OP_SLT = 6'b001010; // This is slti, but for this design we can handle slt here.
    localparam OP_BEQ = 6'b000100;
    localparam OP_BNE = 6'b000101;
    localparam OP_JUMP = 6'b000010;
    localparam OP_JAL = 6'b000011;

    // combinational control unit
    always @(*) begin
        // start with default values
        MemtoReg = 0; MemRead = 0; MemWrite = 0; alu_op = 2'b00; ALUSrc = 0; RegDst = 0; RegWrite = 0;
        Jump = 0; Branch = 0; Jal = 0; Jr = 0;
        
        // select alu_op based on the opcode 
        case (opcode)
            // for r-type opcode (000000), generate "10" alu_op 
            // as input for alu control to decode funct code
            OP_RTYPE: begin
                RegDst = 1; alu_op = 2'b10; RegWrite = 1;
                // Special case for Jr  
                if (funct == 6'b001000) begin
                    Jr = 1; RegWrite = 0;
                end
            end
            OP_ADDI: begin
                RegWrite = 1; ALUSrc = 1; alu_op = 2'b00;
            end 
            OP_ANDI: begin
                RegWrite = 1; ALUSrc = 1; alu_op = 2'b11;
            end
            OP_ORI: begin
                RegWrite = 1; ALUSrc = 1; alu_op = 2'b11;
            end 
            OP_LW: begin
                MemRead = 1; MemtoReg = 1; ALUSrc = 1; RegWrite = 1; alu_op = 2'b00;
            end
            OP_SW: begin
                MemWrite = 1; ALUSrc = 1; alu_op = 2'b00;
            end
            OP_BEQ: begin 
                Branch = 1; alu_op = 2'b01;
            end
            OP_BNE: begin
                Branch = 1; alu_op = 2'b01;
            end
            OP_JUMP: begin 
                Jump = 1;
            end
            OP_JAL: begin 
                Jump = 1; Jal = 1; RegWrite = 1; MemtoReg = 0;
            end
            default: ;
        endcase
    end
endmodule