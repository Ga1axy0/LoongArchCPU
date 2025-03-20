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

wire         ID_Unit_Ready;
wire         EX_Unit_Ready;
wire         ME_Unit_Ready;
wire         WB_Unit_Ready;

wire         IF_Valid;
wire         ID_Valid;
wire         EX_Valid;
wire         ME_Valid;

wire [32:0]  br_bus;
wire [63:0]  IF_to_ID_Bus;
wire [149:0] ID_to_EX_Bus;
wire [70:0] EX_to_ME_Bus;
wire [69:0]  ME_to_WB_Bus;
wire [37:0]  WB_to_RF_Bus;

wire [31:0]  alu_result;


IF_Unit IF(
    .clk(clk),
    .reset(reset),
    .ID_Unit_Ready(ID_Unit_Ready),
    .br_bus(br_bus),
    .inst_sram_en(inst_sram_en),
    .inst_sram_we(inst_sram_we),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata),
    .IF_to_ID_Bus(IF_to_ID_Bus),
    .IF_Valid(IF_Valid)
);

ID_Unit ID(
    .clk(clk),
    .reset(reset),
    .IF_Valid(IF_Valid),
    .ID_Unit_Ready(ID_Unit_Ready),
    .ID_Valid(ID_Valid),
    .ID_to_EX_Bus(ID_to_EX_Bus),
    .IF_to_ID_Bus(IF_to_ID_Bus),
    .WB_to_RF_Bus(WB_to_RF_Bus),
    .br_bus(br_bus)
);

EX_Unit EX(
    .clk(clk),
    .reset(reset),
    .ID_Valid(ID_Valid),
    .ID_to_EX_Bus(ID_to_EX_Bus),
    .alu_result(alu_result),
    .EX_Unit_Ready(EX_Unit_Ready),
    .EX_Valid(EX_Valid),
    .ME_Unit_Ready(ME_Unit_Ready),
    .data_sram_en(data_sram_en),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_we(data_sram_we),
    .EX_to_ME_Bus(EX_to_ME_Bus)   
);

ME_Unit ME(
    .clk(clk),
    .reset(reset),
    .EX_Valid(EX_Valid),
    .ME_Unit_Ready(ME_Unit_Ready),
    .data_sram_rdata(data_sram_rdata),
    .EX_to_ME_Bus(EX_to_ME_Bus),
    .ME_to_WB_Bus(ME_to_WB_Bus),
    .ME_Valid(ME_Valid)
);

WB_Unit WB(
    .clk(clk),
    .reset(reset),
    .ME_Valid(ME_Valid),
    .WB_Unit_Ready(WB_Unit_Ready),
    .ME_to_WB_Bus(ME_to_WB_Bus),
    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_we(debug_wb_rf_we),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),
    .WB_to_RF_Bus(WB_to_RF_Bus)
);


endmodule
