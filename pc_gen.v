//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           pc_gen.v
// Descriptions:        程序计数器（pc）生成模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module pc_gen (
        input               clk,
        input               rst_n,
        input               pc_move,
        input               flush_flag,
        input               wait_exe,
        input               wait_jmp,
        input               decompr_en,
        input               jmp_pred,
        input       [15:0]  pc_now,
        input       [15:0]  pc_jmp,
        output  reg [15:0]  pc
    );

    reg     [15:0]      pc_next;
    reg     [15:0]      pc_branch;
    reg     [15:0]      flush_pc[0:1];

    always @(*) begin
        if(~pc_move)  // 为了修复第一条指令无法取出的问题
            pc_next = 16'd0;
        else if(flush_flag)  // 从预测跳转到执行结果返回预测错误，需要两个时钟周期
            pc_next = flush_pc[1];
        else if(wait_exe | wait_jmp)
            pc_next = pc_now;
        else
            pc_next = pc_now + (decompr_en ? 16'd2 : 16'd4);
    end
    always @(*) begin  // 根据当前状态选择顺序执行和分支跳转
        if(flush_flag) begin
            pc = pc_next;
            pc_branch = pc_jmp;
        end
        else if(wait_exe | wait_jmp) begin
            pc = pc_next;
            pc_branch = pc_jmp;
        end
        else if(jmp_pred) begin
            pc = pc_jmp;
            pc_branch = pc_next;
        end
        else begin
            pc = pc_next;
            pc_branch = pc_jmp;
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if(!rst_n || flush_flag) begin
            flush_pc[0] <= 16'd0;
            flush_pc[1] <= 16'd0;
        end
        else if(wait_exe | wait_jmp) begin
            flush_pc[0] <= flush_pc[0];
            flush_pc[1] <= flush_pc[1];
        end
        else begin
            flush_pc[0] <= pc_branch;
            flush_pc[1] <= flush_pc[0];
        end
    end


endmodule
