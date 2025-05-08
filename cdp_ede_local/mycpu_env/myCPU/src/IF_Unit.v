`include "my_cpu.vh"
module IF_Unit (
    input  wire                          clk,
    input  wire                          reset,
    input  wire                          ID_Allow_in,
    input  wire [`br_bus_Size-1      :0] br_bus,

    
    output wire                          inst_sram_req,
    output wire                          inst_sram_wr,
    output wire [1:0]                    inst_sram_size,
    output wire [31:0]                   inst_sram_addr,
    output wire                          inst_sram_wstrb,
    output wire [31:0]                   inst_sram_wdata,
    output wire                          inst_sram_addr_ok,
    input  wire                          inst_sram_data_ok,
    input  wire [31:0]                   inst_sram_rdata,

    output wire [`IF_to_ID_Bus_Size-1:0] IF_to_ID_Bus,
    output wire                          IF_to_ID_Valid,

    input  wire                          excp_flush,
    input  wire                          ertn_flush,
    input  wire [31:0]                   ex_entry,
    input  wire [31:0]                   er_entry          
);


/* pre-IF stage */

wire excp_adef;
wire excp_en;
wire excp_num;

wire        br_taken;
wire        br_stall;
wire [31:0] br_target;
wire [31:0] seq_pc;
wire [31:0] nextpc;
reg  [31:0] pc;

wire        to_IF_Valid;
wire        pre_IF_ReadyGo;

assign pre_IF_ReadyGo = inst_sram_req & inst_sram_addr_ok; 
assign to_IF_Valid    = ~reset & pre_IF_ReadyGo;


assign seq_pc                 = pc + 3'h4;
assign nextpc                 = excp_flush ? ex_entry  :
                                ertn_flush ? er_entry  :
                                br_taken   ? br_target : seq_pc;

assign excp_adef = |nextpc[1:0];
assign excp_en   = excp_adef;
assign excp_num  = excp_adef;

assign {br_taken , br_target , br_stall} = br_bus;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;
    end
    else if (IF_Allow_in & to_IF_Valid) begin
        pc <= nextpc;
    end
end 

assign inst_sram_req   = ~reset & ~br_stall & IF_Allow_in;
assign inst_sram_wr    = |inst_sram_wstrb;
assign inst_sram_size  = 2'b10;
assign inst_sram_addr  = nextpc;
assign inst_sram_wstrb = 4'b0;
assign inst_sram_wdata = 32'b0;

/* pre-IF excp cancel*/
reg IF_cancel;

always @(posedge clk) begin
    if(reset)begin
        IF_cancel <= 1'b0;
    end else if(flush_flag & (to_IF_Valid | (!IF_Allow_in & !IF_ReadyGO)))begin
        IF_cancel <= 1'b1;
    end else if(inst_sram_data_ok)begin
        IF_cancel <= 1'b0;
    end
end

/* IF stage */

wire flush_flag;
assign flush_flag = excp_flush | ertn_flush;

always @(posedge clk) begin
    if(reset)begin
        IF_Valid <= 1'b0;
    end else if(IF_Allow_in)begin
        IF_Valid <= to_IF_Valid;
    end
end

wire [31:0]                   inst;
reg                           IF_Valid;
wire                          IF_Allow_in;
wire                          IF_ReadyGO;
reg                           IF_buf_en;
reg  [`IF_to_ID_Bus_Size-1:0] IF_buf;
wire [`IF_to_ID_Bus_Size-1:0] to_ID_Bus;

assign IF_ReadyGO     = inst_sram_data_ok | IF_buf_en;
assign IF_Allow_in    = !IF_Valid || IF_ReadyGO && ID_Allow_in;
assign IF_to_ID_Valid = IF_Valid && IF_ReadyGO;

assign inst           = inst_sram_rdata;

assign to_ID_Bus      = IF_buf_en ? IF_buf : {
                                                excp_en,      //[65:65]
                                                excp_num,     //[64:64]
                                                pc,           //[63:0]  
                                                inst          //[31:0]
                                                };

always @(posedge clk) begin
    if(reset | flush_flag | IF_cancel)begin
        IF_buf_en <= 1'b0;
        IF_buf    <= 66'b0;
    end else if(IF_ReadyGO & !ID_Allow_in)begin
        IF_buf_en <= 1'b1;
        IF_buf    <= to_ID_Bus;
    end
end

assign IF_to_ID_Bus = to_ID_Bus;

endmodule