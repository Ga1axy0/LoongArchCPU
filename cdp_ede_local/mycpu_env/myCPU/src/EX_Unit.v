`include "my_cpu.vh"
module EX_Unit (
    input  wire                          clk,
    input  wire                          reset,
    input  wire                          ID_to_EX_Valid,
    input  wire [`ID_to_EX_Bus_Size-1:0] ID_to_EX_Bus,
    output wire                          EX_Allow_in,
    output wire                          EX_to_ME_Valid,
    input  wire                          ME_Allow_in,
    output wire [`EX_to_ME_Bus_Size-1:0] EX_to_ME_Bus,
    
    output wire [`default_Dest_Size-1:0] EX_dest,
    output wire [`default_Data_Size-1:0] EX_Forward_Res,
    output wire                          EX_to_ID_Ld_op,
    output wire                          EX_to_ID_Sys_op,
    output wire                          csr_re,
    input  wire [31:0]                   csr_rvalue,
    output wire [13:0]                   csr_num,


    input  wire                          excp_flush,
    input  wire                          ertn_flush,
    output wire [1:0]                    timer_re,
    input  wire [31:0]                   timer_rdata,

    input  wire [`WB_to_EX_Bus_Size-1:0] WB_to_EX_Bus,
    input  wire [`ME_to_EX_Bus_Size-1:0] ME_to_EX_Bus,
    input  wire                          ME_to_ID_Sys_op,
    input  wire                          WB_to_ID_Sys_op,
    
    output wire                          data_sram_req,
    output wire                          data_sram_wr,
    output wire [1:0]                    data_sram_size,
    output wire [31:0]                   data_sram_addr,
    output wire [3:0]                    data_sram_wstrb,
    output wire [31:0]                   data_sram_wdata,
    input  wire                          data_sram_addr_ok
);

reg                   inst_rdcntid_w;
reg [1:0]             ID_timer_re;
reg                   ID_excp_en;
reg [4:0]             ID_excp_num;
reg                   mem_is_word;
reg                   ID_Store_op;
reg                   inst_ertn;
reg                   ID_Load_op;
reg [`alu_op_Size-1:0] alu_op;
reg [31:0]            pc;
reg [31:0]            imm;
reg [31:0]            rj_value;
reg [31:0]            rkd_value;
reg [4:0]             dest;
reg                   src1_is_pc;
reg                   src2_is_imm;
reg                   res_from_mem;
reg                   gr_we;
reg [3:0]             mem_we;
reg                   EX_Valid;
reg                   src_is_signed;
reg                   mem_is_byte;
reg                   mem_is_half;
reg                   res_from_csr;
reg [13:0]            EX_csr_num;
reg                   EX_csr_wmask_en;
reg                   EX_csr_we;
wire [31:0]           EX_csr_wmask;

wire                  EX_ReadyGo;
wire                  divres_valid;
wire                  flush_flag;

assign flush_flag = excp_flush | ertn_flush;

assign EX_ReadyGo = (alu_op[14]|alu_op[15]) ? divres_valid : 
                    data_sram_req           ? data_sram_addr_ok : 1'b1;
assign EX_Allow_in = !EX_Valid || EX_ReadyGo && ME_Allow_in;
assign EX_to_ME_Valid = EX_Valid && EX_ReadyGo;

assign EX_to_ID_Ld_op  = ID_Load_op;
assign EX_to_ID_Sys_op = (ID_excp_en |inst_ertn) & EX_Valid;

always @(posedge clk) begin

    if(reset | flush_flag)begin
        EX_Valid <= 1'b0;
    end else if(EX_Allow_in) begin
        EX_Valid <= ID_to_EX_Valid;
    end

    if(EX_Allow_in && ID_to_EX_Valid)begin
        {
            ID_timer_re,
            inst_rdcntid_w,
            ID_excp_en,
            ID_excp_num,
            mem_is_word,
            ID_Store_op,
            inst_ertn,
            EX_csr_wmask_en,
            EX_csr_we,
            EX_csr_num,
            res_from_csr,
            mem_is_byte,
            mem_is_half,
            src_is_signed,
            ID_Load_op,
            alu_op,         
            pc,             
            imm,             
            rj_value,       
            rkd_value,       
            src1_is_pc,     
            src2_is_imm,     
            res_from_mem,    
            gr_we,           
            mem_we,         
            dest             
        } <= ID_to_EX_Bus;
    end
end

wire        res_from_timer;
wire [31:0] csr_wvalue;
wire        csr_we;

wire        excp_ale;

assign csr_re       = res_from_csr;
assign csr_we       = EX_csr_we & ~ ME_to_ID_Sys_op & ~WB_to_ID_Sys_op;
assign EX_csr_wmask = EX_csr_wmask_en ? rj_value : 32'hFFFFFFFF;
assign csr_num      = inst_rdcntid_w ? 14'h40 : EX_csr_num;
assign timer_re     = ID_timer_re;

assign res_from_timer = |ID_timer_re[1:0];

wire        ME_csr_we;
wire [13:0] ME_csr_num;
wire [31:0] ME_csr_wvalue;

wire        WB_csr_we;
wire [13:0] WB_csr_num;
wire [31:0] WB_csr_wvalue;

assign { ME_csr_num,       
         ME_csr_we,         
         ME_csr_wvalue } = ME_to_EX_Bus;

assign { WB_csr_num,       
         WB_csr_we,         
         WB_csr_wvalue } = WB_to_EX_Bus;

wire [31:0] csr_rdata;

assign csr_rdata = (ME_csr_we & (csr_num == ME_csr_num)) ? ME_csr_wvalue :
                   (WB_csr_we & (csr_num == WB_csr_num)) ? WB_csr_wvalue : csr_rvalue;

wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [31:0] alu_result;
wire [31:0] final_result;

assign csr_wvalue   = rkd_value & EX_csr_wmask | ~EX_csr_wmask & csr_rdata; 


assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

wire alu_valid = EX_Valid & ~ME_to_ID_Sys_op & ~ WB_to_ID_Sys_op;

alu u_alu(
    .clk(clk),
    .reset(reset),
    .alu_valid(alu_valid),
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .src_is_signed(src_is_signed),
    .alu_result (alu_result),
    .divres_valid(divres_valid)
    );

assign excp_ale = (ID_Load_op | ID_Store_op) & ((mem_is_half && data_sram_offset[0]) ||
                                           (mem_is_word && |data_sram_offset[1:0]));

wire [4:0] dest_flag;
wire [1:0] data_sram_offset;


assign data_sram_addr   = alu_result;
assign data_sram_offset = data_sram_addr [1:0];
assign data_sram_req    = ~excp_ale & EX_to_ME_Valid & (ID_Load_op | ID_Store_op);

assign data_sram_wr     = |data_sram_wstrb;

assign data_sram_size     = mem_is_byte ? 2'b00 :
                            mem_is_half ? 2'b01 : 2'b10;

assign data_sram_wstrb  = (mem_we == 4'b0001) ? (4'b0001 << data_sram_offset) &{4{EX_Valid}} :
                          (mem_we == 4'b0011) ? (4'b0011 << data_sram_offset) &{4{EX_Valid}}:
                          mem_we & {4{EX_Valid}} & {4{~EX_excp_en}} & {4{~ME_to_ID_Sys_op}};


assign data_sram_wdata  = (mem_we == 4'b0001) ? (rkd_value[7:0] << (8 * data_sram_offset)) : 
                          (mem_we == 4'b0011) ? (rkd_value[15:0] << (8 * data_sram_offset)) : 
                          rkd_value;

assign dest_flag = {src_is_signed, mem_is_byte, mem_is_half, data_sram_offset};


wire       EX_excp_en;
wire [5:0] EX_excp_num;

assign EX_excp_en = ID_excp_en | excp_ale;
assign EX_excp_num = {excp_ale, ID_excp_num};

/*
    read byte:
    x1000 => [7:0]
    x1001 => [15:8]
    x1010 => [23:16]
    x1011 => [31:24]
    read half
    x0100 => [15:0]
    x0110 => [31:16]
    read full
    x0000 => [31:0]
*/

wire EX_gr_we;
assign EX_gr_we = gr_we & ~EX_excp_en & ~ME_to_ID_Sys_op & ~WB_to_ID_Sys_op;

assign final_result = res_from_csr   ? csr_rdata   : 
                      res_from_timer ? timer_rdata : alu_result;

assign EX_dest         = dest & {5{EX_Valid}} & {5{gr_we}};

assign EX_to_ME_Bus = {
            ID_Load_op,     //[132:132]
            ID_Store_op,    //[131:131]
            EX_excp_en,     //[130:130]
            EX_excp_num,    //[129:124]
            csr_num,        //[123:110]    
            csr_we,         //[109:109]
            csr_wvalue,     //[108:77]
            inst_ertn,      //[76:76]
            dest_flag,      //[75:71]
            pc,             //[70:39]
            final_result,   //[38:7]    
            res_from_mem,   //[6:6]
            EX_gr_we,       //[5:5]
            dest            //[4:0]
        };

assign EX_Forward_Res = final_result;

endmodule