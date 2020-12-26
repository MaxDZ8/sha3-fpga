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
	
  input[1:0] rgb4r, rgb4g, rgb4b,
  input[1:0] rgb5r, rgb5g, rgb5b,
  // 0=R, 1=G, 2=B
  output[2:0] orgb4, orgb5 
);

for (genvar cp = 0; cp < 4; cp++) begin : mono
    led_4levels pwmer ( .clk(clk), .level(led[cp]), .onoff(pulse[cp]));
end

led_4levels red4 ( .clk(clk), .level(rgb4r), .onoff(orgb4[0]));
led_4levels red5 ( .clk(clk), .level(rgb5r), .onoff(orgb5[0]));
led_4levels green4 ( .clk(clk), .level(rgb4g), .onoff(orgb4[1]));
led_4levels green5 ( .clk(clk), .level(rgb5g), .onoff(orgb5[1]));
led_4levels blue4 ( .clk(clk), .level(rgb4b), .onoff(orgb4[2]));
led_4levels blue5 ( .clk(clk), .level(rgb5b), .onoff(orgb5[2]));

endmodule
