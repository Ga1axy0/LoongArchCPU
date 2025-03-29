module IF_Unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        ID_Allow_in,
    input  wire [33:0] br_bus,

    output wire        inst_sram_en,
    output wire [3:0]  inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    output wire [63:0] IF_to_ID_Bus,
    output wire        IF_to_ID_Valid
);

wire        br_taken;
wire        br_stall;
wire [31:0] br_target;
wire [31:0] seq_pc;
wire [31:0] nextpc;
wire [31:0] inst;
reg  [31:0] pc;

reg         IF_Valid;
wire        IF_Allow_in;
wire        IF_ReadyGO;
wire        to_IF_Valid;

assign IF_ReadyGO = ~br_taken;
assign IF_Allow_in = !IF_Valid || IF_ReadyGO && ID_Allow_in;
assign IF_to_ID_Valid = IF_Valid && IF_ReadyGO;

assign to_IF_Valid = ~reset;
assign seq_pc                 = pc + 3'h4;
assign nextpc                 = br_taken ? br_target : seq_pc;

assign {br_taken , br_target , br_stall} = br_bus;


always @(posedge clk) begin
    if (reset) begin
        pc <= 32'h1bfffffc;
    end
    else if ((br_taken || ID_Allow_in )&& to_IF_Valid) begin
        pc <= nextpc;
    end
end

always @(posedge clk) begin
    if(reset)begin
        IF_Valid <= 1'b0;
    end else if(IF_Allow_in)begin
        IF_Valid <= to_IF_Valid;
    end
end

assign inst_sram_en    = (br_taken || IF_Allow_in) && to_IF_Valid;
assign inst_sram_we    = 4'b0;
assign inst_sram_addr  = nextpc;
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata;
assign IF_to_ID_Bus    = {pc, inst};

endmodule