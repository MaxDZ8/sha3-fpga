`timescale 1ns / 1ps

// Give me the signals from the hasher and I'll automagically convert it to LED signals
// so you can have some feedback of the hashing process.
module artyz7_hasher_led_driver(
    input clk,
    input working,
    input evaluating,
    input found,
    output[3:0] omono
);


// Let me move away from any possible congestion first...
bit buff_working = 1'b0, buff_evaluating = 1'b0, buff_found = 1'b0;
always_ff @(posedge clk) buff_working <= working;
always_ff @(posedge clk) buff_evaluating <= evaluating;
always_ff @(posedge clk) buff_found <= found;

bit[23:0] count = 24'b0; // 8_388_607 hashes, 8Mi-1, top bit is used as easy reset
always @(posedge clk) if(buff_evaluating) begin
    if(count[23]) count <= 24'b0;
    else count <= count + 1'b1;
end

bit[1:0] led_on = 1'b0;
bit fullbrigth = 1'b0;
always_ff @(posedge clk) if(buff_evaluating & count[23]) begin
    if (fullbrigth) begin
        led_on <= led_on + 1'b1;
        fullbrigth <= 1'b0; 
    end
    else fullbrigth <= 1'b1;
end

wire[1:0] led0 = led_on != 2'h3 ? 2'b0 : { fullbrigth, 1'b1 }; 
wire[1:0] led1 = led_on != 2'h2 ? 2'b0 : { fullbrigth, 1'b1 }; 
wire[1:0] led2 = led_on != 2'h1 ? 2'b0 : { fullbrigth, 1'b1 }; 
wire[1:0] led3 = led_on != 2'h0 ? 2'b0 : { fullbrigth, 1'b1 }; // leds are in reverse order physically 

artyz7_4level_leds pwm_them (
  .clk(clk),
  .led('{ led0, led1, led2, led3 }), .pulse('{ omono[0], omono[1], omono[2], omono[3] }),
  
  .red('{ 2{ 1'b0 } }), .green('{ 2{ 1'b0 } }), .blue('{ 2{ 1'b0 } })
	//output ored[2], ogreen[2], oblue[2]
);

endmodule
