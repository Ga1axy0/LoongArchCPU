module ME_Unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         EX_Valid,
    output wire         ME_Unit_Ready,
    input  wire [31:0]  data_sram_rdata,
    input  wire [70:0] EX_to_ME_Bus,
    output wire         ME_Valid,
    output wire [69:0]  ME_to_WB_Bus
);

assign ME_Unit_Ready = 1'b1;
assign ME_Valid = EX_Valid && ME_Unit_Ready;

reg [31:0] pc;
reg        mem_we;
reg [31:0] alu_result;
reg [31:0] rkd_value;
reg        res_from_mem;
reg        gr_we;
reg [4:0]  dest;


always @(posedge clk) begin
    if(ME_Unit_Ready && EX_Valid && ~reset)begin
        {
            pc,             //[70:39]
            alu_result,     //[38:7]    
            res_from_mem,   //[6:6]
            gr_we,          //[5:5]
            dest            //[4:0]
        } <= EX_to_ME_Bus;
    end
end


wire [31:0] mem_result;
wire [31:0] final_result;

assign mem_result   = data_sram_rdata;
assign final_result = res_from_mem ? mem_result : alu_result;



assign ME_to_WB_Bus = {
            pc,          //[69:38]   
            gr_we,       //[37:37]
            dest,        //[36:32]
            final_result //[31:0]
        };


endmodule