`timescale 1ns / 1ps

// Generic sha3 rounds have a second half where they appli chi+iota.
// The last round instead has a finalizer.
module sha3_generic_round_second_half#(
    OUTPUT_BUFFER = 0
)(
    input clk,
    input[4:0] round_index,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output[4:0] oround,
    output ogood
);

wire[63:0] toiotaa[5], toiotab[5], toiotac[5], toiotad[5], toiotae[5];
wire fetch_iota;
sha3_chi #(
    .STYLE("basic"),
    .OUTPUT_BUFFER(0),
    .INPUT_BUFFER(0) // it is critical CHI+IOTA have latency 0 or the last round will go awry
) chi (
    .clk(clk),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise), .sample(sample),
    .osa(toiotaa), .osb(toiotab), .osc(toiotac), .osd(toiotad), .ose(toiotae), .ogood(fetch_iota)
);

sha3_iterable_iota #(
    .OUTPUT_BUFFER(OUTPUT_BUFFER)
) iota (
   .clk(clk), .round_index(round_index),
   .isa(toiotaa), .isb(toiotab), .isc(toiotac), .isd(toiotad), .ise(toiotae), .sample(fetch_iota),
   .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ogood(ogood), .oround(oround)
);

endmodule
