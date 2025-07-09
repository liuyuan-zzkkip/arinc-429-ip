`include "a429/tb/wb_master.v"
`include "a429/a429_top.v"

`timescale 1ns/1ns

module A429_TOP_TB();

///////////////////////////////////////////////////////////
reg  rst_i;
reg  clk_i;
initial begin
        rst_i = 1;
    #60 rst_i = 0;
end
initial clk_i = 0;
always #(5) clk_i = !clk_i;


///////////////////////////////////////////////////////////
wire        cyc_o;
wire        stb_o;
wire [ 1:0] adr_o;
wire        wnr_o;
wire [31:0] dat_o;
wire [31:0] dat_i;
wire        ack_i;

wb_master u_wbm
(
	  .rst_i (rst_i)
	, .clk_i (clk_i)

	, .cyc_o (cyc_o)
	, .stb_o (stb_o)
	, .adr_o (adr_o)
	, .wnr_o (wnr_o)
	, .dat_o (dat_o)
	, .dat_i (dat_i)
	, .ack_i (ack_i)
);

wire [1:0] tx_10_o;
wire [1:0] rx_ab_i;

A429_TOP u_A429_TOP
(
	  .rst_i (rst_i)
	, .clk_i (clk_i)

	, .cyc_i (cyc_o)
	, .stb_i (stb_o)
	, .adr_i (adr_o)
	, .wnr_i (wnr_o)
	, .dat_i (dat_o)
	, .dat_o (dat_i)
	, .ack_o (ack_i)

	, .irq_o	()
	, .tx_slp_o ()
	, .tx_10_o  (tx_10_o)
	, .rx_ab_i  (rx_ab_i)
);

// assign rx_ab_i = tx_10_o;

endmodule