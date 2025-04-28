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

reg flush_pending;

wire excp_detect = IF_excp | ID_excp | EX_excp | ME_excp;

always @(posedge clk) begin
    if(reset)begin
        flush_pending <= 1'b0;
    end else if(excp_commit) begin
        flush_pending <= 1'b0;
    end else if(excp_detect) begin
        flush_pending <= 1'b1;
    end
    
end

assign global_flush_flag = flush_pending;

endmodule