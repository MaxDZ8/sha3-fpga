`timescale 1ns / 1ps

// The last round applies this instead of iota.
// This could be formulated as Iota plus something.
// As with iota, a constant is xorred into s0
// but other two values are xorred into s0 and, if this is not enough s1 is modified as well.
// So one is a 3-way operation and the other a four-way operation.
// Albeit used only once, I might want to consider this more closely in the future. 
module sha3_finalizer #(
    OUTPUT_BUFFER = 1,
    VALUE = 64'h0 // wrong value, you give me the magic number!
)(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood
);

wire[63:0] neg_one = ~isa[1];
wire[63:0] neg_two = ~isa[2];

wire[63:0] updated[5];
// four-way op with a few bits being really simple elaboration-time constant... probably nice for inference
assign updated[0] = isa[0] ^ (neg_one & isa[2]) ^ VALUE;
// three-way op with everything being runtime, perhaps in the future I could be smarter here.
assign updated[1] = isa[1] ^ (neg_two & isa[3]);
for (genvar comp = 2; comp < 5; comp++) assign updated[comp] = isa[comp];

sha3_state_capture#(
    .BUFFERIZE(OUTPUT_BUFFER)
) outbuff(
    .clk(clk),
    .sample(sample), .isa(updated), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(ogood),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);

endmodule
