`timescale 1ns / 1ps

// Iota just xors s[0] with a round constant.
// The constant is just a few bits here and there, given the extreme simplicity
// I doubt it is at all useful to be smart here. Since the constant will be provided
// by parameter, I'd expect inference to optimize away irrelevant bits by itself.
module sha3_iota #(
    OUTPUT_BUFFER = 1,
    longint unsigned VALUE = 64'h0 // wrong value, you give me the magic number!
)(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood
);

wire[63:0] updated[5];
assign updated[0] = isa[0] ^ VALUE;
for (genvar comp = 1; comp < 5; comp++) assign updated[comp] = isa[comp];

sha3_state_capture#(
    .BUFFERIZE(OUTPUT_BUFFER)
) outbuff(
    .clk(clk),
    .sample(sample), .isa(updated), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(ogood),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);

endmodule
