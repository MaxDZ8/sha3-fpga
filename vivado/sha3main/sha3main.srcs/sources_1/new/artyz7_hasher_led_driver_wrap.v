`timescale 1ns / 1ps


module artyz7_hasher_led_driver_wrap (
    input clk, working, evaluating, found,
    output[3:0] omono
);

artyz7_hasher_led_driver really (
    .clk(clk), .working(working), .evaluating(evaluating), .found(found),
    .omono(omono)
);

endmodule
