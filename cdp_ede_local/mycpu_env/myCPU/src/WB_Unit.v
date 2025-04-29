`include "my_cpu.vh"
`include "csr.vh"
module WB_Unit (
    input  wire                         clk,
    input  wire                         reset,
    output wire                         WB_Allow_in,
    input  wire                         ME_to_WB_Valid,
    input  wire [`ME_to_WB_Bus_Size-1:0] ME_to_WB_Bus,

    output wire [31:0]                  debug_wb_pc,// to debug and csr
    output wire [ 3:0]                  debug_wb_rf_we,
    output wire [ 4:0]                  debug_wb_rf_wnum,
    output wire [31:0]                  debug_wb_rf_wdata,

    output wire [`WB_to_RF_Bus_Size-1:0] WB_to_RF_Bus,
    output wire [`default_Dest_Size-1:0] WB_dest,
    output wire [`default_Data_Size-1:0] WB_Forward_Res,

    output wire                          ertn_flush,
    output wire                          excp_flush,
    output wire [ 5:0]                   wb_ecode,
    output wire [ 8:0]                   wb_esubcode,

    output wire                          csr_we,
    output wire [31:0]                   csr_wvalue,
    output wire [13:0]                   csr_num,
    output wire [`WB_to_EX_Bus_Size-1:0] WB_to_EX_Bus,
    output wire                          excp_commit
    );

reg [31:0]  pc;
reg         gr_we;
reg [4:0]   dest;
reg [31:0]  final_result;
reg         WB_csr_we;
reg [31:0]  WB_csr_wvalue;
reg [13:0]  WB_csr_num;
reg [5:0]   ME_excp_num;
reg         ME_excp_en;
reg         inst_ertn;

wire         WB_ReadyGo;
reg          WB_Valid;
wire         rf_we;
wire [4:0]   rf_waddr;
wire [31:0]  rf_wdata;




assign WB_ReadyGo = 1'b1;
assign WB_Allow_in = !WB_Valid || WB_ReadyGo;

always @(posedge clk) begin

    if(reset)begin
        WB_Valid <= 1'b0;
    end else if (WB_Allow_in) begin
        WB_Valid <= ME_to_WB_Valid;
    end 

    if (ME_to_WB_Valid && WB_Allow_in) begin
        {
            ME_excp_en,
            ME_excp_num,
            WB_csr_num,        
            WB_csr_we,       
            WB_csr_wvalue,    
            inst_ertn,
            pc,          //[69:38]   
            gr_we,       //[37:37]
            dest,        //[36:32]
            final_result //[31:0]
        } <= ME_to_WB_Bus;
    end
end

wire       WB_excp_en;
wire [5:0] WB_excp_num;
wire       badv_we;

assign WB_excp_en  = ME_excp_en & WB_Valid;
assign WB_excp_num = ME_excp_num;

assign excp_commit = WB_excp_en & WB_Valid;

assign ertn_flush = inst_ertn & WB_Valid;

/*
    excp_num
    [0] -> int,
    [1] -> ADEF,
    [2] -> BRK,
    [3] -> SYS,
    [4] -> INE,
    [5] -> ALE
*/


assign {wb_ecode, wb_esubcode, badv_we} =   WB_excp_num[0] ? {`ECODE_INT,       9'b0,           1'b0} :
                                            WB_excp_num[1] ? {`ECODE_ADEF_ADEM, `EsubCode_ADEF, 1'b1} :
                                            WB_excp_num[2] ? {`ECODE_BRK,       9'b0,           1'b0} :
                                            WB_excp_num[3] ? {`ECODE_SYS,       9'b0,           1'b0} : 
                                            WB_excp_num[4] ? {`ECODE_INE,       9'b0,           1'b0} :
                                            WB_excp_num[5] ? {`ECODE_ALE,       9'b0,           1'b1} :
                                            16'b0;

wire [31:0] badv_wdata;
assign badv_wdata = WB_excp_num[1] ? pc :
                    WB_excp_num[5] ? final_result : 32'b0;

assign csr_num    = badv_we ? 14'h7 : WB_csr_num;
assign csr_we     = WB_csr_we | badv_we;
assign csr_wvalue = badv_we ? badv_wdata : WB_csr_wvalue;

assign rf_we    = gr_we && WB_Valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

assign excp_flush = WB_Valid & WB_excp_en;

assign WB_dest = dest & {5{rf_we}};

assign WB_to_RF_Bus = {
                        rf_we,         //[37:37]
                        rf_waddr,      //[36:32]
                        rf_wdata       //[31:0]
                    };

assign WB_to_EX_Bus = {
    WB_csr_num,       
    WB_csr_we,         
    WB_csr_wvalue  
};

assign WB_Forward_Res = final_result;

endmodule