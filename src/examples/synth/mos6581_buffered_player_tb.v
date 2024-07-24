//`default_nettype none

module mos6581_buffered_player_tb();

`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal(%x) != value(%x)", signal, value); \
            $finish; \
        end

reg             clk_12MHz = 0;
wire            clk_1MHz;
reg             reset = 1;
reg      [31:0] data = 0;
reg             wen = 0;
wire     [15:0] wave_out;

divider #(12)
    divider_12 (
        .clk_in(clk_12MHz),
        .clk_out(clk_1MHz)
    );

mos6581_buffered_player #()
    Player (
        .clk_HF(clk_12MHz),
        .clk_1MHz(clk_1MHz),
        .reset(reset),
        .data(data),
        .wen(wen),
        .wave_out(wave_out)
);

always
    # 1 clk_12MHz <= ~clk_12MHz;

integer i;
initial begin
    // Dumping all vars adds a few seconds to the simulation.
    $dumpfile("mos6581_buffered_player_tb.vcd");
    $dumpvars(0, mos6581_buffered_player_tb);

    # 4 reset <= 0;

    @(posedge clk_12MHz);

    // Sleep for 0x10 clock cycles
    // Set freq on voice 1 to 0x6581
    // Fill the FIFO
    data = 32'h0010_01_65;
    wen <= 1;
    @(posedge clk_12MHz);
    wen <= 0;

    // Fill the FIFO
    data = 32'h0010_00_81;
    wen <= 1;
    @(posedge clk_12MHz);
    wen <= 0;

    # 200 ;
    // Fill the FIFO with sawtooth on voice 1
    data = 32'h007f_04_10;
    wen <= 1;
    @(posedge clk_12MHz);
    wen <= 0;

    # 100000 $display("Finished");

    $finish;
end

endmodule
