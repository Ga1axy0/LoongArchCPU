module Flush_Unit (
    input  wire clk,
    input  wire reset,
    
    input  wire IF_excp,
    input  wire ID_excp,
    input  wire EX_excp,
    input  wire ME_excp,
    input  wire excp_commit,

    output wire global_flush_flag
);

wire flush_pending;

wire excp_detect = IF_excp | ID_excp | EX_excp | ME_excp;

assign flush_pending = ~excp_commit & excp_detect;

assign global_flush_flag = flush_pending;

endmodule