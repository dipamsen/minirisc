module mux2to1 #(parameter WIDTH = 32) (input wire [WIDTH-1:0] in1, input wire [WIDTH-1:0] in2, input wire sel, output reg [WIDTH-1:0] out);
    always @(*) begin
        if (sel) out = in2;
        else out = in1;
    end
endmodule
