module ex_mem_reg (
    input clk,
    input reset,
    input flush,
    input stall,
    input write_enable,
    
    // Control Signals from EX
    input ex_MemtoReg,
    input ex_RegWrite,
    input ex_MemRead,
    input ex_MemWrite,
    input ex_Branch,
    input ex_AluZero,
    
    // Data from EX
    input [31:0] ex_alu_result,
    input [31:0] ex_write_memdata,
    input [4:0] ex_write_regaddr,
    input [31:0] ex_branch_target,
    input [4:0] ex_rt,                  // data for forwarding logic for MEM-MEM

    // Control Signals to MEM
    output reg mem_MemtoReg,
    output reg mem_RegWrite,
    output reg mem_MemRead,
    output reg mem_MemWrite,
    output reg mem_Branch,
    output reg mem_AluZero,
    
    // Data outputs to MEM
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_write_memdata,
    output reg [4:0] mem_write_regaddr,
    output reg [31:0] mem_branch_target,
    output reg [4:0] mem_rt
);
    
    always @(posedge clk) begin
        // clear everything when reset
        if (reset || flush) begin
            mem_MemtoReg <= 1'b0;
            mem_RegWrite <= 1'b0;
            mem_MemRead <= 1'b0;
            mem_MemWrite <= 1'b0;
            mem_Branch <= 1'b0;
            mem_AluZero <= 1'b0;
            mem_alu_result <= 32'b0;
            mem_write_memdata <= 32'b0;
            mem_write_regaddr <= 5'b0;
            mem_branch_target <= 32'b0;
            mem_rt <= 5'b0;
        end 
        else if (stall) begin
        end
        // pass the data and control signals to Mem
        else begin
            mem_MemtoReg <= ex_MemtoReg;
            mem_RegWrite <= ex_RegWrite;
            mem_MemRead <= ex_MemRead;
            mem_MemWrite <= ex_MemWrite;
            mem_Branch <= ex_Branch;
            mem_AluZero <= ex_AluZero;
            mem_alu_result <= ex_alu_result;
            mem_write_memdata <= ex_write_memdata;
            mem_write_regaddr <= ex_write_regaddr;
            mem_branch_target <= ex_branch_target;
            mem_rt <= ex_rt;
        end
    end
endmodule

