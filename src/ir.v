module ir(
    input wire [31:0] in,
    input wire clk,
    input wire ir_write, 
    output reg [31:0] ir
);
    always @(posedge clk) begin
        if (ir_write) ir <= in;
    end
endmodule
