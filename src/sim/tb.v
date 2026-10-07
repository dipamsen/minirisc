`timescale 1ns/1ps

module tb_datapath();
    localparam OP_R    = 8'h00;
    localparam OP_ADDI = 8'h10;
    localparam OP_ORI  = 8'h11;

    localparam FN_ADD  = 7'd0;
    localparam FN_SUB  = 7'd1;
    localparam FN_AND  = 7'd2;
    localparam FN_SLL  = 7'd3;
    localparam FN_SLT  = 7'd4;

    reg clk;

    reg [2:0] br_type;
    reg pc_write, ir_write;
    reg reg_read, reg_dest, reg_write;
    reg [1:0] reg_src;
    reg imm_ext;
    reg [1:0] alu_src;
    reg sub, shamt_sel;
    reg [1:0] shift_sel;
    reg [2:0] logic_sel;
    reg [1:0] alu_sel;
    reg acc_ld, mul_start, mac_mode;
    reg data_write;

    wire done;
    wire [7:0] op;
    wire [6:0] fn;

    integer errors;
    integer checks;

    datapath dut(
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
        .op(op),
        .fn(fn)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Instruction encoders: R-type {op, rA, rB, rC, shamt, fn}
    //                       I-type {op, rA, rB, imm16}
    // ------------------------------------------------------------
    function [31:0] rtype(input [7:0] o, input [3:0] ra, input [3:0] rb, input [3:0] rc, input [4:0] sh, input [6:0] f);
        rtype = {o, ra, rb, rc, sh, f};
    endfunction

    function [31:0] itype(input [7:0] o, input [3:0] ra, input [3:0] rb, input [15:0] i);
        itype = {o, ra, rb, i};
    endfunction

    // Reads a register straight out of the register file (R0 has no storage, it is hardwired to 0)
    function [31:0] getreg(input [3:0] n);
        case (n)
            0:  getreg = 32'd0;
            1:  getreg = dut.rf.r1;
            2:  getreg = dut.rf.r2;
            3:  getreg = dut.rf.r3;
            4:  getreg = dut.rf.r4;
            5:  getreg = dut.rf.r5;
            6:  getreg = dut.rf.r6;
            7:  getreg = dut.rf.r7;
            8:  getreg = dut.rf.r8;
            9:  getreg = dut.rf.r9;
            10: getreg = dut.rf.r10;
            11: getreg = dut.rf.r11;
            12: getreg = dut.rf.r12;
            13: getreg = dut.rf.r13;
            14: getreg = dut.rf.r14;
            15: getreg = dut.rf.r15;
        endcase
    endfunction

    task check(input [255:0] name, input [31:0] got, input [31:0] exp);
        begin
            checks = checks + 1;
            if (got === exp) $display("  PASS  %0s = 0x%08h", name, got);
            else begin
                $display("  FAIL  %0s = 0x%08h (expected 0x%08h)", name, got, exp);
                errors = errors + 1;
            end
        end
    endtask

    task ctrl_idle;
        begin
            br_type = 0; pc_write = 0; ir_write = 0;
            reg_read = 0; reg_dest = 0; reg_write = 0; reg_src = 1;
            imm_ext = 0; alu_src = 0;
            sub = 0; shamt_sel = 0; shift_sel = 0; logic_sel = 0; alu_sel = 1;
            acc_ld = 0; mul_start = 0; mac_mode = 0;
            data_write = 0;
        end
    endtask

    // Mini controller: derives the control word from the fetched op/fn
    task set_ctrl;
        begin
            ctrl_idle;
            reg_write = 1;
            case (op)
                OP_R: begin
                    reg_dest = 1;
                    case (fn)
                        FN_ADD: ;
                        FN_SUB: sub = 1;
                        FN_AND: begin alu_sel = 3; logic_sel = 0; end
                        FN_SLL: begin alu_sel = 0; shift_sel = 1; alu_src = 2; end
                        FN_SLT: begin alu_sel = 2; sub = 1; end
                    endcase
                end
                OP_ADDI: alu_src = 1;
                OP_ORI: begin alu_src = 1; imm_ext = 1; alu_sel = 3; logic_sel = 1; end
            endcase
        end
    endtask

    task fetch(input [31:0] exp_inst);
        begin
            @(negedge clk);
            ctrl_idle;
            @(negedge clk);
            ir_write = 1;
            @(negedge clk);
            ir_write = 0;
            $display("[PC=%0d] fetched 0x%08h", dut.pc, dut.inst);
            check("IR == ROM word", dut.inst, exp_inst);
        end
    endtask

    task execute(input [31:0] exp_a, input [31:0] exp_b, input chk_b);
        begin
            set_ctrl;
            #1;
            check("read port 1 (rA)", dut.regOut1, exp_a);
            if (chk_b) check("read port 2 (rB)", dut.regOut2, exp_b);
            @(negedge clk);
            ctrl_idle;
            pc_write = 1;
            @(negedge clk);
            ctrl_idle;
        end
    endtask

    integer k;

    initial begin
        errors = 0;
        checks = 0;
        ctrl_idle;

        $dumpfile("tb_datapath.vcd");
        $dumpvars(0, tb_datapath);

        dut.rom.mem[0]  = itype(OP_ADDI, 0, 1, 16'd10);      // ADDI R1  = R0 + 10
        dut.rom.mem[1]  = itype(OP_ADDI, 0, 2, 16'd3);       // ADDI R2  = R0 + 3
        dut.rom.mem[2]  = itype(OP_ADDI, 0, 3, 16'hFFFB);    // ADDI R3  = R0 + (-5)
        dut.rom.mem[3]  = rtype(OP_R, 1, 2, 4, 0, FN_ADD);   // ADD  R4  = R1 + R2
        dut.rom.mem[4]  = rtype(OP_R, 1, 2, 5, 0, FN_SUB);   // SUB  R5  = R1 - R2
        dut.rom.mem[5]  = rtype(OP_R, 1, 2, 6, 0, FN_AND);   // AND  R6  = R1 & R2
        dut.rom.mem[6]  = rtype(OP_R, 1, 0, 7, 2, FN_SLL);   // SLL  R7  = R1 << 2
        dut.rom.mem[7]  = rtype(OP_R, 3, 2, 8, 0, FN_SLT);   // SLT  R8  = (R3 < R2) signed
        dut.rom.mem[8]  = rtype(OP_R, 2, 3, 9, 0, FN_SLT);   // SLT  R9  = (R2 < R3) signed
        dut.rom.mem[9]  = itype(OP_ADDI, 1, 10, 16'hFFFC);   // ADDI R10 = R1 + (-4)
        dut.rom.mem[10] = itype(OP_ORI, 0, 11, 16'hFFFB);    // ORI  R11 = R0 | 0xFFFB (zero-extended)
        dut.rom.mem[11] = rtype(OP_R, 1, 2, 0, 0, FN_ADD);   // ADD  R0  = R1 + R2   (write to R0)
        dut.rom.mem[12] = rtype(OP_R, 0, 2, 12, 0, FN_ADD);  // ADD  R12 = R0 + R2

        $display("---- program in BRAM ----");
        for (k = 0; k < 13; k = k + 1) $display("  mem[%0d] = %08h", k, dut.rom.mem[k]);

        repeat (2) @(negedge clk);

        $display("---- ADDI x3 (immediate arithmetic, fetch of different instructions) ----");
        fetch(dut.rom.mem[0]);  execute(0, 0, 0);   check("R1 write-back", getreg(1), 10);
        fetch(dut.rom.mem[1]);  execute(0, 0, 0);   check("R2 write-back", getreg(2), 3);
        fetch(dut.rom.mem[2]);  execute(0, 0, 0);   check("R3 write-back", getreg(3), 32'hFFFFFFFB);

        $display("---- ADD (two source registers read at once) ----");
        fetch(dut.rom.mem[3]);  execute(10, 3, 1);  check("R4 = R1 + R2", getreg(4), 13);

        $display("---- SUB ----");
        fetch(dut.rom.mem[4]);  execute(10, 3, 1);  check("R5 = R1 - R2", getreg(5), 7);

        $display("---- logical (AND) ----");
        fetch(dut.rom.mem[5]);  execute(10, 3, 1);  check("R6 = R1 & R2", getreg(6), 2);

        $display("---- shift (SLL by shamt=2) ----");
        fetch(dut.rom.mem[6]);  execute(10, 0, 0);  check("R7 = R1 << 2", getreg(7), 40);

        $display("---- signed compare (SLT) ----");
        fetch(dut.rom.mem[7]);  execute(32'hFFFFFFFB, 3, 1);  check("R8 = (-5 < 3)", getreg(8), 1);
        fetch(dut.rom.mem[8]);  execute(3, 32'hFFFFFFFB, 1);  check("R9 = (3 < -5)", getreg(9), 0);

        $display("---- ADDI with non-zero source, ORI with zero-extend ----");
        fetch(dut.rom.mem[9]);  execute(10, 0, 0);  check("R10 = R1 - 4", getreg(10), 6);
        fetch(dut.rom.mem[10]); execute(0, 0, 0);   check("R11 = 0x0000FFFB", getreg(11), 32'h0000FFFB);

        $display("---- attempted write to R0 (R0 is read back by the next instruction) ----");
        fetch(dut.rom.mem[11]); execute(10, 3, 1);
        check("R4 untouched", getreg(4), 13);
        fetch(dut.rom.mem[12]); execute(0, 3, 1);
        check("R12 = R0 + R2 (R0 still 0)", getreg(12), 3);

        $display("----------------------------------------");
        $display("%0d checks, %0d errors", checks, errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("SOME TESTS FAILED");
        $finish;
    end

    initial begin
        #20000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
