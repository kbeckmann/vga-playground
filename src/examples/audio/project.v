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

  assign clk_hz = 48000 * 32; // Tell simulator to use a low frequency, integer factor of 48000. Faster, no glitches.

  reg [31:0] counter;
  wire [15:0] triangle = counter[11] ? -(counter << 4) : (counter << 4);
  wire [15:0] saw = counter << 4;
  // assign audio_out = counter[19] ? triangle : saw;
  assign audio_out = triangle;
  // assign audio_out = saw;

  always @(posedge clk) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  
endmodule
