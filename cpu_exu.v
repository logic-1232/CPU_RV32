//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_exu.v
// Descriptions:        执行模块
//-----------------------------------------README-----------------------------------------
// 只对输入数据做算数/逻辑运算，不做其他处理。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module cpu_exu (
        input               clk,
        input               rst_n,
        input               flush_flag,
        input               wait_exe,
        input       [4:0]   alu_ctrl,
        input       [31:0]  in1,
        input       [31:0]  in2,
        output  reg [31:0]  out
    );

    wire    signed  [32:0]  mul_in1, mul_in2;
    wire    signed  [63:0]  mul;
    wire    signed  [32:0]  div_in1, div_in2;
    wire    signed  [31:0]  div, rem;

    //*****************************************************
    //**                    main code
    //*****************************************************
    assign  mul_in1 = {~alu_ctrl[1]&in1[31], in1};
    assign  mul_in2 = {~alu_ctrl[0]&in2[31], in2};
    assign  mul = mul_in1 * mul_in2;

    assign  div_in1 = {~alu_ctrl[0]&in1[31], in1};
    assign  div_in2 = {~alu_ctrl[0]&in2[31], in2};
    assign  div = div_in1 / div_in2;
    assign  rem = div_in1 % div_in2;

    always @(posedge clk) begin
        if(!rst_n || flush_flag || wait_exe) begin
            out <= 32'd0;
        end
        else begin
            case (alu_ctrl)
                /*基础运算*/
                `ALU_AND    : out <= in1 & in2;
                `ALU_OR     : out <= in1 | in2;
                `ALU_XOR    : out <= in1 ^ in2;
                `ALU_SLL    : out <= in1 << in2[4:0];
                `ALU_SRL    : out <= in1 >> in2[4:0];
                `ALU_SRA    : out <= in1 >>> in2[4:0];
                `ALU_ADD    : out <= in1 + in2;
                `ALU_SUB    : out <= in1 - in2;
                /*比较*/
                `ALU_EQ     : out <= in1 == in2;
                `ALU_NE     : out <= in1 != in2;
                `ALU_LT     : out <= {~in1[31],in1[30:0]} < {~in2[31],in2[30:0]};
                `ALU_GE     : out <= {~in1[31],in1[30:0]} >= {~in2[31],in2[30:0]};
                `ALU_LTU    : out <= in1 < in2;
                `ALU_GEU    : out <= in1 >= in2;
                /*乘除法*/
                `ALU_MULL   : out <= mul[31: 0];
                `ALU_MULH   : out <= mul[63:32];
                `ALU_MULHSU : out <= mul[63:32];
                `ALU_MULHU  : out <= mul[63:32];
                `ALU_DIV    : out <= div[31: 0];
                `ALU_DIVU   : out <= div[31: 0];
                `ALU_REM    : out <= rem[31: 0];
                `ALU_REMU   : out <= rem[31: 0];
                default     : out <= 32'd0;
            endcase
        end
    end


endmodule
