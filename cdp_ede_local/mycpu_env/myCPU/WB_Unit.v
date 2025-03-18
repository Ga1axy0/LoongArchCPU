module WB_Unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        ME_Valid,
    output wire        WB_Unit_Ready,
    input  wire        ME_to_WB_Bus,

    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

always @(posedge clk) begin
    if (~reset && ME_Valid && WB_Unit_Ready) begin
        {
            pc,          //[68:37]   
            rf_we,       //[37:37]
            dest,        //[36:32]
            final_result //[31:0]
        } <= ME_to_WB_Bus;
    end
end

assign debug_wb_pc       = pc;
assign debug_wb_rf_we    = {4{rf_we}};
assign debug_wb_rf_wnum  = dest;
assign debug_wb_rf_wdata = final_result;

endmodule