module IF_Unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        ID_Unit_Ready,
    input  wire [32:0] br_bus,

    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    output wire [63:0] IF_to_ID_Bus,
    output wire        IF_Valid
);

wire        br_taken;
wire [31:0] br_target;
wire [31:0] seq_pc;
wire [31:0] nextpc;
wire [31:0] inst;
reg  [31:0] pc;


assign {br_taken , br_target} = br_bus;
assign seq_pc                 = pc + 3'h4;
assign nextpc                 = br_taken ? br_target : seq_pc;
assign IF_Valid               = ~reset;

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;
    end
    else if (ID_Unit_Ready) begin
        pc <= nextpc;
    end
end

assign inst_sram_en    = ID_Unit_Ready && IF_Valid;
assign inst_sram_we    = 4'b0;
assign inst_sram_addr  = pc;
assign inst_sram_wdata = 32'b0;
assign IF_to_ID_Bus    = {pc, inst};

endmodule