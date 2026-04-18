module hazard_unit(
    // inputs from IF/ID register
    input [4:0] ifid_rs,           
    input [4:0] ifid_rt,          

    // inputs from ID/EX register
    input idex_MemRead,             
    input idex_RegWrite,            
    input [4:0] idex_write_regaddr,  

    // inputs from EX/MEM register
    input exmem_RegWrite,
    input [4:0] exmem_write_regaddr, 

    // inputs from MEM/WB register
    input memwb_RegWrite,
    input [4:0] memwb_write_regaddr,

    // control hazard input
    input flush_req,                // 1 = jump or branch is taken

    // Outputs
    output reg pc_write,            // 0 = stall PC 
    output reg ifid_write,          // 0 = stall IF/ID
    output reg idex_flush,          // 1 = insert bubble (NOP) into ID/EX
    output reg ifid_flush          // 1 = flush instruction in IF/ID
);

    // Hazard Condition Wires 
    // EX Hazard
    wire ex_hazard = (idex_write_regaddr != 5'b0) && (idex_MemRead || idex_RegWrite) &&
                     ((idex_write_regaddr == ifid_rs) || (idex_write_regaddr == ifid_rt));

    // MEM Hazard
    wire mem_hazard = (exmem_write_regaddr != 5'b0) && exmem_RegWrite &&
                      ((exmem_write_regaddr == ifid_rs) || (exmem_write_regaddr == ifid_rt));
    
    // WB Hazard
    wire wb_hazard = (memwb_write_regaddr != 5'b0) && memwb_RegWrite && 
                     ((memwb_write_regaddr == ifid_rs) || (memwb_write_regaddr == ifid_rt));

    
    always @* begin
        // Default: no hazard and everything flows freely
        pc_write   = 1'b1;
        ifid_write = 1'b1;
        idex_flush = 1'b0;
        ifid_flush = 1'b0;

        // Control Hazard
        // When branch or jump, clear the instruction fetched into if/id
        if (flush_req) begin
            ifid_flush = 1'b1;
            idex_flush = 1'b1;
        end
        
        // // Stall if we get hazard from ex, mem or wb stage
        // else if (ex_hazard || mem_hazard || wb_hazard) begin
        //     pc_write   = 1'b0;        
        //     ifid_write = 1'b0;     
        //     idex_flush = 1'b1; // Insert NOP
        // end

        // stall for load_use hazard only
        else if (idex_MemRead && ((idex_write_regaddr == ifid_rs) || (idex_write_regaddr == ifid_rt))) begin
            pc_write   = 1'b0;        
            ifid_write = 1'b0;     
            idex_flush = 1'b1; // Insert NOP
        end
    end
endmodule