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
    output wire                          data_sram_en,
    output wire [3:0]                    data_sram_we,
    output wire [31:0]                   data_sram_addr,
    output wire [31:0]                   data_sram_wdata,
    output wire [`default_Dest_Size-1:0] EX_dest,
    output wire [`default_Data_Size-1:0] EX_Forward_Res,
    output wire                          EX_to_ID_Ld_op,
    output wire                          EX_to_ID_Sys_op,
    output wire                          csr_re,
    input  wire [31:0]                   csr_rvalue,
    output wire                          csr_we,
    output wire [31:0]                   csr_wvalue,
    output wire [13:0]                   csr_num,

    input  wire                          excp_flush,
    input  wire                          ertn_flush
);

reg                   inst_syscall;
reg                   inst_ertn;
reg                   inst_ld_w;
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

assign EX_ReadyGo = (alu_op[14]|alu_op[15]) ? divres_valid : 1'b1;
assign EX_Allow_in = !EX_Valid || EX_ReadyGo && ME_Allow_in;
assign EX_to_ME_Valid = EX_Valid && EX_ReadyGo;

assign EX_to_ID_Ld_op  = inst_ld_w;
assign EX_to_ID_Sys_op = (inst_syscall | inst_ertn) & EX_Valid;

always @(posedge clk) begin

    if(reset | flush_flag)begin
        EX_Valid <= 1'b0;
    end else if(EX_Allow_in) begin
        EX_Valid <= ID_to_EX_Valid;
    end

    if(EX_Allow_in && ID_to_EX_Valid)begin
        {
            inst_syscall,
            inst_ertn,
            EX_csr_wmask_en,
            EX_csr_we,
            EX_csr_num,
            res_from_csr,
            mem_is_byte,
            mem_is_half,
            src_is_signed,
            inst_ld_w,
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


assign csr_re       = res_from_csr;
assign csr_we       = EX_csr_we;
assign EX_csr_wmask = EX_csr_wmask_en ? rj_value : 32'hFFFFFFFF;
assign csr_wvalue   = rkd_value & EX_csr_wmask; 
assign csr_num      = EX_csr_num;

wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [31:0] alu_result;
wire [31:0] final_result;


assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .clk(clk),
    .reset(reset),
    .alu_valid(EX_Valid),
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .src_is_signed(src_is_signed),
    .alu_result (alu_result),
    .divres_valid(divres_valid)
    );

wire [4:0] dest_flag;
wire [1:0] data_sram_offset;

assign data_sram_addr   = alu_result;
assign data_sram_offset = data_sram_addr [1:0];
assign data_sram_en     = 1'b1;

assign data_sram_we    = (mem_we == 4'b0001) ? (4'b0001 << data_sram_offset) &{4{EX_Valid}} :
                         (mem_we == 4'b0011) ? (4'b0011 << data_sram_offset) &{4{EX_Valid}}:
                          mem_we & {4{EX_Valid}};

assign data_sram_wdata = (mem_we == 4'b0001) ? (rkd_value[7:0] << (8 * data_sram_offset)) : 
                         (mem_we == 4'b0011) ? (rkd_value[15:0] << (8 * data_sram_offset)) : 
                          rkd_value;

assign dest_flag = {src_is_signed, mem_is_byte, mem_is_half, data_sram_offset};

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


assign final_result = res_from_csr ? csr_rvalue : alu_result;

assign EX_dest         = dest & {5{EX_Valid}} & {5{gr_we}};

assign EX_to_ME_Bus = {
            inst_syscall,
            inst_ertn,      //[76:76]
            dest_flag,      //[75:71]
            pc,             //[70:39]
            final_result,   //[38:7]    
            res_from_mem,   //[6:6]
            gr_we,          //[5:5]
            dest            //[4:0]
        };

assign EX_Forward_Res = final_result;

endmodule