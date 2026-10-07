module regfile(
    input wire [3:0] ra1, ra2, wrA, 
    input wire [31:0] wrD,
    input wire reg_write,
    input wire clk,
    output wire [31:0] out1,
    output wire [31:0] out2
);

    reg [31:0] r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15;

    initial begin
        r1 = 0; r2 = 0; r3 = 0; r4 = 0; r5 = 0; r6 = 0; r7 = 0; r8 = 0;
        r9 = 0; r10 = 0; r11 = 0; r12 = 0; r13 = 0; r14 = 0; r15 = 0;
    end

    mux16to1 m1(0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, ra1, out1);
    mux16to1 m2(0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, ra2, out2);

    always @(posedge clk) begin
        if (reg_write) begin
            if (wrA == 1) r1 <= wrD;
            if (wrA == 2) r2 <= wrD;
            if (wrA == 3) r3 <= wrD;
            if (wrA == 4) r4 <= wrD;
            if (wrA == 5) r5 <= wrD;
            if (wrA == 6) r6 <= wrD;
            if (wrA == 7) r7 <= wrD;
            if (wrA == 8) r8 <= wrD;
            if (wrA == 9) r9 <= wrD;
            if (wrA == 10) r10 <= wrD;
            if (wrA == 11) r11 <= wrD;
            if (wrA == 12) r12 <= wrD;
            if (wrA == 13) r13 <= wrD;
            if (wrA == 14) r14 <= wrD;
            if (wrA == 15) r15 <= wrD;
        end
    end

endmodule

module mux16to1(
    input wire [31:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, 
    input wire [3:0] sel,
    output reg [31:0] out
);
    always @(*) begin
        case (sel)
            0: out = r0;
            1: out = r1;
            2: out = r2;
            3: out = r3;
            4: out = r4;
            5: out = r5;
            6: out = r6;
            7: out = r7;
            8: out = r8;
            9: out = r9;
            10: out = r10;
            11: out = r11;
            12: out = r12;
            13: out = r13;
            14: out = r14;
            15: out = r15;
            default: out = 0;
        endcase
    end
endmodule
