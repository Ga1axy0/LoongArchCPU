module WB_Unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        ME_Valid,
    output wire        WB_Unit_Ready,
    input  wire [69:0] ME_to_WB_Bus,

    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata,

    output wire [37:0] WB_to_RF_Bus 
    );

reg [31:0]  pc;
reg         gr_we;
reg [4:0]   dest;
reg [31:0]  final_result;


wire         WB_Valid;
wire         rf_we;
wire [4:0]   rf_waddr;
wire [31:0]  rf_wdata;

assign WB_Unit_Ready = 1'b1;
assign WB_Valid      = ME_Valid && WB_Unit_Ready;

always @(posedge clk) begin
    if (~reset && ME_Valid && WB_Unit_Ready) begin
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



assign WB_to_RF_Bus = {
                        rf_we,         //[37:37]
                        rf_waddr,      //[36:32]
                        rf_wdata       //[31:0]
                    };

endmodule