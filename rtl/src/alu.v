module alu(
    input wire [31:0] x, y,
    input wire sub, shamt_sel,
    input wire [1:0] shift_sel,
    input wire [2:0] logic_sel,
    input wire [1:0] alu_sel,
    output wire [31:0] alu_out
);

    wire [31:0] yxorsub;
    assign yxorsub = sub ? ~y : y;

    wire [31:0] adder_out, shift_out, logic_out, shamt;

    adder adr(.a(x), .b(yxorsub), .cin(sub), .out(adder_out));

    mux2to1 mux1(.in1(y), .in2(16), .sel(shamt_sel), .out(shamt));

    shifter shft(.val(x), .shamt(shamt[4:0]), .mode(shift_sel), .shift_out(shift_out));

    logicunit lu(.in1(x), .in2(y), .mode(logic_sel), .out(logic_out));

    mux4to1 mux2(
        .in1(shift_out),
        .in2(adder_out),
        .in3({31'b0, adder_out[31]}),
        .in4(logic_out),
        .sel(alu_sel),
        .out(alu_out)
    );


endmodule

module logicunit(
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire [2:0] mode,
    output reg [31:0] out
);
    always @(*) begin
        case (mode) 
            0: out = in1 & in2;
            1: out = in1 | in2;
            2: out = in1 ^ in2;
            3: out = ~(in1 | in2);
            4: out = ~in1;
            default: out = 32'b0;
        endcase
    end
endmodule

module shifter (
    input  wire [31:0] val,
    input  wire [4:0]  shamt,
    input  wire [1:0]  mode,
    output reg [31:0] shift_out
);

    always @(*) begin
        case (mode)
            2'b00:   shift_out = val;
            2'b01:   shift_out = val << shamt;
            2'b10:   shift_out = val >> shamt;
            2'b11:   shift_out = $signed(val) >>> shamt;
            default: shift_out = 32'b0;
        endcase
    end

endmodule
