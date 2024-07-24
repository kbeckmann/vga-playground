module voice_tb();

reg clk = 0;

wire tb_clk_50kHz;
wire [11:0] voice1;
wire [11:0] voice2;

reg [15:0] frequency1 = 7382; // A4
reg [ 7:0] control1 = 8'b00100000;
reg [11:0] w = (1<<9);

voice #()
    Voice1(
        .clk_1MHz(clk),
        .frequency(frequency1),
        .pulsewidth(w),
        .control(control1),
        .PA_MSB_in(),
        .PA_MSB_out(),
        .signal(voice1)
    );

reg [15:0] frequency2 = 7382/4; // A3
reg [ 7:0] control2 = 8'b10000000;
voice #()
    Voice2(
        .clk_1MHz(clk),
        .frequency(frequency2),
        .pulsewidth(w),
        .control(control2),
        .PA_MSB_in(),
        .PA_MSB_out(),
        .signal(voice2)
    );

always 
    # 1 clk <= ~clk;

divider #(20)
    clk_50KHz (
        .clk_in(clk),
        .clk_out(tb_clk_50kHz)
    );

integer f1, f2, f3, i, crap;
reg [15:0] sum;
initial begin
    // Dumping all vars adds 5 seconds to the simulation.
    // $dumpfile("voice_tb.vcd");
    // $dumpvars(0, voice_tb);

    f1 = $fopen("voice1.raw", "wb");
    f2 = $fopen("voice2.raw", "wb");
    f3 = $fopen("mux.raw",    "wb");

    // 50k samples @ 50kHz sampling rate = 1s
    for (i = 0; i < 50000/2; i=i+1)
    begin
        @(posedge tb_clk_50kHz);
        begin
            // $fputc() is weird - arguments are (data, fd) instead of the other way around
            // Also, you have to handle the return value, or it will not compile.
            crap = $fputc(voice1[ 7:0], f1);
            crap = $fputc(voice1[11:8], f1);

            crap = $fputc(voice2[ 7:0], f2);
            crap = $fputc(voice2[11:8], f2);

            sum <= voice1 + voice2;
            crap = $fputc(sum[ 7:0], f3);
            crap = $fputc(sum[15:8], f3);
        end
    end

    $fclose(f1);
    $fclose(f2);
    $fclose(f3);

    $finish;
end

endmodule

