module ME_Unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         EX_to_ME_Valid,
    input  wire         WB_Allow_in,
    output wire         ME_Allow_in,
    input  wire [31:0]  data_sram_rdata,
    input  wire [70:0]  EX_to_ME_Bus,
    output wire         ME_to_WB_Valid,
    output wire [69:0]  ME_to_WB_Bus,
    output wire [4:0]   ME_dest
);

wire       ME_ReadyGO;

assign ME_ReadyGO = 1'b1;
assign ME_Allow_in = !ME_Valid || ME_ReadyGO && WB_Allow_in;
assign ME_to_WB_Valid = ME_Valid && ME_ReadyGO;

reg        ME_Valid;
reg [31:0] pc;
reg        mem_we;
reg [31:0] alu_result;
reg [31:0] rkd_value;
reg        res_from_mem;
reg        gr_we;
reg [4:0]  dest;


always @(posedge clk) begin

    if(reset)begin
        ME_Valid <= 1'b0;
    end else if (ME_Allow_in) begin
        ME_Valid <= EX_to_ME_Valid;
    end

    if(ME_Unit_Ready && EX_Valid)begin
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