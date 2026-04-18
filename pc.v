module pc (
    input clk,
    input reset,
    input write_enable,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);
    always @(posedge clk) begin
        if (reset)
            pc_out <= 32'b0;
        // update pc if write_enable is 1, else hold current value
        else if (write_enable)
            pc_out <= pc_in;
    end
endmodule
