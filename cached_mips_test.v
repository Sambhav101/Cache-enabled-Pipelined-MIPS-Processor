module cached_mips_test;

    reg clk;
    reg reset;
    integer i;

    // instantiate processor
    cached_mips_processor processor (
        .clk(clk),
        .reset(reset)
    );

    // toggle clock every 5 ns (Period = 10ns)
    always #5 clk = ~clk;

    // Safety Timeout
    initial begin
        #200000; 
        $display("\n[ERROR] TIMEOUT: Simulation took too long!");
        $finish;
    end

    initial begin
        // Waveform generation for GTKWave
        $dumpfile("cached_mips_test1.vcd");
        $dumpvars(0, cached_mips_test);
        
        clk = 0;
        reset = 1;
        #10; reset = 0;

        $display("Loading Program and Starting Simulation...");
        
        // Load instructions
        $readmemh("programs/prog8.hex", processor.imem.mem); 
        
        // TRAP LOGI
        // Wait until Register 8 equals 128 (Result of 32 * 4)
        wait (processor.rf.registers[8] === 32'd400); 

        // Wait extra cycles for pipeline flush
        #200;

        // SIMULATION REPORT
        $display("\n\n");
        $display("==================================================================");
        $display("                    MIPS PROCESSOR SIMULATION REPORT              ");
        $display("==================================================================");


        // SECTION 1: CACHE STATISTICS 
        $display("\n[1] CACHE PERFORMANCE METRICS");
        $display("+-----------------------+------------------+");
        $display("| Metric                | Value            |");
        $display("+-----------------------+------------------+");
        $display("| Total Accesses        | %16d |", processor.cache_accesses);
        $display("| Cache Hits            | %16d |", processor.cache_hits);
        $display("| Cache Misses          | %16d |", processor.cache_misses);
        $display("+-----------------------+------------------+");

        // Hit Rate
        $write("Hit Rate: %0.2f%%  [", (processor.cache_hits*100.0)/processor.cache_accesses);

        // REGISTER FILE
        $display("[2] REGISTER FILE STATE (Non-Zero)");
        $display("+------+------------+------+------------+------+------------+------+------------+");
        
        // Loop to print in 4 columns
        for (i = 0; i < 32; i = i + 1) begin
            if (processor.rf.registers[i] != 0) begin
                $write("| R%02d: %h (%3d) ", i, processor.rf.registers[i], processor.rf.registers[i]);
            end
        end
        $display("\n+------+------------+------+------------+------+------------+------+------------+");

        // CACHE CONTENT (valid lines only)
        // $display("\n[3] CACHE CONTENT SNAPSHOT (Valid & Dirty Lines)");
        // $display("   Set | Tag   | D | Word 0   Word 1   Word 2   Word 3   Word 4   Word 5   Word 6   Word 7");
        // $display("-------+-------+---+-------------------------------------------------------------------------");

        // for (i = 0; i < 256; i = i + 1) begin
        //     if (processor.dcache.valid[i]) begin
        //         $display("   %3d | %5h | %1b | %8d %8d %8d %8d %8d %8d %8d %8d", 
        //             i, 
        //             processor.dcache.tag_store[i], 
        //             processor.dcache.dirty[i],
        //             processor.dcache.data_store[i][0],
        //             processor.dcache.data_store[i][1],
        //             processor.dcache.data_store[i][2],
        //             processor.dcache.data_store[i][3],
        //             processor.dcache.data_store[i][4],
        //             processor.dcache.data_store[i][5],
        //             processor.dcache.data_store[i][6],
        //             processor.dcache.data_store[i][7]
        //         );
        //     end
        // end
        // $display("-------+-------+---+-------------------------------------------------------------------------");

        // ---------------------------------------------------------
        // SECTION 3: 2-WAY CACHE DUMP
        // ---------------------------------------------------------
        // $display("\n[3] CACHE CONTENT SNAPSHOT (Active Sets Only)");
        // $display("Set | MRU Way | Way | Tag   | D | Words 0-7 (Hex)");
        // $display("----+---------+-----+-------+---+-----------------------------------------");

        // // Iterate through 128 Sets
        // for (i = 0; i < 128; i = i + 1) begin
        //     // Print set only if at least one way is valid
        //     if (processor.dcache.valid[i][0] || processor.dcache.valid[i][1]) begin
                
        //         // --- WAY 0 ---
        //         if (processor.dcache.valid[i][0]) begin
        //             $display("%3d |    %1d    |  0  | %5h | %1b | %h %h %h %h %h %h %h %h", 
        //                 i, processor.dcache.use_bit[i], 
        //                 processor.dcache.tag_store[i][0], 
        //                 processor.dcache.dirty[i][0],
        //                 processor.dcache.data_store[i][0][0], processor.dcache.data_store[i][0][1],
        //                 processor.dcache.data_store[i][0][2], processor.dcache.data_store[i][0][3],
        //                 processor.dcache.data_store[i][0][4], processor.dcache.data_store[i][0][5],
        //                 processor.dcache.data_store[i][0][6], processor.dcache.data_store[i][0][7]
        //             );
        //         end else begin
        //             $display("%3d |    %1d    |  0  | ----- | - | (Empty)", i, processor.dcache.use_bit[i]);
        //         end

        //         // --- WAY 1 ---
        //         if (processor.dcache.valid[i][1]) begin
        //             $display("    |         |  1  | %5h | %1b | %h %h %h %h %h %h %h %h", 
        //                 processor.dcache.tag_store[i][1], 
        //                 processor.dcache.dirty[i][1],
        //                 processor.dcache.data_store[i][1][0], processor.dcache.data_store[i][1][1],
        //                 processor.dcache.data_store[i][1][2], processor.dcache.data_store[i][1][3],
        //                 processor.dcache.data_store[i][1][4], processor.dcache.data_store[i][1][5],
        //                 processor.dcache.data_store[i][1][6], processor.dcache.data_store[i][1][7]
        //             );
        //         end else begin
        //             $display("    |         |  1  | ----- | - | (Empty)");
        //         end
        //         $display("----+---------+-----+-------+---+-----------------------------------------");
        //     end
        // end


        // MAIN MEMORY
        // $display("\n[4] MAIN MEMORY DUMP (Non-Zero)");
        // $display("Address    (Idx) | Value (Dec)");
        // $display("------------+-------------+-------------");
        // for (i = 0; i < 128; i = i + 1) begin
        //     if (processor.dmem.mem[i] !== 0) begin
        //         $display("0x%03h (%3d) | %-11d", i*4, i, processor.dmem.mem[i]);
        //     end
        // end
        // $display("------------+-------------+-------------");

        $display("\nSimulation Finished Successfully");
        $finish;
    end
endmodule