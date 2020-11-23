`timescale 1ns / 1ps

// A pack of 6 SHA rounds, where the last MIGHT be the last round of SHA3 itself.
// Iterate a single hash 4 times through this to produce a full SHA3!
// Note it takes the index of the first round as port parameter.
module sha3_iterating_pack(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    input[4:0] base_round,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood
);

bit[4:0] delay[11];
always_ff @(posedge clk) begin
    delay[ 0] <= base_round;
    delay[ 1] <= delay[ 0];
    delay[ 2] <= delay[ 1];
    delay[ 3] <= delay[ 2];
    delay[ 4] <= delay[ 3];
    delay[ 5] <= delay[ 4];
    delay[ 6] <= delay[ 5];
    delay[ 7] <= delay[ 6];
    delay[ 8] <= delay[ 7];
    delay[ 9] <= delay[ 8];
    delay[10] <= delay[ 9];
    delay[11] <= delay[10];
end

wire[4:0] round_p1 = delay[ 2] + 4'd1;
wire[4:0] round_p2 = delay[ 4] + 4'd2;
wire[4:0] round_p3 = delay[ 6] + 4'd3;
wire[4:0] round_p4 = delay[ 8] + 4'd4;
wire[4:0] round_p5 = delay[10] + 4'd5;

wire[63:0] n0osa[5], n0osb[5], n0osc[5], n0osd[5], n0ose[5];
wire n0good;

sha3_iterable_round #( .MIGHT_BE_LAST(0) ) r6n0(
    .clk(clk), .round_index(base_round), .sample(sample),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(n0good),
    .osa(n0osa), .osb(n0osb), .osc(n0osc), .osd(n0osd), .ose(n0ose)
);

wire[63:0] n1osa[5], n1osb[5], n1osc[5], n1osd[5], n1ose[5];
wire n1good;

sha3_iterable_round #( .MIGHT_BE_LAST(0) ) r6n1(
    .clk(clk), .round_index(round_p1), .sample(n0good),
    .isa(n0osa), .isb(n0osb), .isc(n0osc), .isd(n0osd), .ise(n0ose),
    .ogood(n1good),
    .osa(n1osa), .osb(n1osb), .osc(n1osc), .osd(n1osd), .ose(n1ose)
);

wire[63:0] n2osa[5], n2osb[5], n2osc[5], n2osd[5], n2ose[5];
wire n2good;

sha3_iterable_round #( .MIGHT_BE_LAST(0) ) r6n2(
    .clk(clk), .round_index(round_p2), .sample(n1good),
    .isa(n1osa), .isb(n1osb), .isc(n1osc), .isd(n1osd), .ise(n1ose),
    .ogood(n2good),
    .osa(n2osa), .osb(n2osb), .osc(n2osc), .osd(n2osd), .ose(n2ose)
);

wire[63:0] n3osa[5], n3osb[5], n3osc[5], n3osd[5], n3ose[5];
wire n3good;

sha3_iterable_round #( .MIGHT_BE_LAST(0) ) r6n3(
    .clk(clk), .round_index(round_p3), .sample(n2good),
    .isa(n2osa), .isb(n2osb), .isc(n2osc), .isd(n2osd), .ise(n2ose),
    .ogood(n3good),
    .osa(n3osa), .osb(n3osb), .osc(n3osc), .osd(n3osd), .ose(n3ose)
);

wire[63:0] n4osa[5], n4osb[5], n4osc[5], n4osd[5], n4ose[5];
wire n4good;

sha3_iterable_round #( .MIGHT_BE_LAST(0) ) r6n4(
    .clk(clk), .round_index(round_p4), .sample(n3good),
    .isa(n3osa), .isb(n3osb), .isc(n3osc), .isd(n3osd), .ise(n3ose),
    .ogood(n4good),
    .osa(n4osa), .osb(n4osb), .osc(n4osc), .osd(n4osd), .ose(n4ose)
);

sha3_iterable_round #( .MIGHT_BE_LAST(1) ) r6n5(
    .clk(clk), .round_index(round_p5), .sample(n4good),
    .isa(n4osa), .isb(n4osb), .isc(n4osc), .isd(n4osd), .ise(n4ose),
    .ogood(ogood),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);

endmodule
