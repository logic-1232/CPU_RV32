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
        input       [1:0]   fp_ctrl,
        input       [4:0]   alu_ctrl,
        input       [63:0]  in1,
        input       [63:0]  in2,
        input       [63:0]  in3,
        output  reg [63:0]  out
    );

    wire    [63:0]      out_alu;
    wire    [63:0]      out_alu_fp32;
    wire    [63:0]      out_alu_fp64;

    //*****************************************************
    //**                    main code
    //*****************************************************

    always @(posedge clk) begin
        if(!rst_n || flush_flag || wait_exe) begin
            out <= 64'd0;
        end
        else begin
            case (fp_ctrl)
                `INT    : out <= out_alu;
                `FP_S   : out <= out_alu_fp32;
                `FP_D   : out <= out_alu_fp64;
                default : out <= 64'd0;
            endcase
        end
    end

    alu alu_inst(
        .alu_ctrl   (alu_ctrl),
        .in1        (in1[31:0]),
        .in2        (in2[31:0]),
        .out        (out_alu)
    );

    alu_fp32 alu_fp32_inst(
        .alu_ctrl   (alu_ctrl),
        .in1        (in1[31:0]),
        .in2        (in2[31:0]),
        .in3        (in3[31:0]),
        .out        (out_alu_fp32)
    );

    alu_fp64 alu_fp64_inst(
        .alu_ctrl   (alu_ctrl),
        .in1        (in1[63:0]),
        .in2        (in2[63:0]),
        .in3        (in3[63:0]),
        .out        (out_alu_fp64)
    );


endmodule
