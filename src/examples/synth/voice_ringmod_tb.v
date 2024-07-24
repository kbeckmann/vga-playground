module voice_ringmod_tb();

reg clk = 0;

wire tb_clk_50kHz;
wire [11:0] voice1;
wire [11:0] voice2;

reg [15:0] frequency1 = 7382/8;
reg [ 7:0] control1 = 8'b00010000; // sawtooth
reg [11:0] pulsewidth1 = (1<<9);
wire ringmod_connect;

voice #()
    Voice1(
        .clk_1MHz(clk),
        .frequency(frequency1),
        .pulsewidth(pulsewidth1),
        .control(control1),
        .PA_MSB_in(),
        .PA_MSB_out(ringmod_connect),
        .signal(voice1)
    );

reg [15:0] frequency2 = 7382/4; // will change this during simulation!
reg [ 7:0] control2 = 8'b00100100; // triangle | ringmod
reg [11:0] pulsewidth2 = (1<<9);
voice #()
    Voice2(
        .clk_1MHz(clk),
        .frequency(frequency2),
        .pulsewidth(pulsewidth2),
        .control(control2),
        .PA_MSB_in(ringmod_connect),
        .PA_MSB_out(),
        .signal(voice2)
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

    f = $fopen("voice_ringmod.raw", "wb");

    // 50k samples @ 50kHz sampling rate = 1s
    // Playback using: ffplay -f s16le -ar 50k -ac 1 voice_ringmod.raw
    for (i = 0; i < 50000*2; i=i+1)
    begin
        @(posedge tb_clk_50kHz);
        begin
            // The return value has to be handled, or it will not compile.
            upscaled <= voice2 << 3;
            ret = $fputc(upscaled[ 7:0], f);
            ret = $fputc(upscaled[15:8], f);

            // Increment the frequency a bit over time to get a sweet sound.
            if (i & 31 == 0)
                frequency2 <= frequency2 + 1;
        end
    end

    $fclose(f);
    $finish;
end

endmodule

