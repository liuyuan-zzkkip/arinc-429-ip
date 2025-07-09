// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Tx Module
// Revision   : v1.3
// =============================================================================
`ifndef	A429_TX
`define	A429_TX

`include "a429/bit_width_utils.v"

`timescale 1ns/1ns

module A429_TX
(
	// Clock and Reset
	  rst_i
	, clk_i

	// FIFO Interface
	, tf_rd  // FIFO read enable
	, tf_do  // FIFO data output
	, tf_et  // FIFO empty flag

	// Control Signals
	, tx_ena  // Transmit enable
	, hi_spd  // 1 = 100kbps, 0 = 12.5kbps
	, tx_10   // Differential outputs (A/B)
);

parameter CLOCK_KHZ = 100*1000;

input rst_i;
input clk_i;

input       tx_ena;
input       hi_spd;
output[1:0]	tx_10;
reg	  [1:0]	tx_10;

output reg  tf_rd;
input[31:0]	tf_do;
input 		tf_et;

// ARINC429 Line States
localparam AB_1 = 2'b10;// High state (Mark)
localparam AB_0 = 2'b01;// Low state (Space)
localparam AB_N = 2'b00;// Null state

localparam ST0 = 0;
localparam ST1 = 1;
localparam ST2 = 2;
localparam ST3 = 3;

localparam BIT_CYCLES_100K = CLOCK_KHZ*10/1000;
localparam MAX_COUNT = 8*BIT_CYCLES_100K/2-2;
localparam CW = `calc_cw(MAX_COUNT);
reg  [CW  :0] count;
wire [CW-1:0] COUNT = hi_spd ? (BIT_CYCLES_100K/2-2):(8*BIT_CYCLES_100K/2-2);

reg [ 1:0] state;
reg [ 3:0] g_num;
reg [ 5:0] b_num;
reg [31:0] shift;
wire[31:0] dat_i = tf_do;

always @(posedge clk_i)
if(rst_i)
	begin
		count <= #1 COUNT;
		g_num <= #1 4*2-2;
		tf_rd <= #1 0;
		tx_10 <= #1 AB_N;
		state <= #1 ST0;
	end
else
	begin
		tf_rd <= #1 0;
		
		case(state)	// synthesis parallel_case
			ST0:
				begin
					count <= #1 count - 1;
					if(count[CW])
						begin
							count <= #1 COUNT;
							g_num <= #1 g_num - 1;
							if(g_num[3])
								begin
									g_num <= #1 4*2-2;
									state <= #1 ST1;
								end
						end
				end

			ST1:
				begin
					if(~tf_et & tx_ena)
						begin
							shift[ 7]   <= #1 dat_i[ 0];
							shift[ 6]   <= #1 dat_i[ 1];
							shift[ 5]   <= #1 dat_i[ 2];
							shift[ 4]   <= #1 dat_i[ 3];
							shift[ 3]   <= #1 dat_i[ 4];
							shift[ 2]   <= #1 dat_i[ 5];
							shift[ 1]   <= #1 dat_i[ 6];
							shift[ 0]   <= #1 dat_i[ 7];
							shift[31]   <= #1 ^{dat_i[31:9], /*parity_type ODD*/1'b1, dat_i[7:0]};
							shift[29]   <= #1 dat_i[ 9];
							shift[30]   <= #1 dat_i[10];
							shift[28:8] <= #1 dat_i[31:11];

							tf_rd <= #1 1;
							
							b_num <= #1 32 - 2;
							count <= #1 COUNT;
							state <= #1 ST2;
						end
				end

			ST2:
				begin
					tx_10 <= #1 shift[0] ? AB_1 : AB_0;
					count <= #1 count - 1;
					if(count[CW])
						begin
							count <= #1 COUNT;
							state <= #1 ST3;
						end
				end
				
			ST3:
				begin
					tx_10 <= #1 AB_N;
					count <= #1 count - 1;
					if(count[CW])
						begin
							count <= #1 COUNT;
							shift <= #1 {1'b0, shift[31:1]};
							
							b_num <= #1 b_num - 1;
							if(b_num[5])
								state <= #1 ST0;
							else
								state <= #1 ST2;
						end
				end
		endcase
	end

endmodule
`endif
