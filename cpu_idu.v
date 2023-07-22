//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_idu.v
// Descriptions:        译码模块
//-----------------------------------------README-----------------------------------------
// 根据指令编码规则拆分指令，并判断指令类型，给出相应的运行控制信号。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "command.vh"

module cpu_idu (
        input               clk,
        input               rst_n,
        input               flush_flag,
        input               wait_exe,
        input               decompr_en,
        input       [31:0]  instruction,
        /*寄存器地址*/
        output  reg         pc_en,
        output  reg [2:1]   rs_en,
        output  reg [4:0]   rs1,
        output  reg [4:0]   rs2,
        output  reg [4:0]   rd,
        /*功能使能、控制信号*/
        output  reg [4:0]   alu_ctrl,  // 运算单元控制
        output  reg         wr_en,  // 通用寄存器写使能
        output  reg [2:0]   jmp_ctrl,  // 指令跳转功能控制（[2]:寄存器链接，[1]:无条件跳转，[0]:条件分支）
        output  reg [4:0]   ram_ctrl,  // [4:2]:数据长度控制，即funct3；[1]:写；[0]:使用数据存储器
        /*立即数*/
        output  reg [1:0]   imm_en,
        output  reg [31:0]  imm0,
        output  reg [31:0]  imm1
    );

    /*指令片段拆分*/
    wire    [6:0]       opcode;
    wire    [2:0]       funct3;
    wire    [6:0]       funct7;
    wire    [11:0]      imm_i;
    wire    [11:0]      imm_s;
    wire    [11:0]      imm_b;
    wire    [19:0]      imm_u;
    wire    [19:0]      imm_j;


    //*****************************************************
    //**                    main code
    //*****************************************************
    /*指令拆分*/
    assign  opcode = instruction[6:0];
    assign  funct3 = instruction[14:12];
    assign  funct7 = instruction[31:25];
    assign  imm_i = instruction[31:20];
    assign  imm_s = {instruction[31:25], instruction[11:7]};
    assign  imm_b = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};
    assign  imm_u = instruction[31:12];
    assign  imm_j = {instruction[31],instruction[19:12],instruction[20],instruction[30:21]};

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag) begin
            rs1 <= `X0;
            rs2 <= `X0;
            rd  <= `X0;
        end
        else if(wait_exe) begin
            rs1 <= rs1;
            rs2 <= rs2;
            rd  <= rd;
        end
        else begin
            rs1 <= instruction[19:15];
            rs2 <= instruction[24:20];
            rd  <= instruction[11:7];
        end
    end

    /*alu_ctrl*/
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag) begin
            alu_ctrl <= `ALU_ADD;
        end
        else if(wait_exe) begin
            alu_ctrl <= alu_ctrl;
        end
        else begin
            case (opcode)
                `OP     : begin  // 基础整数运算-寄存器
                    case (funct7)
                        `BASE   : begin
                            case (funct3)
                                `ADD    : alu_ctrl <= `ALU_ADD;
                                `SLL    : alu_ctrl <= `ALU_SLL;
                                `SLT    : alu_ctrl <= `ALU_LT;
                                `SLTU   : alu_ctrl <= `ALU_LTU;
                                `XOR    : alu_ctrl <= `ALU_XOR;
                                `SRL    : alu_ctrl <= `ALU_SRL;
                                `OR     : alu_ctrl <= `ALU_OR;
                                `AND    : alu_ctrl <= `ALU_AND;
                            endcase
                        end
                        `SPEC   : begin
                            case (funct3)
                                `ADD    : alu_ctrl <= `ALU_SUB;
                                `SRL    : alu_ctrl <= `ALU_SRA;
                                default : alu_ctrl <= `ALU_NOP;
                            endcase
                        end
                        default : alu_ctrl <= `ALU_NOP;
                    endcase
                end
                `OP_IMM : begin   // 基础整数运算-立即数
                    case (funct3)
                        `ADD    : alu_ctrl <= `ALU_ADD;
                        `SLL    : alu_ctrl <= `ALU_SLL;
                        `SLT    : alu_ctrl <= `ALU_LT;
                        `SLTU   : alu_ctrl <= `ALU_LTU;
                        `XOR    : alu_ctrl <= `ALU_XOR;
                        `SRL    : alu_ctrl <= (funct7==`BASE) ? `ALU_SRL : `ALU_SRA;
                        `OR     : alu_ctrl <= `ALU_OR;
                        `AND    : alu_ctrl <= `ALU_AND;
                    endcase
                end
                `AUIPC  : alu_ctrl <= `ALU_ADD;
                `LUI    : alu_ctrl <= `ALU_SLL;
                `JAL    : alu_ctrl <= `ALU_ADD;
                `JALR   : alu_ctrl <= `ALU_ADD;
                `BRANCH : alu_ctrl <= {2'b01, funct3};
                `LOAD   : alu_ctrl <= `ALU_ADD;
                `STORE  : alu_ctrl <= `ALU_ADD;
                default : alu_ctrl <= `ALU_NOP;
            endcase
        end
    end

    /**/
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag) begin
            pc_en <= 1'b0;
            rs_en <= 2'b00;
            wr_en <= 1'b0;
            jmp_ctrl <= 3'b000;
            ram_ctrl <= 5'b00000;
            imm_en <= 2'b00;
            imm1 <= 32'd0;
            imm0 <= 32'd0;
        end
        else if(wait_exe) begin
            pc_en <= pc_en;
            rs_en <= rs_en;
            wr_en <= wr_en;
            jmp_ctrl <= jmp_ctrl;
            ram_ctrl <= ram_ctrl;
            imm_en <= imm_en;
            imm1 <= imm1;
            imm0 <= imm0;
        end
        else begin
            case (opcode)
                `OP     : begin  // 基础整数运算-寄存器
                    pc_en <= 1'b0;
                    rs_en <= 2'b11;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b00;
                    imm1 <= 32'd0;
                    imm0 <= 32'd0;
                end
                `OP_IMM : begin   // 基础整数运算-立即数
                    pc_en <= 1'b0;
                    rs_en <= 2'b01;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b01;
                    imm1 <= 32'd0;
                    if(funct3!=`SLTU)
                        imm0 <= {{20{imm_i[11]}}, imm_i};
                    else
                        imm0 <= imm_i;
                end
                `AUIPC  : begin
                    pc_en <= 1'b1;
                    rs_en <= 2'b00;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b01;
                    imm1 <= 32'd0;
                    imm0 <= {imm_u, 12'b0};
                end
                `LUI    : begin
                    pc_en <= 1'b0;
                    rs_en <= 2'b00;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b11;
                    imm1 <= imm_u;
                    imm0 <= 32'd12;
                end
                `JAL    : begin
                    pc_en <= 1'b1;
                    rs_en <= 2'b00;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b010;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b01;
                    imm1 <= {{11{imm_j[19]}}, imm_j, 1'b0};  // 末尾补0相当于左移一位
                    imm0 <= decompr_en ? 32'd2 : 32'd4;
                end
                `JALR   : begin
                    pc_en <= 1'b1;
                    rs_en <= 2'b00;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b110;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b01;
                    imm1 <= {{20{imm_i[11]}}, imm_i};
                    imm0 <= decompr_en ? 32'd2 : 32'd4;
                end
                `BRANCH : begin
                    pc_en <= 1'b0;
                    rs_en <= 2'b11;
                    wr_en <= 1'b0;
                    jmp_ctrl <= 3'b001;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b00;
                    imm1 <= {{19{imm_b[11]}}, imm_b, 1'b0};  // 末尾补0相当于左移一位
                    imm0 <= 32'd0;
                end
                `LOAD   : begin
                    pc_en <= 1'b0;
                    rs_en <= 2'b01;
                    wr_en <= 1'b1;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= {funct3, 2'b01};
                    imm_en <= 2'b01;
                    imm1 <= 32'd0;
                    imm0 <= {{20{imm_i[11]}}, imm_i};
                end
                `STORE  : begin
                    pc_en <= 1'b0;
                    rs_en <= 2'b11;
                    wr_en <= 1'b0;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= {funct3, 2'b11};
                    imm_en <= 2'b01;
                    imm1 <= 32'd0;
                    imm0 <= {{20{imm_s[11]}}, imm_s};
                end
                default : begin
                    pc_en <= 1'b0;
                    rs_en <= 2'b00;
                    wr_en <= 1'b0;
                    jmp_ctrl <= 3'b000;
                    ram_ctrl <= 5'b00000;
                    imm_en <= 2'b00;
                    imm1 <= 32'd0;
                    imm0 <= 32'd0;
                end
            endcase
        end
    end


endmodule
