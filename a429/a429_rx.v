
// =============================================================================
// Copyright (c) 2025 Tianjin Deepspace Smartcore Technology Co., Ltd.
// 天津深空智核科技有限公司
// https://www.zzkkip.cn
// SPDX-License-Identifier: MIT
// File       : a429_top.v
// Author     : LiuYuan
// Description: ARINC429 Protocol Controller - Rx Module
// Revision   : v1.1
// =============================================================================
`ifndef A429_RX
`define A429_RX

`include "a429/bit_width_utils.v"
`include "a429/a429_rx_filter.v"

`timescale 1ns/1ns

module A429_RX
(
	  rst_i
	, clk_i

	, rf_wr
	, rf_di
	, rf_fl

	, rx_ena
	, hi_spd // 1: 100kbps, 0: 12.5kbps
	, rx_ab_i
);

parameter CLOCK_KHZ = 100*1000;

input rst_i;
input clk_i;

output reg        rf_wr;
output reg [31:0] rf_di;
input             rf_fl;

input rx_ena;
input hi_spd;
input [1:0] rx_ab_i;

// preprocessing
//===================================================================
reg  [1:0] ab_1 = 0;
reg  [1:0] ab_2 = 0;
wire [1:0] ab;

always @(posedge clk_i)
begin
	ab_2 <= #1 ab_1;
	ab_1 <= #1 rx_ab_i;
end
A429_RX_FILTER #(.CLOCK_KHZ(CLOCK_KHZ)) filter_A
(
	  .rst_i (rst_i)
	, .clk_i (clk_i)
	, .dat_i (ab_2[0])
	, .dat_o (ab[0])
	, .spd_i (hi_spd)
);
A429_RX_FILTER #(.CLOCK_KHZ(CLOCK_KHZ)) filter_B
(
	  .rst_i (rst_i)
	, .clk_i (clk_i)
	, .dat_i (ab_2[1])
	, .dat_o (ab[1])
	, .spd_i (hi_spd)
);

reg  ab_xor     = 0;
reg  ab_xor_reg = 0;
reg  ab_xor_pe  = 0;
reg  ab_value   = 0;

always @(posedge clk_i)
begin
	ab_xor_reg <= #1 ab_xor;
	ab_xor <= #1 ^ab;
	ab_xor_pe <= #1 ~ab_xor_reg & ab_xor;
	ab_value <= #1 ab[1];
end


// state machine
//===================================================================
localparam AB_1 = 2'b10;
localparam AB_0 = 2'b01;
localparam AB_N = 2'b00;

localparam st0 = 0;
localparam st1 = 1;
localparam st2 = 2;
localparam st3 = 3;

reg[ 1:0] state;
reg[ 5:0] c_bit;
reg[31:0] shift;
reg       chkTO;// check time-out

localparam BIT_CYCLES_100K = CLOCK_KHZ*10/1000;
localparam MAX_COUNT = 8*BIT_CYCLES_100K*2/1-2;
localparam CM = `calc_cw(MAX_COUNT);

reg [CM  :0] count;
wire[CM-1:0] MAX_GAP_TIME;
wire[CM-1:0] MAX_BIT_TIME;

assign MAX_GAP_TIME = hi_spd ? (BIT_CYCLES_100K*2/1-2):(8*BIT_CYCLES_100K*2/1-2);//2.0bit
assign MAX_BIT_TIME = hi_spd ? (BIT_CYCLES_100K*3/2-2):(8*BIT_CYCLES_100K*3/2-2);//1.5bit

always @(posedge clk_i)
if(rst_i)
	begin
		rf_wr <= #1 0;
		state <= #1 st0;
	end
else
	begin
		rf_wr <= #1 0;

		if(ab_xor_pe)
			begin
				chkTO <= #1 1;

				shift <= #1 {ab_value, shift[31:1]};
				c_bit <= #1 c_bit - 1;
			end
			
		case(state)	// synthesis parallel_case
			st0:
				begin
					count <= #1 MAX_GAP_TIME;

					if(rx_ena)
						begin
							if(ab == AB_N)
								state <= #1 st1;
						end
				end

			st1:
				begin
					c_bit <= #1 32-2;
					chkTO <= #1 0;
					count <= #1 count - 1;
					if(ab == AB_N)
						begin
							if(count[CM])
								begin
									count <= #1 MAX_BIT_TIME;
									state <= #1 st2;
								end
						end
					else
						begin
							state <= #1 st0;
						end
				end

			st2:
				begin
					count <= #1 count - 1;
					if(ab_xor_pe)
						begin
							count <= #1 MAX_BIT_TIME;

							if(c_bit[5])
								state <= #1 st3;
						end
					else if(chkTO & count[CM])
						begin
							state <= #1 st0;
						end
				end

			st3:
				begin
					rf_di[ 7]    <= #1 shift[ 0];
					rf_di[ 6]    <= #1 shift[ 1];
					rf_di[ 5]    <= #1 shift[ 2];
					rf_di[ 4]    <= #1 shift[ 3];
					rf_di[ 3]    <= #1 shift[ 4];
					rf_di[ 2]    <= #1 shift[ 5];
					rf_di[ 1]    <= #1 shift[ 6];
					rf_di[ 0]    <= #1 shift[ 7];
					rf_di[31:11] <= #1 shift[28:8];
					rf_di[ 9]    <= #1 shift[29];
					rf_di[10]    <= #1 shift[30];
					rf_di[ 8]    <= #1 ^shift ? 0:1;// parity: ODD

					rf_wr <= #1 ~rf_fl;
					state <= #1 st0;
				end
		endcase
	end

endmodule
`endif

