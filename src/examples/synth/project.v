/*
 * Public domain
 */

`default_nettype none

module tt_audio_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  output wire [15:0] audio_out, // Audio sample output
  output wire [31:0] clk_hz,    // clk frequency in Hz. Output consumed by simulator to adjust sampling rate (when to consume audio_out)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // assign clk_hz = 48000 * 21; // Close enough to 1MHz, but integer factor of 48kHz
  assign clk_hz = 1000000;
  
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
        .voice(voice1)
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
        .voice(voice2)
    );


    assign audio_out = voice2;

  
endmodule
