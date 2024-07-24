`default_nettype none

module mos6581 (
    input           clk_1MHz,
    input           reset,
	input     [7:0] addr,
	input     [7:0] data,
	input           wen,
    output   [15:0] wave_out
);

wire [11:0] voice_1_signal;
reg  [15:0] voice_1_freq                = 0;
reg  [11:0] voice_1_pulsewidth          = 0;
reg  [ 7:0] voice_1_control             = 0;
reg  [ 7:0] voice_1_attack_decay        = 0;
reg  [ 7:0] voice_1_sustain_release     = 0;
wire         voice_1_PA_MSB;

wire [11:0] voice_2_signal;
reg  [15:0] voice_2_freq                = 0;
reg  [11:0] voice_2_pulsewidth          = 0;
reg  [ 7:0] voice_2_control             = 0;
reg  [ 7:0] voice_2_attack_decay        = 0;
reg  [ 7:0] voice_2_sustain_release     = 0;
wire         voice_2_PA_MSB;

wire [11:0] voice_3_signal;
reg  [15:0] voice_3_freq                = 0;
reg  [11:0] voice_3_pulsewidth          = 0;
reg  [ 7:0] voice_3_control             = 0;
reg  [ 7:0] voice_3_attack_decay        = 0;
reg  [ 7:0] voice_3_sustain_release     = 0;
wire         voice_3_PA_MSB;

//reg  [15:0] filter_fc;
//reg  [ 7:0] filter_res_filt;
//reg  [ 7:0] filter_mode_vol;

assign wave_out = voice_1_signal;
//assign wave_out = voice_1_signal + voice_2_signal + voice_3_signal;

voice #()
    Voice1 (
        .clk_1MHz   (clk_1MHz),
        .reset      (reset),
        .frequency  (voice_1_freq),
        .pulsewidth (voice_1_pulsewidth),
        .control    (voice_1_control),
        .Att_dec    (voice_1_attack_decay),
        .Sus_Rel    (voice_1_sustain_release),
        .PA_MSB_in  (voice_3_PA_MSB),
        .PA_MSB_out (voice_1_PA_MSB),
        .voice      (voice_1_signal)
    );

voice #()
    Voice2 (
        .clk_1MHz   (clk_1MHz),
        .reset      (reset),
        .frequency  (voice_2_freq),
        .pulsewidth (voice_2_pulsewidth),
        .control    (voice_2_control),
        .Att_dec    (voice_2_attack_decay),
        .Sus_Rel    (voice_2_sustain_release),
        .PA_MSB_in  (voice_1_PA_MSB),
        .PA_MSB_out (voice_2_PA_MSB),
        .voice      (voice_2_signal)
    );

voice #()
    Voice3 (
        .clk_1MHz   (clk_1MHz),
        .reset      (reset),
        .frequency  (voice_3_freq),
        .pulsewidth (voice_3_pulsewidth),
        .control    (voice_3_control),
        .Att_dec    (voice_3_attack_decay),
        .Sus_Rel    (voice_3_sustain_release),
        .PA_MSB_in  (voice_2_PA_MSB),
        .PA_MSB_out (voice_3_PA_MSB),
        .voice      (voice_3_signal)
    );

always @(posedge clk_1MHz) begin
    if (wen)
        case (addr)
            8'b00000000: voice_1_freq[ 7:0]       <= data;
            8'b00000001: voice_1_freq[15:8]       <= data;
            8'b00000010: voice_1_pulsewidth[ 7:0] <= data;
            8'b00000011: voice_1_pulsewidth[11:8] <= data[3:0];
            8'b00000100: voice_1_control          <= data;
            8'b00000101: voice_1_attack_decay     <= data;
            8'b00000110: voice_1_sustain_release  <= data;

            8'b00000111: voice_2_freq[ 7:0]       <= data;
            8'b00001000: voice_2_freq[15:8]       <= data;
            8'b00001001: voice_2_pulsewidth[ 7:0] <= data;
            8'b00001010: voice_2_pulsewidth[11:8] <= data[3:0];
            8'b00001011: voice_2_control          <= data;
            8'b00001100: voice_2_attack_decay     <= data;
            8'b00001101: voice_2_sustain_release  <= data;

            8'b00001110: voice_3_freq[ 7:0]       <= data;
            8'b00001111: voice_3_freq[15:8]       <= data;
            8'b00010000: voice_3_pulsewidth[ 7:0] <= data;
            8'b00010001: voice_3_pulsewidth[11:8] <= data[3:0];
            8'b00010010: voice_3_control          <= data;
            8'b00010011: voice_3_attack_decay     <= data;
            8'b00010100: voice_3_sustain_release  <= data;

    //        8'b00010101: filter_fc[ 7:0]          <= data;
    //        8'b00010110: filter_fc[15:8]          <= data;
    //        8'b00010111: filter_res_filt          <= data;
    //        8'b00011000: filter_mode_vol          <= data;
            default: ;
        endcase
end

endmodule