`include "my_cpu.vh"
module alu(
  input  wire                         clk,
  input  wire                         reset,
  input  wire [alu_op_Size:0]         alu_op,
  input  wire [31:0]                  alu_src1,
  input  wire [31:0]                  alu_src2,
  input  wire                         src_is_signed,
  output wire [default_Data_Size-1:0] alu_result,
  output wire                         divres_valid
);

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate
wire op_mul;   //mul operation
wire op_mulh;  //mulh operation
wire op_div;   //div operation
wire op_mod;   //mod operation

// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];
assign op_mul  = alu_op[12];
assign op_mulh = alu_op[13];
assign op_div  = alu_op[14];
assign op_mod  = alu_op[15];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;
wire [65:0] mul66_result;
wire [31:0] mul_result;
wire [63:0] div_mod_result;
wire [63:0] u_div_mod_result;
wire [63:0] s_div_mod_result;
wire [31:0] div_result;
wire [31:0] mod_result;

wire        div_en;
wire        udiv_valid;
wire        div_valid;
assign      divres_valid = src_is_signed ? div_valid : udiv_valid;
assign      div_en = op_mod | op_div;

// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

wire [32:0] mul_src1;
wire [32:0] mul_src2;

assign mul_src1   = src_is_signed ? {alu_src1[31], alu_src1} : {1'b0, alu_src1};
assign mul_src2   = src_is_signed ? {alu_src2[31], alu_src2} : {1'b0, alu_src2};
assign mul66_result = $signed(mul_src1) * $signed(mul_src2);

div_signed div_signed(
  .clk(clk),
  .reset(reset),
  .src1(alu_src1),
  .src2(alu_src2),
  .src_is_signed(src_is_signed),
  .div_en(div_en),
  .div_result(s_div_mod_result),
  .divres_valid(div_valid)
);

div_unsigned div_unsigned(
  .clk(clk),
  .reset(reset),
  .src1(alu_src1),
  .src2(alu_src2),
  .src_is_signed(src_is_signed),
  .div_en(div_en),
  .div_result(u_div_mod_result),
  .divres_valid(udiv_valid)
);

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << i5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign sr_result   = sr64_result[31:0];

assign mul_result  = op_mul ? mul66_result[31:0] : mul66_result[63:32];

assign div_mod_result = src_is_signed ? s_div_mod_result : u_div_mod_result;

assign div_result  = div_mod_result[63:32];
assign mod_result  = div_mod_result[31:0];
// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mul|op_mulh}}& mul_result)
                  | ({32{op_div       }} & div_result)
                  | ({32{op_mod       }} & mod_result);

endmodule
