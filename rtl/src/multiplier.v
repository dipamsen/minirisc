module multiplier(
    input wire [31:0] x, y,
    input wire clk,
    input wire acc_ld,
    input wire mul_start,
    input wire mac_mode,
    output wire done,
    output wire [31:0] mul_out
);
    assign done = 0;
    assign mul_out = 0;
endmodule