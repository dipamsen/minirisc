module inst_rom(
    input wire [9:0] addra,
    input wire clka,
    input wire ena,
    output reg [31:0] douta
);
    reg [31:0] mem [0:1023];

    initial douta = 0;

    always @(posedge clka) begin
        if (ena) douta <= mem[addra];
    end
endmodule

module data_ram(
    input wire [9:0] addra,
    input wire clka,
    input wire [31:0] dina,
    input wire ena,
    input wire wea,
    output reg [31:0] douta
);
    reg [31:0] mem [0:1023];

    initial douta = 0;

    always @(posedge clka) begin
        if (ena) begin
            if (wea) mem[addra] <= dina;
            douta <= mem[addra];
        end
    end
endmodule

// Placeholder only: the multiplier is not exercised by this testbench.
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