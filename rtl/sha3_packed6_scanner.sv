`timescale 1ns / 1ps

// A scanner dealing with the SHA3-packed-by-6 iterative hasher needs to be quite smarter than just dispatch
// like there's no tomorrow.
module sha3_packed6_scanner(
    input clk,
    // Scan request
    input start,
    input[63:0] threshold,
    input[31:0] blockTemplate[24],

    output ofound,
    output[63:0] ohash[25],
    output[31:0] ononce,
    // Status
    output odispatching, oevaluating, oready
);

wire feedgood, hasher_can_take, hashgood;
wire[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5];
wire[63:0] hasha[5], hashb[5], hashc[5], hashd[5], hashe[5];
sha3_scanner_control fsm (
    .clk(clk),
    .start(start), .threshold(threshold), .blockTemplate(blockTemplate),
    .ofound(ofound), .ohash(ohash), .ononce(ononce),
    .odispatching(odispatching), .oevaluating(oevaluating), .oready(oready),
    
    .hasher_ready(hasher_can_take),
    .feedgood(feedgood),
    .feeda(feeda), .feedb(feedb), .feedc(feedc), .feedd(feedd), .feede(feede),
    .hashgood(hashgood),
    .hasha(hasha), .hashb(hashb), .hashc(hashc), .hashd(hashd), .hashe(hashe)
);


sha3_iterating_pipe6 hasher (
    .clk(clk),
    .sample(feedgood),
    .rowa(feeda), .rowb(feedb), .rowc(feedc), .rowd(feedd), .rowe(feede),
    .gimme(hasher_can_take),
    .ogood(hashgood),
    .oa(hasha), .ob(hashb), .oc(hashc), .od(hashd), .oe(hashe)
);


endmodule
