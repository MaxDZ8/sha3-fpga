`timescale 1ns / 1ps
// Tick a led. Not quite PWM. For example, PWM 50% is something like:
// ------------PERIOD--------------
// ------DUTY------
// ||||||||||||||||________________||||||||||||||||________________
// Whereas our 50% is:
// |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_
// PWM works high frequency but then due to the long pulses it effectively reduces the blink frequency.
// By contrast, I try to leave the "on" time fixed at the fastest possible.
// Give me ~100MHZ clock. Will be reduced to some appropriate 'blink' frequency.
// Control brightness level using the .level port
// 00 - OFF
// 01 - WEAK (aka FAINT), probably unsuitable for most purposes but visible in the dark.
// 10 - ON. Suggested setting for normal operation.
// 11 - FULLBRIGHT  some boards are uncomfortable at this brightness level but it is appropriate for blink,
//      emphasis, get more attention.
// Leds can flip in the Mhz with ease, but the driving transistors might distort a lot.
// Contemporary (Dec 2020) LED dimmers go 100khz - 1Mhz. 
module led_4levels #(
    shortint unsigned FAINT = 16'b1000_0000_1000_0000, // 12.5%
    shortint unsigned ON    = 16'b1010_1000_1010_1000 // 25% + 12.5% = 37.5%
) (
    input clk,
    input[1:0] level,
    output onoff
);

// Buffering inputs for maximum P&R liberty.
bit[1:0] wanted = 2'b0;
always_ff @(posedge clk) wanted <= level;

bit[7:0] divisor = 8'b0;
always_ff @(posedge clk) divisor <= divisor + 1'b1;

wire tick = divisor == 8'hFF; // 100Mhz --> 390.625Khz, a bit overkill but ok-ish.

bit[3:0] index = 4'b0;
always_ff @(posedge clk) if(tick) index <= index + 1'b1;


wire now = wanted[1] ? (wanted[0] ? 1'b1 : ON[index]) : (wanted[0] ? FAINT[index] : 1'b0);

	
// Also buffering outputs really place me as you better see fit!
bit buffout = 1'b0;
always_ff @(posedge clk) buffout <= now;
assign onoff = buffout;

endmodule
