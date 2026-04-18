module pipelined_mips_test;

    reg clk;
    reg reset;
    integer i;
    integer ok;

    // instantiate processor
    pipelined_mips_processor processor (
        .clk(clk),
        .reset(reset)
    );

    // toggle clock every 5 ns
    always #5 clk = ~clk;

    // Initialize clock, reset and memory
    initial begin

        // $dumpfile("pipelined_mips_test1.vcd");
        $dumpfile("pipelined_mips_test2.vcd");
        $dumpvars(0, pipelined_mips_test);
        
        clk = 0;
        reset = 1;
        #10; reset = 0;

        // load instructions from program file
        $display("Loading Program....");
        // $readmemh("programs/prog4.hex", processor.imem.mem, 0, 10); 
        $readmemh("programs/prog6.hex", processor.imem.mem); 
        #1000;

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

        // Expected results
        // ok = 1;

        // if (processor.rf.registers[8]  !== 32'd8)   begin ok=0; $display("FAIL: $t0 != 8"); end
        // if (processor.rf.registers[9]  !== 32'd15)  begin ok=0; $display("FAIL: $t1 != 15"); end
        // if (processor.rf.registers[10] !== 32'd15)  begin ok=0; $display("FAIL: $t2 != 15"); end
        // if (processor.rf.registers[11] !== 32'd30)  begin ok=0; $display("FAIL: $t3 != 30"); end
        // if (processor.rf.registers[12] !== 32'd15)  begin ok=0; $display("FAIL: $t4 != 15"); end
        // if (processor.rf.registers[16] !== 32'd45)  begin ok=0; $display("FAIL: $s0 != 45"); end
        // if (processor.dmem.mem[8>>2]   !== 32'd15)  begin ok=0; $display("FAIL: Mem[8] != 15"); end

        // if (ok) $display("PASS: hazard unit inserted 4 NOPs. architectural state correct.");
        // else     $fatal(1, "FAIL: final state incorrect.");
        $finish;
    end
endmodule
