// address = 32 bits, word = 4 bytes
// cache_size = 8 KB = 8192 Bytes
// block_size = 32 bytes
// number_of_lines = cache_size/block_size = 256
// addr_offset_bits = log2(32) = 5 bits
// index_bits = log2(256) = 8 bits
// tag_bits = 32-8-5 = 19 bits
// words_per_block = 32/4 = 8

module dm_cache (
    input clk,
    input reset,
    input MemWrite,
    input MemRead,
    input [31:0] addr,
    input [31:0] wd,
    output [31:0] rd,
    output mem_stall,

    // Memory Interface (word-at-a-time burst)
    output reg mem_req,
    output reg mem_we,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wd,
    input [31:0] mem_rd,
    input mem_ready,

    // Statistics
    output reg [31:0] total_accesses,
    output reg [31:0] hit_count,
    output reg [31:0] miss_count
);

    // Cache storage
    reg [18:0] tag_store [0:255];
    reg valid [0:255];
    reg dirty [0:255];
    reg [31:0] data_store [0:255][0:7];

    // Address breakdown
    wire [18:0] tag_in = addr[31:13];
    wire [7:0] index = addr[12:5];
    wire [2:0] word_idx = addr[4:2];

    // save address/data during stall or miss
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg saved_is_write;
    wire [18:0] saved_tag = saved_addr[31:13];
    wire [7:0] saved_index = saved_addr[12:5];
    wire [2:0] saved_word = saved_addr[4:2];

    // FSM States
    localparam IDLE = 2'd0, WRITEBACK = 2'd1, REFILL = 2'd2;
    reg [1:0] state;
    reg [2:0] word_counter;
    reg [31:0] temp_block [0:7];

    // Hit/Miss Detection
    wire [7:0] op_index = (state == IDLE) ? index : saved_index;
    wire [18:0] op_tag = (state == IDLE) ? tag_in : saved_tag;
    wire hit = valid[op_index] && (tag_store[op_index] == op_tag);
    wire miss = !hit;
    wire needs_writeback = valid[op_index] && dirty[op_index];

    // flag to prevent double counting
    reg after_miss;

    // assign mem stall and rd
    assign mem_stall = (state != IDLE) || ((MemRead || MemWrite) && miss);
    assign rd = (state == IDLE && hit && MemRead) ? data_store[index][word_idx] : 32'h0;

    // FSM & Cache Logic
    // combinational logic
    always @(*) begin
        mem_req = 0;
        mem_we = 0;
        mem_addr = 32'b0;
        mem_wd = 32'b0;

        case (state)
            IDLE: mem_req = 0;
            WRITEBACK: begin
                mem_req = 1;
                mem_we = 1;
                mem_addr = {tag_store[saved_index], saved_index, word_counter, 2'b00};
                mem_wd = data_store[saved_index][word_counter];
            end
            REFILL: begin
                mem_req = 1;
                mem_we = 0;
                mem_addr = {saved_addr[31:5], word_counter, 2'b00};
            end
        endcase
    end

    // sequential logic
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            word_counter <= 0;
            total_accesses <= 0; hit_count <= 0; miss_count <= 0;
            
            for (i = 0; i < 256; i = i + 1) begin
                valid[i] <= 0;
                dirty[i] <= 0;
            end
        end else begin
            case (state)
                // IDLE State
                IDLE: begin
                    word_counter <= 0;

                    // check if we just come from a Refill
                    if (after_miss) begin
                        after_miss <= 0; 
                    end

                    else if (MemRead || MemWrite) begin
                        // update stats
                        total_accesses <= total_accesses + 1;
                        if (hit) hit_count <= hit_count + 1;
                        else miss_count <= miss_count + 1;
                        
                        // Cache hit
                        if (hit) begin
                            if (MemWrite) begin
                                data_store[index][word_idx] <= wd;
                                dirty[index] <= 1;
                            end
                        end else begin
                            // Cache miss
                            saved_addr <= addr; saved_data <= wd; saved_is_write <= MemWrite;                          
                            if (needs_writeback) 
                                state <= WRITEBACK;
                            else 
                                state <= REFILL;
                        end
                    end
                end

                // WRITEBACK State
                WRITEBACK: begin                   
                    if (mem_ready) begin
                        if (word_counter == 3'd7) begin
                            word_counter <= 0;
                            state <= REFILL;
                        end else begin
                            word_counter <= word_counter + 1;
                        end
                    end
                end

                // REFILL State
                REFILL: begin                   
                    if (mem_ready) begin
                        temp_block[word_counter] <= mem_rd;
                        
                        if (word_counter == 3'd7) begin
                            // Refill complete - update cache line
                            tag_store[saved_index] <= saved_tag;
                            valid[saved_index] <= 1;
                            dirty[saved_index] <= saved_is_write;
                            
                            // Copy all words from temp buffer to cache
                            for (i = 0; i < 7; i = i + 1) begin
                                data_store[saved_index][i] <= temp_block[i];
                            end
                            data_store[saved_index][7] <= mem_rd; 
                            
                            // Apply CPU write if write-allocate
                            if (saved_is_write) begin
                                data_store[saved_index][saved_word] <= saved_data;
                            end

                            after_miss <= 1;
                            state <= IDLE;
                            word_counter <=0;
                        end else begin
                            word_counter <= word_counter + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule