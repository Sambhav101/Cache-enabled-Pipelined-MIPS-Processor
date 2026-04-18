module sc_mips_processor(
    input clk,
    input rst
);

    // Fetch Instruction
    reg [31:0] pc;
    wire [31:0] instr;
    instr_mem imem (
        .addr(pc),
        .instr(instr)
    );

    // Decode Instruction
    wire [5:0] opcode = instr[31:26];
    wire [4:0] rs = instr[25:21];
    wire [4:0] rt = instr[20:16];
    wire [4:0] rd = instr[15:11];
    wire [4:0] shamt = instr[10:6];
    wire [5:0] funct = instr[5:0];
    wire [15:0] imm = instr[15:0];
    wire [25:0] jump_addr = instr[25:0];

    // Control Signals
    wire MemtoReg, MemWrite, MemRead, ALUSrc, RegDst, RegWrite;
    wire [1:0] alu_op;
    wire Branch, Jump, Jal, Jr;

    // intermediate wires
    wire isAluZero, isShift, isBranchTaken;
    wire [31:0] sext_imm;
    // set isShift to 1 for sll, srl, slt
    assign isShift = (opcode == 6'b000000) && ((funct == 6'b000000) || (funct == 6'b000010) || (funct == 6'b000011));
    // set isBranchTaken t0 1 if beq (6'd4 opcode) and alu is zero or bne (6'd5 opcode) and alu is not zero
    assign isBranchTaken = (Branch && opcode == 6'd4 && isAluZero) | (Branch && opcode == 6'd5 && !isAluZero);
    // sign extend immediate
    assign sext_imm = {{16{imm[15]}}, imm};

    // CONTROL UNIT
    control_unit Control_Unit (
        .opcode(opcode),
        .funct(funct),
        .alu_op(alu_op),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ALUSrc(ALUSrc),
        .RegDst(RegDst),
        .RegWrite(RegWrite),
        .Branch(Branch),
        .Jump(Jump),
        .Jal(Jal),
        .Jr(Jr)
    );

    // REGISTER FILE
    wire [4:0] read_addr1, read_addr2, write_addr;
    wire [31:0] read_regdata1, read_regdata2, write_regdata;
    // select write_address from rd or rt based on r-type
    assign read_addr1 = rs;
    assign read_addr2 = rt;
    assign write_addr = Jal ? 5'd31 : 
                        RegDst ? rd : rt;
    regfile rf (
        .clk(clk),
        .we(RegWrite),
        .ra1(read_addr1),
        .ra2(read_addr2),
        .wa(write_addr),
        .wd(write_regdata),
        .rd1(read_regdata1),
        .rd2(read_regdata2)
    );
    
    // ALU CONTROL LOGIC
    wire [3:0] ALUControl;
    alu_control alu_ctrl (
        .alu_op(alu_op),
        .funct(funct),
        .opcode(opcode),
        .ALUControl(ALUControl)
    );

    // ALU LOGIC
    wire [31:0] SrcA, SrcB, alu_result;
    // assign each input of ALU based on isShift and ALUSrc
    assign SrcA = (isShift) ? shamt: read_regdata1;
    assign SrcB = ALUSrc ? sext_imm : read_regdata2;
    alu ALU (
        .a(SrcA),
        .b(SrcB),
        .ALUControl(ALUControl),
        .result(alu_result),
        .Zero(isAluZero)
    );

    // DATA MEMORY
    wire[31:0] mem_addr, write_memdata, read_memdata;
    // connect alu_result to mem_addr and  data from second register to write data port
    assign mem_addr = alu_result;
    assign write_memdata = read_regdata2;
    data_mem dmem (
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .addr(alu_result),
        .wd(write_memdata),
        .rd(read_memdata)
    );

    
    // PC Logic
    wire [31:0] pc_plus_4, branch_target, jump_target, pc_out;
    assign pc_plus_4 = pc + 4;
    assign jump_target = {pc_plus_4[31:28], jump_addr, 2'b00};
    assign branch_target = pc_plus_4 + (sext_imm << 2);
    // mux to select PC based on conditions
    assign pc_out = Jr ? read_regdata1 :
                     Jump ? jump_target :
                     isBranchTaken ? branch_target : pc_plus_4;
    // update program counter after each clock cycle
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0;
        else
            pc <= pc_out;
    end

    // WRITEBACK to REGISTER
    assign write_regdata = Jal ? pc_plus_4 :
                            MemtoReg ? read_memdata : alu_result;
endmodule