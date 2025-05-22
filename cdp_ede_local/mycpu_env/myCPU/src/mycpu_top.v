`include "my_cpu.vh"
module mycpu_top(
    input  wire         aclk,
    input  wire         aresetn,
    //axi read address channel
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
    output wire         bready,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge aclk) reset <= ~aresetn;

wire         ID_Allow_in;
wire         IF_Allow_in;
wire         EX_Allow_in;
wire         ME_Allow_in;
wire         WB_Allow_in;

wire         IF_to_ID_Valid;
wire         ID_to_EX_Valid;
wire         EX_to_ME_Valid;
wire         ME_to_WB_Valid;

wire         ME_Forward_valid;

wire         EX_to_ID_Ld_op; 
wire         ME_to_ID_ld_op;        
wire         EX_to_ID_Sys_op;
wire         ME_to_ID_Sys_op;
wire         WB_to_ID_Sys_op;  

// inst sram axi-like interface
wire         inst_sram_req;
wire         inst_sram_wr;
wire [1:0]   inst_sram_size;
wire [31:0]  inst_sram_addr;
wire [3:0]   inst_sram_wstrb;
wire [31:0]  inst_sram_wdata;
wire         inst_sram_addr_ok;
wire         inst_sram_data_ok;
wire [31:0]  inst_sram_rdata;
// data sram axi-like interface
wire         data_sram_req;
wire         data_sram_wr;
wire [1:0]   data_sram_size;
wire [31:0]  data_sram_addr; 
wire [3:0]   data_sram_wstrb;
wire [31:0]  data_sram_wdata;
wire         data_sram_addr_ok;
wire         data_sram_data_ok;
wire [31:0]  data_sram_rdata;

wire [`default_Dest_Size-1:0]   EX_dest;
wire [`default_Dest_Size-1:0]   ME_dest;
wire [`default_Dest_Size-1:0]   WB_dest;

wire [`br_bus_Size-1      :0]  br_bus;
wire [`IF_to_ID_Bus_Size-1:0]  IF_to_ID_Bus;
wire [`ID_to_EX_Bus_Size-1:0]  ID_to_EX_Bus;
wire [`EX_to_ME_Bus_Size-1:0]  EX_to_ME_Bus;
wire [`ME_to_WB_Bus_Size-1:0]  ME_to_WB_Bus;
wire [`WB_to_RF_Bus_Size-1:0]  WB_to_RF_Bus;
wire [`WB_to_EX_Bus_Size-1:0]  WB_to_EX_Bus;
wire [`ME_to_EX_Bus_Size-1:0]  ME_to_EX_Bus;


wire [`default_Data_Size-1:0]  EX_Forward_Res;
wire [`default_Data_Size-1:0]  ME_Forward_Res;
wire [`default_Data_Size-1:0]  WB_Forward_Res;

wire [31:0] core_id_in;

assign core_id_in = 32'd0;

wire [ 7:0] hw_int_in;
wire        ipi_int_in;
wire [13:0] EX_csr_num;
wire [13:0] WB_csr_num;
wire        csr_re;
wire [31:0] csr_rdata;
wire        csr_we;
wire [31:0] csr_wdata;
wire [31:0] ex_entry;
wire [31:0] er_entry;
wire        has_int;
wire        ertn_flush;
wire        excp_flush;
wire [ 5:0] wb_ecode;
wire [ 8:0] wb_esubcode;

wire [ 1:0] timer_re;
wire [31:0] timer_rdata;

assign hw_int_in  = 8'd0;
assign ipi_int_in = 1'd0;

IF_Unit IF(
    .clk               (aclk              ),
    .reset             (reset             ),
    .ID_Allow_in       (ID_Allow_in       ),
    .br_bus            (br_bus            ),
    .inst_sram_req     (inst_sram_req     ),
    .inst_sram_wr      (inst_sram_wr      ),
    .inst_sram_size    (inst_sram_size    ),
    .inst_sram_addr    (inst_sram_addr    ),
    .inst_sram_wstrb   (inst_sram_wstrb   ),
    .inst_sram_wdata   (inst_sram_wdata   ),
    .inst_sram_addr_ok (inst_sram_addr_ok ),
    .inst_sram_data_ok (inst_sram_data_ok ),
    .inst_sram_rdata   (inst_sram_rdata   ),
    .IF_to_ID_Bus      (IF_to_ID_Bus      ),
    .IF_to_ID_Valid    (IF_to_ID_Valid    ),
    .excp_flush        (excp_flush        ),
    .ertn_flush        (ertn_flush        ),
    .ex_entry          (ex_entry          ),
    .er_entry          (er_entry          )
);

ID_Unit ID(
    .clk             (aclk            ),
    .reset           (reset           ),
    .IF_to_ID_Valid  (IF_to_ID_Valid  ),
    .EX_Allow_in     (EX_Allow_in     ),
    .EX_dest         (EX_dest         ),
    .ME_dest         (ME_dest         ),
    .WB_dest         (WB_dest         ),
    .ID_Allow_in     (ID_Allow_in     ),
    .ID_to_EX_Valid  (ID_to_EX_Valid  ),
    .ID_to_EX_Bus    (ID_to_EX_Bus    ),
    .IF_to_ID_Bus    (IF_to_ID_Bus    ),
    .WB_to_RF_Bus    (WB_to_RF_Bus    ),
    .br_bus          (br_bus          ),
    .EX_to_ID_Ld_op  (EX_to_ID_Ld_op  ),
    .ME_to_ID_ld_op  (ME_to_ID_ld_op  ),
    .EX_to_ID_Sys_op (EX_to_ID_Sys_op ),
    .ME_to_ID_Sys_op (ME_to_ID_Sys_op ),
    .WB_to_ID_Sys_op (WB_to_ID_Sys_op ),
    .EX_Forward_Res  (EX_Forward_Res  ),
    .ME_Forward_Res  (ME_Forward_Res  ),
    .WB_Forward_Res  (WB_Forward_Res  ),
    .excp_flush      (excp_flush      ),
    .ertn_flush      (ertn_flush      ),
    .has_int         (has_int         ),
    .ME_Forward_valid(ME_Forward_valid)
);

EX_Unit EX(
    .clk               (aclk              ),
    .reset             (reset             ),
    .ID_to_EX_Valid    (ID_to_EX_Valid    ),
    .ID_to_EX_Bus      (ID_to_EX_Bus      ),
    .EX_Allow_in       (EX_Allow_in       ),
    .EX_to_ME_Valid    (EX_to_ME_Valid    ),
    .ME_Allow_in       (ME_Allow_in       ),
    .EX_to_ME_Bus      (EX_to_ME_Bus      ),
    .EX_dest           (EX_dest           ),
    .EX_Forward_Res    (EX_Forward_Res    ),
    .EX_to_ID_Ld_op    (EX_to_ID_Ld_op    ),
    .EX_to_ID_Sys_op   (EX_to_ID_Sys_op   ),
    .csr_re            (csr_re            ),
    .csr_rvalue        (csr_rdata         ),
    .csr_num           (EX_csr_num        ),
    .excp_flush        (excp_flush        ),
    .ertn_flush        (ertn_flush        ),
    .timer_re          (timer_re          ),
    .timer_rdata       (timer_rdata       ),
    .WB_to_EX_Bus      (WB_to_EX_Bus      ),
    .ME_to_EX_Bus      (ME_to_EX_Bus      ),
    .ME_to_ID_Sys_op   (ME_to_ID_Sys_op   ),
    .WB_to_ID_Sys_op   (WB_to_ID_Sys_op   ),
    .data_sram_req     (data_sram_req     ),
    .data_sram_wr      (data_sram_wr      ),
    .data_sram_size    (data_sram_size    ),
    .data_sram_addr    (data_sram_addr    ),
    .data_sram_wstrb   (data_sram_wstrb   ),
    .data_sram_wdata   (data_sram_wdata   ),
    .data_sram_addr_ok (data_sram_addr_ok )
);


ME_Unit ME(
    .clk               (aclk              ),
    .reset             (reset             ),
    .EX_to_ME_Valid    (EX_to_ME_Valid    ),
    .WB_Allow_in       (WB_Allow_in       ),
    .ME_Allow_in       (ME_Allow_in       ),
    .EX_to_ME_Bus      (EX_to_ME_Bus      ),
    .ME_to_WB_Valid    (ME_to_WB_Valid    ),
    .ME_to_WB_Bus      (ME_to_WB_Bus      ),
    .ME_dest           (ME_dest           ),
    .ME_Forward_Res    (ME_Forward_Res    ),
    .ME_to_ID_Sys_op   (ME_to_ID_Sys_op   ),
    .ME_to_ID_ld_op    (ME_to_ID_ld_op    ),
    .excp_flush        (excp_flush        ),
    .ertn_flush        (ertn_flush        ),
    .ME_to_EX_Bus      (ME_to_EX_Bus      ),
    .data_sram_rdata   (data_sram_rdata   ),
    .data_sram_data_ok (data_sram_data_ok ),
    .ME_Forward_Valid  (ME_Forward_valid  )
);

WB_Unit WB(
    .clk               (aclk              ),
    .reset             (reset             ),
    .WB_Allow_in       (WB_Allow_in       ),
    .ME_to_WB_Valid    (ME_to_WB_Valid    ),
    .ME_to_WB_Bus      (ME_to_WB_Bus      ),
    .debug_wb_pc       (debug_wb_pc       ),
    .debug_wb_rf_we    (debug_wb_rf_we    ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata ),
    .WB_to_RF_Bus      (WB_to_RF_Bus      ),
    .WB_dest           (WB_dest           ),
    .WB_Forward_Res    (WB_Forward_Res    ),
    .WB_to_ID_Sys_op   (WB_to_ID_Sys_op   ),
    .ertn_flush        (ertn_flush        ),
    .excp_flush        (excp_flush        ),
    .wb_ecode          (wb_ecode          ),
    .wb_esubcode       (wb_esubcode       ),
    .csr_we            (csr_we            ),
    .csr_wvalue        (csr_wdata         ),
    .csr_num           (WB_csr_num        ),
    .WB_to_EX_Bus      (WB_to_EX_Bus      )
);

CSR_Unit CSR(
    .clk         (aclk         ),
    .reset       (reset       ),
    .core_id_in  (core_id_in  ),
    .hw_int_in   (hw_int_in   ),
    .ipi_int_in  (ipi_int_in  ),
    .csr_rnum    (EX_csr_num  ),
    .csr_re      (csr_re      ),
    .csr_rdata   (csr_rdata   ),
    .csr_we      (csr_we      ),
    .csr_wdata   (csr_wdata   ),
    .ex_entry    (ex_entry    ),
    .er_entry    (er_entry    ),
    .has_int     (has_int     ),
    .ertn_flush  (ertn_flush  ),
    .wb_ex       (excp_flush  ),
    .wb_ecode    (wb_ecode    ),
    .wb_esubcode (wb_esubcode ),
    .wb_pc       (debug_wb_pc ),
    .csr_wnum    (WB_csr_num  ),
    .timer_rdata (timer_rdata ),
    .timer_re    (timer_re    )
);


sram_axi_brige u_sram_axi_brige(
    .inst_sram_req     (inst_sram_req     ),
    .inst_sram_wr      (inst_sram_wr      ),
    .inst_sram_size    (inst_sram_size    ),
    .inst_sram_addr    (inst_sram_addr    ),
    .inst_sram_wstrb   (inst_sram_wstrb   ),
    .inst_sram_wdata   (inst_sram_wdata   ),
    .inst_sram_addr_ok (inst_sram_addr_ok ),
    .inst_sram_data_ok (inst_sram_data_ok ),
    .inst_sram_rdata   (inst_sram_rdata   ),
    .data_sram_req     (data_sram_req     ),
    .data_sram_wr      (data_sram_wr      ),
    .data_sram_size    (data_sram_size    ),
    .data_sram_addr    (data_sram_addr    ),
    .data_sram_wstrb   (data_sram_wstrb   ),
    .data_sram_wdata   (data_sram_wdata   ),
    .data_sram_addr_ok (data_sram_addr_ok ),
    .data_sram_data_ok (data_sram_data_ok ),
    .data_sram_rdata   (data_sram_rdata   ),
    .aclk              (aclk              ),
    .aresetn           (aresetn           ),
    .arid              (arid              ),
    .araddr            (araddr            ),
    .arlen             (arlen             ),
    .arsize            (arsize            ),
    .arburst           (arburst           ),
    .arlock            (arlock            ),
    .arcache           (arcache           ),
    .arprot            (arprot            ),
    .arvalid           (arvalid           ),
    .arready           (arready           ),
    .rid               (rid               ),
    .rdata             (rdata             ),
    .rresp             (rresp             ),
    .rlast             (rlast             ),
    .rvalid            (rvalid            ),
    .rready            (rready            ),
    .awid              (awid              ),
    .awaddr            (awaddr            ),
    .awlen             (awlen             ),
    .awsize            (awsize            ),
    .awburst           (awburst           ),
    .awlock            (awlock            ),
    .awcache           (awcache           ),
    .awprot            (awprot            ),
    .awvalid           (awvalid           ),
    .awready           (awready           ),
    .wid               (wid               ),
    .wdata             (wdata             ),
    .wstrb             (wstrb             ),
    .wlast             (wlast             ),
    .wvalid            (wvalid            ),
    .wready            (wready            ),
    .bid               (bid               ),
    .bresp             (bresp             ),
    .bvalid            (bvalid            ),
    .bready            (bready            )
);


endmodule
