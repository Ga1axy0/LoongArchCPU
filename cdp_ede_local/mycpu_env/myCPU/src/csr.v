`include "csr.vh"

module CSR_Unit (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] core_id_in,

    //Hardware Interrupt
    input  wire [7:0]  hw_int_in,

    //Inter-Processor Interrupt
    input  wire        ipi_int_in,
 
    //EX
    input  wire [13:0] csr_rnum,

    input  wire        csr_re,
    output wire [31:0] csr_rdata,

    

    //Pre-IF
    output wire [31:0] ex_entry,
    output wire [31:0] er_entry,
    //ID
    output wire        has_int,

    //WB
    input  wire        ertn_flush,
    input  wire        wb_ex,
    input  wire [ 5:0] wb_ecode,
    input  wire [ 8:0] wb_esubcode,
    input  wire [31:0] wb_pc,

    input  wire        csr_we,
    input  wire [31:0] csr_wdata,
    input  wire [13:0] csr_wnum

);

localparam CRMD      = 14'h0;     //当前模式信息
localparam PRMD      = 14'h1;     //例外前模式信息
localparam EUEN      = 14'h2;     //扩展部件使能
localparam ECFG      = 14'h4;     //例外配置
localparam ESTAT     = 14'h5;     //例外状态
localparam ERA       = 14'h6;     //例外返回地址
localparam BADV      = 14'h7;     //出错虚地址
localparam EENTRY    = 14'hc;     //例外入口地址
localparam TLBIDX    = 14'h10;    //TLB锁引
localparam TLBEHI    = 14'h11;    //TLB表项高位
localparam TLBELO0   = 14'h12;    //TLB表项低位0
localparam TLBELO1   = 14'h13;    //TLB表项低位1
localparam ASID      = 14'h18;    //地址空间标识符
localparam PGDL      = 14'h19;    //低半地址空间全局目录基址
localparam PGDH      = 14'h1A;    //高半地址空间全局目录基址
localparam PGD       = 14'h1B;    //全局目录基址
localparam CPUID     = 14'h20;    //处理器编号
localparam SAVE0     = 14'h30;    //数据保存0
localparam SAVE1     = 14'h31;    //数据保存1
localparam SAVE2     = 14'h32;    //数据保存2
localparam SAVE3     = 14'h33;    //数据保存3
localparam TID       = 14'h40;    //定时器编号
localparam TCFG      = 14'h41;    //定时器配置
localparam TVAL      = 14'h42;    //定时器值
localparam TICLR     = 14'h44;    //定时中断清除
localparam LLBCTL    = 14'h60;    //LLBit控制
localparam TLBRENTRY = 14'h88;    //TLB重填例外入口地址
localparam CTAG      = 14'h98;    //高速缓存标签
localparam DMW0      = 14'h180;   //直接映射配置窗口0
localparam DMW1      = 14'h181;   //直接映射配置窗口1



reg [31:0] csr_crmd;
reg [31:0] csr_prmd;
reg [31:0] csr_ecfg;
reg [31:0] csr_estat;
reg [31:0] csr_era;
reg [31:0] csr_badv;
reg [31:0] csr_eentry;
reg [31:0] csr_save_0;
reg [31:0] csr_save_1;
reg [31:0] csr_save_2;
reg [31:0] csr_save_3;
reg [31:0] csr_tid;
reg [31:0] csr_tcfg;
reg [31:0] csr_tval;
reg [31:0] csr_ticlr;


wire crmd_wen;
wire prmd_wen;
wire ecfg_wen;
wire estat_wen;
wire era_wen;
wire badv_wen;
wire eentry_wen;
wire save_0_wen;
wire save_1_wen;
wire save_2_wen;
wire save_3_wen;
wire tid_wen;
wire tcfg_wen;
wire tval_wen;
wire ticlr_wen;


wire [31:0] csr_rvalue;

reg  [31:0] timer_cnt;
wire [31:0] tcfg_next_value;

assign csr_rvalue  = {32{csr_rnum == CRMD  }} & csr_crmd   |
                     {32{csr_rnum == PRMD  }} & csr_prmd   |
                     {32{csr_rnum == ECFG  }} & csr_ecfg   | 
                     {32{csr_rnum == ESTAT }} & csr_estat  |
                     {32{csr_rnum == ERA   }} & csr_era    |
                     {32{csr_rnum == BADV  }} & csr_badv   |
                     {32{csr_rnum == EENTRY}} & csr_eentry |
                     {32{csr_rnum == SAVE0 }} & csr_save_0 |
                     {32{csr_rnum == SAVE1 }} & csr_save_1 | 
                     {32{csr_rnum == SAVE2 }} & csr_save_2 |
                     {32{csr_rnum == SAVE3 }} & csr_save_3 |
                     {32{csr_rnum == TID   }} & csr_tid    |
                     {32{csr_rnum == TCFG  }} & csr_tcfg   |
                     {32{csr_rnum == TVAL  }} & csr_tval   |
                     {32{csr_rnum == TICLR }} & csr_ticlr  ;

assign crmd_wen   = csr_we & {csr_wnum == CRMD};
assign prmd_wen   = csr_we & {csr_wnum == PRMD};
assign ecfg_wen   = csr_we & {csr_wnum == ECFG};
assign estat_wen  = csr_we & {csr_wnum == ESTAT};
assign era_wen    = csr_we & {csr_wnum == ERA};
assign badv_wen   = csr_we & {csr_wnum == BADV};
assign eentry_wen = csr_we & {csr_wnum == EENTRY};
assign save_0_wen = csr_we & {csr_wnum == SAVE0};
assign save_1_wen = csr_we & {csr_wnum == SAVE1};
assign save_2_wen = csr_we & {csr_wnum == SAVE2};
assign save_3_wen = csr_we & {csr_wnum == SAVE3};
assign tid_wen    = csr_we & {csr_wnum == TID};
assign tcfg_wen   = csr_we & {csr_wnum == TCFG};
assign tval_wen   = csr_we & {csr_wnum == TVAL};
assign ticlr_wen  = csr_we & {csr_wnum == TICLR};

assign csr_rdata = {32{csr_re}} & csr_rvalue;

assign has_int = ((csr_estat[`IS] & csr_ecfg[`LIE]) != 13'b0) && (csr_crmd[`IE] == 1'b1);

assign ex_entry = csr_eentry;

assign er_entry = csr_era;


//CRMD
always @(posedge clk) begin
    if (reset) begin
        csr_crmd[`PLV]  <= 2'b0;
        csr_crmd[`IE]   <= 1'b0;
        csr_crmd[`DA]   <= 1'b1;
        csr_crmd[`PG]   <= 1'b0;
        csr_crmd[`DATF] <= 2'b00;
        csr_crmd[`DATM] <= 2'b00;
        csr_crmd[31:9]  <= 23'd0;
    end else if (wb_ex) begin
        csr_crmd[`PLV] <= 2'b0;
        csr_crmd[`IE]  <= 1'b0;
    end else if (ertn_flush) begin
        csr_crmd[`PLV] <= csr_prmd[`PPLV];
        csr_crmd[`IE]  <= csr_prmd[`PIE];
    end else if (crmd_wen) begin
        csr_crmd[`PLV] <= csr_wdata[`PLV];
        csr_crmd[`IE]  <= csr_wdata[`IE];
    end
end


//PRMD
always @(posedge clk) begin
    if (reset) begin
        csr_prmd <= 32'b0;
    end else if (wb_ex) begin
        csr_prmd[`PPLV] <= csr_crmd[`PLV];
        csr_prmd[`PIE]  <= csr_crmd[`IE];
    end else if (ertn_flush) begin
        csr_prmd[`PPLV] <= csr_crmd[`PLV];
        csr_prmd[`PIE]  <= csr_crmd[`IE];
    end
    else if (prmd_wen) begin
        csr_prmd[`PPLV] <= csr_wdata[`PPLV];
        csr_prmd[`PIE]  <= csr_wdata[`PIE];
    end
end

//ECFG
always @(posedge clk) begin
    if (reset) begin
        csr_ecfg[`LIE] <= 13'b0;
    end else if (ecfg_wen) begin
        csr_ecfg[`LIE] <= csr_wdata[`LIE] & 13'h1BFF; //第10位为保留域
    end
end

//ESTAT
always @(posedge clk) begin
    if (reset) begin
        csr_estat[`IS]   <= 13'b0;
        csr_estat[15:13] <= 3'b0;
        csr_estat[31]    <= 1'b0;
    end else if (estat_wen) begin
        csr_estat[`IS_1_0] <= csr_wdata[`IS_1_0];
    end

    csr_estat[`IS_9_2] <= hw_int_in;
    csr_estat[`IS_12]  <= ipi_int_in;

    if(wb_ex) begin
        csr_estat[`Ecode]    <= wb_ecode;   
        csr_estat[`EsubCode] <= wb_esubcode;
    end

    if(csr_tcfg[`En] && timer_cnt == 32'b0)
        csr_estat[`IS_11] <= 1'b1;
    else if(ticlr_wen) 
        csr_estat[`IS_11] <= 1'b0;
end

//ERA
always @(posedge clk) begin
    if(wb_ex) begin
        csr_era <= wb_pc;
    end else if (era_wen) begin
        csr_era <= csr_wdata;
    end
end

//EENTRY
always @(posedge clk) begin
    if(reset)begin
        csr_eentry <= 32'b0;
    end else if (eentry_wen) begin
        csr_eentry[`VA] <= csr_wdata[`VA];
    end
end

//SAVE0~3
always @(posedge clk) begin
    if(save_0_wen) begin
        csr_save_0 <= csr_wdata;
    end
    if(save_1_wen) begin
        csr_save_1 <= csr_wdata;
    end
    if(save_2_wen) begin
        csr_save_2 <= csr_wdata;
    end
    if(save_3_wen) begin
        csr_save_3 <= csr_wdata;
    end
end


//TID
always @(posedge clk) begin
    if(reset)begin
        csr_tid[`TID] <= core_id_in;
    end else if (tid_wen) begin
        csr_tid[`TID] <= csr_wdata[`TID];
    end
end

//TCFG
always @(posedge clk) begin
    if(reset)begin
        csr_tcfg[`En] <= 1'b0;
    end else if (tcfg_wen) begin
        csr_tcfg[`En] <= csr_wdata[`En];
    end

    if(tcfg_wen)begin
        csr_tcfg[`Periodic] <= csr_wdata[`Periodic];
        csr_tcfg[`InitVal]  <= csr_wdata[`InitVal];
    end
end

//TVAL
assign tcfg_next_value = tcfg_wen ? csr_wdata : csr_tcfg;

always @(posedge clk) begin
    if(reset)
        timer_cnt <= 32'hffffffff;
    else if (tcfg_wen && tcfg_next_value[`En])
        timer_cnt <= {tcfg_next_value[`InitVal], 2'b0}; 
    else if (csr_tcfg[`En] && timer_cnt != 32'hffffffff)begin
        if(timer_cnt == 32'b0 && csr_tcfg[`Periodic])
            timer_cnt <= {csr_tcfg[`InitVal], 2'b0};
        else
            timer_cnt <= timer_cnt - 1'b1;
    end
end

assign csr_tval = timer_cnt;

//TICLR
assign csr_ticlr[`CLR] = 1'b0;

                    
endmodule