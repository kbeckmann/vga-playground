module mos6581_buffered_player (
    input           clk_HF,
    input           clk_1MHz,
    input           reset,
	input    [31:0] data,
	input           wen,
    output   [15:0] wave_out
);

reg   [7:0] sid_addr = 0;
reg   [7:0] sid_data = 0;
reg         sid_wen = 0;
reg  [31:0] fifo_wdata = 0;
wire [31:0] fifo_rdata;
reg         fifo_wen = 0;
reg         fifo_ren = 0;
reg  [1:0]   fifo_ren_buf = 0;
wire        fifo_full;
wire        fifo_empty;
reg   [1:0] fifo_empty_buf;
wire        fifo_over_watermark;
wire        fifo_data_ready;

mos6581 #()
    SID (
        .clk_1MHz(clk_1MHz),
        .reset(reset),
        .addr(sid_addr),
        .data(sid_data),
        .wen(sid_wen),
        .wave_out(wave_out)
    );

fifo_4k #()
    FIFO (
        .clk_RAM(clk_HF),
        .clk_write(clk_HF),
        .clk_read(clk_1MHz),
        .fifo_wdata(fifo_wdata),
        .fifo_rdata(fifo_rdata),
        .fifo_wen(fifo_wen),
        .fifo_ren(fifo_ren),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_over_watermark(fifo_over_watermark),
        .fifo_data_ready(fifo_data_ready)
    );

always @(posedge clk_HF) begin
    if (wen) begin
        sid_addr <= data[15:8];
        sid_data <= data[7:0];
        sid_wen  <= 1; // can keep it high cause addr/data is kept with sane inputs
    end
end

/*
// Put data in the FIFO
always @(posedge clk_HF) begin
    if (wen) begin
        fifo_wdata <= data;
        fifo_wen <= 1;
    end else begin
        fifo_wen <= 0;
    end
end

always @(posedge clk_1MHz)
    if (reset)
        fifo_ren <= 0;
    else
        fifo_ren <= 1;

always @(posedge clk_1MHz) begin
    fifo_empty_buf <= {fifo_empty_buf[0], fifo_empty};
    if (fifo_data_ready && !fifo_empty_buf[1]) begin
        sid_addr <= fifo_rdata[15:8];
        sid_data <= fifo_rdata[7:0];
        sid_wen <= 1;
    end else
        sid_wen <= 0;
end

*/

endmodule