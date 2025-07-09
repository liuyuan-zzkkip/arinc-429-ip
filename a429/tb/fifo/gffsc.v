`ifndef gffsc
`define gffsc

`include "a429/tb/fifo/dpram_sc.v"

`timescale 1ns/1ns

module gffsc
(
      clk
    , rst
    , clr
    , we
    , di
    , fl
	, af
    , re
    , do
    , vl
    , et
	, ae
    , cn
    , uc
	, wp
	, rp

// when write
	, over_run_o
	, over_run_c
// when read
	, underrun_o
	, underrun_c
);

parameter aw =  3;
parameter dw = 16;//non-meaningfull when WITH_RAM==0, but can not be zero
parameter FWFT = 1;// First Word Fall Through; non-meaningfull when WITH_RAM==0; also means register-output
parameter WITH_RAM = 1;

input clk;
input rst;// reset, active high
input clr;// clear, active high

input  [dw-1:0]   di;// data input
output [dw-1:0]   do;// data output

input             we;// write
input             re;// read

output            vl;// valid flag of do
output reg        fl;// full
output reg        et;// empty
output reg        af;// almost full
output reg        ae;// almost empty

output reg [aw:0] cn;// count
output reg [aw:0] uc;// space

output   [aw-1:0] wp;// write pointer
output   [aw-1:0] rp;// read  pointer

// when write
output reg over_run_o;
input      over_run_c;// clear
// when read
output reg underrun_o;
input      underrun_c;// clear

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//

wire we_protected = we & ~fl;
wire re_protected = re & ~et;

always @(posedge clk)
	if(rst)                 over_run_o <= #1 0;
	else if(over_run_c|clr) over_run_o <= #1 0;
	else if(we & fl)        over_run_o <= #1 1;

always @(posedge clk)
	if(rst)                 underrun_o <= #1 0;
	else if(underrun_c|clr) underrun_o <= #1 0;
	else if(re & et)        underrun_o <= #1 1;


////////////////////////////////////////////////////////////////////
//
// pointers
//

reg    [aw-1:0] wp;
wire   [aw-1:0] wp_pl1;
reg    [aw-1:0] rp;
wire   [aw-1:0] rp_pl1;

always @(posedge clk)
	if(rst)               wp <= #1 {aw{1'b0}};
	else if(clr)          wp <= #1 {aw{1'b0}};
	else if(we_protected) wp <= #1 wp_pl1;

assign wp_pl1 = wp + { {aw-1{1'b0}}, 1'b1 };

always @(posedge clk)
	if(rst)               rp <= #1 {aw{1'b0}};
	else if(clr)          rp <= #1 {aw{1'b0}};
	else if(re_protected) rp <= #1 rp_pl1;

assign rp_pl1 = rp + { {aw-1{1'b0}}, 1'b1};



////////////////////////////////////////////////////////////////////
//
// cn & uc
//

always @(posedge clk)
	if(rst)                                cn <= #1 {aw+1{1'b0}};
	else if(clr)                           cn <= #1 {aw+1{1'b0}};
	else if( re_protected & !we_protected) cn <= #1 cn + { {aw{1'b1}}, 1'b1};
	else if(!re_protected &  we_protected) cn <= #1 cn + { {aw{1'b0}}, 1'b1};

always @(posedge clk)
	if(rst)                                 uc <= #1 {1'b1, {aw{1'b0}}};
	else if(clr)                            uc <= #1 {1'b1, {aw{1'b0}}};
	else if( re_protected & !we_protected)	uc <= #1 uc + { {aw{1'b0}}, 1'b1};
	else if(!re_protected &  we_protected)	uc <= #1 uc + { {aw{1'b1}}, 1'b1};

////////////////////////////////////////////////////////////////////
//
// Registered Full & Empty Flags
//

// if zero, af=fl, ae=et
// if aw=1, ALMOST_TRIG_LEVEL=1, et=~af, fl=~ae
parameter ALMOST_TRIG_LEVEL = 1;

// fl: uc <= 0
// af: uc <= ALMOST_TRIG_LEVEL
// et: cn <= 0
// ae: cn <= ALMOST_TRIG_LEVEL

wire [aw-0:0] c0 = ALMOST_TRIG_LEVEL;
wire [aw-0:0] c1 = ALMOST_TRIG_LEVEL + 1;

always @(posedge clk)
	if(rst)                                               fl <= #1 1'b0;
	else if(clr)                                          fl <= #1 1'b0;
	else if(we_protected & !re_protected & (&cn[aw-1:0])) fl <= #1 1'b1;
	else if(re_protected & !we_protected                ) fl <= #1 1'b0;

always @(posedge clk)
	if(rst)                                                  af <= #1 (ALMOST_TRIG_LEVEL>=(1<<aw)) ? 1:0;
	else if(clr)                                             af <= #1 (ALMOST_TRIG_LEVEL>=(1<<aw)) ? 1:0;
	else if(we_protected & !re_protected & (uc[aw-0:0]==c1)) af <= #1 1'b1;
	else if(re_protected & !we_protected & (uc[aw-0:0]==c0)) af <= #1 1'b0;

always @(posedge clk)
	if(rst)                                                 et <= #1 1'b1;
	else if(clr)                                            et <= #1 1'b1;
	else if(we_protected & !re_protected                  ) et <= #1 1'b0;
	else if(re_protected & !we_protected & (cn[aw-1:0]==1)) et <= #1 1'b1;

always @(posedge clk)
	if(rst)                                                  ae <= #1 1'b1;
	else if(clr)                                             ae <= #1 1'b1;
	else if(we_protected & !re_protected & (cn[aw-0:0]==c0)) ae <= #1 1'b0;
	else if(re_protected & !we_protected & (cn[aw-0:0]==c1)) ae <= #1 1'b1;

////////////////////////////////////////////////////////////////////
//
// Memory Block
//

//==================================================================
generate
if(WITH_RAM) begin
//==================================================================
wire   [dw-1:0] do_temp;
reg    [dw-1:0] do_norm;
wire   [dw-1:0] do_fwft;

reg  vl_norm;
wire vl_fwft;

dpram_sc #(aw, dw) u_dpram_sc
(
    .ck   ( clk          ),
    .rd   ( 1'b1         ),
    .ra   ( rp           ),
    .dq   ( do_temp      ),

    .wr   ( we_protected ),
    .wa   ( wp           ),
    .di   ( di           )
);

always @(posedge clk)
	if(rst)               do_norm <= #1 0;
	else if(clr)          do_norm <= #1 0;
	else if(re_protected) do_norm <= #1 do_temp;

// if use re_protected, there is no vl, maybe cause state machine died.
always @(posedge clk)
	if(rst)      vl_norm <= #1 0;
	else if(clr) vl_norm <= #1 0;
	else         vl_norm <= #1 re;//re_protected;

assign do_fwft = do_temp;
assign vl_fwft = 1'b1;//et

assign do = FWFT ? do_fwft : do_norm;
assign vl = FWFT ? vl_fwft : vl_norm;
end
//==================================================================
else
//==================================================================
begin
assign do = 0;
assign vl = 1;
end
//==================================================================
endgenerate

endmodule
`endif





// module sim_gffsc();

// parameter aw =  2;
// parameter dw = 16;
// parameter FWFT = 0;//: First Word Fall Through
// parameter WITH_RAM = 1;

// reg         fft_wr;
// wire        fft_fl;
// reg         fft_rd;
// wire        fft_et;
// wire [aw:0] fft_cn;
// wire [aw:0] fft_uc;
// reg  [dw-1:0] fft_di;
// wire [dw-1:0] fft_do;

// reg rst_i;
// reg clk_i;

// initial begin
//       rst_i <= 1'b1;
//    #6 rst_i <= 0;
// end

// initial clk_i = 0;
// always #(1) clk_i = !clk_i;

// initial begin
// 	fft_rd = 0;
// 	fft_wr = 0;
// 	fft_di = 0;

// 	#14 fft_wr = 0;

// 	#20 fft_wr = 1;	fft_di = 1; #2 fft_wr = 0;
// 	#20 fft_wr = 1;	fft_di = 2; #2 fft_wr = 0;
// 	#20 fft_wr = 1;	fft_di = 3; #2 fft_wr = 0;
// 	#20 fft_wr = 1;	fft_di = 4; #2 fft_wr = 0;
// 	#20 fft_wr = 1;	fft_di = 5; #2 fft_wr = 0;

// #20
// 	// #20 fft_wr = 1;
// 	// #2 fft_wr = 0;

// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// // end

// // initial begin
// 	// fft_rd = 0;
// 	// fft_wr = 0;

// 	// #14 fft_wr = 0;

// 	#20 fft_wr = 1;	fft_di = 6; #2 fft_wr = 0;
// 	#20 fft_wr = 1;	fft_di = 7; #2 fft_wr = 0;
// 	#20 fft_wr = 1;	fft_di = 8; #2 fft_wr = 0;

// 	#20 fft_wr = 1;	fft_di = 9;
// 	    fft_rd = 1;
// 	#2  fft_wr = 0;
// 	    fft_rd = 0;

// 	#20 fft_wr = 1;	fft_di = 10;
// 	    fft_rd = 1;
// 	#2  fft_wr = 0;
// 	    fft_rd = 0;

// 	#20 fft_wr = 1;	fft_di = 11; #2 fft_wr = 0;

// #20
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;

// 	#20 fft_wr = 1;	fft_di = 12;
// 	    fft_rd = 1;
// 	#2  fft_wr = 0;
// 	    fft_rd = 0;

// 	#20 fft_wr = 1;	fft_di = 13;
// 	    fft_rd = 1;
// 	#2  fft_wr = 0;
// 	    fft_rd = 0;

// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// 	#20 fft_rd = 1;	#2 fft_rd = 0;
// end


// gffsc #(.aw(aw), .dw(dw), .FWFT(FWFT), .WITH_RAM(1)) gffsc_u
// (
// 	  .clk (clk_i)
// 	, .rst (rst_i)
// 	, .clr (rst_i)

// 	, .we  (fft_wr)
// 	, .re  (fft_rd)

// 	, .fl  (fft_fl)
// 	, .et  (fft_et)

// 	, .cn  (fft_cn)
// 	, .uc  (fft_uc)

//     , .di  (fft_di)
//     , .do  (fft_do)
//     , .vl  (fft_vl)

// 	, .wp  ()
// 	, .rp  ()
// );


// endmodule
