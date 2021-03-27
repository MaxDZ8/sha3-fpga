`timescale 1ns / 1ps

// Give me the signals from the hasher and I'll automagically convert it to LED signals
// so you can have some feedback of the hashing process.
module artyz7_hasher_led_driver(
    input clk,
    input dispatching, evaluating, idle,
    input found,
    output[3:0] omono,
    // 0=R, 1=G 2=B
    output[2:0] orgb4, orgb5 
);


// Let me move away from any possible congestion first...
bit buff_dispatching = 1'b0, buff_evaluating = 1'b0, buff_found = 1'b0, buff_idle;
always_ff @(posedge clk) buff_dispatching <= dispatching;
always_ff @(posedge clk) buff_evaluating <= evaluating;
always_ff @(posedge clk) buff_found <= found;
always_ff @(posedge clk) buff_idle <= idle;

bit[23:0] count = 24'b0; // counts up to 8_388_607, 8Mi-1, top bit is used as easy reset
always @(posedge clk) if(buff_evaluating) begin
    if(count[23]) count <= 24'b0;
    else count <= count + 1'b1;
end

// Green "scan" leds. //////////////////////////////////////////////////////
bit[1:0] brigthness = 2'h0;
bit[1:0] which = 2'b0;

always_ff @(posedge clk) if(buff_evaluating & count[23]) begin
    brigthness <= brigthness + 1'b1;
    if (brigthness == 2'h3) which <= which + 1'b1;
end

wire[1:0] led0 = which == 2'h3 ? brigthness : 2'h0; // leds are physically in reverse order
wire[1:0] led1 = which == 2'h2 ? brigthness : 2'h0;
wire[1:0] led2 = which == 2'h1 ? brigthness : 2'h0;
wire[1:0] led3 = which == 2'h0 ? brigthness : 2'h0; 


// RGB4, status led ///////////////////////////////////////////////////////////////////////
// RED: on when idle. ---------------------------------------------------------------------
// Now fetched from IP.

// GREEN: blinks when started. ------------------------------------------------------------
bit was_dispatching = 1'b0;
always_ff @(posedge clk) was_dispatching <= buff_dispatching; // misnamed
wire started = ~was_dispatching & buff_dispatching;

shortint unsigned since_start = 16'h0;
bit just_started = 1'b0;
always_ff @(posedge clk) begin
     if (~just_started) just_started <= started;
     else begin
         since_start <= since_start + 1'b1;
         just_started <= since_start != 16'hFFFF;
     end
end

// BLUE: blinks when something found. -----------------------------------------------------
shortint unsigned since_found = 16'h0;
bit just_found = 1'b0;
always_ff @(posedge clk) begin
     if (~just_found) just_found <= buff_found;
     else begin
         since_found <= since_found + 1'b1;
         just_found <= since_found != 16'hFFFF;
     end
end

wire[1:0] tied = 2'b0;
wire[1:0] idle_level = { idle & ~just_found, 1'b0 };

artyz7_4level_leds pwm_them (
  .clk(clk),
  .led('{ led0, led1, led2, led3 }), .pulse('{ omono[0], omono[1], omono[2], omono[3] }),
  
  .rgb4r(idle_level), .rgb4g({ just_started, just_started }), .rgb4b({ 1'b0, just_found }),
  .orgb4(orgb4),
  .rgb5r(tied), .rgb5g(tied), .rgb5b(tied),
  .orgb5(orgb5) 
);

endmodule
