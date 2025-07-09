`ifndef dpram_sc
`define dpram_sc

`timescale 1ns/1ns

module dpram_sc
(
ck, 
rd, ra, dq,
wr, wa, di
);

parameter aw = 2;
parameter dw = 8;

input           ck;

input           rd;
input  [aw-1:0] ra;
output [dw-1:0] dq;

input           wr;
input  [aw-1:0] wa;
input  [dw-1:0] di;

reg [dw-1:0] mem [(1<<aw) -1:0];

assign dq = mem[ra];

always @(posedge ck)
    if(wr)
        mem[wa] <= #1 di;

endmodule
`endif