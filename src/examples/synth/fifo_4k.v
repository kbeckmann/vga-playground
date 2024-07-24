`default_nettype none

module fifo_4k (
    input               clk_RAM,
    input               clk_write,
    input               clk_read,
	input        [31:0] fifo_wdata,
    output reg   [31:0] fifo_rdata = 0,
	input               fifo_wen,
	input               fifo_ren,
    output              fifo_full,
    output              fifo_empty,
    output              fifo_over_watermark,
    output reg          fifo_data_ready = 0
);
parameter           FIFO_LENGTH_BITS = 7;             // 2**7 = 128 32-bit words = 512 bytes = 4k bit
parameter           FIFO_LENGTH = 1<<FIFO_LENGTH_BITS;
parameter           FIFO_ADDR_MASK = FIFO_LENGTH - 1;
parameter           FIFO_WATERMARK = FIFO_LENGTH / 2 - 1;

// BlockRAM
reg             ram_wen = 0;
reg             ram_ren = 0;
reg       [7:0] ram_waddr = 0;
reg       [7:0] ram_raddr = 0;
reg      [31:0] ram_wdata = 0;
wire     [31:0] ram_rdata;

// Fifo specific
reg       [7:0] fifo_bottom_addr = 0;
reg             fifo_increase_bottom_addr = 0;
reg       [7:0] fifo_top_addr = 0;
wire      [7:0] fifo_entries = (FIFO_LENGTH + fifo_top_addr - fifo_bottom_addr) & FIFO_ADDR_MASK;
assign          fifo_full = fifo_entries == FIFO_LENGTH - 1;
assign          fifo_empty = fifo_entries == 0;
reg             fifo_empty_x = 0;
assign          fifo_over_watermark = fifo_entries > FIFO_WATERMARK;
reg             fifo_data_ready_buf = 0;
reg             fifo_wen_x;

blockram #()
    RAM0 (
        .clk(clk_RAM),
        .wen(ram_wen),
        .ren(ram_ren),
        .waddr(ram_waddr),
        .raddr(ram_raddr),
        .wdata(ram_wdata),
        .rdata(ram_rdata)
    );

always @(posedge clk_write) begin
    if (fifo_wen) begin
        fifo_top_addr <= (fifo_top_addr + 1 ) & FIFO_ADDR_MASK;
        ram_waddr <= fifo_top_addr;
        ram_wdata <= fifo_wdata;
        ram_wen <= 1;
    end else begin
        ram_wen <= 0;
    end
    if (fifo_full && !fifo_increase_bottom_addr)
        fifo_bottom_addr <= (fifo_top_addr + 2 ) & FIFO_ADDR_MASK;;
end

always @(posedge clk_write) begin
    if (fifo_increase_bottom_addr) begin
        fifo_bottom_addr <= (fifo_bottom_addr + 1) & FIFO_ADDR_MASK;
        fifo_increase_bottom_addr <= 0;
    end
end    

// Empty the FIFO using the 1MHZ clock to sync with the SID
always @(posedge clk_read) begin
    fifo_empty_x <= fifo_empty;
    if (fifo_ren) begin
        if (!fifo_empty)
            fifo_increase_bottom_addr <= 1;
        ram_raddr <= fifo_bottom_addr;
        fifo_rdata <= ram_rdata;
        ram_ren <= 1;
        { fifo_data_ready, fifo_data_ready_buf } <= {fifo_data_ready_buf, 1'b1};
    end else begin
        ram_ren <= 0;
        { fifo_data_ready, fifo_data_ready_buf } <= {fifo_data_ready_buf, 1'b0};
    end
end

endmodule