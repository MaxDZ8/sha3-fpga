`timescale 1ns / 1ps

// IOTA taking a round number 0..23 by port.
// Internally selects its magic number to XOR into el[0].
// It also becomes a finalizer transparently on round 23.
module sha3_iterable_iota_or_finalizer(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input[4:0] round_index,
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood
);

wire[63:0] iotaa[5];
sha3_iterable_iota usually(
    .clk(clk),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise), .round_index(round_index), .sample(sample),
    .ogood(ogood), .osa(iotaa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);

wire[63:0] neg_one = ~isa[1];
wire[63:0] neg_two = ~isa[2];
wire[63:0] fin0 = iotaa[0] ^ (neg_one & isa[2]);
wire[63:0] fin1 = iotaa[1] ^ (neg_two & isa[3]);

assign osa[0] = round_index < 5'd23 ? iotaa[0] : fin0;
assign osa[1] = round_index < 5'd23 ? iotaa[1] : fin1;
assign osa[2] = iotaa[2];  
assign osa[3] = iotaa[3];  
assign osa[4] = iotaa[4];  

endmodule
