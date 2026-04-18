module alu(
    input [31:0] a, b,
    input [3:0] ALUControl,
    output reg [31:0] result,
    output Zero
);

    // ALU Operation codes
    localparam AND = 4'b0000;
    localparam OR = 4'b0001;
    localparam NOR = 4'b0010;
    localparam ADD = 4'b0011;
    localparam SUB = 4'b0100;
    localparam MUL = 4'b0101;
    localparam SLL = 4'b0110;
    localparam SRL = 4'b0111;
    localparam SLT = 4'b1000;

    always @(*) begin
        case (ALUControl)
            AND: result = a & b;
            OR: result = a | b;
            NOR: result = ~ (a | b);
            ADD: result = a + b;
            SUB: result = a - b;
            MUL: result = a * b;
            SLL: result = b << a[4:0];
            SRL: result = b >> a[4:0];
            SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'b0;
        endcase
    end
    assign Zero = (result == 32'b0);
endmodule