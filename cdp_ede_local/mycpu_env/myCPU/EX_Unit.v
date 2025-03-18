module EX_Unit (
    input  wire         clk,
    input  wire         reset,
    input  wire         ID_Valid,
    input  wire [141:0] ID_to_EX_Bus;
    output wire [31:0]  alu_result,
    output wire         EX_Unit_Ready,
    output wire         EX_Valid,
    input  wire         ME_Unit_Ready
    output wire [72:0]  EX_to_ME_Bus;
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

always @(posedge clk) begin
    if(EXE_Unit_Ready && ID_Valid && ~reset)begin
        {
            alu_op,          //[150:138]
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


assign alu_src1 = src1_is_pc  ? pc[31:0] : rj_value;
assign alu_src2 = src2_is_imm ? imm : rkd_value;

alu u_alu(
    .alu_op     (alu_op    ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)
    );

assign EX_to_ME_Bus = {
            mem_we,         //[72:72]
            valid,          //[71:71]
            alu_result,     //[70:39]    
            rkd_value,      //[38:7]
            res_from_mem    //[6:6]
            gr_we,          //[5:5]
            dest,           //[4:0]
        }

endmodule