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
wire         WB_Allow_in;

wire         IF_to_ID_Valid;
wire         ID_to_EX_Valid;
wire         EX_to_ME_Valid;
wire         ME_to_WB_Valid;

wire         EX_to_ID_Ld_op;     

wire [default_Dest_Size-1:0]   EX_dest;
wire [default_Dest_Size-1:0]   ME_dest;
wire [default_Dest_Size-1:0]   WB_dest;

wire [br_bus_Size-1      :0]  br_bus;
wire [IF_to_ID_Bus_Size-1:0]  IF_to_ID_Bus;
wire [ID_to_EX_Bus_Size-1:0] ID_to_EX_Bus;
wire [EX_to_ME_Bus_Size-1:0]  EX_to_ME_Bus;
wire [ME_to_WB_Bus_Size-1:0]  ME_to_WB_Bus;
wire [WB_to_RF_Bus_Size-1:0]  WB_to_RF_Bus;

wire [default_Data_Size-1:0]  alu_result;

wire [default_Data_Size-1:0]  EX_Forward_Res;
wire [default_Data_Size-1:0]  ME_Forward_Res;
wire [default_Data_Size-1:0]  WB_Forward_Res;

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
    .ID_Allow_in(ID_Allow_in)
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
    .EX_to_ID_Ld_op(EX_to_ID_Ld_op)
);

EX_Unit EX(
    .clk(clk),
    .reset(reset),
    .ID_to_EX_Bus(ID_to_EX_Bus),
    .alu_result(alu_result),
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
    .EX_to_ID_Ld_op(EX_to_ID_Ld_op)
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
    .ME_Forward_Res(ME_Forward_Res)
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
    .WB_Forward_Res(WB_Forward_Res)
);


endmodule
