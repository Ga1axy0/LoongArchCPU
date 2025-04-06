module ME_Unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         EX_to_ME_Valid,
    input  wire         WB_Allow_in,
    output wire         ME_Allow_in,
    input  wire [31:0]  data_sram_rdata,
    input  wire [75:0]  EX_to_ME_Bus,
    output wire         ME_to_WB_Valid,
    output wire [69:0]  ME_to_WB_Bus,
    output wire [4:0]   ME_dest,
    output wire [31:0]  ME_Forward_Res
);

wire       ME_ReadyGO;
reg        ME_Valid;

assign ME_ReadyGO = 1'b1;
assign ME_Allow_in = !ME_Valid || ME_ReadyGO && WB_Allow_in;
assign ME_to_WB_Valid = ME_Valid && ME_ReadyGO;

assign ME_dest = dest & {5{ME_Valid}};

reg [31:0] pc;
reg        mem_we;
reg [31:0] alu_result;
reg [31:0] rkd_value;
reg        res_from_mem;
reg        gr_we;
reg [4:0]  dest;
reg [4:0]  dest_flag;

always @(posedge clk) begin

    if(reset)begin
        ME_Valid <= 1'b0;
    end else if (ME_Allow_in) begin
        ME_Valid <= EX_to_ME_Valid;
    end

    if(EX_to_ME_Valid && ME_Allow_in)begin
        {
            dest_flag,
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

/* 
    read byte:
    x1000 => [7:0]
    x1001 => [15:8]
    x1010 => [23:16]
    x1011 => [31:24]
    read half
    x0100 => [15:0]
    x0110 => [31:16]
    read full
    00000 => [31:0]
*/

assign mem_result   = (dest_flag == 5'b11000) ? {{24{datadata_sram_rdata[7]}},data_sram_rdata[7:0]}:
                      (dest_flag == 5'b01000) ? {24'b0,data_sram_rdata[7:0]}:

                      (dest_flag == 5'b11001) ? {{24{datadata_sram_rdata[15]}},data_sram_rdata[15:8]}:
                      (dest_flag == 5'b01001) ? {24'b0,data_sram_rdata[15:8]}:

                      (dest_flag == 5'b11010) ? {{24{datadata_sram_rdata[23]}},data_sram_rdata[23:16]}:
                      (dest_flag == 5'b01010) ? {24'b0,data_sram_rdata[23:16]}:

                      (dest_flag == 5'b11011) ? {{24{datadata_sram_rdata[31]}},data_sram_rdata[31:24]}:
                      (dest_flag == 5'b01011) ? {24'b0,data_sram_rdata[31:24]}:
                      
                      (dest_flag == 5'b10100) ? {{16{datadata_sram_rdata[15]}},data_sram_rdata[15:0]}:
                      (dest_flag == 5'b00100) ? {16'b0,data_sram_rdata[15:0]}:

                      (dest_flag == 5'b10110) ? {{16{datadata_sram_rdata[31]}},data_sram_rdata[31:16]}:
                      (dest_flag == 5'b00110) ? {16'b0,data_sram_rdata[31:16]}:

                      (dest_flag == 5'b00000) ? data_sram_rdata;

assign final_result = res_from_mem ? mem_result : alu_result;



assign ME_to_WB_Bus = {
            pc,          //[69:38]   
            gr_we,       //[37:37]
            dest,        //[36:32]
            final_result //[31:0]
        };
assign ME_Forward_Res = final_result;
endmodule