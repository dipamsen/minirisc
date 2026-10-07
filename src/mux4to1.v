module mux4to1 #(parameter WIDTH = 32) (input wire [WIDTH-1:0] in1, in2, in3, in4, input wire [1:0] sel, output reg [WIDTH-1:0] out);
    always @(*) begin
        case (sel) 
            0: out = in1;
            1: out = in2;
            2: out = in3;
            3: out = in4;
            default: ;
        endcase
    end
endmodule
