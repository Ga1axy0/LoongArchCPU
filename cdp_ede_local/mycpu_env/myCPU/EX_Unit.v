module EX_Unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         ID_to_EX_Valid,
    input  wire [149:0] ID_to_EX_Bus,
    output wire [31:0]  alu_result,
    output wire         EX_Allow_in,
    output wire         EX_to_ME_Valid,
    input  wire         ME_Allow_in,
    output wire [70:0]  EX_to_ME_Bus,
    output wire         data_sram_en,
    output wire [3:0]   data_sram_we,
    output wire [31:0]  data_sram_addr,
    output wire [31:0]  data_sram_wdata,
    output wire [4:0]   EX_dest,
    output wire [36:0]  EX_Forward
);

reg [11:0] alu_op;
reg [31:0] pc;
reg [31:0] imm;
reg [31:0] rj_value;
reg [31:0] rkd_value;
reg [4:0]  dest;
reg        src1_is_pc;
reg        src2_is_imm;
reg        res_from_mem;
reg        gr_we;
reg        mem_we;
reg        EX_Valid;

wire       EX_ReadGo;

assign EX_ReadyGo = 1'b1;
assign EX_Allow_in = !EX_Valid || EX_ReadyGo && ME_Allow_in;
assign EX_to_ME_Valid = EX_Valid && EX_ReadyGo;

always @(posedge clk) begin

    if(reset)begin
        EX_Valid <= 1'b0;
    end else if(EX_Allow_in) begin
        EX_Valid <= ID_to_EX_Valid;
    end

    if(EX_Allow_in && ID_to_EX_Valid)begin
        {
            alu_op,          //[149:138]
            pc,              //[137:106]
            imm,             //[105:74]
            rj_value,        //[73:42]
            rkd_value,       //[41:10]
            src1_is_pc,      //[9:9]
            src2_is_imm,     //[8:8]
            res_from_mem,    //[7:7]
            gr_we,           //[6:6]
            mem_we,          //[5:5]
            dest             //[4:0]
        } <= ID_to_EX_Bus;
    end
end


wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [31:0] alu_result;

assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

assign data_sram_en    = 1'b1;
assign data_sram_we    = mem_we && EX_Valid ? 4'b1111 : 4'b0000;
assign data_sram_addr  = alu_result;
assign data_sram_wdata = rkd_value;

assign EX_dest         = dest & {5{EX_Valid}};

assign EX_to_ME_Bus = {
            pc,             //[70:39]
            alu_result,     //[38:7]    
            res_from_mem,   //[6:6]
            gr_we,          //[5:5]
            dest            //[4:0]
        };
assign EX_Forward = {
            EX_dest,
            alu_result
        };

endmodule