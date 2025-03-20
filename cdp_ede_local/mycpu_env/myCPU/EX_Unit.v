module EX_Unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         ID_Valid,
    input  wire [149:0] ID_to_EX_Bus,
    output wire [31:0]  alu_result,
    output wire         EX_Unit_Ready,
    output wire         EX_Valid,
    input  wire         ME_Unit_Ready,
    output wire [70:0] EX_to_ME_Bus,
    output wire        data_sram_en,
    output wire [3:0]  data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata
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

assign EX_Unit_Ready = 1'b1;
assign EX_Valid = ID_Valid && EX_Unit_Ready;

always @(posedge clk) begin
    if(EX_Unit_Ready && ID_Valid && ~reset)begin
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

assign EX_to_ME_Bus = {
            pc,             //[70:39]
            alu_result,     //[38:7]    
            res_from_mem,   //[6:6]
            gr_we,          //[5:5]
            dest            //[4:0]
        };

endmodule