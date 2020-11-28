`timescale 1ns / 1ps
/*
 * LEDS in arty z7 are numbered as:
 * ___________________________________________________________
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                                                         |
 * |                      5     4                            |
 * |                                                         |
 * |                                                         |
 * |                                          3   2   1   0  |
 * |                                                         |
 * |_________________________________________________________|
 */
// Drive all the leds with a basic 2-bit pwm. Not enough for smooth animations, designed primarly for simple status feedback.
// LED 5 and 4 are rgb. Currently always driven OFF.
// LED 3210 are green.
module artyz7_4level_leds(
  input clk,
	input[1:0] led[4],
	output pulse[4],
	
	// RGB requests. Here, led4 has index 0, led5 has index 1.
	input[1:0] red[2], green[2], blue[2], // currently ignored, provided for forward compatibility!
	output ored[2], ogreen[2], oblue[2]
);

for (genvar cp = 0; cp < 4; cp++) begin : mono
    led_4levels pwmer ( .clk(clk), .level(led[cp]), .onoff(pulse[cp]));
end

// RGB is currently unused, really.
for (genvar cp = 0; cp < 2; cp++) begin : rgb_is_hardwired
    assign ored[cp] = 1'b0;
    assign ogreen[cp] = 1'b0;
    assign oblue[cp] = 1'b0;
end


endmodule
