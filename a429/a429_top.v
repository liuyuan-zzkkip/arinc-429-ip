// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Top Module
// Revision   : v1.1
// =============================================================================
`ifndef	A429_TOP
`define	A429_TOP

`include "a429/bit_width_utils.v"
`include "a429/a429_cs.v"
`include "a429/a429_tx.v"
`include "a429/a429_rx.v"

// `define SIM
`ifdef SIM
`include "a429/tb/fifo/gffsc.v"
`endif

module A429_TOP
(
	  rst_i
	, clk_i

	// Wishbone bus interface
	, cyc_i
	, stb_i
	, adr_i
	, wnr_i
	, dat_i
	, dat_o
	, ack_o

	, irq_o	   // Active high interrupt
	, tx_slp_o // Speed select: 1=high-speed (100Kbps), 0=low-speed (12.5Kbps)
	, tx_10_o  // ARINC429 differential lines. // TX lines: [1] = Line A, [0] = Line B
	, rx_ab_i  // ARINC429 differential lines. // RX lines: [1] = Line A, [0] = Line B
);
parameter ENABLE_TX = 1; // 1: with tx, 0: without tx
parameter ENABLE_RX = 1; // 1: with rx, 0: without rx
parameter ENABLE_IRQ = 1; // 1: with irq, 0: without irq

// Change the unit from MHz to kHz to avoid using floating-point numbers. 
//  Some versions of Verilog don't support floating-point values, 
//  and they may cause compatibility issues during compilation and synthesis.
parameter CLOCK_KHZ = 100*1000;// Must be an integer multiple of 200
parameter TX_FIFO_DEEP = 514;// 32bit fwft scff
parameter RX_FIFO_DEEP = 514;// 32bit fwft scff

// support different FIFO depths for transmission and reception
localparam TFAW = `calc_cw(TX_FIFO_DEEP);
localparam RFAW = `calc_cw(RX_FIFO_DEEP);

// wishbone bus signals
//===================================================================
input  rst_i;
input  clk_i;

input        cyc_i;
input        stb_i;
input [ 1:0] adr_i;
input        wnr_i;
input [31:0] dat_i;
output[31:0] dat_o;
output       ack_o;

output       irq_o;
output       tx_slp_o;
output [1:0] tx_10_o;
input  [1:0] rx_ab_i;

// internal signals
//===================================================================
// FIFO signals for TX
wire           tf_rs;
wire           tf_wr;
wire[31:0]     tf_di;
wire[TFAW-1:0] tf_cn;
wire           tf_fl;
wire           tf_af;
wire           tf_rd;
wire[31:0]     tf_do;
wire           tf_et;
wire           tf_ae;

// FIFO signals for RX
wire           rf_rs;
wire           rf_wr;
wire[31:0]     rf_di;
wire[RFAW-1:0] rf_cn;
wire           rf_fl;
wire           rf_af;
wire           rf_rd;
wire[31:0]     rf_do;
wire           rf_et;
wire           rf_ae;

wire tx_ena;
wire rx_ena;
wire tx_hi_spd;
wire rx_hi_spd;

// Loopback control
wire lloop_ena;// Enable local  loopback (TX connected to RX)
wire rloop_ena;// Enable remote loopback (RX connected to TX)

wire [1:0] tx_10;

assign tx_slp_o = tx_hi_spd;

assign tf_af = tf_cn[TFAW/2];
assign tf_ae = tf_cn[TFAW/2];
assign rf_af = rf_cn[RFAW/2];
assign rf_ae = rf_cn[RFAW/2];

// command and status module
//===================================================================
A429_CS #(.ENABLE_IRQ(ENABLE_IRQ)) a429_cs_inst
(
	  .rst_i (rst_i)
	, .clk_i (clk_i)
	, .irq_o (irq_o)

	, .cyc_i (cyc_i)
	, .stb_i (stb_i)
	, .adr_i (adr_i)
	, .wnr_i (wnr_i)
	, .dat_i (dat_i)
	, .dat_o (dat_o)
	, .ack_o (ack_o)
	
	, .tf_rs (tf_rs)
	, .tf_wr (tf_wr)
	, .tf_di (tf_di)
	, .tf_cn (tf_cn)
	, .tf_fl (tf_fl)
	, .tf_af (tf_af)
	, .tf_et (tf_et)
	, .tf_ae (tf_ae)
	
	, .rf_rs (rf_rs)
	, .rf_rd (rf_rd)
	, .rf_do (rf_do)
	, .rf_cn (rf_cn)
	, .rf_fl (rf_fl)
	, .rf_af (rf_af)
	, .rf_et (rf_et)
	, .rf_ae (rf_ae)

	, .tx_ena     (tx_ena)
	, .rx_ena     (rx_ena)
	, .tx_hi_spd  (tx_hi_spd)
	, .rx_hi_spd  (rx_hi_spd)
	, .lloop_ena  (lloop_ena)
	, .rloop_ena  (rloop_ena)
);

// tx
//===================================================================
generate
if(ENABLE_TX!=0)
begin

A429_TX #(.CLOCK_KHZ(CLOCK_KHZ)) a429_tx_inst
(
	  .rst_i (~tx_ena)//(rst_i)
	, .clk_i (clk_i)
	
	, .tx_ena  (1'b1)//(tx_ena)
	, .hi_spd  (tx_hi_spd)
	, .tx_10   (tx_10)

	, .tf_rd (tf_rd)
	, .tf_do (tf_do)
	, .tf_et (tf_et)
);
assign tx_10_o = rloop_ena ? rx_ab_i : tx_10;// Remote loopback: RX → TX

`ifndef SIM
scff_fwft_a429 txff
(
	  .srst      (tf_rs|rst_i)
	, .clk       (clk_i)
	, .wr_en     (tf_wr)
	, .din       (tf_di)
	, .full      (tf_fl)
	, .rd_en     (tf_rd)
	, .dout      (tf_do)
	, .empty     (tf_et)
	, .data_count(tf_cn)
);
`endif
`ifdef SIM
gffsc #(.aw(TFAW-1),.dw(32),.FWFT(1),.WITH_RAM(1)) gffsc_tx
(
      .clk (clk_i)
    , .rst (tf_rs|rst_i)
    , .clr (1'b0 )
    , .we  (tf_wr)
    , .di  (tf_di)
    , .fl  (tf_fl)
	, .af  ()
    , .re  (tf_rd)
    , .do  (tf_do)
    , .vl  ()
    , .et  (tf_et)
	, .ae  ()
    , .cn  (tf_cn)
    , .uc  ()
	, .wp  ()
	, .rp  ()

	, .over_run_o ()
	, .over_run_c (1'b0)
	, .underrun_o ()
	, .underrun_c (1'b0)
);
`endif
end
endgenerate


// rx
//===================================================================
generate
if(ENABLE_RX!=0)
begin

A429_RX #(.CLOCK_KHZ(CLOCK_KHZ)) a429_rx_inst
(
	  .rst_i (~rx_ena)//(rst_i)
	, .clk_i (clk_i)
	
	, .rx_ena  (1'b1)//(rx_ena)
	, .hi_spd  (rx_hi_spd)
	, .rx_ab_i (lloop_ena ? tx_10:rx_ab_i)// Local loopback: TX → RX

	, .rf_wr (rf_wr)
	, .rf_di (rf_di)
	, .rf_fl (rf_fl)
);

`ifndef SIM
scff_fwft_a429 rxff
(
	  .srst      (rf_rs|rst_i)
	, .clk       (clk_i)
	, .wr_en     (rf_wr)
	, .din       (rf_di)
	, .full      (rf_fl)
	, .rd_en     (rf_rd)
	, .dout      (rf_do)
	, .empty     (rf_et)
	, .data_count(rf_cn)
);
`endif
`ifdef SIM
gffsc #(.aw(RFAW-1),.dw(32),.FWFT(1),.WITH_RAM(1)) gffsc_rx
(
      .clk (clk_i)
    , .rst (rf_rs|rst_i)
    , .clr (1'b0 )
    , .we  (rf_wr)
    , .di  (rf_di)
    , .fl  (rf_fl)
	, .af  ()
    , .re  (rf_rd)
    , .do  (rf_do)
    , .vl  ()
    , .et  (rf_et)
	, .ae  ()
    , .cn  (rf_cn)
    , .uc  ()
	, .wp  ()
	, .rp  ()

	, .over_run_o ()
	, .over_run_c (1'b0)
	, .underrun_o ()
	, .underrun_c (1'b0)
);
`endif
end
endgenerate

endmodule
`endif
