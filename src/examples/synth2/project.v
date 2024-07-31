/*
 * Apache 2
 * Based on https://github.com/rejunity/tt05-psg-ay8913
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
    parameter CHANNEL_OUTPUT_BITS = 8;
    parameter MASTER_OUTPUT_BITS = 8;

    wire reset = ! rst_n;

    // assign clk_hz = 48000 * 21; // Close enough to 1MHz, but integer factor of 48kHz
    assign clk_hz = 2000000;

    // wire [1:0] master_clock_control = 2'b01; // always on
    wire [1:0] master_clock_control = 2'b00; // Assume ~2 MHz

    reg [$clog2(128)-1:0] clk_counter;
    reg clk_master_strobe;
    always @(*) begin
        case(master_clock_control[1:0])
            2'b01:  clk_master_strobe = 1;                                  // no div, counters for tone & noise are always enabled
                                                                            // useful to speedup record.py
            2'b10:  clk_master_strobe = clk_counter[$clog2(128)-1:0] == 0;  // div 128, for TinyTapeout5 running 32..50Mhz
            default:
                    clk_master_strobe = clk_counter[$clog2(8)-1:0] == 0;    // div  8, for standard AY-3-819x 
                                                                            // running on 1.7 MHz .. 2 MHz frequencies
        endcase
    end

    reg restart_envelope;

    always @(posedge clk) begin
        if (reset) begin
            clk_counter <= 0;
            restart_envelope <= 0;
        end else begin
            clk_counter <= clk_counter + 1;                 // provides clk_master_strobe for tone, noise and envelope
        end
    end


    reg [11:0]  tone_period_A = 12'h200; // 0x000 -> 0x7FF
    reg [11:0]  tone_period_B = 12'h100;
    reg [11:0]  tone_period_C = 12'h080;
    reg [4:0]   noise_period;
    reg         tone_disable_A = 1'b0; // flip here to make tones
    reg         tone_disable_B = 1'b1;
    reg         tone_disable_C = 1'b1;
    reg         noise_disable_A = 1'b1; // flip here to make noise
    reg         noise_disable_B = 1'b1;
    reg         noise_disable_C = 1'b1;
    reg         envelope_A;
    reg         envelope_B;
    reg         envelope_C;
    reg [3:0]   amplitude_A = 4'b1000;
    reg [3:0]   amplitude_B = 4'b1000;
    reg [3:0]   amplitude_C = 4'b1000;
    reg [15:0]  envelope_period;
    reg         envelope_continue;
    reg         envelope_attack;
    reg         envelope_alternate;
    reg         envelope_hold;


    // Tone, noise & envelope generators
    wire tone_A, tone_B, tone_C, noise;
    tone #(.PERIOD_BITS(12)) tone_A_generator (
        .clk(clk),
        .enable(clk_master_strobe),
        .reset(reset),
        .period(tone_period_A),
        .out(tone_A)
        );
    tone #(.PERIOD_BITS(12)) tone_B_generator (
        .clk(clk),
        .enable(clk_master_strobe),
        .reset(reset),
        .period(tone_period_B),
        .out(tone_B)
        );
    tone #(.PERIOD_BITS(12)) tone_C_generator (
        .clk(clk),
        .enable(clk_master_strobe),
        .reset(reset),
        .period(tone_period_C),
        .out(tone_C)
        );

    noise #(.PERIOD_BITS(5)) noise_generator (
        .clk(clk),
        .enable(clk_master_strobe),
        .reset(reset),
        .period(noise_period),
        .out(noise)
        );

    wire [3:0] envelope; // NOTE: Y2149 envelope outputs 5 bits, but programmable amplitude is only 4 bits!
    envelope #(.PERIOD_BITS(16), .ENVELOPE_BITS(4)) envelope_generator (
        .clk(clk),
        .enable(clk_master_strobe),
        .reset(reset | restart_envelope),
        .continue_(envelope_continue),
        .attack(envelope_attack),
        .alternate(envelope_alternate),
        .hold(envelope_hold),
        .period(envelope_period),
        .out(envelope)
        );

    // FROM https://github.com/mamedev/mame/blob/master/src/devices/sound/ay8910.cpp ay8910_device::sound_stream_update
    // The 8910 has three outputs, each output is the mix of one of the three
    // tone generators and of the (single) noise generator. The two are mixed
    // BEFORE going into the DAC. The formula to mix each channel is:
    // (ToneOn | ToneDisable) & (NoiseOn | NoiseDisable).
    // Note that this means that if both tone and noise are disabled, the output
    // is 1, not 0, and can be modulated changing the volume.
    wire channel_A = (tone_disable_A | tone_A) & (noise_disable_A | noise);
    wire channel_B = (tone_disable_B | tone_B) & (noise_disable_B | noise);
    wire channel_C = (tone_disable_C | tone_C) & (noise_disable_C | noise);

    wire [CHANNEL_OUTPUT_BITS-1:0] volume_A, volume_B, volume_C;
    attenuation #(.VOLUME_BITS(CHANNEL_OUTPUT_BITS)) attenuation_A ( // @TODO: rename to amplitude to match docs
        .in(channel_A),
        .control(envelope_A ? envelope: amplitude_A),
        .out(volume_A)
        );
    attenuation #(.VOLUME_BITS(CHANNEL_OUTPUT_BITS)) attenuation_B (
        .in(channel_B),
        .control(envelope_B ? envelope: amplitude_B),
        .out(volume_B)
        );
    attenuation #(.VOLUME_BITS(CHANNEL_OUTPUT_BITS)) attenuation_C (
        .in(channel_C),
        .control(envelope_C ? envelope: amplitude_C),
        .out(volume_C)
        );

    // @TODO: divide master by 3 instead of 2
    localparam MASTER_ACCUMULATOR_BITS = CHANNEL_OUTPUT_BITS + 1;
    localparam MASTER_MAX_OUTPUT_VOLUME = {MASTER_OUTPUT_BITS{1'b1}};
    wire [MASTER_ACCUMULATOR_BITS-1:0] master;
    wire master_overflow;
    assign { master_overflow, master } = volume_A + volume_B + volume_C; // sum all channels
    assign uo_out[MASTER_OUTPUT_BITS-1:0] = 
        (master_overflow == 0) ? master[MASTER_ACCUMULATOR_BITS-1 -: MASTER_OUTPUT_BITS] :  // pass highest MASTER_OUTPUT_BITS to the DAC output pins
                                 MASTER_MAX_OUTPUT_VOLUME;                                  // ALSO prevent value wraparound in the master output


    // assign audio_out = master;
    assign audio_out = master << 7;

  
endmodule
