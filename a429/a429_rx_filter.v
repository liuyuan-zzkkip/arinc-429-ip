// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Filter for Rx Module
// Revision   : v1.3
// =============================================================================
`ifndef	A429_RX_FILTER
`define	A429_RX_FILTER

`include "a429/bit_width_utils.v"

`timescale 1ns/1ns

module A429_RX_FILTER
(
	  rst_i
	, clk_i
	, dat_i
	, dat_o
	, spd_i
);

parameter CLOCK_KHZ = 100*1000;

input  rst_i;
input  clk_i;
input  spd_i;
input  dat_i;
output dat_o;
reg    dat_o;

localparam MAX_COUNT = 8*CLOCK_KHZ*3/1000-2;
localparam CM = `calc_cw(MAX_COUNT);

reg [ 0:0] state;
reg [CM:0] count;

localparam st0 = 0;
localparam st1 = 1;

always @(posedge clk_i)
if(rst_i)
	begin
		dat_o <= #1 0;
		count <= #1 0;
		state <= #1 st0;
	end
else
	begin
		count <= #1 count - 1;

		case(state)	// synthesis parallel_case
			st0:
				begin
					count <= #1 spd_i ? (CLOCK_KHZ*3/1000-2):(8*CLOCK_KHZ*3/1000-2);

					if(dat_o != dat_i)
						state <= #1 st1;
				end
			
			st1:
				begin
					if(dat_o == dat_i)
						begin
							state <= #1 st0;
						end
					else if(count[CM])
						begin
							dat_o <= #1 ~dat_o;
							state <= #1 st0;
						end
				end
		endcase
	end

endmodule
`endif
