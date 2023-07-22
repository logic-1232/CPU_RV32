`include "command.vh"

module alu_fp64 (
        input       [4:0]   alu_ctrl,
        input       [63:0]  in1,
        input       [63:0]  in2,
        input       [63:0]  in3,
        output  reg [63:0]  out
    );

    wire    [63:0]      fadd, fmul, fdiv, fsqrt;
    wire                feq, flt;
    reg     [3:0]       fclass;
    wire    [31:0]      fp64_int, fp64_uint;
    wire    [63:0]      fmadd;
    wire    [31:0]      fp32;

    //*****************************************************
    //**                    main code
    //*****************************************************

    always @(*) begin
        case (alu_ctrl)
            /*基础运算*/
            `ALU_FADD   : out = fadd;
            `ALU_FSUB   : out = fadd;
            `ALU_FMUL   : out = fmul;
            `ALU_FDIV   : out = fdiv;
            `ALU_FSQRT  : out = fsqrt;
            `ALU_FMIN   : out = flt ? in1 : in2;
            `ALU_FMAX   : out = flt ? in2 : in1;
            `ALU_FSGNJ  : out = {in2[63], in1[62:0]};
            `ALU_FSGNJN : out = {~in2[63], in1[62:0]};
            `ALU_FSGNJX : out = {in1[63]^in2[63], in1[62:0]};
            `ALU_FEQ    : out = feq;
            `ALU_FLT    : out = flt;
            `ALU_FLE    : out = feq | flt;
            `ALU_FCLASS : out = fclass;
            /*转为整数*/
            `ALU_F_W_S  : out = fp64_int;
            `ALU_F_WU_S : out = fp64_uint;
            `ALU_F_D    : out = fp32;
            /*R4*/
            `ALU_FMADD  : out = fmadd;
            `ALU_FMSUB  : out = fmadd;
            `ALU_FNMADD : out = fmadd;
            `ALU_FNMSUB : out = fmadd;
            default     : out = 64'd0;
        endcase
    end

    fp64_addsub fp64_addsub_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         ({alu_ctrl[0]^in2[63], in2[62:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fadd)
    );
    fp64_mul fp64_mul_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fmul)
    );
    fp64_div fp64_div_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fdiv)
    );
    fp64_sqrt fp64_sqrt_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fsqrt)
    );

    fp64_cmp_eq fp64_cmp_eq_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (feq)
    );
    fp64_cmp_lt fp64_cmp_lt_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (flt)
    );

    fp64_fp2int fp64_fp2int_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fp64_int)
    );
    fp64_fp2uint fp64_fp2uint_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         ({1'b0, in1[62:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fp64_uint)
    );
    fp_d2s fp_d2s_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fp32)
    );

    /*浮点数分类*/
    wire                sign;
    wire    [10:0]      exp;
    wire    [51:0]      frac;
    assign  {sign, exp, frac} = in1;
    always @(*) begin
        if(exp==11'h7ff) begin
            if(frac==52'd0)  // 无穷大
                fclass = sign ? 4'd0 : 4'd7;
            else  // NaN
                fclass = frac[51] ? 4'd8 : 4'd9;
        end
        else if(exp==11'h000) begin
            if(frac==52'd0)  // 0
                fclass = sign ? 4'd3 : 4'd4;
            else  // 非规格化数
                fclass = sign ? 4'd2 : 4'd5;
        end
        else begin  // 规格化数
            fclass = sign ? 4'd1 : 4'd6;
        end
    end

    fp64_madd fp64_madd_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         ({alu_ctrl[1]^in1[63], in1[62:0]}),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .s_axis_c_tvalid        (1'b1),
        .s_axis_c_tdata         ({alu_ctrl[0]^in3[63], in3[62:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fmadd)
    );

endmodule
