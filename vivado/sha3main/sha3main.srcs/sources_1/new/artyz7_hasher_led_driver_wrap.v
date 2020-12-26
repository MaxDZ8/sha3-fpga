`timescale 1ns / 1ps


module artyz7_hasher_led_driver_wrap (
    input clk, dispatching, evaluating, idle, found,
    output[3:0] omono,
    output[2:0] orgb4, orgb5
);

artyz7_hasher_led_driver really (
    .clk(clk), .dispatching(dispatching), .evaluating(evaluating), .found(found), .idle(idle),
    .omono(omono),
    .orgb4(orgb4), .orgb5(orgb5) 
);

endmodule
