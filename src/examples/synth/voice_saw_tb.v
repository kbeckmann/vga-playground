module voice_saw_tb();

reg clk = 0;

wire tb_clk_50kHz;
wire [11:0] voice1;

reg [15:0] frequency1 = 7382; // A4
reg [ 7:0] control1 = 8'b00010000;
reg [11:0] pulsewidth = (1<<9);

voice #()
    Voice1(
        .clk_1MHz(clk),
        .frequency(frequency1),
        .pulsewidth(pulsewidth),
        .control(control1),
        .PA_MSB_in(),
        .PA_MSB_out(),
        .signal(voice1)
    );

always
    # 1 clk <= ~clk;

// Used to get 50kHz sampling rate on the output
divider #(20)
    clk_50KHz (
        .clk_in(clk),
        .clk_out(tb_clk_50kHz)
    );

integer f, i, ret;
reg [15:0] upscaled;
initial begin
    // Dumping all vars adds a few seconds to the simulation.
    // $dumpfile("voice_tb.vcd");
    // $dumpvars(0, voice_tb);

    f = $fopen("voice_saw.raw", "wb");

    // 50k samples @ 50kHz sampling rate = 1s
    // Playback using: ffplay -f s16le -ar 50k -ac 1 voice_tri.raw
    for (i = 0; i < 50000; i=i+1)
    begin
        @(posedge tb_clk_50kHz);
        begin
            // The return value has to be handled, or it will not compile.
            upscaled <= voice1 << 3;
            ret = $fputc(upscaled[ 7:0], f);
            ret = $fputc(upscaled[15:8], f);
        end
    end

    $fclose(f);
    $finish;
end

endmodule

