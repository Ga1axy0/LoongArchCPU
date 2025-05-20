module sram_axi_brige (
    //inst_sram from IF
    input  wire         inst_sram_req,
    input  wire         inst_sram_wr,
    input  wire [ 1:0]  inst_sram_size,
    input  wire [31:0]  inst_sram_addr,
    input  wire [ 3:0]  inst_sram_wstrb,
    input  wire [31:0]  inst_sram_wdata,
    output wire         inst_sram_addr_ok,
    output wire         inst_sram_data_ok,
    output wire [31:0]  inst_sram_rdata,
    
    //data_sram from EX and MEM
    input  wire         data_sram_req,
    input  wire         data_sram_wr,
    input  wire [ 1:0]  data_sram_size,
    input  wire [31:0]  data_sram_addr,
    input  wire [ 3:0]  data_sram_wstrb,
    input  wire [31:0]  data_sram_wdata,
    output wire         data_sram_addr_ok,
    output wire         data_sram_data_ok,
    output wire [31:0]  data_sram_rdata,

    //axi_interface
    //axi read address channel
    input  wire         aclk,
    input  wire         aresetn,
    output wire         arid,
    output wire [31:0]  araddr,
    output wire [ 7:0]  arlen,
    output wire [ 2:0]  arsize,
    output wire [ 1:0]  arburst,
    output wire [ 1:0]  arlock,
    output wire [ 3:0]  arcache,
    output wire [ 2:0]  arprot,
    output wire         arvalid,
    input  wire         arready,
    //axi read data channel
    input  wire [ 3:0]  rid,
    input  wire [31:0]  rdata,
    input  wire [ 1:0]  rresp,
    input  wire         rlast,
    input  wire         rvalid,
    output wire         rready,
    //axi write address channel
    output wire [ 3:0]  awid,
    output wire [31:0]  awaddr,
    output wire [ 7:0]  awlen,
    output wire [ 2:0]  awsize,
    output wire [ 1:0]  awburst,
    output wire [ 1:0]  awlock,
    output wire [ 3:0]  awcache,
    output wire [ 2:0]  awprot,
    output wire         awvalid,
    input  wire         awready,
    //axi write data channel
    output wire [ 3:0]  wid,
    output wire [31:0]  wdata,
    output wire [ 3:0]  wstrb,
    output wire         wlast,
    output wire         wvalid,
    input  wire         wready,
    //axi write response channel
    input  wire [ 3:0]  bid,
    input  wire [ 1:0]  bresp,
    input  wire         bvalid,
    output wire         bready
);

//----------------- type defination ------------------//

//Burst type
localparam FIXED = 2'b00;
localparam INCR  = 2'b01;
localparam WRAP  = 2'b10;

//Burst size
localparam byte_1   = 3'b000;
localparam byte_2   = 3'b001;
localparam byte_4   = 3'b010;
localparam byte_8   = 3'b011;
localparam byte_16  = 3'b100;
localparam byte_32  = 3'b101;
localparam byte_64  = 3'b110;
localparam byte_128 = 3'b111;

//Atomic access
localparam Normal_access    = 2'b00;
localparam Exclusive_access = 2'b01;
localparam Locked_access    = 2'b10;

//Cache support
//TODO: The bridge will support cache in future
localparam cache_unsupported = 4'b0000; //Noncacheable and nonbufferable

//Protection unit support
localparam Protection_unsupported = 3'b000;

//Response signaling
localparam OKAY   = 2'b00;
localparam EXOKAY = 2'b01;
localparam SLVERR = 2'b10;
localparam DECERR = 2'b11;

//---------------------------------------------------//



//------------- axi read address chanel -------------//
//Localparam defination
wire ar_cur;

//Interface definaton
reg r_arvalid;

//Interface connection
assign arvalid = r_arvalid;

//State machine
always @(posedge aclk) begin
    if(~aresetn)begin
        r_arvalid <= 1'b0;
    end
end

endmodule