module cached_mips_processor (
    input clk,
    input reset
);
    
    // Cache-Memory Interface Signals
    wire cache_mem_req, cache_mem_we;
    wire [31:0] cache_mem_addr, cache_mem_wd, cache_mem_rd;
    wire cache_mem_ready, cache_stall;
    wire [31:0] cache_accesses, cache_hits, cache_misses;
    
    // Hazard unit signals
    wire ifid_flush;
    wire idex_flush;
    wire flush_req;

    // Combine hazard stalls with cache stalls
    wire pc_write = ~cache_stall;
    wire ifid_write = ~cache_stall;
    wire idex_write  = ~cache_stall;
    wire exmem_write = ~cache_stall; 
    wire memwb_write = ~cache_stall;
    wire exmem_flush = flush_req;

    // Forwarding signals
    wire [1:0] forwardA, forwardB;
    wire [31:0] dm_write_memdata;
    wire forwardMem;

    // PC and Branching wires
    wire [31:0] pc_in, pc_out, pc_plus_4;
    wire PcSrc, branch_taken;

    // IF/ID wires
    wire [31:0] if_instr;
    wire [31:0] id_pc_plus_4, id_instr;

    // ID/EX wires and signals
    wire [31:0] id_read_regdata1, id_read_regdata2, id_sext_imm;
    wire [5:0] id_opcode, id_funct;
    wire [4:0] id_rs, id_rt, id_rd, id_shamt;
    wire [1:0] id_AluOp;
    wire id_RegDst, id_AluSrc, id_MemtoReg, id_RegWrite, id_MemRead, id_MemWrite; 
    wire id_Branch, id_Jump, id_Jal, id_Jr;
    // output
    wire [31:0] ex_pc_plus_4, ex_read_regdata1, ex_read_regdata2, ex_sext_imm;
    wire [5:0] ex_opcode, ex_funct;
    wire [4:0] ex_rs, ex_rt, ex_rd, ex_shamt;
    wire [1:0] ex_AluOp;
    wire ex_RegDst, ex_AluSrc, ex_MemtoReg, ex_RegWrite, ex_MemRead, ex_MemWrite; 
    wire ex_Branch, ex_Jump, ex_Jal, ex_Jr;

    // EX/Mem wires and signals
    wire [31:0] ex_SrcA, ex_SrcB;
    wire [31:0] ex_alu_result, ex_write_memdata;
    wire [4:0] ex_write_regaddr;
    wire [3:0] ex_ALUControl;
    wire [31:0] ex_branch_target;
    wire ex_AluZero;
    // outputs
    wire mem_MemtoReg, mem_RegWrite, mem_MemRead, mem_MemWrite, mem_Branch, mem_AluZero;
    wire [31:0] mem_alu_result, mem_write_memdata;
    wire [4:0] mem_write_regaddr;
    wire [31:0] mem_branch_target;
    wire [4:0] mem_rt;

    // MEM/WB wires and signals
    wire [31:0] mem_read_memdata;
    wire [31:0] dm_write_data;
    // outputs
    wire [31:0] wb_alu_result, wb_read_memdata;
    wire [4:0]  wb_write_regaddr;
    wire wb_MemtoReg, wb_RegWrite;
    wire [31:0] wb_write_memdata;


    // IF STAGE

    // pc mux, selects between pc plus 4 and mem branch target
    assign pc_in = (PcSrc) ? mem_branch_target : pc_plus_4;

    // PC Register
    pc pc_reg (
        .clk(clk),
        .reset(reset),
        .write_enable(pc_write),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );
    // pc + 4
    assign pc_plus_4 = pc_out + 32'd4;

    // Instruction Memory
    instr_mem imem (
        .addr(pc_out),
        .instr(if_instr)
    );
    
    // IF/ID Pipeline Register
    if_id_reg if_id (
        .clk(clk),
        .reset(reset),
        .stall(~ifid_write),
        .flush(ifid_flush),
        .if_pc_plus_4(pc_plus_4),
        .if_instr(if_instr),
        .id_pc_plus_4(id_pc_plus_4),
        .id_instr(id_instr)
    );

    // ID Stage

    // Decode instruction
    assign id_opcode = id_instr[31:26];
    assign id_rs = id_instr[25:21];
    assign id_rt = id_instr[20:16];
    assign id_rd = id_instr[15:11];
    assign id_shamt  = id_instr[10:6];
    assign id_funct = id_instr[5:0];
    // Control Unit
    control_unit cu (
        .opcode(id_opcode),
        .funct(id_funct),
        .alu_op(id_AluOp),
        .MemtoReg(id_MemtoReg),
        .MemWrite(id_MemWrite),
        .MemRead(id_MemRead),
        .ALUSrc(id_AluSrc),
        .RegDst(id_RegDst),
        .RegWrite(id_RegWrite),
        .Branch(id_Branch),
        .Jump(id_Jump),
        .Jal(id_Jal),
        .Jr(id_Jr)
    );

    // Register File
    regfile rf (
        .clk(clk),
        .we(wb_RegWrite),
        .ra1(id_rs),
        .ra2(id_rt),
        .wa(wb_write_regaddr),     
        .wd(wb_write_memdata),         
        .rd1(id_read_regdata1),
        .rd2(id_read_regdata2)
    );

    // sign extend immediate
    assign id_sext_imm = {{16{id_instr[15]}}, id_instr[15:0]};

    // Hazard detection unit
    hazard_unit hu (
        .ifid_rs(id_rs),
        .ifid_rt(id_rt),
        .idex_MemRead(ex_MemRead),
        .idex_RegWrite(ex_RegWrite),
        .idex_write_regaddr(ex_write_regaddr),
        .exmem_RegWrite(mem_RegWrite),
        .exmem_write_regaddr(mem_write_regaddr),
        .memwb_RegWrite(wb_RegWrite),
        .memwb_write_regaddr(wb_write_regaddr),
        .flush_req(flush_req),
        .pc_write(pc_write),
        .ifid_write(ifid_write),
        .idex_flush(idex_flush),
        .ifid_flush(ifid_flush)
    );

    // Remove the hazard unit, no stalls (set flush to 0)
    // assign pc_write = 1'b1;
    // assign ifid_write = 1'b1;
    // assign idex_flush = 1'b0;

    // ID/EX Pipeline Register
    id_ex_reg id_ex (
        .clk(clk),
        .reset(reset),
        .flush(idex_flush),
        .stall(~idex_write),
        // control signals
        .id_RegDst(id_RegDst),
        .id_AluSrc(id_AluSrc),
        .id_MemtoReg(id_MemtoReg),
        .id_RegWrite(id_RegWrite),
        .id_MemRead(id_MemRead),
        .id_MemWrite(id_MemWrite),
        .id_Branch(id_Branch),
        .id_AluOp(id_AluOp),
        // Data Inputs
        .id_pc_plus_4(id_pc_plus_4),
        .id_read_regdata1(id_read_regdata1),
        .id_read_regdata2(id_read_regdata2),
        .id_sext_imm(id_sext_imm),
        .id_opcode(id_opcode),
        .id_funct(id_funct),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_rd(id_rd),
        .id_shamt(id_shamt),
        // Control Outputs
        .ex_RegDst(ex_RegDst),
        .ex_AluSrc(ex_AluSrc),
        .ex_MemtoReg(ex_MemtoReg),
        .ex_RegWrite(ex_RegWrite),
        .ex_MemRead(ex_MemRead),
        .ex_MemWrite(ex_MemWrite),
        .ex_Branch(ex_Branch),
        .ex_AluOp(ex_AluOp),
        // Data Outputs
        .ex_pc_plus_4(ex_pc_plus_4),
        .ex_read_regdata1(ex_read_regdata1),
        .ex_read_regdata2(ex_read_regdata2),
        .ex_sext_imm(ex_sext_imm),
        .ex_opcode(ex_opcode),
        .ex_funct(ex_funct),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd),
        .ex_shamt(ex_shamt)
    );

    // EX Stage

    // ALU Control Logic
    alu_control alu_ctrl (
        .alu_op(ex_AluOp),
        .funct(ex_funct),
        .opcode(ex_opcode),
        .ALUControl(ex_ALUControl)
    );

    // Forwarding unit
    forwarding_unit fwd (
        .idex_rs(ex_rs),
        .idex_rt(ex_rt),
        .exmem_write_regaddr(mem_write_regaddr),
        .memwb_write_regaddr(wb_write_regaddr),
        .exmem_rt(mem_rt),
        .exmem_RegWrite(mem_RegWrite),
        .exmem_MemWrite(mem_MemWrite),
        .memwb_RegWrite(wb_RegWrite),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .forwardMem(forwardMem)
    );

    // set isShift to 1 for sll, srl, sra
    wire ex_isShift = (ex_opcode == 6'b000000) && 
    ((ex_funct == 6'b000000) || (ex_funct == 6'b000010) || (ex_funct == 6'b000011));

    // ALU
    // assign ex_SrcA = (ex_isShift) ? {27'b0, ex_shamt} : ex_read_regdata1;
    // assign ex_SrcB = (ex_AluSrc) ? ex_sext_imm : ex_read_regdata2;
    // Forwarding MUX for ALU inputs
    assign ex_SrcA = (forwardA == 2'b10) ? mem_alu_result :
                    (forwardA == 2'b01) ? wb_write_memdata : ex_read_regdata1;

    assign ex_SrcB = (forwardB == 2'b10) ? mem_alu_result :
                    (forwardB == 2'b01) ? wb_write_memdata :
                    ((ex_AluSrc) ? ex_sext_imm : ex_read_regdata2);
    alu ALU (
        .a(ex_SrcA),
        .b(ex_SrcB),
        .ALUControl(ex_ALUControl),
        .result(ex_alu_result),
        .Zero(ex_AluZero)
    );

    // set branch target address
    assign ex_branch_target = ex_pc_plus_4 + (ex_sext_imm << 2);

    // assign wa from rd or rt based on RegDst
    assign ex_write_regaddr = (ex_RegDst) ? ex_rd : ex_rt;

    // EX/MEM Pipeline Register
    ex_mem_reg ex_mem (
        .clk(clk),
        .reset(reset),
        .flush(exmem_flush),
        .stall(~exmem_write),
        // Control Inputs
        .ex_MemtoReg(ex_MemtoReg),
        .ex_RegWrite(ex_RegWrite),
        .ex_MemRead(ex_MemRead),
        .ex_MemWrite(ex_MemWrite),
        .ex_Branch(ex_Branch),
        .ex_AluZero(ex_AluZero),
        // Data Inputs
        .ex_alu_result(ex_alu_result),
        .ex_write_memdata(ex_read_regdata2),
        .ex_write_regaddr(ex_write_regaddr),
        .ex_branch_target(ex_branch_target),
        .ex_rt(ex_rt),
        // Control Outputs
        .mem_MemtoReg(mem_MemtoReg),
        .mem_RegWrite(mem_RegWrite),
        .mem_MemRead(mem_MemRead),
        .mem_MemWrite(mem_MemWrite),
        .mem_Branch(mem_Branch),
        .mem_AluZero(mem_AluZero),
        // Data Outputs
        .mem_alu_result(mem_alu_result),
        .mem_write_memdata(mem_write_memdata),
        .mem_write_regaddr(mem_write_regaddr),
        .mem_branch_target(mem_branch_target),
        .mem_rt(mem_rt)
    );

    // MEM  Stage

    // Forwarding for store-use hazard
    assign dm_write_memdata = (forwardMem) ? wb_write_memdata : mem_write_memdata;

    // Data Cache
    sa_cache dcache (
        .clk(clk),
        .reset(reset),
        .MemWrite(mem_MemWrite),
        .MemRead(mem_MemRead),
        .addr(mem_alu_result),
        .wd(dm_write_memdata),
        .rd(mem_read_memdata),
        .mem_stall(cache_stall),
        // Memory interface
        .mem_req(cache_mem_req),
        .mem_we(cache_mem_we),
        .mem_addr(cache_mem_addr),
        .mem_wd(cache_mem_wd),
        .mem_rd(cache_mem_rd),
        .mem_ready(cache_mem_ready),
        // stats
        .total_accesses(cache_accesses),
        .hit_count(cache_hits),
        .miss_count(cache_misses)
    );

    // Data Memory
    data_mem dmem (
        .clk(clk),
        .we(cache_mem_we),
        .req(cache_mem_req),
        .addr(cache_mem_addr),
        .wd(cache_mem_wd),
        .rd(cache_mem_rd),
        .mem_ready(cache_mem_ready)
    );

    // Branch logic
    assign branch_taken = mem_Branch & ~mem_AluZero;
    assign PcSrc = branch_taken;
    assign flush_req = branch_taken;

    // MEM/WB Pipeline Register
    mem_wb_reg mem_wb (
        .clk(clk),
        .reset(reset),
        .stall(~memwb_write),
        // Control Inputs
        .mem_MemtoReg(mem_MemtoReg),
        .mem_RegWrite(mem_RegWrite),
        // Data Inputs
        .mem_alu_result(mem_alu_result),
        .mem_read_memdata(mem_read_memdata),
        .mem_write_regaddr(mem_write_regaddr),
        // Control Outputs
        .wb_MemtoReg(wb_MemtoReg),
        .wb_RegWrite(wb_RegWrite),
        // Data Outputs
        .wb_alu_result(wb_alu_result),
        .wb_read_memdata(wb_read_memdata),
        .wb_write_regaddr(wb_write_regaddr)
    );

    // WB Stage

    // Writeback Mux (selects alu result or memory data)
    assign wb_write_memdata = (wb_MemtoReg) ? wb_read_memdata : wb_alu_result;

endmodule