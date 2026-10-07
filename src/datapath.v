module datapath(
    input wire clk,

    input wire [2:0] br_type,
    input wire pc_write,
    input wire ir_write,

    input wire reg_read,
    input wire reg_dest,
    input wire reg_write,
    input wire [1:0] reg_src,

    input wire imm_ext,
    input wire [1:0] alu_src,
    input wire sub,
    input wire shamt_sel,
    input wire [1:0] shift_sel,
    input wire [2:0] logic_sel,
    input wire [1:0] alu_sel,

    input wire acc_ld,
    input wire mul_start,
    input wire mac_mode,

    input wire data_write,

    output wire [7:0] op,
    output wire [6:0] fn
);

    wire [31:0] rom_out, inst;
    wire [31:0] pc;

    assign op = inst[31:24];
    wire [3:0] rA = inst[23:20];
    wire [3:0] rB = inst[19:16];
    wire [3:0] rC = inst[15:12];
    wire [4:0] shamt = inst[11:7];
    assign fn = inst[6:0];
    wire [15:0] imm = inst[15:0];

    wire [3:0] write_addr, ra1;
    wire [31:0] writeback;
    wire [31:0] regOut1, regOut2, alu_out;
    wire [31:0] data_out, mul_out;
    wire [31:0] immE, alu_operand;

    inst_rom rom(
        .addra(pc[9:0]),
        .clka(clk),
        .douta(rom_out),
        .ena(1'b1)
    );

    pcunit pcu(
        .immE(immE),
        .rA(regOut1),
        .clk(clk),
        .br_type(br_type),
        .pc_write(pc_write),
        .pc(pc)
    );

    ir ir_reg(
        .in(rom_out),
        .clk(clk),
        .ir_write(ir_write),
        .ir(inst)
    );


    regfile rf(
        .ra1(ra1),
        .ra2(rB),
        .wrA(write_addr),
        .wrD(writeback),
        .clk(clk),
        .reg_write(reg_write),
        .out1(regOut1),
        .out2(regOut2)
    );

    mux2to1 #(.WIDTH(4)) mux1(
        .in1(rA),
        .in2(rC),
        .sel(reg_read),
        .out(ra1)
    );

    mux2to1 #(.WIDTH(4)) mux2(
        .in1(rB),
        .in2(rC),
        .sel(reg_dest),
        .out(write_addr)
    );

    mux4to1 mux3(
        .in1(data_out),
        .in2(alu_out),
        .in3(mul_out),
        .in4(0),
        .sel(reg_src),
        .out(writeback)
    );

    mux2to1 mux4(
        .in1({{16{imm[15]}}, imm}),
        .in2({16'b0, imm}),
        .sel(imm_ext),
        .out(immE)
    );

    mux4to1 mx(
        .in1(regOut2),
        .in2(immE),
        .in3({27'b0, shamt}),
        .in4(0),
        .sel(alu_src),
        .out(alu_operand)
    );

    alu alunit(
        .x(regOut1),
        .y(alu_operand),
        .sub(sub),
        .shamt_sel(shamt_sel),
        .shift_sel(shift_sel),
        .logic_sel(logic_sel),
        .alu_sel(alu_sel),
        .alu_out(alu_out)
    );

    multiplier mul(
        .x(regOut1),
        .y(regOut2),
        .clk(clk),
        .acc_ld(acc_ld),
        .mul_start(mul_start),
        .mac_mode(mac_mode),
        .done(done),
        .mul_out(mul_out)
    );

    data_ram ram(
        .addra(alu_out[9:0]),
        .clka(clk),
        .dina(regOut2),
        .douta(data_out),
        .ena(1'b1),
        .wea(data_write)
    );

endmodule
