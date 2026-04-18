module sc_mips_test;
    
    reg clk;
    reg rst;

    integer i;

    // instantiate single cycle microprocessor
    sc_mips_processor processor (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin

        // $dumpfile("mips_test_1.vcd");
        // $dumpfile("mips_test_2.vcd");
        $dumpfile("mips_test_3.vcd");
        $dumpvars(0, sc_mips_test);

        clk = 0;
        rst = 1; 
        // set reset to 0 at next clock cycle
        #10; rst = 0;

        // load instructions from program file
        $display("Loading Program....");
        // $readmemh("programs/prog1.hex", processor.imem.mem, 0, 11); #400;
        // $readmemh("programs/prog2.hex", processor.imem.mem, 0, 11); #400;
        $readmemh("programs/prog3.hex", processor.imem.mem, 0, 21); #1000;

        // When done, display data memory contents
        $display("\n==== Data Memory Dump ====");
        for (i = 0; i < 128; i = i + 1)
            begin
                if (processor.dmem.mem[i] != 0)
                    $display("mem[%-3d] = %h --> %-3d", i, processor.dmem.mem[i], processor.dmem.mem[i]);
            end
        // Display registers
        $display("\n==== Register File Dump ====");
        for (i = 0; i < 32; i = i + 1)
            begin
                if (processor.rf.registers[i] != 0)
                    $display("reg[%-3d] = %h --> %-3d", i, processor.rf.registers[i], processor.rf.registers[i]);
            end
            
        $display("============================\nSimulation finished.");
        $finish;
    end

endmodule