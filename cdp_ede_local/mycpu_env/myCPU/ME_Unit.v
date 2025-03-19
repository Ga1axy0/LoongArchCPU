module ME_Unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        EX_Valid,
    output wire        ME_Unit_Ready,
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    input  wire [72:0] EX_to_ME_Bus,
    output wire        ME_Valid,
    output wire [68:0] ME_to_WB_Bus
);

assign ME_Unit_Ready = 1'b1;

always @(posedge clk) begin
    if(ME_Unit_Ready && EX_Valid && ~reset)begin
        {
            mem_we,         //[72:72]
            valid,          //[71:71]
            alu_result,     //[70:39]    
            rkd_value,      //[38:7]
            res_from_mem    //[6:6]
            gr_we,          //[5:5]
            dest,           //[4:0]
        } <= EX_to_ME_Bus;
    end
end


wire [31:0] mem_result;
wire [31:0] final_result;

assign data_sram_we    = mem_we && valid ? 4'b1111 : 4'b0000;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = rkd_value;

assign mem_result   = data_sram_rdata;
assign final_result = res_from_mem ? mem_result : alu_result;

assign rf_we    = gr_we && valid;
assign rf_waddr = dest;
assign rf_wdata = final_result;

assign ME_to_WB_Bus = {
            pc,          //[68:37]   
            rf_we,       //[37:37]
            dest,        //[36:32]
            final_result //[31:0]
        };


endmodule