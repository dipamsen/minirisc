module pcunit(
    input wire [31:0] immE, rA,
    input wire clk,
    input wire pc_write,
    input wire [2:0] br_type,
    output reg [31:0] pc
);
    wire [31:0] nextpc, operand;
    wire zero, neg, take;

    assign zero = ~|rA;
    assign neg = rA[31];

    assign take = (br_type == 1) | ((br_type == 2) & zero) | ((br_type == 3) & neg) | ((br_type == 4) & ~neg);

    assign operand = immE & {32{take}};

    adder addr(.a(pc), .b(operand), .cin(1'b1), .out(nextpc));

    initial pc = 0;

    always @(posedge clk) begin
        if (pc_write) pc <= nextpc;
    end

endmodule
