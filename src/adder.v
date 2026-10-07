module carry_lookahead_unit (
    input wire [3:0] p,
    input wire [3:0] g,
    input wire cin,
    output wire [3:0] c,
    output wire p_blk,
    output wire g_blk
);
    assign c[0] = g[0] | (p[0] & cin);
    assign c[1] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);

    assign p_blk = &p;
    assign g_blk = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
endmodule

module cla_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire cin,
    output wire [3:0] sum,
    output wire cout,
    output wire p_blk,
    output wire g_blk
);
    wire [3:0] p = a ^ b;
    wire [3:0] g = a & b;
    wire [3:0] c;

    carry_lookahead_unit gen (
        .p(p),
        .g(g),
        .cin(cin),
        .c(c),
        .p_blk(p_blk),
        .g_blk(g_blk)
    );

    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c[0];
    assign sum[2] = p[2] ^ c[1];
    assign sum[3] = p[3] ^ c[2];

    assign cout = c[3];
endmodule

module cla_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire cin,
    output wire [15:0] sum,
    output wire cout,
    output wire p_blk,
    output wire g_blk
);
    wire [3:0] blk_p;
    wire [3:0] blk_g;
    wire [3:0] c;

    carry_lookahead_unit l2_gen (
        .p(blk_p),
        .g(blk_g),
        .cin(cin),
        .c(c),
        .p_blk(p_blk),
        .g_blk(g_blk)
    );

    cla_4bit b0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .sum(sum[3:0]),
        .p_blk(blk_p[0]),
        .g_blk(blk_g[0])
    );

    cla_4bit b1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c[0]),
        .sum(sum[7:4]),
        .p_blk(blk_p[1]),
        .g_blk(blk_g[1])
    );

    cla_4bit b2 (
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(c[1]),
        .sum(sum[11:8]),
        .p_blk(blk_p[2]),
        .g_blk(blk_g[2])
    );

    cla_4bit b3 (
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(c[2]),
        .sum(sum[15:12]),
        .p_blk(blk_p[3]),
        .g_blk(blk_g[3])
    );

    assign cout = c[3];
endmodule

module adder (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire cin,
    output wire [31:0] out,
    output wire cout
);
    wire p16_0, g16_0;
    wire p16_1, g16_1;
    wire c16;

    assign c16 = g16_0 | (p16_0 & cin);

    cla_16bit lower_16 (
        .a(a[15:0]),
        .b(b[15:0]),
        .cin(cin),
        .sum(out[15:0]),
        .p_blk(p16_0),
        .g_blk(g16_0)
    );

    cla_16bit upper_16 (
        .a(a[31:16]),
        .b(b[31:16]),
        .cin(c16),
        .sum(out[31:16]),
        .p_blk(p16_1),
        .g_blk(g16_1)
    );

    assign cout = g16_1 | (p16_1 & c16);
endmodule
