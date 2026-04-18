module forwarding_unit (
    // source registers from EX stage
    input [4:0] idex_rs,
    input [4:0] idex_rt,

    // dest registers from MEM and WB
    input [4:0] exmem_write_regaddr,
    input [4:0] memwb_write_regaddr,
    input [4:0] exmem_rt,

    // control signals
    input exmem_RegWrite,
    input exmem_MemWrite,
    input memwb_RegWrite,

    // forwarding control outputs
    output reg [1:0] forwardA,
    output reg [1:0] forwardB,
    output reg forwardMem
);
    always @(*) begin
        // default: no forwarding
        forwardA   = 2'b00;
        forwardB   = 2'b00;
        forwardMem = 1'b0;

        // EX–EX forwarding
        if (exmem_RegWrite && (exmem_write_regaddr != 5'b0) && (exmem_write_regaddr == idex_rs))
            forwardA = 2'b10;
        if (exmem_RegWrite && (exmem_write_regaddr != 5'b0) && (exmem_write_regaddr == idex_rt))
            forwardB = 2'b10;

        // MEM–EX forwarding
        if (memwb_RegWrite && (memwb_write_regaddr != 5'b0) && (memwb_write_regaddr == idex_rs) && (forwardA == 2'b00))
            forwardA = 2'b01;
        
        if (memwb_RegWrite && (memwb_write_regaddr != 5'b0) && (memwb_write_regaddr == idex_rt) && (forwardB == 2'b00))
            forwardB = 2'b01;

        // MEM–MEM forwarding
        if (exmem_MemWrite && memwb_RegWrite && (memwb_write_regaddr != 5'b0) && (memwb_write_regaddr == exmem_rt))
            forwardMem = 1'b1;
    end
endmodule