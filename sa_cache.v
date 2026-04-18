// address = 32 bits, word = 4 bytes
// cache_size = 8 KB = 8192 Bytes
// block_size = 32 bytes
// Ways = 2 (2-Way Set Associative)
// Sets = 8192 / (32 * 2) = 128 sets
// addr_offset_bits = log2(32) = 5 bits
// index_bits = log2(128) = 7 bits
// tag_bits = 32 - 7 - 5 = 20 bits
// words_per_block = 32/4 = 8

module sa_cache (
    input clk,
    input reset,
    input MemWrite,
    input MemRead,
    input [31:0] addr,
    input [31:0] wd,
    output [31:0] rd,
    output mem_stall,

    // Memory Interface
    output reg mem_req,
    output reg mem_we,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wd,
    input [31:0] mem_rd,
    input mem_ready,

    // stats
    output reg [31:0] total_accesses,
    output reg [31:0] hit_count,
    output reg [31:0] miss_count
);

    // Cache storage: [Set][Way]
    reg [19:0] tag_store [0:127][0:1];
    reg valid [0:127][0:1];
    reg dirty [0:127][0:1];
    reg [31:0] data_store [0:127][0:1][0:7];
    
    // LRU Replacement Policy
    // use_bit[set] stores the MRU (Most Recently Used) way.
    // 0 = Way 0 is MRU (Victim is Way 1)
    // 1 = Way 1 is MRU (Victim is Way 0)
    reg use_bit [0:127];

    // Address breakdown
    wire [19:0] tag_in = addr[31:12];
    wire [6:0] index = addr[11:5];
    wire [2:0] word_idx = addr[4:2];

    // State Variables for Miss Handling
    reg [31:0] saved_addr;
    reg [31:0] saved_data;
    reg saved_is_write;
    
    // We must "lock in" which way we are evicting/filling once a miss starts
    reg saved_victim_way; 

    // Derived saved values
    wire [19:0] saved_tag = saved_addr[31:12];
    wire [6:0] saved_index = saved_addr[11:5];
    wire [2:0] saved_word = saved_addr[4:2];

    // FSM States
    localparam IDLE = 2'd0, WRITEBACK = 2'd1, REFILL = 2'd2;
    reg [1:0] state;
    reg [2:0] word_counter;
    reg [31:0] temp_block [0:7];
    
    reg after_miss;

    // HIT/MISS/VICTIM LOGIC
    
    // Check both ways for a match
    wire hit0 = valid[index][0] && (tag_store[index][0] == tag_in);
    wire hit1 = valid[index][1] && (tag_store[index][1] == tag_in);
    wire hit = hit0 || hit1;
    
    // Select data based on which way hit
    wire [31:0] read_data = hit1 ? data_store[index][1][word_idx] : data_store[index][0][word_idx];
    
    // Victim is the inverse of MRU bit
    wire victim_way_comb = ~use_bit[index];
    
    // Write-Back Condition: Does the Victim have dirty data?
    // Note: We check the victim based on current state (IDLE) or saved state (Miss)
    wire op_victim = (state == IDLE) ? victim_way_comb : saved_victim_way;
    wire [6:0] op_idx = (state == IDLE) ? index : saved_index;
    
    wire needs_writeback = valid[op_idx][op_victim] && dirty[op_idx][op_victim];

    // Outputs
    assign mem_stall = (state != IDLE) || ((MemRead || MemWrite) && !hit);
    assign rd = (state == IDLE && hit && MemRead) ? read_data : 32'h0;

    // combinational logic
    always @(*) begin
        mem_req = 0; mem_we = 0; mem_addr = 0; mem_wd = 0;

        case (state)
            IDLE: mem_req = 0;
            
            WRITEBACK: begin
                mem_req = 1;
                mem_we = 1;
                // Construct address from the VICTIM'S tag, not the requested address
                mem_addr = {tag_store[saved_index][saved_victim_way], saved_index, word_counter, 2'b00};
                mem_wd = data_store[saved_index][saved_victim_way][word_counter];
            end
            
            REFILL: begin
                mem_req = 1;
                mem_we = 0;
                mem_addr = {saved_addr[31:5], word_counter, 2'b00};
            end
        endcase
    end

    // SEQUENTIAL LOGIC
    integer k;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            word_counter <= 0;
            total_accesses <= 0; hit_count <= 0; miss_count <= 0;
            after_miss <= 0;
            
            for (k = 0; k < 128; k = k + 1) begin
                valid[k][0] <= 0; valid[k][1] <= 0;
                dirty[k][0] <= 0; dirty[k][1] <= 0;
                use_bit[k] <= 0; // Reset LRU (Way 0 is candidate)
            end
        end else begin
            
            case (state)
                IDLE: begin
                    word_counter <= 0;

                    if (after_miss) begin
                        after_miss <= 0; 
                    end
                    else if (MemRead || MemWrite) begin
                        total_accesses <= total_accesses + 1;
                        if (hit) hit_count <= hit_count + 1;
                        else miss_count <= miss_count + 1;
                        
                        if (hit) begin
                            // Cache Hit: Update LRU (MRU) bit
                            use_bit[index] <= hit1; 
                            
                            if (MemWrite) begin
                                if (hit1) begin
                                    data_store[index][1][word_idx] <= wd;
                                    dirty[index][1] <= 1;
                                end else begin
                                    data_store[index][0][word_idx] <= wd;
                                    dirty[index][0] <= 1;
                                end
                            end
                        end else begin
                            // Cache miss
                            saved_addr <= addr; 
                            saved_data <= wd; 
                            saved_is_write <= MemWrite;
                            // Lock in the victim for this entire transaction
                            saved_victim_way <= victim_way_comb;
                            if (needs_writeback) 
                                state <= WRITEBACK;
                            else 
                                state <= REFILL;
                        end
                    end
                end

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

                REFILL: begin
                    if (mem_ready) begin
                        temp_block[word_counter] <= mem_rd;
                        
                        if (word_counter == 3'd7) begin
                            // Update Metadata for the victim way
                            tag_store[saved_index][saved_victim_way] <= saved_tag;
                            valid[saved_index][saved_victim_way] <= 1;
                            dirty[saved_index][saved_victim_way] <= saved_is_write;
                            
                            // Update Data store table
                            for (k = 0; k < 7; k = k + 1) begin
                                data_store[saved_index][saved_victim_way][k] <= temp_block[k];
                            end
                            data_store[saved_index][saved_victim_way][7] <= mem_rd; 
                            
                            // Perform pending write
                            if (saved_is_write) begin
                                data_store[saved_index][saved_victim_way][saved_word] <= saved_data;
                            end
                            
                            // Update LRU: The way we just filled is now the Most Recently Used
                            use_bit[saved_index] <= saved_victim_way;
                            
                            after_miss <= 1; 
                            state <= IDLE;
                            word_counter <= 0;
                        end else begin
                            word_counter <= word_counter + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule