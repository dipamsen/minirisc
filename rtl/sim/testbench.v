`timescale 1ns/1ps

module tb_minirisc_ldst();
    reg clk, rst;
    integer errors;

    minirisc_top dut (.clk(clk), .rst(rst));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin #200000; $display("[FAIL] timeout"); $finish; end

    always @(posedge clk) if (dut.mem_en)
        $display("%6t  BRAM %s  addr=%0d  din=%0d  | PC=%0d inst=%h EA(alu)=%0d",
                 $time, dut.data_write ? "WRITE" : "READ ", dut.dp.alu_out[9:0],
                 dut.dp.regOut2, dut.dp.pc, dut.dp.inst, dut.dp.alu_out);
    always @(posedge clk) if (dut.reg_write && dut.dp.inst[31:24]==8'h07)
        $display("%6t  LD write-back: R%0d <= %0d (wb_sel=%0d)", $time,
                 dut.dp.write_addr, dut.dp.writeback, dut.reg_src);

    task check(input [255:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got === exp) $display("[PASS] %0s = %0d", name, got);
            else begin $display("[FAIL] %0s = %0d, expected %0d", name, got, exp); errors = errors + 1; end
        end
    endtask

    initial begin
        errors = 0; rst = 1; #22; rst = 0;
        wait(dut.dp.op === 8'hFF);
        #40;
        $display("---- results ----");
        check("R2 (base)             ", dut.dp.rf.r2, 2);
        check("Case1 R4=LD 3(R2)=M[5]", dut.dp.rf.r4, 60);
        check("Case2 Mem[5]=ST 4(R5) ", dut.dp.ram.mem[5], 99);
        check("Case3 R7=LD 4(R5)     ", dut.dp.rf.r7, 99);
        check("NegOff R8=LD -2(R3)=M4", dut.dp.rf.r8, 50);
        check("Mem[4] untouched      ", dut.dp.ram.mem[4], 50);
        if (errors == 0) $display("ALL TESTS PASSED"); else $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
