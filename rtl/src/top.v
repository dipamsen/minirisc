`timescale 1ns/1ps

module minirisc_top (
    input wire clk,
    input wire rst
);
    wire [2:0] br_type;
    wire pc_write, ir_write, reg_read, reg_dest, reg_write, imm_ext;
    wire sub, shamt_sel, acc_ld, mul_start, mac_mode, data_write, mem_en;
    wire [1:0] reg_src, alu_src, shift_sel, alu_sel;
    wire [2:0] logic_sel;
    
    wire done;
    wire [7:0] op;
    wire [6:0] fn;

    control_unit ctrl (
        .clk(clk),
        .rst(rst),
        .op(op),
        .fn(fn),
        .done(done),
        .br_type(br_type),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .reg_read(reg_read),
        .reg_dest(reg_dest),
        .reg_write(reg_write),
        .reg_src(reg_src),
        .imm_ext(imm_ext),
        .alu_src(alu_src),
        .sub(sub),
        .shamt_sel(shamt_sel),
        .shift_sel(shift_sel),
        .logic_sel(logic_sel),
        .alu_sel(alu_sel),
        .acc_ld(acc_ld),
        .mul_start(mul_start),
        .mac_mode(mac_mode),
        .data_write(data_write),
        .mem_en(mem_en)
    );

    datapath dp (
        .clk(clk),
        .br_type(br_type),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .reg_read(reg_read),
        .reg_dest(reg_dest),
        .reg_write(reg_write),
        .reg_src(reg_src),
        .imm_ext(imm_ext),
        .alu_src(alu_src),
        .sub(sub),
        .shamt_sel(shamt_sel),
        .shift_sel(shift_sel),
        .logic_sel(logic_sel),
        .alu_sel(alu_sel),
        .acc_ld(acc_ld),
        .mul_start(mul_start),
        .mac_mode(mac_mode),
        .data_write(data_write),
        .mem_en(mem_en),
        .done(done),
        .op(op),
        .fn(fn)
    );
endmodule
