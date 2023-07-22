`define     NOP         32'h00000013// nop指令
`define     X0          5'd0

/*ALU*/
`define     ALU_NOP     5'bzzzzz

`define     ALU_AND     5'b00000    // 逻辑与
`define     ALU_OR      5'b00001    // 逻辑或
`define     ALU_XOR     5'b00010    // 逻辑异或
`define     ALU_SLL     5'b00011    // 逻辑左移
`define     ALU_SRL     5'b00100    // 逻辑右移
`define     ALU_SRA     5'b00101    // 算数右移
`define     ALU_ADD     5'b00110    // 加法
`define     ALU_SUB     5'b00111    // 减法

`define     ALU_EQ      5'b01000    // 等于
`define     ALU_NE      5'b01001    // 不等于
`define     ALU_LT      5'b01100    // 小于
`define     ALU_GE      5'b01101    // 大于等于
`define     ALU_LTU     5'b01110    // 无符号小于
`define     ALU_GEU     5'b01111    // 无符号大于等于

`define     ALU_MULL    5'b10001    // 为了后续解码方便，调换了顺序
`define     ALU_MULH    5'b10000
`define     ALU_MULHSU  5'b10010
`define     ALU_MULHU   5'b10011
`define     ALU_DIV     5'b10100
`define     ALU_DIVU    5'b10101
`define     ALU_REM     5'b10110
`define     ALU_REMU    5'b10111


/*opcode*/
`define     OP          7'b0110011  // 基础整数运算-寄存器
`define     OP_IMM      7'b0010011  // 基础整数运算-立即数
`define     LOAD        7'b0000011
`define     STORE       7'b0100011
`define     BRANCH      7'b1100011  // 分支指令集
`define     JAL         7'b1101111  // 跳转并链接
`define     JALR        7'b1100111  // 跳转并寄存器链接
`define     AUIPC       7'b0010111  // pc加立即数
`define     LUI         7'b0110111  // 高位立即数加载

/*funct3*/
/*OP、OP_IMM*/
`define     ADD     3'b000      //整数加法
`define     SUB     3'b000      //整数减法
`define     SLL     3'b001      //左移运算
`define     SLT     3'b010      //小于则置位
`define     SLTU    3'b011      //小于无符号数则置位
`define     XOR     3'b100      //异或
`define     SRL     3'b101      //逻辑右移运算
`define     SRA     3'b101      //算数右移运算
`define     OR      3'b110      //或
`define     AND     3'b111      //与
/*opcode==`OP, funct7==`MULDIV*/
`define     MULL    3'b000      //乘法，取低位
`define     MULH    3'b001      //乘法，有符号*有符号，取高位
`define     MULHSU  3'b010      //乘法，有符号*无符号，取高位
`define     MULHU   3'b011      //乘法，无符号*无符号，取高位
`define     DIV     3'b100      //有符号除法求商
`define     DIVU    3'b101      //无符号除法求商
`define     REM     3'b110      //有符号除法取余
`define     REMU    3'b111      //无符号除法取余
/*BRANCH*/
`define     BEQ     3'b000      //相等时分支
`define     BNE     3'b001      //不相等时分支
`define     BLT     3'b100      //小于时分支
`define     BGE     3'b101      //大于等于时分支
`define     BLTU    3'b110      //无符号小于时分支
`define     BGEU    3'b111      //无符号大于等于时分支
/*LOAD*/
`define     LB      3'b000      //加载字节
`define     LH      3'b001      //加载半字
`define     LW      3'b010      //加载字
`define     LBU     3'b100      //加载无符号字节
`define     LHU     3'b101      //加载无符号半字
/*STORE*/
`define     SB      3'b000      //存字节
`define     SH      3'b001      //存半字
`define     SW      3'b010      //存字

/*funct7*/
`define     BASE    7'b0000000
`define     SPEC    7'b0100000
`define     MULDIV  7'b0000001  //乘除法
