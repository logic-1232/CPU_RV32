//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_ifu.v
// Descriptions:        取指模块
//-----------------------------------------README-----------------------------------------
// 主要包含pc的生成和分支预测，输出pc值到程序存储器完成取指。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module cpu_ifu (
        input               clk,
        input               rst_n,
        input               running,  // 程序运行标志
        input               flush_flag,
        input               wait_exe,
        input               wait_jmp,
        input               decompr_en,
        output  reg         jmp_pred,  // 跳转预测标志
        output  reg         jmp_reg_en,  // 使用寄存器跳转标志
        output      [4:0]   jmp_rs,  // 跳转指令使用的寄存器地址
        input       [31:0]  jmp_data,  // 跳转指令使用的寄存器数据
        output  reg [15:0]  pc_now,  // 记录当前指令对应的pc，用于jal和jalr指令
        output      [15:0]  pc,  // 取指用的pc
        input       [31:0]  instruction  // 与pc_now对应的指令，用于判断跳转
    );

    reg                 running_d;
    wire                pc_move;

    reg     [31:0]      jmp_imm;
    reg     [15:0]      pc_jmp;

    /*指令片段拆分*/
    wire    [6:0]       opcode;
    wire    [11:0]      imm_i;
    wire    [19:0]      imm_j;
    wire    [11:0]      imm_b;
    assign  opcode = instruction[6:0];
    assign  imm_i = instruction[31:20];
    assign  imm_j = {instruction[31],instruction[19:12],instruction[20],instruction[30:21]};
    assign  imm_b = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};

    assign  jmp_rs = instruction[19:15];

    //*****************************************************
    //**                    main code
    //*****************************************************
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            running_d <= 1'b0;
        else
            running_d <= running;
    end
    assign  pc_move = running_d & running;

    always @(posedge clk or negedge rst_n) begin  // 记录上一次取指的pc，用于计算下一个pc
        if(!rst_n)
            pc_now <= 16'd0;
        else if(pc_move)
            pc_now <= pc;
        else
            pc_now <= pc_now;
    end

    pc_gen pc_gen_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .pc_move        (pc_move),
        .flush_flag     (flush_flag),
        .wait_exe       (wait_exe),
        .wait_jmp       (wait_jmp),
        .decompr_en     (decompr_en),
        .jmp_pred       (jmp_pred),
        .pc_now         (pc_now),
        .pc_jmp         (pc_jmp),
        .pc             (pc)
    );


    /*分支预测机制*/
    always @(*) begin
        case (opcode)
            `JAL        : begin
                jmp_pred = 1'b1;
                jmp_reg_en = 1'b0;
                jmp_imm = {{11{imm_j[19]}}, imm_j, 1'b0};  // 末尾补0相当于左移一位
            end
            `JALR       : begin
                jmp_pred = 1'b1;
                jmp_reg_en = 1'b1;
                jmp_imm = {{20{imm_i[11]}}, imm_i};
            end
            `BRANCH     : begin
                jmp_pred = imm_b[11];  //向前跳转默认预测为跳
                jmp_reg_en = 1'b0;
                jmp_imm = {{19{imm_b[11]}}, imm_b, 1'b0};  // 末尾补0相当于左移一位
            end
            default     : begin
                jmp_pred = 1'b0;
                jmp_reg_en = 1'b0;
                jmp_imm = 32'd0;
            end
        endcase
    end

    always @(*) begin
        if(jmp_reg_en)
            pc_jmp = (jmp_data + jmp_imm) & 32'hfffffffe;  // 最低位置零
        else
            pc_jmp = pc_now + jmp_imm;
    end


endmodule
