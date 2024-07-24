// https://www.reddit.com/r/yosys/comments/5aqzyr/can_i_write_behavioral_verilog_that_infers_ice40/d9imje6/

module blockram (
	input     	clk,
	input		wen,
	input		ren,
	input     	[ADDR_WIDTH-1:0] waddr,
	input     	[ADDR_WIDTH-1:0] raddr,
	input      	[WORDSIZE-1:0] wdata,
	output reg  [WORDSIZE-1:0] rdata
);
	parameter WORDSIZE = 32;
	parameter BLOCKS = 128;
	parameter ADDR_WIDTH = 8;

	reg [WORDSIZE-1:0] mem [0:BLOCKS-1];
	wire [WORDSIZE-1:0] data0 = mem[0];
	wire [WORDSIZE-1:0] data1 = mem[1];
	wire [WORDSIZE-1:0] data2 = mem[2];
	wire [WORDSIZE-1:0] data3 = mem[3];
	wire [WORDSIZE-1:0] datamax_0 = mem[BLOCKS-1];
	wire [WORDSIZE-1:0] datamax_1 = mem[BLOCKS-2];
	wire [WORDSIZE-1:0] datamax_2 = mem[BLOCKS-3];
	wire [WORDSIZE-1:0] datamax_3 = mem[BLOCKS-4];

	always @(posedge clk) begin
		if (wen)
			mem[waddr] <= wdata;
		if (ren)
			rdata <= mem[raddr];
	end
endmodule
