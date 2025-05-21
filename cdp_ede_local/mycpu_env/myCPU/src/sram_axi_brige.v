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
    output wire [ 3:0]  arid,
    output wire [31:0]  araddr,
    output wire [ 7:0]  arlen,
    output wire [ 2:0]  arsize,
    output wire [ 1:0]  arburst,
    output wire [ 1:0]  arlock,
    output wire [ 3:0]  arcache,
    output wire [ 2:0]  arprot,
    output wire         arvalid,
    input  wire         arready,
    //axi read response channel
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

//--------------- constant assignment ---------------//

//axi read address channel
assign arlen    = 8'b0;
assign arburst  = INCR;
assign arlock   = Normal_access;
assign arcache  = cache_unsupported;
assign arprot   = Protection_unsupported;

//axi write address channel
assign awid     = 4'b1;
assign awlen    = 8'b0;
assign awburst  = INCR;
assign awlock   = Normal_access;
assign awcache  = cache_unsupported;
assign awprot   = Protection_unsupported;

//axi write data channel
assign wid      = 4'b1;
assign wlast    = 1'b1;

//---------------------- Global -----------------------//

//Size transitioner
//only suppor max to 4 byte, because of 32b CPU 
wire [2:0] inst_size;
wire [2:0] data_size;
assign inst_size = {1'b0,inst_sram_size};
assign data_size = {1'b0,data_sram_size};

//interface connection
assign inst_sram_addr_ok = r_rinst_sram_addr_ok;
assign inst_sram_data_ok = r_rinst_sram_data_ok;
assign data_sram_addr_ok = r_rdata_sram_addr_ok | r_wdata_sram_addr_ok;
assign data_sram_data_ok = r_rdata_sram_data_ok  | r_wdata_sram_data_ok;


//variable defination
wire inst_read_req;
wire data_read_req;
wire data_write_req;
assign inst_read_req = inst_sram_req & ~inst_sram_wr;
assign data_read_req = data_sram_req & ~data_sram_wr;
assign data_write_req = data_sram_req & data_sram_wr;

//------------- axi read address channel -------------//
//Localparam defination
reg [2:0]  ar_cur;
wire       ar_stall;

assign     ar_stall = (w_cur != w_IDLE) | (b_cur != b_IDLE); //Stall read req while writing process undone

localparam ar_IDLE = 3'b000;
localparam ar_REQD = 3'b001;
localparam ar_REQI = 3'b010;
localparam ar_AUTI = 3'b011;
localparam ar_AUTD = 3'b100;

//Interface definaton
reg        r_arvalid;
reg [ 3:0] r_arid;
reg [31:0] r_araddr;
reg [2:0]  r_arsize;
reg        r_rdata_sram_addr_ok;
reg        r_rinst_sram_addr_ok;


//Interface connection
assign arvalid              = r_arvalid;
assign araddr               = r_araddr;
assign arsize               = r_arsize;
assign arid                 = r_arid;

//State machine
always @(posedge aclk) begin
    if(~aresetn)begin
        r_arvalid <= 1'b0;
        ar_cur    <= ar_IDLE;
    end else begin
        case (ar_cur)
            ar_IDLE:begin
                if(data_read_req & ~ar_stall)
                    ar_cur <= ar_REQD;
                else if (inst_read_req & ~ar_stall)
                    ar_cur <= ar_REQI;
            end
            ar_REQD:begin
                r_arid      <= 4'b0001;
                r_araddr    <= data_sram_addr;
                r_arsize    <= data_size;
                r_arvalid   <= 1'b1;
                ar_cur      <= ar_AUTD;
            end
            ar_REQI:begin
                r_arid      <= 4'b0000;
                r_araddr    <= inst_sram_addr;
                r_arsize    <= inst_size;
                r_arvalid   <= 1'b1;
                ar_cur      <= ar_AUTI;
            end
            ar_AUTD:begin
                if(arready & arvalid)begin
                    r_rdata_sram_addr_ok <= 1'b1;
                    ar_cur               <= ar_IDLE;
                    r_arvalid            <= 1'b0;
                end
            end
            ar_AUTI:begin
                if(arready & arvalid)begin
                    r_rinst_sram_addr_ok <= 1'b1;
                    ar_cur               <= ar_IDLE;
                    r_arvalid            <= 1'b0;
                end
            end

        endcase
    end
end

//---------- axi write address & data channel ----------//
//Localparam defination
reg [1:0] w_cur;

localparam w_IDLE = 2'b00;
localparam w_REQ  = 2'b01;
localparam w_AAUT = 2'b10;
localparam w_DAUT = 2'b11;

//Interface definaton
reg        r_awvalid;
reg        r_wvalid;
reg [31:0] r_awaddr;
reg [31:0] r_wdata;
reg [ 3:0] r_wstrb;
reg [ 2:0] r_awsize;
reg        r_wdata_sram_addr_ok;


//Interface connection
assign awvalid              = r_awvalid;
assign awaddr               = r_awaddr;
assign awsize               = r_awsize;

assign wvalid               = r_wvalid;
assign wstrb                = r_wstrb;
assign wdata                = r_wdata;

//State machine
always @(posedge aclk) begin
    if(~aresetn)begin
        r_awvalid <= 1'b0;
        w_cur    <= w_IDLE;
    end else begin
        case (w_cur)
            w_IDLE:begin
                if(data_write_req)begin
                    w_cur <= w_REQ;
                end
            end
            w_REQ:begin
                r_awaddr    <= data_sram_addr;
                r_awsize    <= data_size;
                r_awvalid   <= 1'b1;
                w_cur       <= w_AAUT;
            end
            w_AAUT:begin
                if(awready & awvalid)begin
                    r_wdata_sram_addr_ok <= 1'b1;
                    r_wvalid             <= 1'b1;
                    w_cur                <= w_DAUT;
                    r_awvalid            <= 1'b0;
                end
            end
            w_DAUT:begin
                if(wvalid & wready)begin
                    r_wdata     <= data_sram_wdata;
                    r_wstrb     <= data_sram_wstrb;
                    w_cur       <= w_IDLE;
                    r_wvalid    <= 1'b0;
                end
            end
        endcase
    end
end

//----------- axi read response channel -----------//
//Localparam defination
reg [2:0] r_cur;

localparam r_IDLE = 3'b000;
localparam r_PEDI = 3'b001;
localparam r_PEDD = 3'b010;
localparam r_AUTD = 3'b011;
localparam r_AUTI = 3'b100;


//Interface definaton
reg         r_rready;
reg [31:0]  r_data_sram_rdata;
reg [31:0]  r_inst_sram_rdata;
reg         r_rdata_sram_data_ok;
reg         r_rinst_sram_data_ok;

//Interface connection
assign rready               = r_rready;
assign inst_sram_rdata      = r_inst_sram_rdata;
assign data_sram_rdata      = r_data_sram_rdata;


//State machine
always @(posedge aclk) begin
    if(~aresetn)begin
        r_rready <= 1'b0;
        r_cur    <= r_IDLE;
    end else begin
        case (r_cur)
            r_IDLE:begin
                if(ar_cur == ar_AUTD)
                    r_cur <= r_PEDD;
                else if(ar_cur == ar_AUTI)
                    r_cur <= r_PEDI;
            end
            r_PEDD:begin
                r_rready <= 1'b1;
                r_cur    <= r_AUTD;
            end
            r_PEDI:begin
                r_rready <= 1'b1;
                r_cur    <= r_AUTI;
            end
            r_AUTD:begin
                if(rready & rvalid & rid == 4'b0001)begin
                    r_data_sram_rdata       <= rdata;
                    r_cur                   <= r_IDLE;
                    r_rdata_sram_data_ok    <= 1'b1;
                    r_rready                <= 1'b0;
                end
            end
            r_AUTI:begin
                if(rready & rvalid & rid == 4'b0000)begin
                    r_inst_sram_rdata       <= rdata;
                    r_cur                   <= r_IDLE;
                    r_rinst_sram_data_ok    <= 1'b1;
                    r_rready                <= 1'b0;
                end
            end
        endcase
    end
end

//----------- axi write response channel -----------//
//Localparam defination
reg [1:0] b_cur;

localparam b_IDLE = 2'b00;
localparam b_PED  = 2'b01;
localparam b_AUTH = 2'b10;



//Interface definaton
reg         r_bready;
reg         r_wdata_sram_data_ok;


//Interface connection
assign bready = r_bready;

//State machine
always @(posedge aclk) begin
    if(~aresetn)begin
        r_bready <= 1'b0;
        b_cur    <= b_IDLE;
    end else begin
        case (b_cur)
            b_IDLE:begin
                if(w_cur == w_DAUT)
                    b_cur <= b_PED;
            end
            b_PED:begin
                r_bready <= 1'b1;
                b_cur    <= b_AUTH;
            end 
            b_AUTH:begin
                if(bvalid & bready)begin
                    r_wdata_sram_data_ok <= 1'b1;
                    b_cur                <= b_IDLE;
                    r_bready             <= 1'b0;
                end

            end
        endcase
    end
end

endmodule