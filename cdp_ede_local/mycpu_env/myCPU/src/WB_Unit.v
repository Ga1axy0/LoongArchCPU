`include "my_cpu.vh"
module WB_Unit (
    input  wire                         clk,
    input  wire                         reset,
    output wire                         WB_Allow_in,
    input  wire                         ME_to_WB_Valid,
    input  wire [`ME_to_WB_Bus_Size-1:0] ME_to_WB_Bus,

    output wire [31:0]                  debug_wb_pc,
    output wire [ 3:0]                  debug_wb_rf_we,
    output wire [ 4:0]                  debug_wb_rf_wnum,
    output wire [31:0]                  debug_wb_rf_wdata,

    output wire [`WB_to_RF_Bus_Size-1:0] WB_to_RF_Bus,
    output wire [`default_Dest_Size-1:0] WB_dest,
    output wire [`default_Data_Size-1:0] WB_Forward_Res
    );

reg [31:0]  pc;
reg         gr_we;
reg [4:0]   dest;
reg [31:0]  final_result;

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
            pc,          //[69:38]   
            gr_we,       //[37:37]
            dest,        //[36:32]
            final_result //[31:0]
        } <= ME_to_WB_Bus;
    end
end

assign rf_we    = gr_we && WB_Valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

assign WB_dest = dest & {5{rf_we}};

assign WB_to_RF_Bus = {
                        rf_we,         //[37:37]
                        rf_waddr,      //[36:32]
                        rf_wdata       //[31:0]
                    };

assign WB_Forward_Res = final_result;

endmodule