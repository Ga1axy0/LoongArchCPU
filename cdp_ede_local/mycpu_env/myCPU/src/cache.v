module cache (
    input  wire         clk,
    input  wire         resetn,

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
    input  wire         ret_last,
    input  wire [31:0]  ret_data,
    output wire         wr_req,
    output wire [2:0]   wr_type,
    output wire [31:0]  wr_addr,
    output wire [3:0]   wr_wstrb,
    output wire [127:0] wr_data,
    input  wire         wr_rdy

    
);
/**************** Global defination ****************/
genvar i,j;
reg  [ 1:0] r_way_d       [255:0];
wire [20:0] way_tagv_in     [1:0];

wire reset = ~resetn;

wire [ 7:0] way_bank_addra [1:0][3:0];
wire [31:0] way_bank_dina  [1:0][3:0];
wire [31:0] way_bank_douta [1:0][3:0];
wire        way_bank_ena   [1:0][3:0];
wire [ 3:0] way_bank_wea   [1:0][3:0];

wire [ 7:0] way_tagv_addra [1:0];
wire [20:0] way_tagv_dina  [1:0];
wire [20:0] way_tagv_douta [1:0];
wire        way_tagv_ena   [1:0];
wire        way_tagv_wea   [1:0];

wire 		wr_match_way_bank[1:0][3:0];

reg         r_req_buf_op;
reg  [ 7:0] r_req_buf_index;
reg  [19:0] r_req_buf_tag;
reg  [ 3:0] r_req_buf_offset;
reg  [ 3:0] r_req_buf_wstrb;
reg  [31:0] r_req_buf_wdata;
reg         r_wr_req;
reg  [ 1:0] r_miss_buffer_num;

reg [ 7:0]  r_wr_buf_index;
reg [ 3:0]  r_wr_buf_wstrb;
reg [31:0]  r_wr_buf_wdata;
reg [ 1:0]  r_wr_buf_way;
reg [ 3:0]  r_wr_buf_offset;

reg [  1:0] miss_buf_replace_way;
reg [255:0] lru_bit;

wire [19:0] replace_tag;
wire        replace_v;
wire        replace_d;
wire [127:0] replace_data;

wire [31:0] write_in;
wire [ 1:0] way_wr_en;


wire [ 1:0] way_d;

assign way_d    = r_way_d[r_req_buf_index] |
                  {2{(r_wr_buf_index == r_req_buf_index) && wr_is_occupied}} & r_wr_buf_way;
assign wr_req   = r_wr_req;

/**************** state defination ****************/
localparam IDLE     = 3'd1;
localparam LOOKUP   = 3'd2;
localparam MISS     = 3'd3;
localparam REPLACE  = 3'd4;
localparam REFILL   = 3'd5;
localparam WRITE    = 3'd6;



/****************** tag compare ******************/

wire [1:0]  way_hit;
wire        cache_hit;  

generate
    for(i=0;i<2;i=i+1)begin:gen_way_hit 
        assign way_hit[i] = way_tagv_douta[i][0] && (tag == way_tagv_douta[i][20:1]);
    end
endgenerate

assign cache_hit = |way_hit;


/***************** data selection *****************/
wire [127:0] way_data       [1:0];
wire [ 31:0] way_load_word  [1:0];
wire [ 31:0] load_res;

generate
    for(i=0;i<2;i=i+1)begin:gen_way_data
        assign way_data[i] = {way_bank_douta[i][3],way_bank_douta[i][2],way_bank_douta[i][1],way_bank_douta[i][0]};
        assign way_load_word[i] = way_data[i][r_req_buf_offset[3:2]*32 +: 32];
    end
    
endgenerate

assign load_res = {32{way_hit[0]}} & way_load_word[0] | 
                  {32{way_hit[1]}} & way_load_word[1];





/****************** main state ********************/
wire        idle_to_lookup_valid;
wire        lookup_to_lookup_valid;

wire        main_state_is_idle;
wire        main_state_is_look_up;
wire        main_state_is_miss;
wire        main_state_is_replace;
wire        main_state_is_refill;

wire [1:0]  replace_way;


assign idle_to_lookup_valid     = valid & ~hit_wr_conflict;
assign lookup_to_lookup_valid   = valid & ~hit_wr_conflict & ~RAW_conflict & cache_hit;


assign main_state_is_look_up    = main_cur == LOOKUP;
assign main_state_is_idle       = main_cur == IDLE;
assign main_state_is_miss       = main_cur == MISS;
assign main_state_is_replace    = main_cur == REPLACE;
assign main_state_is_refill     = main_cur == REFILL;

assign addr_ok =    (main_state_is_idle && idle_to_lookup_valid) | 
                    (main_state_is_look_up && lookup_to_lookup_valid);

assign replace_way  = lru_bit[r_req_buf_index];
assign replace_tag  = {20{miss_buf_replace_way[0]}} & way_tagv_douta[0][20:1] |
                      {20{miss_buf_replace_way[1]}} & way_tagv_douta[1][20:1];

assign replace_d    = |(replace_way & way_d);
assign replace_v    = |(replace_way & {way_tagv_douta[1][0],way_tagv_douta[0][0]});

assign replace_data = {128{miss_buf_replace_way[0]}} & way_data[0] | 
				      {128{miss_buf_replace_way[1]}} & way_data[1] ;

assign wr_type  = 3'b100;
assign wr_addr  = {replace_tag, r_req_buf_index, 4'b0};
assign wr_data  = replace_data;
assign wr_wstrb = 4'hf;

assign rd_req  = main_state_is_replace;
assign rd_type = 3'b100;
assign rd_addr = {r_req_buf_tag, r_req_buf_index, 4'b0};

assign data_ok = (main_state_is_look_up && cache_hit) || 
                 (main_state_is_refill && (ret_valid && (r_miss_buffer_num == r_req_buf_offset[3:2])));

assign write_in = {(r_req_buf_wstrb[3] ? r_req_buf_wdata[31:24] : ret_data[31:24]), 
                   (r_req_buf_wstrb[2] ? r_req_buf_wdata[23:16] : ret_data[23:16]),
                   (r_req_buf_wstrb[1] ? r_req_buf_wdata[15: 8] : ret_data[15: 8]),
                   (r_req_buf_wstrb[0] ? r_req_buf_wdata[ 7: 0] : ret_data[ 7: 0])};

assign refill_data = (r_req_buf_op && (r_req_buf_offset[3:2] == r_miss_buffer_num)) ? write_in : ret_data; 

assign way_wr_en = miss_buf_replace_way & {2{ret_valid}};

reg rd_req_buffer;

always @(posedge clk) begin
    if (reset) begin
        rd_req_buffer <= 1'b0;
    end
    else if (rd_req) begin
        rd_req_buffer <= 1'b1;
    end
    else if (main_state_is_refill && (ret_valid && ret_last)) begin
        rd_req_buffer <= 1'b0;
    end
end

/***************** hit write state ****************/
wire        wr_addr_dupl;
wire        wr_is_occupied;
wire        hit_wr_conflict;
wire        RAW_conflict;




assign wr_is_occupied   = wr_cur == WRITE;
assign wr_addr_dupl     = offset[3:2] == r_wr_buf_offset[3:2];
assign hit_wr_conflict  = wr_addr_dupl & wr_is_occupied;
assign RAW_conflict     = r_req_buf_op & !op & (offset[3:2] == r_req_buf_offset);


assign wr_type  = 3'b100;
assign wr_addr  = {replace_tag,r_req_buf_index,4'b0};

always @(posedge clk) begin
    if (main_state_is_refill && ((ret_valid && ret_last) || !rd_req_buffer)) begin
		r_way_d[r_req_buf_index][0] <= miss_buf_replace_way[0] ? r_req_buf_op : r_way_d[r_req_buf_index][0];
		r_way_d[r_req_buf_index][1] <= miss_buf_replace_way[1] ? r_req_buf_op : r_way_d[r_req_buf_index][1];
    end
    else if (wr_is_occupied) begin
		r_way_d[r_wr_buf_index] <= r_way_d[r_wr_buf_index] | r_wr_buf_way;
    end
end

assign rdata = {32{main_state_is_look_up}} & load_res |
               {32{main_state_is_refill}} & ret_data ;


generate 
for(i=0;i<2;i=i+1) begin:gen_data_way
	for(j=0;j<4;j=j+1) begin:gen_data_bank
/*===============================bank addra logic==============================*/

		assign wr_match_way_bank[i][j] = wr_is_occupied && (r_wr_buf_way[i] && (r_wr_buf_offset[3:2] == j[1:0]));

		assign way_bank_addra[i][j] = wr_match_way_bank[i][j] ? r_wr_buf_index : ({8{addr_ok}}  & index                |    /*lookup*/
						                                                          {8{!addr_ok}} & r_req_buf_index); 

/*===============================bank we logic=================================*/

		assign way_bank_wea[i][j] = {4{wr_match_way_bank[i][j]}} & r_wr_buf_wstrb | 
									{4{main_state_is_refill && (way_wr_en[i] && (r_miss_buffer_num == j[1:0]))}} & 4'hf;

/*===============================bank dina logic=================================*/

		assign way_bank_dina[i][j] = {32{wr_is_occupied}}  & r_wr_buf_wdata |
                                     {32{main_state_is_refill}} & refill_data        ;

/*===============================bank ena logic=================================*/

		assign way_bank_ena[i][j] = main_state_is_idle || main_state_is_look_up;
	end
end
endgenerate


generate
for(i=0;i<2;i=i+1) begin:gen_tagv_way
/*===============================tagv addra logic=================================*/

assign way_tagv_addra[i] = {8{addr_ok }} & index                |
                           {8{!addr_ok}} & r_req_buf_index ; 

/*===============================tagv ena logic=================================*/

assign way_tagv_ena[i] = main_state_is_idle || main_state_is_look_up;

/*===============================tagv wea logic=================================*/

assign way_tagv_wea[i] = miss_buf_replace_way[i] && main_state_is_refill &&
	                     (ret_valid && ret_last); //write at least 4B

/*===============================tagv dina logic=================================*/

assign way_tagv_dina[i] = {r_req_buf_tag, 1'b1};
end
endgenerate

generate
for(i=0;i<2;i=i+1) begin:data_ram_way
	for(j=0;j<4;j=j+1) begin:data_ram_bank
		data_bank_sram u(
    		.addra      (way_bank_addra[i][j]),
    		.clka       (clk                 ),
    		.dina       (way_bank_dina[i][j] ),
    		.douta      (way_bank_douta[i][j]),
    		.ena        (way_bank_ena[i][j]  ),
    		.wea        (way_bank_wea[i][j]  )  
		);
	end
end
endgenerate

generate
for(i=0;i<2;i=i+1) begin:tagv_ram_way
	//[20:1] tag     [0:0] v
	tagv_sram u( 
	    .addra      (way_tagv_addra[i]),
	    .clka       (clk              ),
	    .dina       (way_tagv_dina[i] ),
	    .douta      (way_tagv_douta[i]),
	    .ena        (way_tagv_ena[i]  ),
	    .wea        (way_tagv_wea[i]  )
	);
end
endgenerate


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

        miss_buf_replace_way    <=2'b0;

        r_wr_req <= 1'b0;
        
    end else case (main_cur)
        IDLE: begin
            if(idle_to_lookup_valid)begin
                main_cur <= LOOKUP;

                r_req_buf_op        <= op;
                r_req_buf_index     <= index;
                r_req_buf_tag       <= tag;
                r_req_buf_offset    <= offset;
                r_req_buf_wstrb     <= wstrb;
                r_req_buf_wdata     <= wdata; 
            end
        end
        LOOKUP: begin
            if(lookup_to_lookup_valid)begin 
                r_req_buf_op        <= op;
                r_req_buf_index     <= index;
                r_req_buf_tag       <= tag;
                r_req_buf_offset    <= offset;
                r_req_buf_wstrb     <= wstrb;
                r_req_buf_wdata     <= wdata; 
            end else if(~cache_hit)begin
                if(replace_d & replace_v)begin
                    main_cur <= MISS;
                end else begin
                    main_cur <= REPLACE;
                end
                //r_req_buf_tag        <= tag;
                miss_buf_replace_way <= replace_way; 

            end else begin
                main_cur <= IDLE;
            end          

        end
        MISS:begin
            if(wr_rdy)begin
                main_cur <= REPLACE;
                r_wr_req <= 1'b1;
            end
        end
        REPLACE:begin
            if(rd_rdy)begin
                main_cur <= REFILL;
                r_miss_buffer_num <= 2'b0;
            end
            r_wr_req <= 1'b0;
        end
        REFILL:begin
            if(ret_valid & ret_last || !rd_req_buffer)begin
                main_cur <= IDLE;
            end else begin
                if(ret_valid)begin
                    r_miss_buffer_num <= r_miss_buffer_num + 1'b1; 
                end
            end
        end
        default:
            main_cur <= IDLE;
    endcase
end

/*************** write state machine ***************/
reg [2:0] wr_cur;
always @(posedge clk) begin
    if(reset)begin
        wr_cur <= IDLE;

        r_wr_buf_index     <= 8'b0;
        r_wr_buf_wstrb     <= 4'b0;
        r_wr_buf_wdata     <= 32'b0;
        r_wr_buf_way       <= 2'b0;
        r_wr_buf_offset    <= 4'b0;

    end else case (wr_cur)
        IDLE: begin
            if(main_state_is_look_up & cache_hit & r_req_buf_op)begin
                wr_cur <= WRITE;

                r_wr_buf_index     <= r_req_buf_index;
                r_wr_buf_wstrb     <= r_req_buf_wstrb;
                r_wr_buf_wdata     <= r_req_buf_wdata;
                r_wr_buf_way       <= way_hit;
                r_wr_buf_offset    <= r_req_buf_offset;
                
            end
        end
        WRITE : begin
            if(main_state_is_look_up & cache_hit & r_req_buf_op)begin
                r_wr_buf_index     <= r_req_buf_index;
                r_wr_buf_wstrb     <= r_req_buf_wstrb;
                r_wr_buf_wdata     <= r_req_buf_wdata;
                r_wr_buf_way       <= way_hit;
                r_wr_buf_offset    <= r_req_buf_offset;
            end else begin
                wr_cur <= IDLE;
            end
        end
        default :begin
            wr_cur <= IDLE;
        end
            
    endcase
end

/******************* LRU *******************/
// LRU: 0表示最近使用的是way0，1表示最近使用的是way1
always @(posedge clk) begin
    if (reset) begin
        lru_bit <= 256'b0;
    end else if (main_state_is_look_up && cache_hit) begin
        // 命中时，lru记录最近访问的way
        lru_bit[r_req_buf_index] <= way_hit[1]; // 1表示最近用的是way1，0表示way0
    end else if (main_state_is_replace && rd_rdy) begin
        // 替换时，lru记录刚被替换的way的相反值
        lru_bit[r_req_buf_index] <= ~miss_buf_replace_way[0];
    end
end


endmodule //cache