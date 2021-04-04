`timescale 1ns / 1ps

// SHA3 round function which can be iterated.
// Always performs THETA, RHO+PI, CHI, IOTA(i).
module sha3_iterable_round #(
    CAPTURE_CONTINUOUSLY = 1,
    OUTPUT_BUFFER = 0
) (
    input clk,
    input[4:0] round_index,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output[4:0] oround,
    output ogood
);


wire[63:0] tochia[5], tochib[5], tochic[5], tochid[5], tochie[5];
wire fetch_chi;
wire[4:0] rndaft_semi;
sha3_iterable_semiround #(
    .CAPTURE_CONTINUOUSLY(CAPTURE_CONTINUOUSLY)
) simply(
    .clk(clk), .round_index(round_index), .sample(sample),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    
    .osa(tochia), .osb(tochib), .osc(tochic), .osd(tochid), .ose(tochie),
    .oround(rndaft_semi), .ogood(fetch_chi)
);
assign oround = rndaft_semi; // everything below must have latency 0


sha3_generic_round_second_half #(
    .OUTPUT_BUFFER(OUTPUT_BUFFER)
) usual (
    .clk(clk), .round_index(rndaft_semi), .sample(fetch_chi),
    .isa(tochia), .isb(tochib), .isc(tochic), .isd(tochid), .ise(tochie),
    
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose),
    .ogood(ogood),
    .oround(oround)
);

endmodule
