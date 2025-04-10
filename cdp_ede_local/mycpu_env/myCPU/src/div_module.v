module div_signed (
    input  wire clk,
    input  wire reset,

    input  wire [31:0] src1,
    input  wire [31:0] src2,

    input  wire src_is_signed,
    input  wire div_en,

    output wire [63:0] div_result,
    output wire divres_valid
);


wire divisor_ready;
reg  divisor_valid;
wire dividend_ready;
reg  dividend_valid;


parameter free = 2'b00;
parameter load = 2'b01;
parameter retn = 2'b10;

reg [1:0] cur;
    
div_gen div_gen(
    .aclk(clk),
    .s_axis_divisor_tvalid(divisor_valid),
    .s_axis_divisor_tready(divisor_ready),
    .s_axis_divisor_tdata(src2),
    .s_axis_dividend_tvalid(dividend_valid),
    .s_axis_dividend_tready(dividend_ready),
    .s_axis_dividend_tdata(src1),
    .m_axis_dout_tvalid(divres_valid),
    .m_axis_dout_tdata(div_result)
);

always @(posedge clk) begin
    if (reset) begin
        cur <=  free;
        divisor_valid <= 1'b0;
        dividend_valid <= 1'b0;
    end else if (src_is_signed & div_en) begin
        case(cur)
            free : begin
                cur <= load;
                divisor_valid <= 1'b1;
                dividend_valid <= 1'b1;
            end
            load : begin
                if(dividend_ready && divisor_ready) begin
                    cur <= retn;
                    divisor_valid <=1'b0;
                    dividend_valid <=1'b0;
                end
            end
            retn : begin
                if(divres_valid) begin
                    cur <= free;
                end
            end
            default : cur <= free;
        endcase   
    end
end



endmodule

module div_unsigned (
    input  wire clk,
    input  wire reset,

    input  wire [31:0] src1,
    input  wire [31:0] src2,
    input  wire src_is_signed,
    input  wire div_en,

    output wire [63:0] div_result,
    output wire divres_valid
);

wire divisor_ready;
reg  divisor_valid;
wire dividend_ready;
reg  dividend_valid;

parameter free = 2'b00;
parameter load = 2'b01;
parameter retn = 2'b10;

reg [1:0] cur;
    
divu_gen divu_gen(
    .aclk(clk),
    .s_axis_divisor_tvalid(divisor_valid),
    .s_axis_divisor_tready(divisor_ready),
    .s_axis_divisor_tdata(src2),
    .s_axis_dividend_tvalid(dividend_valid),
    .s_axis_dividend_tready(dividend_ready),
    .s_axis_dividend_tdata(src1),
    .m_axis_dout_tvalid(divres_valid),
    .m_axis_dout_tdata(div_result)
);

always @(posedge clk) begin
    if (reset) begin
        cur <=  free;
        divisor_valid <= 1'b0;
        dividend_valid <= 1'b0;
    end else if (~src_is_signed & div_en) begin
        case(cur)
            free : begin
                cur <= load;
                divisor_valid <= 1'b1;
                dividend_valid <= 1'b1;
            end
            load : begin
                if(dividend_ready && divisor_ready) begin
                    cur <= retn;
                    divisor_valid <=1'b0;
                    dividend_valid <=1'b0;
                end
            end
            retn : begin
                if(divres_valid) begin
                    cur <= free;
                end
            end
            default : cur <= free;
        endcase   
    end
end



endmodule

