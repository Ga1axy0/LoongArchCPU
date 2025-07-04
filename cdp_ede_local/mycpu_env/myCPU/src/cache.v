module cache (
    input  wire         clk,
    input  wire         reset,

    //cache-cpu interface
    input  wire         valid,
    input  wire         op,  // 1:write 0:read
    input  wire [7:0]   index,
    input  wire [19:0]  tag,
    input  wire [3:0]   offset,
    input  wire [3:0]   wstrb,
    input  wire [31:0]  wdata,
    output wire         addr_ok,
    output wire         data_ok,
    output wire [31:0]  rdata,

    //cache-axi interface
    output wire         rd_req,
    output wire [2:0]   rd_type,
    output wire [31:0]  rd_addr,
    input  wire         rd_rdy,
    input  wire         ret_valid,
    input  wire [2:0]   ret_last,
    input  wire [31:0]  ret_data,
    output wire         wr_req,
    output wire [2:0]   wr_type,
    output wire [31:0]  wr_addr,
    output wire [3:0]   wr_wstrb,
    output wire [127:0] wr_wdata,
    input  wire         wr_rdy

    
);
/**************** Global defination ****************/
genvar i;
reg  [1:0]  way_d_reg       [255:0];
wire [20:0] way_tagv_in     [1:0];
wire [20:0] way_tagv_out    [1:0];

reg         r_req_buf_op;
reg [ 7:0]  r_req_buf_index;
reg [19:0]  r_req_buf_tag;
reg [ 3:0]  r_req_buf_offset;
reg [ 3:0]  r_req_buf_wstrb;
reg [31:0]  r_req_buf_wdata;

/**************** state defination ****************/
localparam IDLE     = 3'd1;
localparam LOOKUP   = 3'd2;
localparam MISS     = 3'd3;
localparam REPLACE  = 3'd4;
localparam REFILL   = 3'd5;
localparam WRITE    = 3'd6;



/****************** tag compare ******************/

wire    way0_hit;
wire    way1_hit;
wire    cache_hit;  

assign way0_hit = way_tagv_out[0][0] && (tag == way_tagv_out[0][20:1]);
assign way1_hit = way_tagv_out[1][0] && (tag == way_tagv_out[1][20:1]);

assign cache_hit = way0_hit | way1_hit;



/****************** main state ********************/
wire        idle_to_lookup_valid;
wire        lookup_to_lookup_valid;

assign idle_to_lookup_valid     = valid & ~hit_wr_conflict;
assign lookup_to_lookup_valid   = valid & ~hit_wr_conflict & cache_hit;


/***************** hit write state ****************/
wire [3:0]  write_buffer_offset;
wire        wr_addr_dupl;
wire        wr_is_occupied;
wire        hit_wr_conflict;

assign wr_is_occupied   = wr_cur == WRITE;
assign wr_addr_dupl     = offset[3:2] == write_buffer_offset[3:2];
assign hit_wr_conflict  = wr_addr_dupl & wr_is_occupied;

/*************** main state machine ***************/
reg [2:0] main_cur;
always @(posedge clk) begin
    if(reset)begin
        main_cur <= IDLE;

        r_req_buf_op        <= 1'b0;
        r_req_buf_index     <= 8'b0;
        r_req_buf_tag       <= 20'b0;
        r_req_buf_offset    <= 4'b0;
        r_req_buf_wstrb     <= 4'b0;
        r_req_buf_wdata     <= 32'b0;
        
    end else case (main_cur)
        IDLE: begin
            if(idle_to_lookup_valid)begin
                r_req_buf_op        <= op;
                r_req_buf_index     <= index;
                r_req_buf_tag       <= tag;
                r_req_buf_offset    <= offset;
                r_req_buf_wstrb     <= wstrb;
                r_req_buf_wdata     <= wdata;
            end
        end
    endcase
end

/*************** write state machine ***************/
reg [2:0] wr_cur;
always @(posedge clk) begin
    if(reset)begin
        wr_cur <= IDLE;

    end else case (main_cur)
        IDLE: begin
            if(idle_to_lookup_valid)begin
                
            end
        end
    endcase
end


endmodule //cache