// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Cmd & Sts Register Module
// Revision   : v1.3
/*
v1.3 2025-07-09
1. rename full to fl, etc.
2. 写清除中断改为读清除中断
3. 更改中断置位与清除的优先级
4. 更改中断置位逻辑
TODO: 将普通状态信息与中断状态信息分开，不共用寄存器。共用寄存器会导致软件不方便。
*/
// =============================================================================
`ifndef	A429_CS
`define	A429_CS

`timescale 1ns/1ns

module A429_CS
(
	  rst_i
	, clk_i
	, irq_o	// active high

	, cyc_i
	, stb_i
	, adr_i
	, wnr_i
	, dat_i
	, dat_o
	, ack_o

	, tf_rs
	, tf_wr
	, tf_di
	, tf_cn
	, tf_fl
	, tf_af
	, tf_et
	, tf_ae

	, rf_rs
	, rf_rd
	, rf_do
	, rf_cn
	, rf_fl
	, rf_af
	, rf_et
	, rf_ae
	
	, tx_ena
	, rx_ena
	, tx_hi_spd
	, rx_hi_spd
	, lloop_ena
	, rloop_ena
);
parameter ENABLE_IRQ = 1; // 1: with irq, 0: without irq

// port signals
//===================================================================
input  rst_i;
input  clk_i;
output irq_o;
reg    irq_o;

input             cyc_i;
input             stb_i;
input      [ 1:0] adr_i;
input             wnr_i;
input      [31:0] dat_i;
output reg [31:0] dat_o;
output reg        ack_o;

output            tf_rs;
output reg        tf_wr;
output reg [31:0] tf_di;
input      [15:0] tf_cn;
input             tf_fl;
input             tf_af;
input             tf_et;
input             tf_ae;

output       rf_rs;
output reg   rf_rd;
input [31:0] rf_do;
input [15:0] rf_cn;
input        rf_fl;
input        rf_af;
input        rf_et;
input        rf_ae;

output tx_ena;
output rx_ena;
output tx_hi_spd;
output rx_hi_spd;
output lloop_ena;
output rloop_ena;

// internal signals
//===================================================================
wire[31:0] txsts;
wire[31:0] rxsts;
reg [31:0] cmd;
reg [ 7:0] sts_irq;
reg [23:20] tx_irq;
reg [23:20] rx_irq;
reg clr_tx_irq = 0;
reg clr_rx_irq = 0;

//===================================================================
localparam st0 = 0;
localparam st1 = 1;
reg [0:0] state;

always @(posedge clk_i)
if(rst_i)
	begin
		cmd <= #1 0;
		tf_wr <= #1 0;
		rf_rd <= #1 0;
		ack_o <= #1 0;
		state <= #1 st0;
	end
else
	begin
		ack_o <= #1 0;
		tf_wr <= #1 0;
		rf_rd <= #1 0;
		clr_tx_irq <= #1 0;
		clr_rx_irq <= #1 0;

		case(state)	// synthesis parallel_case
			st0:
				if(stb_i & cyc_i)
					begin
						ack_o <= #1 1;
						state <= #1 st1;
						
						if(wnr_i)
							begin
								case(adr_i)	// synthesis parallel_case
									2'd0:
										begin
											tf_di <= #1 dat_i;
											tf_wr <= #1 ~tf_fl;
										end
									2'd1:
										begin
											cmd <= #1 dat_i;
										end
									// 2'd2:
									// 	begin
									// 		clr_tx_irq <= #1 1;
									// 	end
									// 2'd3:
									// 	begin
									// 		clr_rx_irq <= #1 1;
									// 	end
								endcase
							end
						else
							begin
								if(adr_i == 2'd0)
									rf_rd <= #1 ~rf_et;

								case(adr_i)	// synthesis parallel_case
									2'd0:	dat_o <= #1 rf_do;
									2'd1:	dat_o <= #1 cmd;
									2'd2:	begin dat_o <= #1 txsts; clr_tx_irq <= #1 1; end
									2'd3:	begin dat_o <= #1 rxsts; clr_rx_irq <= #1 1; end
								endcase
							end
					end

			st1:
				begin
					state <= #1 st0;
				end
		endcase
	end

assign tx_ena      = cmd[0];
assign tx_hi_spd   = cmd[1];
assign tf_rs       = cmd[2];
assign lloop_ena   = cmd[3];
assign rx_ena      = cmd[4];
assign rx_hi_spd   = cmd[5];
assign rf_rs       = cmd[6];
assign rloop_ena   = cmd[7];

assign txsts[15:0] = tf_cn;
assign txsts[16]   = tf_et;
assign txsts[17]   = tf_fl;
assign txsts[18]   = tf_ae;
assign txsts[19]   = tf_af;
assign txsts[20]   = tx_irq[20];
assign txsts[21]   = tx_irq[21];
assign txsts[22]   = tx_irq[22];
assign txsts[23]   = tx_irq[23];

assign rxsts[15:0] = rf_cn;
assign rxsts[16]   = rf_et;
assign rxsts[17]   = rf_fl;
assign rxsts[18]   = rf_ae;
assign rxsts[19]   = rf_af;
assign rxsts[20]   = rx_irq[20];
assign rxsts[21]   = rx_irq[21];
assign rxsts[22]   = rx_irq[22];
assign rxsts[23]   = rx_irq[23];

// irq
//===================================================================
generate
if(ENABLE_IRQ)
begin

reg last_tf_et;
reg last_tf_fl;
reg last_tf_ae;
reg last_tf_af;
reg last_rf_et;
reg last_rf_fl;
reg last_rf_ae;
reg last_rf_af;
always @(posedge clk_i)
begin
    last_tf_et <= #1 tf_et;
    last_tf_fl <= #1 tf_fl;
    last_tf_ae <= #1 tf_ae;
    last_tf_af <= #1 tf_af;
    last_rf_et <= #1 rf_et;
    last_rf_fl <= #1 rf_fl;
    last_rf_ae <= #1 rf_ae;
    last_rf_af <= #1 rf_af;
end

reg pe_tf_et;
reg pe_tf_fl;
reg pe_tf_ae;
reg pe_tf_af;
reg pe_rf_et;
reg pe_rf_fl;
reg pe_rf_ae;
reg pe_rf_af;

always @(posedge clk_i)
begin
    pe_tf_et <= #1 tf_et && !last_tf_et;
    pe_tf_fl <= #1 tf_fl && !last_tf_fl;
    pe_tf_ae <= #1 tf_ae && !last_tf_ae;
    pe_tf_af <= #1 tf_af && !last_tf_af;
    pe_rf_et <= #1 rf_et && !last_rf_et;
    pe_rf_fl <= #1 rf_fl && !last_rf_fl;
    pe_rf_ae <= #1 rf_ae && !last_rf_ae;
    pe_rf_af <= #1 rf_af && !last_rf_af;
end

reg pe_tf_et_last;
reg pe_tf_fl_last;
reg pe_tf_ae_last;
reg pe_tf_af_last;
reg pe_rf_et_last;
reg pe_rf_fl_last;
reg pe_rf_ae_last;
reg pe_rf_af_last;

always @(posedge clk_i)
begin
	pe_tf_et_last <= #1 pe_tf_et;
	pe_tf_fl_last <= #1 pe_tf_fl;
	pe_tf_ae_last <= #1 pe_tf_ae;
	pe_tf_af_last <= #1 pe_tf_af;
	pe_rf_et_last <= #1 pe_rf_et;
	pe_rf_fl_last <= #1 pe_rf_fl;
	pe_rf_ae_last <= #1 pe_rf_ae;
	pe_rf_af_last <= #1 pe_rf_af;
end

always @(posedge clk_i)
begin
begin
	if((pe_tf_et | pe_tf_et_last) & cmd[ 8]) tx_irq[20] <= #1 1; else if(clr_tx_irq) tx_irq[20] <= #1 0;
	if((pe_tf_fl | pe_tf_fl_last) & cmd[ 9]) tx_irq[21] <= #1 1; else if(clr_tx_irq) tx_irq[21] <= #1 0;
	if((pe_tf_ae | pe_tf_ae_last) & cmd[10]) tx_irq[22] <= #1 1; else if(clr_tx_irq) tx_irq[22] <= #1 0;
	if((pe_tf_af | pe_tf_af_last) & cmd[11]) tx_irq[23] <= #1 1; else if(clr_tx_irq) tx_irq[23] <= #1 0;
end

begin
	if((pe_rf_et | pe_rf_et_last) & cmd[12]) rx_irq[20] <= #1 1; else if(clr_rx_irq) rx_irq[20] <= #1 0;
	if((pe_rf_fl | pe_rf_fl_last) & cmd[13]) rx_irq[21] <= #1 1; else if(clr_rx_irq) rx_irq[21] <= #1 0;
	if((pe_rf_ae | pe_rf_ae_last) & cmd[14]) rx_irq[22] <= #1 1; else if(clr_rx_irq) rx_irq[22] <= #1 0;
	if((pe_rf_af | pe_rf_af_last) & cmd[15]) rx_irq[23] <= #1 1; else if(clr_rx_irq) rx_irq[23] <= #1 0;
end
end

always @(posedge clk_i)
	irq_o <= #1 |tx_irq[23:20] | |rx_irq[23:20];

end
endgenerate

//===================================================================
endmodule
`endif
