//CRMD
`define PLV  1:0
`define IE   2
`define DA   3
`define PG   4
`define DATF 6:5
`define DATM 8:7

//PRMD
`define PPLV 1:0
`define PIE  2

//EUEN
`define FPE  0

//ECFG
`define LIE 12:0

//ESTAT
`define IS       12:0
`define IS_1_0   1:0
`define IS_9_2   9:2
`define IS_11    11
`define IS_12    12
`define Ecode    21:16
`define EsubCode 30:22

//EENTRY
`define VA 31:6

//TID
`define TID 31:0

//TCFG
`define En          0
`define Periodic    1
`define InitVal     31:2

//TVAL
`define TimeVal     29:0

//TICLR
`define CLR         31:0

//BADV
`define VAddr       31:0


//Ecode
`define ECODE_INT 6'h00         //中断
`define ECODE_PIL 6'h01         //load操作页无效例外
`define ECODE_PIS 6'h02         //store操作页无效例外
`define ECODE_PIF 6'h03         //取值操作页无效例外
`define ECODE_PME 6'h04         //页修改例外
`define ECODE_PPI 6'h07         //页特权登记不合规例外
`define ECODE_ADEF_ADEM 6'h08   //取指地址错例外 & 访存指令地址错例外
`define ECODE_ALE 6'h09         //地址非对齐例外 
`define ECODE_SYS 6'h0b         //系统调用例外 
`define ECODE_BRK 6'h0c         //断点例外
`define ECODE_INE 6'h0d         //指令不存在例外
`define ECODE_IPE 6'h0e         //指令特权登记错例外
`define ECODE_FPD 6'h0f         //浮点指令未使能例外
`define ECODE_FPE 6'h12         //基础浮点指令例外
`define ECODE_TLBR 6'h3f        //TLB重填例外

//EsubCode
`define EsubCode_ADEF 9'h000    //取指地址错例外 
`define EsubCode_ADEM 9'h001    //访存指令地址错例外
