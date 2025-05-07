`include "my_cpu.vh"
module ID_Unit (
    input  wire                           clk,
    input  wire                           reset,
    input  wire                           IF_to_ID_Valid,
    input  wire                           EX_Allow_in,
    input  wire [`default_Dest_Size-1:0]  EX_dest,
    input  wire [`default_Dest_Size-1:0]  ME_dest,
    input  wire [`default_Dest_Size-1:0]  WB_dest,
    output wire                           ID_Allow_in,
    output wire                           ID_to_EX_Valid,
    output wire [`ID_to_EX_Bus_Size-1:0]  ID_to_EX_Bus,

    input  wire [`IF_to_ID_Bus_Size-1:0]  IF_to_ID_Bus,
    input  wire [`WB_to_RF_Bus_Size-1:0]  WB_to_RF_Bus,
    output wire [`br_bus_Size-1:0]        br_bus,

    input  wire                           EX_to_ID_Ld_op,
    input  wire                           EX_to_ID_Sys_op,
    input  wire                           ME_to_ID_Sys_op,
    input  wire                           WB_to_ID_Sys_op,

    input  wire [`default_Data_Size-1:0]  EX_Forward_Res,
    input  wire [`default_Data_Size-1:0]  ME_Forward_Res,
    input  wire [`default_Data_Size-1:0]  WB_Forward_Res,

    input  wire                           excp_flush,
    input  wire                           ertn_flush,

    input  wire                           has_int
);

reg [31:0] pc;
reg [31:0] inst;
reg        IF_excp_num;
reg        IF_excp_en;

wire excp_ine;

reg        ID_Valid;
wire       ID_ReadyGo;
wire       flush_flag;

wire        rd_eq;
wire        rj_eq;
wire        rk_eq;
wire        stall;      
wire        ld_stall;
wire        sys_stall;

assign      sys_stall = EX_to_ID_Sys_op | ME_to_ID_Sys_op;

assign      ld_stall = EX_to_ID_Ld_op && (((rj == EX_dest) & rj_eq) || 
                                          ((rd == EX_dest) & rd_eq) || 
                                          ((rk == EX_dest) & rk_eq));

assign      ID_ReadyGo = ID_Valid & ~ld_stall &  ~sys_stall;
assign      ID_Allow_in = !ID_Valid || ID_ReadyGo && EX_Allow_in;
assign      ID_to_EX_Valid = ID_Valid && ID_ReadyGo;

assign      flush_flag = excp_flush | ertn_flush;

always @(posedge clk) begin
    if(reset | br_taken | flush_flag)begin
        ID_Valid <= 1'b0;
    end else if (ID_Allow_in) begin
        ID_Valid <= IF_to_ID_Valid;
    end

    if(IF_to_ID_Valid && ID_Allow_in)begin
        {IF_excp_en, IF_excp_num, pc, inst} <= IF_to_ID_Bus;
    end 
    
end


wire        br_taken;
wire [31:0] br_target;

wire        inst_valid;
wire        load_op;
wire        src1_is_pc;
wire        src2_is_imm;
wire        res_from_mem;
wire        res_from_csr;
wire        csr_we;
wire        csr_wmask_en;
wire        dst_is_r1;
wire        gr_we;
wire [3:0]  mem_we;
wire        src_reg_is_rd;
wire        src_reg_is_rj;
wire        src_reg_is_rk;
wire        src_is_signed;
wire        mem_is_byte;
wire        mem_is_half;
wire        mem_is_word;



wire [`alu_op_Size-1:0] alu_op;
wire [4: 0] dest;
wire [31:0] rj_value;
wire [31:0] rkd_value;
wire [31:0] imm;
wire [31:0] br_offs;
wire [31:0] jirl_offs;

wire [ 5:0] op_31_26;
wire [ 3:0] op_25_22;
wire [ 1:0] op_21_20;
wire [ 1:0] op_25_24;
wire [ 4:0] op_9_5;
wire [ 4:0] op_4_0;
wire [ 4:0] op_19_15;
wire [ 4:0] op_14_10;
wire [ 4:0] rd;
wire [ 4:0] rj;
wire [ 4:0] rk;
wire [11:0] i12;
wire [19:0] i20;
wire [15:0] i16;
wire [25:0] i26;
wire [13:0] csr_num;

wire [63:0] op_31_26_d;
wire [15:0] op_25_22_d;
wire [ 3:0] op_21_20_d;
wire [ 3:0] op_25_24_d;
wire [31:0] op_14_10_d;
wire [31:0] op_19_15_d;
wire [31:0] op_9_5_d;
wire [31:0] op_4_0_d;

wire        inst_add_w;
wire        inst_sub_w;
wire        inst_slt;
wire        inst_sltu;
wire        inst_nor;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_slli_w;
wire        inst_srli_w;
wire        inst_srai_w;
wire        inst_addi_w;
wire        inst_ld_w;
wire        inst_st_w;
wire        inst_jirl;
wire        inst_b;
wire        inst_bl;
wire        inst_beq;
wire        inst_bne;
wire        inst_lu12i_w;
wire        inst_slti;
wire        inst_sltui;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sll_w;
wire        inst_srl_w;
wire        inst_sra_w;
wire        inst_pcaddu12i;
wire        inst_mul_w;
wire        inst_mulh_w;
wire        inst_mulh_wu;
wire        inst_div_w;
wire        inst_div_wu;
wire        inst_mod_w;
wire        inst_mod_wu;
wire        inst_blt;
wire        inst_bltu;
wire        inst_bge;
wire        inst_bgeu;
wire        inst_ld_b;
wire        inst_ld_h;
wire        inst_ld_bu;
wire        inst_ld_hu;
wire        inst_st_b;
wire        inst_st_h;

wire        inst_csrrd;
wire        inst_csrwr;
wire        inst_csrxchg;
wire        inst_ertn;

wire        inst_syscall;
wire        inst_break;

wire        inst_rdcntid_w;
wire        inst_rdcntvl_w;
wire        inst_rdcntvh_w;

wire        need_ui5;
wire        need_ui12;
wire        need_si12;
wire        need_si16;
wire        need_si20;
wire        need_si26;
wire        src2_is_4;

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;

wire        ID_Load_op;
wire        ID_Store_op;

assign op_31_26  = inst[31:26];
assign op_25_22  = inst[25:22];
assign op_21_20  = inst[21:20];
assign op_19_15  = inst[19:15];
assign op_14_10  = inst[14:10];
assign op_25_24  = inst[25:24];
assign op_9_5    = inst[ 9: 5];
assign op_4_0    = inst[ 4: 0];


assign rd   = inst[ 4: 0];
assign rj   = inst[ 9: 5];
assign rk   = inst[14:10];

assign i12  = inst[21:10];
assign i20  = inst[24: 5];
assign i16  = inst[25:10];
assign i26  = {inst[ 9: 0], inst[25:10]};

assign csr_num = inst[23:10];

decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));
decoder_2_4  u_dec4(.in(op_25_24 ), .out(op_25_24_d ));
decoder_5_32 u_dec5(.in(op_9_5   ), .out(op_9_5_d   ));
decoder_5_32 u_dec6(.in(op_14_10 ), .out(op_14_10_d ));
decoder_5_32 u_dec7(.in(op_4_0   ), .out(op_4_0_d   ));

assign inst_add_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
assign inst_sub_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
assign inst_slt       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
assign inst_sltu      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
assign inst_nor       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
assign inst_and       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
assign inst_or        = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
assign inst_xor       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
assign inst_slli_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
assign inst_srli_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
assign inst_srai_w    = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];

assign inst_lu12i_w   = op_31_26_d[6'h05] & ~inst[25];
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~inst[25];

assign inst_addi_w    = op_31_26_d[6'h00] & op_25_22_d[4'ha];
assign inst_slti      = op_31_26_d[6'h00] & op_25_22_d[4'h8];
assign inst_sltui     = op_31_26_d[6'h00] & op_25_22_d[4'h9];
assign inst_andi      = op_31_26_d[6'h00] & op_25_22_d[4'hd];
assign inst_ori       = op_31_26_d[6'h00] & op_25_22_d[4'he];
assign inst_xori      = op_31_26_d[6'h00] & op_25_22_d[4'hf];

assign inst_ld_w      = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
assign inst_ld_b      = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
assign inst_ld_h      = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
assign inst_ld_bu     = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
assign inst_ld_hu     = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
assign inst_st_w      = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
assign inst_st_b      = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
assign inst_st_h      = op_31_26_d[6'h0a] & op_25_22_d[4'h5];


assign inst_sll_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0e];
assign inst_srl_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
assign inst_sra_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
assign inst_mul_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
assign inst_mulh_w    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
assign inst_mulh_wu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
assign inst_div_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h00];
assign inst_mod_w     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h01];
assign inst_div_wu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h02];
assign inst_mod_wu    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h03];

assign inst_jirl      = op_31_26_d[6'h13];
assign inst_b         = op_31_26_d[6'h14];
assign inst_bl        = op_31_26_d[6'h15];
assign inst_beq       = op_31_26_d[6'h16];
assign inst_bne       = op_31_26_d[6'h17];
assign inst_blt       = op_31_26_d[6'h18];  
assign inst_bge       = op_31_26_d[6'h19];
assign inst_bltu      = op_31_26_d[6'h1a];
assign inst_bgeu      = op_31_26_d[6'h1b];



assign inst_rdcntid_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & op_14_10_d[5'h18] & op_4_0_d[5'h00];
assign inst_rdcntvh_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & op_14_10_d[5'h19] & op_9_5_d[5'h00];
assign inst_rdcntvl_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & op_14_10_d[5'h18] & op_9_5_d[5'h00];

assign inst_csrrd     = op_31_26_d[6'h01] & op_25_24_d[2'h0] & op_9_5_d[5'h00];
assign inst_csrwr     = op_31_26_d[6'h01] & op_25_24_d[2'h0] & op_9_5_d[5'h01];
assign inst_csrxchg   = op_31_26_d[6'h01] & op_25_24_d[2'h0] & ~(op_9_5_d[5'h00] | op_9_5_d[5'h01]); 
assign inst_ertn      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & op_14_10_d[5'h0e] & op_9_5_d[5'h00] & op_4_0_d[5'h00  ];

assign inst_syscall   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16];
assign inst_break     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14];

assign inst_valid     = inst_add_w      |
                        inst_sub_w      |
                        inst_slt        |
                        inst_sltu       |
                        inst_nor        |
                        inst_and        |
                        inst_or         |
                        inst_xor        |
                        inst_slli_w     |
                        inst_srli_w     |
                        inst_srai_w     |
                        inst_lu12i_w    |
                        inst_pcaddu12i  |
                        inst_addi_w     |
                        inst_slti       |
                        inst_sltui      |
                        inst_andi       |
                        inst_ori        |
                        inst_xori       |
                        inst_ld_w       |
                        inst_ld_b       |
                        inst_ld_h       |
                        inst_ld_bu      |
                        inst_ld_hu      |
                        inst_st_w       |
                        inst_st_b       |
                        inst_st_h       |
                        inst_sll_w      |
                        inst_srl_w      |
                        inst_sra_w      |
                        inst_mul_w      |
                        inst_mulh_w     |
                        inst_div_w      |
                        inst_mod_w      |
                        inst_div_wu     |
                        inst_mod_wu     |
                        inst_mulh_wu    |
                        inst_jirl       |
                        inst_b          |
                        inst_bl         |
                        inst_beq        |
                        inst_bne        |
                        inst_blt        |
                        inst_bge        |
                        inst_bltu       |
                        inst_bgeu       |
                        inst_csrrd      |
                        inst_csrwr      |
                        inst_csrxchg    |
                        inst_ertn       |
                        inst_syscall    |
                        inst_break      |
                        inst_rdcntid_w  |
                        inst_rdcntvh_w  |
                        inst_rdcntvl_w  ;

wire ID_excp_en;
wire [4:0] ID_excp_num;

assign excp_ine = ~inst_valid;
assign ID_excp_en  = IF_excp_en | excp_ine | inst_syscall | inst_break | has_int;
assign ID_excp_num = {excp_ine, inst_syscall, inst_break, IF_excp_num, has_int};

assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w |
                     inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_b|
                     inst_ld_bu| inst_ld_h | inst_ld_hu | inst_st_b | inst_st_h;
assign alu_op[ 1] = inst_sub_w;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltui;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_slli_w | inst_sll_w;
assign alu_op[ 9] = inst_srli_w | inst_srl_w;
assign alu_op[10] = inst_srai_w | inst_sra_w;
assign alu_op[11] = inst_lu12i_w;
assign alu_op[12] = inst_mul_w ;
assign alu_op[13] = inst_mulh_w | inst_mulh_wu;
assign alu_op[14] = inst_div_w | inst_div_wu;
assign alu_op[15] = inst_mod_w | inst_mod_wu;


assign ID_Load_op  = inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu | inst_ld_w;
assign ID_Store_op = inst_st_b | inst_st_h | inst_st_w;

assign src_is_signed = inst_mul_w | inst_mulh_w | inst_div_w | inst_mod_w | inst_blt | inst_bge | inst_ld_b | inst_ld_h;

assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;
assign need_ui12  =  inst_andi | inst_ori | inst_xori;
assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui | 
                     inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu | inst_st_b | inst_st_h;
assign need_si16  =  inst_jirl | inst_beq | inst_bne | inst_blt | inst_bltu | inst_bge | inst_bgeu;
assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
assign need_si26  =  inst_b | inst_bl;
assign src2_is_4  =  inst_jirl | inst_bl;

assign imm = src2_is_4 ? 32'h4                      :
             need_si20 ? {i20[19:0], 12'b0}         :
             need_ui5  ? rk                         :
             need_ui12 ? {20'b0,i12[11:0]}          :
/*need_si12*/            {{20{i12[11]}}, i12[11:0]} ;

assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                             {{14{i16[15]}}, i16[15:0], 2'b0} ;

assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_blt | inst_bltu | inst_bge | inst_bgeu | inst_st_b | inst_st_h | inst_csrwr | inst_csrxchg | inst_rdcntid_w;
assign src_reg_is_rj = ~(inst_b | inst_bl | inst_lu12i_w | inst_csrrd | inst_csrwr);
assign src_reg_is_rk = ~(inst_slli_w | inst_srli_w | inst_srai_w | inst_addi_w | inst_ld_w | inst_st_w | inst_jirl | 
                         inst_b | inst_bl | inst_beq | inst_bne | inst_lu12i_w | inst_slti | inst_sltui | inst_andi | 
                         inst_ori | inst_xori | inst_st_b | inst_st_h | inst_blt | inst_bltu | inst_bge | inst_bgeu |
                         inst_csrrd | inst_csrwr | inst_csrxchg | inst_rdcntid_w | inst_rdcntvh_w | inst_rdcntvl_w);

assign rd_eq = src_reg_is_rd && rd != 5'b0 && ((rd == EX_dest) || (rd == ME_dest) || (rd == WB_dest));
assign rj_eq = src_reg_is_rj && rj != 5'b0 && ((rj == EX_dest) || (rj == ME_dest) || (rj == WB_dest));
assign rk_eq = src_reg_is_rk && rk != 5'b0 && ((rk == EX_dest) || (rk == ME_dest) || (rk == WB_dest));

assign stall = rd_eq | rj_eq | rk_eq;

assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

assign src2_is_imm   = inst_slli_w |
                       inst_srli_w |
                       inst_srai_w |
                       inst_addi_w |
                       inst_ld_w   |
                       inst_st_w   |
                       inst_lu12i_w|
                       inst_jirl   |
                       inst_bl     |
                       inst_slti   |
                       inst_sltui  |
                       inst_andi   |
                       inst_ori    |
                       inst_xori   |
                       inst_pcaddu12i|
                       inst_ld_h   |
                       inst_ld_hu  |
                       inst_ld_b   |
                       inst_ld_bu  |
                       inst_st_h   |
                       inst_st_b;

assign res_from_mem  = inst_ld_w | inst_ld_b | inst_ld_bu | inst_ld_h | inst_ld_hu;


assign dst_is_r1     = inst_bl;
assign gr_we         = (~inst_st_w & ~inst_beq & ~inst_bne & ~inst_b & ~inst_st_h & ~inst_st_b & ~inst_blt & ~inst_bltu & ~inst_bge & ~inst_bgeu & ~inst_ertn)
                        & ~ID_excp_en;
assign mem_we        = inst_st_w ? 4'b1111 : 
                       inst_st_b ? 4'b0001 :
                       inst_st_h ? 4'b0011 :
                                   4'b0000 ;
assign dest          = dst_is_r1      ? 5'd1 : 
                       inst_rdcntid_w ? rj   : 
                       rd;
assign mem_is_byte   = inst_ld_b | inst_ld_bu | inst_st_b;
assign mem_is_half   = inst_ld_h | inst_ld_hu | inst_st_h;
assign mem_is_word   = inst_ld_w | inst_st_w;

assign rf_raddr1 = rj;
assign rf_raddr2 = src_reg_is_rd ? rd :rk;

assign {rf_we, rf_waddr, rf_wdata} = WB_to_RF_Bus;

regfile u_regfile(
    .clk    (clk      ),
    .reset  (reset    ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

assign rj_value  = rj_eq ? ((EX_dest == rj) ? EX_Forward_Res : 
                            (ME_dest == rj) ? ME_Forward_Res : WB_Forward_Res) : 
                            rf_rdata1;
assign rkd_value = rd_eq ? ((EX_dest == rd) ? EX_Forward_Res : 
                            (ME_dest == rd) ? ME_Forward_Res : WB_Forward_Res) : 
                   rk_eq ? ((EX_dest == rk) ? EX_Forward_Res : 
                            (ME_dest == rk) ? ME_Forward_Res : WB_Forward_Res) :
                            rf_rdata2;

wire rj_gt_rd;
wire rj_eq_rd;

assign rj_eq_rd = (rj_value == rkd_value);
assign rj_gt_rd = src_is_signed ? ($signed(rj_value) >= $signed(rkd_value)) : ($unsigned(rj_value) >= $unsigned(rkd_value));


assign br_taken = (   (inst_beq  &&  rj_eq_rd)
                   || (inst_bne  && !rj_eq_rd)
                   || inst_jirl
                   || inst_bl
                   || inst_b
                   || ((inst_bge | inst_bgeu) && rj_gt_rd)
                   || ((inst_blt | inst_bltu) && !rj_gt_rd)
) && ID_Valid && ~ld_stall;

assign br_target = (inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bltu || inst_bge || inst_bgeu) ? (pc + br_offs) :
                                                   /*inst_jirl*/ (rj_value + jirl_offs);

wire br_stall;
assign br_stall = br_taken & ~ID_ReadyGo;
assign br_bus = {br_taken , br_target, br_stall};


assign csr_wmask_en = inst_csrxchg;
assign csr_we       = inst_csrwr | inst_csrxchg;
assign res_from_csr = inst_csrrd | inst_csrxchg | inst_csrwr | inst_rdcntid_w | inst_rdcntid_w;

wire [1:0] timer_re;

assign timer_re = {inst_rdcntvh_w, inst_rdcntvl_w};

assign ID_to_EX_Bus = { 
                        timer_re,        //[189:188]
                        inst_rdcntid_w,  //[187:187]
                        ID_excp_en,      //[186:186]
                        ID_excp_num,     //[185:181]     
                        mem_is_word,     //[180:180]
                        ID_Store_op,     //[179:179]
                        inst_ertn,       //[178:178]
                        csr_wmask_en,    //[177:177]
                        csr_we,          //[176:176]
                        csr_num,         //[175:162]
                        res_from_csr,    //[161:161]
                        mem_is_byte,     //[160:160]
                        mem_is_half,     //[159:159]
                        src_is_signed,   //[158:158]
                        ID_Load_op,      //[157:157]
                        alu_op,          //[156:141]
                        pc,              //[140:109]
                        imm,             //[108:77]
                        rj_value,        //[76:45]
                        rkd_value,       //[44:13]
                        src1_is_pc,      //[12:12]
                        src2_is_imm,     //[11:11]
                        res_from_mem,    //[10:10]
                        gr_we,           //[9:9]
                        mem_we,          //[8:5]
                        dest             //[4:0]
                       };



endmodule 