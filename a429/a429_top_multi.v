// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Multi Chanel Top Module
// Revision   : v1.1
// =============================================================================
`ifndef	A429_TOP_MULTI
`define	A429_TOP_MULTI

`include "a429/a429_top.v"

module A429_TOP_MULTI
(
	  rst_i
	, clk_i

	, cyc_i
	, stb_i
	, adr_i
	, wnr_i
	, dat_i
	, dat_o
	, ack_o

	, irq_o
	, tx_slp_o
	, tx_10_o
	, rx_ab_i
);

// Channel configuration
//===================================================================
parameter CLOCK_KHZ = 100*1000;// Clock frequency(clk_i) in KHz: The value must be an integer multiple of 200.
parameter ENABLE_IRQ = 1; // 1: enable interrupt, 0: disable
parameter TX_NUM = 5;// Number of TX channels (0-32)
parameter RX_NUM = 8;// Number of RX channels (0-32)

localparam CHAN_NUM = (TX_NUM > RX_NUM) ? TX_NUM : RX_NUM;// CHAN_NUM >= 2
localparam TX_MASK = (1<<TX_NUM) - 1; // Bitmask of active TX channels
localparam RX_MASK = (1<<RX_NUM) - 1; // Bitmask of active RX channels

//===================================================================
localparam REGS_ADDR_WIDTH = `calc_aw(4);
localparam CHAN_ADDR_WIDTH = `calc_aw(CHAN_NUM);// Address width for channel index
localparam MAX_CHANNELS = 1 << CHAN_ADDR_WIDTH; // Maximum number of instances

localparam AW = CHAN_ADDR_WIDTH + REGS_ADDR_WIDTH;// Total address width

// Clock and Reset
//===================================================================
input rst_i;
input clk_i;

// Wishbone Bus Interface: slave
//===================================================================
input            cyc_i;
input            stb_i;
input   [AW-1:0] adr_i;
input            wnr_i;
input   [31:0]   dat_i;
output  [31:0]   dat_o;
output           ack_o;

// a429 signals
//===================================================================
output [CHAN_NUM  -1:0] irq_o;// interrupt output, active high
output [CHAN_NUM  -1:0] tx_slp_o;// Output slew rate control for Line Driver Pin. High selects ARINC 429 high-speed. Low selects ARINC 429 low-speed.
// tx_10_o[1]:Data input one (TX1IN) for Line Driver Pin
// tx_10_o[0]:Data input zero (TX0IN) for Line Driver Pin
output [CHAN_NUM*2-1:0] tx_10_o;
// rx_ab_i[1]: from Receiver's "ONE" output
// rx_ab_i[0]: from Receiver's "ZERO" output
input  [CHAN_NUM*2-1:0] rx_ab_i;

// internal signals
//===================================================================
wire [MAX_CHANNELS-1:0] ack_o_array;
wire             [31:0] dat_o_array [MAX_CHANNELS-1:0];

// functions
//===================================================================
wire [CHAN_ADDR_WIDTH-1:0] chan_addr = adr_i[AW-1:REGS_ADDR_WIDTH];

assign dat_o = dat_o_array[chan_addr];
assign ack_o = ack_o_array[chan_addr];

generate
genvar i;

for(i=0; i<CHAN_NUM; i=i+1)
begin
	A429_TOP #(.CLOCK_KHZ(CLOCK_KHZ), .ENABLE_TX(TX_MASK[i]), .ENABLE_RX(RX_MASK[i]), .ENABLE_IRQ(ENABLE_IRQ)) u_a429_top
	(
		  .rst_i	(rst_i)
		, .clk_i	(clk_i)
		
		, .cyc_i	(cyc_i & (chan_addr == i))
		, .stb_i	(stb_i & (chan_addr == i))
		, .adr_i	(adr_i[REGS_ADDR_WIDTH-1:0])
		, .wnr_i	(wnr_i)
		, .dat_i	(dat_i)
		, .dat_o	(dat_o_array[i])
		, .ack_o	(ack_o_array[i])

		, .irq_o	(irq_o[i])
		, .tx_slp_o (tx_slp_o[i])
		, .tx_10_o	(tx_10_o[2*i+1 : 2*i])
		, .rx_ab_i	(rx_ab_i[2*i+1 : 2*i])
	);
end

// UNUSED ADDRESS SPACE HANDLING
//===================================================================
// Prevent bus hanging by responding to undefined addresses
// - Acknowledge all accesses (ack_o = 1)
// - Return zero data (dat_o = 0)
for(i=CHAN_NUM; i<MAX_CHANNELS; i=i+1)
begin
	assign ack_o_array[i] = 1;
	assign dat_o_array[i] = 0;
end

endgenerate

//===================================================================
endmodule
`endif
