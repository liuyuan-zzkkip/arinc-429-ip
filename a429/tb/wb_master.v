
`timescale 1ns/1ns

module wb_master
(
	  rst_i
	, clk_i

	// Wishbone bus interface
	, cyc_o
	, stb_o
	, adr_o
	, wnr_o
	, dat_o
	, dat_i
	, ack_i
);

input  rst_i;
input  clk_i;

output            cyc_o;
output reg        stb_o;
output reg [ 1:0] adr_o;
output reg        wnr_o;
output reg [31:0] dat_o;
input      [31:0] dat_i;
input             ack_i;





localparam st0 = 0;
localparam st1 = 1;
localparam st2 = 2;
localparam st3 = 3;
reg [1:0] state;

assign cyc_o = stb_o;

always @(posedge clk_i)
if(rst_i)
	begin
		stb_o <= #1 0;
		state <= #1 st0;
	end
else
	begin
		case(state)	// synthesis parallel_case
			st0:
				begin
					stb_o <= #1 1;
					adr_o <= #1 1;
					wnr_o <= #1 1;
					dat_o <= #1 'h3b;
					if(stb_o & ack_i)
						begin
							stb_o <= #1 0;
							state <= #1 st1;
						end
				end

			st1:
				begin
					stb_o <= #1 1;
					adr_o <= #1 0;
					wnr_o <= #1 1;
					dat_o <= #1 'h5555_5555;
					if(stb_o & ack_i)
						begin
							stb_o <= #1 0;
							state <= #1 st2;
						end
				end
				
			st2:
				begin
					stb_o <= #1 1;
					adr_o <= #1 0;
					wnr_o <= #1 1;
					dat_o <= #1 'haaaa_aaaa;
					if(stb_o & ack_i)
						begin
							stb_o <= #1 0;
							state <= #1 st3;
						end
				end

			st3:
				begin
					
				end
		endcase
	end

endmodule