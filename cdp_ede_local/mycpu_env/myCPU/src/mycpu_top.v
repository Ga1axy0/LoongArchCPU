`include "my_cpu.vh"
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

wire         ID_Allow_in;
wire         IF_Allow_in;
wire         EX_Allow_in;
wire         ME_Allow_in;
wire         WB_Allow_in;

wire         IF_to_ID_Valid;
wire         ID_to_EX_Valid;
wire         EX_to_ME_Valid;
wire         ME_to_WB_Valid;

wire         EX_to_ID_Ld_op; 
  

wire [`default_Dest_Size-1:0]   EX_dest;
wire [`default_Dest_Size-1:0]   ME_dest;
wire [`default_Dest_Size-1:0]   WB_dest;

wire [`br_bus_Size-1      :0]  br_bus;
wire [`IF_to_ID_Bus_Size-1:0]  IF_to_ID_Bus;
wire [`ID_to_EX_Bus_Size-1:0]  ID_to_EX_Bus;
wire [`EX_to_ME_Bus_Size-1:0]  EX_to_ME_Bus;
wire [`ME_to_WB_Bus_Size-1:0]  ME_to_WB_Bus;
wire [`WB_to_RF_Bus_Size-1:0]  WB_to_RF_Bus;
wire [`WB_to_EX_Bus_Size-1:0]  WB_to_EX_Bus;
wire [`ME_to_EX_Bus_Size-1:0]  ME_to_EX_Bus;


wire [`default_Data_Size-1:0]  EX_Forward_Res;
wire [`default_Data_Size-1:0]  ME_Forward_Res;
wire [`default_Data_Size-1:0]  WB_Forward_Res;

wire [31:0] core_id_in;

assign core_id_in = 32'd0;

wire [ 7:0] hw_int_in;
wire        ipi_int_in;
wire [13:0] EX_csr_num;
wire [13:0] WB_csr_num;
wire        csr_re;
wire [31:0] csr_rdata;
wire        csr_we;
wire [31:0] csr_wdata;
wire [31:0] ex_entry;
wire [31:0] er_entry;
wire        has_int;
wire        ertn_flush;
wire        excp_flush;
wire [ 5:0] wb_ecode;
wire [ 8:0] wb_esubcode;

wire [ 1:0] timer_re;
wire [31:0] timer_rdata;

wire        IF_excp;
wire        ID_excp;
wire        EX_excp;
wire        ME_excp;
wire        excp_commit;
wire        global_flush_flag;

assign hw_int_in  = 8'd0;
assign ipi_int_in = 1'd0;

IF_Unit IF(
    .clk(clk),
    .reset(reset),
    .br_bus(br_bus),
    .inst_sram_en(inst_sram_en),
    .inst_sram_we(inst_sram_we),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata),
    .IF_to_ID_Bus(IF_to_ID_Bus),
    .IF_to_ID_Valid(IF_to_ID_Valid),
    .ID_Allow_in(ID_Allow_in),
    .ex_entry(ex_entry),
    .excp_flush(excp_flush),
    .ertn_flush(ertn_flush),
    .er_entry(er_entry),
    .IF_excp(IF_excp)
);

ID_Unit ID(
    .clk(clk),
    .reset(reset),
    .ID_to_EX_Bus(ID_to_EX_Bus),
    .IF_to_ID_Bus(IF_to_ID_Bus),
    .WB_to_RF_Bus(WB_to_RF_Bus),
    .br_bus(br_bus),
    .EX_dest(EX_dest),
    .ME_dest(ME_dest),
    .WB_dest(WB_dest),
    .IF_to_ID_Valid(IF_to_ID_Valid),
    .ID_Allow_in(ID_Allow_in),
    .ID_to_EX_Valid(ID_to_EX_Valid),
    .EX_Allow_in(EX_Allow_in),
    .EX_Forward_Res(EX_Forward_Res),
    .ME_Forward_Res(ME_Forward_Res),
    .WB_Forward_Res(WB_Forward_Res),
    .EX_to_ID_Ld_op(EX_to_ID_Ld_op),
    .excp_flush(excp_flush),
    .ertn_flush(ertn_flush),
    .has_int(has_int),
    .ID_excp(ID_excp),
    .global_flush_flag(global_flush_flag)
);

EX_Unit EX(
    .clk(clk),
    .reset(reset),
    .ID_to_EX_Bus(ID_to_EX_Bus),
    .data_sram_en(data_sram_en),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_we(data_sram_we),
    .EX_to_ME_Bus(EX_to_ME_Bus),
    .EX_dest(EX_dest),
    .ID_to_EX_Valid(ID_to_EX_Valid),
    .EX_to_ME_Valid(EX_to_ME_Valid),
    .EX_Allow_in(EX_Allow_in),
    .ME_Allow_in(ME_Allow_in),
    .EX_Forward_Res(EX_Forward_Res),
    .EX_to_ID_Ld_op(EX_to_ID_Ld_op),
    .excp_flush(excp_flush),
    .ertn_flush(ertn_flush),
    .csr_re(csr_re),
    .csr_rvalue(csr_rdata),
    .csr_num(EX_csr_num),
    .ME_to_EX_Bus(ME_to_EX_Bus),
    .WB_to_EX_Bus(WB_to_EX_Bus),
    .timer_rdata (timer_rdata ),
    .timer_re    (timer_re    ),
    .EX_excp(EX_excp)
);

ME_Unit ME(
    .clk(clk),
    .reset(reset),
    .data_sram_rdata(data_sram_rdata),
    .EX_to_ME_Bus(EX_to_ME_Bus),
    .ME_to_WB_Bus(ME_to_WB_Bus),
    .ME_dest(ME_dest),
    .EX_to_ME_Valid(EX_to_ME_Valid),
    .ME_to_WB_Valid(ME_to_WB_Valid),
    .ME_Allow_in(ME_Allow_in),
    .WB_Allow_in(WB_Allow_in),
    .ME_Forward_Res(ME_Forward_Res),
    .excp_flush(excp_flush),
    .ertn_flush(ertn_flush),
    .ME_to_EX_Bus(ME_to_EX_Bus),
    .ME_excp(ME_excp)
);

WB_Unit WB(
    .clk(clk),
    .reset(reset),
    .ME_to_WB_Bus(ME_to_WB_Bus),
    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_we(debug_wb_rf_we),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .WB_to_RF_Bus(WB_to_RF_Bus),
    .WB_dest(WB_dest),
    .ME_to_WB_Valid(ME_to_WB_Valid),
    .WB_Allow_in(WB_Allow_in),
    .WB_Forward_Res(WB_Forward_Res),
    .excp_flush(excp_flush),
    .ertn_flush(ertn_flush),
    .wb_ecode(wb_ecode),
    .wb_esubcode(wb_esubcode),
    .csr_we(csr_we),
    .csr_wvalue(csr_wdata),
    .csr_num(WB_csr_num),
    .WB_to_EX_Bus(WB_to_EX_Bus),
    .excp_commit(excp_commit)
);

CSR_Unit CSR(
    .clk         (clk         ),
    .reset       (reset       ),
    .core_id_in  (core_id_in  ),
    .hw_int_in   (hw_int_in   ),
    .ipi_int_in  (ipi_int_in  ),
    .csr_rnum    (EX_csr_num  ),
    .csr_re      (csr_re      ),
    .csr_rdata   (csr_rdata   ),
    .csr_we      (csr_we      ),
    .csr_wdata   (csr_wdata   ),
    .ex_entry    (ex_entry    ),
    .er_entry    (er_entry    ),
    .has_int     (has_int     ),
    .ertn_flush  (ertn_flush  ),
    .wb_ex       (excp_flush  ),
    .wb_ecode    (wb_ecode    ),
    .wb_esubcode (wb_esubcode ),
    .wb_pc       (debug_wb_pc ),
    .csr_wnum    (WB_csr_num  ),
    .timer_rdata (timer_rdata ),
    .timer_re    (timer_re    )
);

Flush_Unit u_Flush_Unit(
    .clk               (clk               ),
    .reset             (reset             ),
    .IF_excp           (IF_excp           ),
    .ID_excp           (ID_excp           ),
    .EX_excp           (EX_excp           ),
    .ME_excp           (ME_excp           ),
    .excp_commit       (excp_commit       ),
    .global_flush_flag (global_flush_flag )
);


endmodule
