//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           decompress.v
// Descriptions:        指令解压缩模块
//-----------------------------------------README-----------------------------------------
// 将压缩指令还原。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module decompress (
        input       [15:0]  instr_c,
        output  reg [31:0]  instruction
    );

    wire    [1:0]       opcode;
    wire    [2:0]       funct3;
    wire    [4:0]       rs1_, rs2_, rd_;
    wire    [4:0]       rs1, rs2, rd;
    wire    [19:0]      imm_ci;
    wire    [11:0]      imm_16sp;
    wire    [11:0]      uimm_4spn;
    wire    [11:1]      imm_cb;
    wire    [20:1]      imm_cj;
    wire    [11:0]      uimm_cw;
    wire    [11:0]      uimm_lwsp, uimm_swsp;
    assign  opcode = instr_c[1:0];
    assign  funct3 = instr_c[15:13];
    assign  rs1_ = {2'b01, instr_c[9:7]};
    assign  rs2_ = {2'b01, instr_c[4:2]};
    assign  rd_ = {2'b01, instr_c[9:7]};
    assign  rs1 = instr_c[11:7];
    assign  rs2 = instr_c[6:2];
    assign  rd = instr_c[11:7];
    assign  imm_ci = {{15{instr_c[12]}}, instr_c[6:2]};  // 符号扩展
    assign  imm_16sp = {{3{instr_c[12]}}, instr_c[4:3], instr_c[5], instr_c[2], instr_c[6], 4'b0};
    assign  uimm_4spn = {2'b0, instr_c[10:7], instr_c[12:11], instr_c[5], instr_c[6], 2'b0};
    assign  imm_cb = {{4{instr_c[12]}}, instr_c[6:5], instr_c[2], instr_c[11:10], instr_c[4:3]};
    assign  imm_cj = {{10{instr_c[12]}}, instr_c[8], instr_c[10:9], instr_c[6], instr_c[7], instr_c[2], instr_c[11], instr_c[5:3]};
    assign  uimm_cw = {5'b0, instr_c[5], instr_c[12:10], instr_c[6], 2'b0};
    assign  uimm_lwsp = {4'b0, instr_c[3:2], instr_c[12], instr_c[6:4], 2'b0};
    assign  uimm_swsp = {4'b0, instr_c[8:7], instr_c[12:9], 2'b0};

    always @(*) begin
        case (opcode)
            2'b00   : begin
                case (funct3)
                    3'b000  : begin
                        if(instr_c[12:5]!=8'd0)
                            instruction = {uimm_4spn, `X2, `ADD, rd_, `OP_IMM};  // c.addi4spn
                        else
                            instruction = `NOP;
                    end
                    3'b010  : instruction = {uimm_cw, rs1_, `LW, rd_, `LOAD};  // c.lw
                    3'b110  : instruction = {uimm_cw[11:5], rs2_, rs1_, `SW, uimm_cw[4:0], `STORE};  // c.sw
                    default : instruction = `NOP;
                endcase
            end
            2'b01   : begin
                case (funct3)
                    3'b000  : instruction = {imm_ci[11:0], rd, `ADD, rd, `OP_IMM};  // c.addi
                    3'b001  : instruction = {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12], `X1, `JAL};  // c.jal
                    3'b010  : instruction = {imm_ci[11:0], rd, `ADD, `X0, `OP_IMM};  // c.li
                    3'b011  : begin
                        if(rd==`X2)
                            instruction = {imm_16sp, rd, `ADD, rd, `OP_IMM};  // c.addi16sp
                        else
                            instruction = {imm_ci[19:0], rd, `LUI};  // c.lui
                    end
                    3'b100  : begin
                        case (instr_c[11:10])
                            2'b11   : begin
                                case (instr_c[6:5])
                                    2'b11   : instruction = {`BASE, rs2_, rd_, `AND, rd_, `OP};  // c.and
                                    2'b10   : instruction = {`BASE, rs2_, rd_, `OR, rd_, `OP};  // c.or
                                    2'b01   : instruction = {`BASE, rs2_, rd_, `XOR, rd_, `OP};  // c.xor
                                    2'b00   : instruction = {`SPEC, rs2_, rd_, `ADD, rd_, `OP};  // c.sub
                                endcase
                            end
                            2'b10   : instruction = {imm_ci[11:0], rd, `AND, rd_, `OP_IMM};  // c.andi
                            2'b01   : instruction = {6'b0, imm_ci[5:0], rd, `SRA, rd_, `OP_IMM};  // c.srai
                            2'b00   : instruction = {6'b0, imm_ci[5:0], rd, `SRL, rd_, `OP_IMM};  // c.srli
                        endcase
                    end
                    3'b101  : instruction = {imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12], `X0, `JAL};  // c.j
                    3'b110  : instruction = {imm_cb[11:5], `X0, rs1_, `BEQ, imm_cb[4:1], 1'b0, `BRANCH};  // c.beqz
                    3'b111  : instruction = {imm_cb[11:5], `X0, rs1_, `BNE, imm_cb[4:1], 1'b0, `BRANCH};  // c.bnez
                endcase
            end
            2'b10   : begin
                case (funct3)
                    3'b000  : instruction = {6'b0, imm_ci[5:0], rd, `SLL, rd, `OP_IMM};  // c.slli
                    3'b010  : instruction = {uimm_lwsp, `X2, `LW, rd, `LOAD};  // c.lwsp
                    3'b100  : begin
                        if(rs2==`X0)
                            instruction = {12'b0, rs1, 3'b010, {4'b0, instr_c[12]}, `JALR};  // c.jalr和c.jr
                        else
                            instruction = {`BASE, rs2, rd&{5{instr_c[12]}}, `ADD, rd, `OP};  // c.add和c.mv
                    end
                    3'b110  : instruction = {uimm_swsp[11:5], rs2, `X0, `SW, uimm_swsp[4:0], `STORE};  // c.swsp
                    default : instruction = `NOP;
                endcase
            end
            default : instruction = `NOP;
        endcase
    end


endmodule
