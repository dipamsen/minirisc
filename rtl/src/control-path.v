`timescale 1ns/1ps

module control_unit (
    input wire clk,
    input wire rst,
    input wire [7:0] op,
    input wire [6:0] fn,
    input wire done,
    
    output reg [2:0] br_type,
    output reg pc_write,
    output reg ir_write,
    output reg reg_read,
    output reg reg_dest,
    output reg reg_write,
    output reg [1:0] reg_src,
    output reg imm_ext,
    output reg [1:0] alu_src,
    output reg sub,
    output reg shamt_sel,
    output reg [1:0] shift_sel,
    output reg [2:0] logic_sel,
    output reg [1:0] alu_sel,
    output reg acc_ld,
    output reg mul_start,
    output reg mac_mode,
    output reg data_write,
    output reg mem_en
);
    localparam ST_INIT     = 3'd0;
    localparam ST_FETCH    = 3'd1;
    localparam ST_DECEX    = 3'd2;
    localparam ST_ACCFETCH = 3'd3;
    localparam ST_MEMWAIT  = 3'd4;
    localparam ST_MULSTALL = 3'd5;
    localparam ST_WB       = 3'd6;
    localparam ST_HALT     = 3'd7;

    reg [2:0] state, next_state;

    // ISA Opcodes
    localparam OP_R     = 8'h00;
    localparam OP_ADDI  = 8'h01;
    localparam OP_SUBI  = 8'h02;
    localparam OP_ANDI  = 8'h03;
    localparam OP_ORI   = 8'h04;
    localparam OP_XORI  = 8'h05;
    localparam OP_NORI  = 8'h06;
    localparam OP_LD    = 8'h07;
    localparam OP_ST    = 8'h08;
    localparam OP_BZ    = 8'h09;
    localparam OP_BMI   = 8'h0A;
    localparam OP_BPL   = 8'h0B;
    localparam OP_LUI   = 8'h0C;
    localparam OP_SLTI  = 8'h0E;
    localparam OP_BR    = 8'h0F;
    localparam OP_HALT  = 8'hFF;

    // ISA Function Codes
    localparam FN_ADD   = 7'h01;
    localparam FN_SUB   = 7'h02;
    localparam FN_AND   = 7'h03;
    localparam FN_OR    = 7'h04;
    localparam FN_XOR   = 7'h05;
    localparam FN_NOR   = 7'h06;
    localparam FN_NOT   = 7'h07;
    localparam FN_SLL   = 7'h08;
    localparam FN_SRL   = 7'h09;
    localparam FN_SRA   = 7'h0A;
    localparam FN_SLLV  = 7'h0B;
    localparam FN_SRLV  = 7'h0C; 
    localparam FN_SLT   = 7'h0E;
    localparam FN_MOVE  = 7'h0F;
    localparam FN_MUL   = 7'h10;
    localparam FN_MAC   = 7'h11;

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= ST_INIT;
        else     state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            ST_INIT: 
                next_state = ST_FETCH;
                
            ST_FETCH: 
                next_state = ST_DECEX;
                
            ST_DECEX: begin
                if (op == OP_HALT) 
                    next_state = ST_HALT;
                else if (op == OP_R && fn == FN_MAC)
                    next_state = ST_ACCFETCH;
                else if (op == OP_R && fn == FN_MUL)
                    next_state = ST_MULSTALL;
                else if (op == OP_LD)
                    next_state = ST_MEMWAIT;
                else if (op == OP_ST || op == OP_BR || op == OP_BZ || op == OP_BMI || op == OP_BPL)
                    next_state = ST_INIT;
                else 
                    next_state = ST_WB;
            end
            
            ST_ACCFETCH: 
                next_state = ST_MULSTALL;
                
            ST_MEMWAIT: 
                next_state = ST_WB;
                
            ST_MULSTALL: 
                if (done) next_state = ST_WB;
                
            ST_WB: 
                next_state = ST_INIT;
                
            ST_HALT: 
                next_state = ST_HALT;
                
            default: next_state = ST_INIT;
        endcase
    end

    always @(*) begin
        br_type    = 3'd0;
        pc_write   = 1'b0;
        ir_write   = 1'b0;
        reg_read   = 1'b0;
        reg_dest   = 1'b0;
        reg_write  = 1'b0;
        reg_src    = 2'd1;
        imm_ext    = 1'b0;
        alu_src    = 2'd0;
        sub        = 1'b0;
        shamt_sel  = 1'b0;
        shift_sel  = 2'd0;
        logic_sel  = 3'd0;
        alu_sel    = 2'd1;
        acc_ld     = 1'b0;
        mul_start  = 1'b0;
        mac_mode   = 1'b0;
        data_write = 1'b0;
        mem_en     = 1'b0;

        case (state)
            ST_INIT: begin
            end

            ST_FETCH: begin
                ir_write = 1'b1;
                pc_write = 1'b1;
            end

            ST_DECEX: begin
                // reg_read stays 0: read port 1 = rA (base register / branch source)
                if (op == OP_BR)       begin br_type = 3'd1; pc_write = 1'b1; imm_ext = 1'b1; end
                else if (op == OP_BZ)  begin br_type = 3'd2; pc_write = 1'b1; imm_ext = 1'b1; end
                else if (op == OP_BMI) begin br_type = 3'd3; pc_write = 1'b1; imm_ext = 1'b1; end
                else if (op == OP_BPL) begin br_type = 3'd4; pc_write = 1'b1; imm_ext = 1'b1; end

                if (op == OP_ST) begin
                    // EA = rA + SE(imm) on ALU; rB -> Data In; write at end of this cycle
                    mem_en     = 1'b1;
                    data_write = 1'b1;
                    alu_src = 2'd1;
                    imm_ext = 1'b1;
                    alu_sel = 2'd1;
                end

                if (op == OP_R && fn == FN_MUL) begin
                    mul_start = 1'b1;
                end
            end

            ST_ACCFETCH: begin
                reg_read = 1'b1;
                acc_ld = 1'b1;
            end

            ST_MULSTALL: begin
                if (op == OP_R && fn == FN_MAC) mac_mode = 1'b1;
                else mul_start = 1'b1;
            end

            ST_MEMWAIT: begin
                // EA applied to BRAM this cycle; douta valid in the next (WB) cycle
                mem_en  = 1'b1;
                alu_src = 2'd1; 
                imm_ext = 1'b1;
                alu_sel = 2'd1;
            end

            ST_WB: begin
                reg_write = 1'b1;
                
                if (op == OP_R) begin
                    reg_dest = 1'b1;
                    
                    case (fn)
                        FN_ADD:  begin alu_sel = 2'd1; sub = 1'b0; end
                        FN_SUB:  begin alu_sel = 2'd1; sub = 1'b1; end
                        FN_SLT:  begin alu_sel = 2'd2; sub = 1'b1; end
                        FN_AND:  begin alu_sel = 2'd3; logic_sel = 3'd0; end
                        FN_OR:   begin alu_sel = 2'd3; logic_sel = 3'd1; end
                        FN_XOR:  begin alu_sel = 2'd3; logic_sel = 3'd2; end
                        FN_NOR:  begin alu_sel = 2'd3; logic_sel = 3'd3; end
                        FN_NOT:  begin alu_sel = 2'd3; logic_sel = 3'd4; end
                        FN_SLL:  begin alu_sel = 2'd0; shift_sel = 2'd0; shamt_sel = 1'b1; end
                        FN_SRL:  begin alu_sel = 2'd0; shift_sel = 2'd1; shamt_sel = 1'b1; end
                        FN_SRA:  begin alu_sel = 2'd0; shift_sel = 2'd2; shamt_sel = 1'b1; end
                        FN_SLLV: begin alu_sel = 2'd0; shift_sel = 2'd0; shamt_sel = 1'b0; end
                        FN_SRLV: begin alu_sel = 2'd0; shift_sel = 2'd1; shamt_sel = 1'b0; end
                        FN_MOVE: begin alu_sel = 2'd1; alu_src = 2'd2; end
                        FN_MUL, FN_MAC: reg_src = 2'd2;
                    endcase
                end else begin
                    reg_dest = 1'b0;
                    
                    case (op)
                        OP_ADDI: begin alu_src = 2'd1; imm_ext = 1'b1; alu_sel = 2'd1; end
                        OP_SUBI: begin alu_src = 2'd1; imm_ext = 1'b1; alu_sel = 2'd1; sub = 1'b1; end
                        OP_SLTI: begin alu_src = 2'd1; imm_ext = 1'b1; alu_sel = 2'd2; sub = 1'b1; end
                        OP_ANDI: begin alu_src = 2'd1; imm_ext = 1'b0; alu_sel = 2'd3; logic_sel = 3'd0; end
                        OP_ORI:  begin alu_src = 2'd1; imm_ext = 1'b0; alu_sel = 2'd3; logic_sel = 3'd1; end
                        OP_XORI: begin alu_src = 2'd1; imm_ext = 1'b0; alu_sel = 2'd3; logic_sel = 3'd2; end
                        OP_NORI: begin alu_src = 2'd1; imm_ext = 1'b0; alu_sel = 2'd3; logic_sel = 3'd3; end
                        OP_LD:   begin alu_src = 2'd1; imm_ext = 1'b1; alu_sel = 2'd1; reg_src = 2'd0; end
                        OP_LUI:  begin alu_src = 2'd1; imm_ext = 1'b0; alu_sel = 2'd0; shift_sel = 2'd3; end
                    endcase
                end
            end
            
            ST_HALT: begin
                ir_write = 1'd1;
            end
        endcase
    end
endmodule
