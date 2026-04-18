module mem_wb_reg (
    input clk,
    input reset,
    input stall,
    input write_enable,

    // Control Signals from MEM
    input mem_MemtoReg,
    input mem_RegWrite,

    // Data from MEM
    input [31:0] mem_alu_result,
    input [31:0] mem_read_memdata,
    input [4:0] mem_write_regaddr,

    // Control Signals to WB
    output reg wb_MemtoReg,
    output reg wb_RegWrite,

    // Data outputs to WB
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_read_memdata,
    output reg [4:0] wb_write_regaddr
);

    always @(posedge clk) begin
        if(reset) begin
            wb_MemtoReg <= 1'b0;
            wb_RegWrite <= 1'b0;
            wb_alu_result <= 32'b0;
            wb_read_memdata <= 32'b0;
            wb_write_regaddr <= 5'b0;
        end 
        else if (stall) begin
        end
        else begin
            wb_MemtoReg <= mem_MemtoReg;
            wb_RegWrite <= mem_RegWrite;
            wb_alu_result <= mem_alu_result;
            wb_read_memdata <= mem_read_memdata;
            wb_write_regaddr <= mem_write_regaddr;
        end
    end
endmodule