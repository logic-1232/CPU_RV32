//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_reg.v
// Descriptions:        浮点数寄存器管理模块
//-----------------------------------------README-----------------------------------------
// 实现对浮点数寄存器的读写控制。
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module cpu_fpreg (
        input               clk,
        input               rst_n,
        input       [4:0]   rs1,
        output      [63:0]  data1,
        input       [4:0]   rs2,
        output      [63:0]  data2,
        input       [4:0]   rs3,
        output      [63:0]  data3,
        input       [4:0]   rs4,
        output      [63:0]  data4,
        input               wr_en,
        input       [4:0]   wr_addr,
        input       [63:0]  wr_data
    );

    integer i;
    reg     [63:0]      fp_register[0:31];

    //*****************************************************
    //**                    main code
    //*****************************************************
    assign  data1 = fp_register[rs1];
    assign  data2 = fp_register[rs2];
    assign  data3 = fp_register[rs3];
    assign  data4 = fp_register[rs4];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<32; i=i+1) begin
                fp_register[i] <= 64'd0;
            end
        end
        else if(wr_en) begin
            fp_register[wr_addr] <= wr_data;
        end
        else begin
            for(i=0; i<32; i=i+1) begin
                fp_register[i] <= fp_register[i];
            end
        end
    end


endmodule
