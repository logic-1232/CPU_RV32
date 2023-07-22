`include "command.vh"

module alu_fp32 (
        input       [4:0]   alu_ctrl,
        input       [31:0]  in1,
        input       [31:0]  in2,
        input       [31:0]  in3,
        output  reg [63:0]  out
    );

    wire    [31:0]      fadd, fmul, fdiv, fsqrt;
    wire                feq, flt;
    reg     [3:0]       fclass;
    wire    [31:0]      fp32_int, fp32_uint;
    wire    [31:0]      fmadd;
    wire    [63:0]      fp64;

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
            `ALU_FSGNJ  : out = {in2[31], in1[30:0]};
            `ALU_FSGNJN : out = {~in2[31], in1[30:0]};
            `ALU_FSGNJX : out = {in1[31]^in2[31], in1[30:0]};
            `ALU_FEQ    : out = feq;
            `ALU_FLT    : out = flt;
            `ALU_FLE    : out = feq | flt;
            `ALU_FMV_X_W: out = in1;
            `ALU_FCLASS : out = fclass;
            /*转为整数*/
            `ALU_F_W_S  : out = fp32_int;
            `ALU_F_WU_S : out = fp32_uint;
            `ALU_F_D    : out = fp64;
            /*R4*/
            `ALU_FMADD  : out = fmadd;
            `ALU_FMSUB  : out = fmadd;
            `ALU_FNMADD : out = fmadd;
            `ALU_FNMSUB : out = fmadd;
            default     : out = 64'd0;
        endcase
    end

    fp32_addsub fp32_addsub_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         ({alu_ctrl[0]^in2[31], in2[30:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fadd)
    );
    fp32_mul fp32_mul_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fmul)
    );
    fp32_div fp32_div_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fdiv)
    );
    fp32_sqrt fp32_sqrt_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fsqrt)
    );

    fp32_cmp_eq fp32_cmp_eq_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (feq)
    );
    fp32_cmp_lt fp32_cmp_lt_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (flt)
    );

    fp32_fp2int fp32_fp2int_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fp32_int)
    );
    fp32_fp2uint fp32_fp2uint_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         ({1'b0, in1[30:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fp32_uint)
    );
    fp_s2d fp_s2d_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         (in1),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fp64)
    );

    /*浮点数分类*/
    // 无穷大：exp==8'hff, frac==23'd0
    // 零：exp==8'd0, frac==23'd0
    // 非规格化数：exp==8'd0, frac!=23'd0  // 用于表示更接近0的数
    // NaN：exp==8'hff, frac!=23'd0（其中，frac最高位为1表示sNaN，为0表示qNaN）
    wire                sign;
    wire    [7:0]       exp;
    wire    [22:0]      frac;
    assign  {sign, exp, frac} = in1;
    always @(*) begin
        if(exp==8'hff) begin
            if(frac==23'd0)  // 无穷大
                fclass = sign ? 4'd0 : 4'd7;
            else  // NaN
                fclass = frac[22] ? 4'd8 : 4'd9;
        end
        else if(exp==8'h00) begin
            if(frac==23'd0)  // 0
                fclass = sign ? 4'd3 : 4'd4;
            else  // 非规格化数
                fclass = sign ? 4'd2 : 4'd5;
        end
        else begin  // 规格化数
            fclass = sign ? 4'd1 : 4'd6;
        end
    end

    fp32_madd fp32_madd_inst (
        .s_axis_a_tvalid        (1'b1),
        .s_axis_a_tdata         ({alu_ctrl[1]^in1[31], in1[30:0]}),
        .s_axis_b_tvalid        (1'b1),
        .s_axis_b_tdata         (in2),
        .s_axis_c_tvalid        (1'b1),
        .s_axis_c_tdata         ({alu_ctrl[0]^in3[31], in3[30:0]}),
        .m_axis_result_tvalid   (),
        .m_axis_result_tdata    (fmadd)
    );

endmodule
