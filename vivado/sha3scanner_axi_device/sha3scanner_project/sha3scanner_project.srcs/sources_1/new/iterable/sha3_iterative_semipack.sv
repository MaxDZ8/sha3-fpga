`timescale 1ns / 1ps

// A pack of 6 (or 12) SHA rounds, where the last is partial.
// Iterate a single hash (4 or 2) times through this to produce a full SHA3!
// Note it takes the index of the first round as port parameter.
//
// Because the last round is only partial, when iterating you should be adjusting outputs accordingly
// by applying the last CHI+IOTA or the FINALIZER before feeding back in!
//
// Latency is ROUND_COUNT * LATENCY_EACH_ROUND, the fact last round is only partial is of little matter
// as latency of the CHI+IOTA is typically 0.
module sha3_iterating_semipack #(
    ROUND_COUNT = 6,
    LAST_ROUND_IS_PROPER = 1
) (
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    input[4:0] base_round,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output[4:0] oround,
    output ogood
);

wire[63:0] n0osa[5], n0osb[5], n0osc[5], n0osd[5], n0ose[5];
wire n0good;
wire[4:0] n0round;
sha3_iterable_round r6n0(
    .clk(clk), .round_index(base_round), .sample(sample),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(n0good), .oround(n0round),
    .osa(n0osa), .osb(n0osb), .osc(n0osc), .osd(n0osd), .ose(n0ose)
);

wire[63:0] n1osa[5], n1osb[5], n1osc[5], n1osd[5], n1ose[5];
wire n1good;
wire[4:0] n1round;
sha3_iterable_round r6n1(
    .clk(clk), .round_index(n0round + 1'b1), .sample(n0good),
    .isa(n0osa), .isb(n0osb), .isc(n0osc), .isd(n0osd), .ise(n0ose),
    .ogood(n1good), .oround(n1round),
    .osa(n1osa), .osb(n1osb), .osc(n1osc), .osd(n1osd), .ose(n1ose)
);

wire[63:0] n2osa[5], n2osb[5], n2osc[5], n2osd[5], n2ose[5];
wire n2good;
wire[4:0] n2round;
sha3_iterable_round r6n2(
    .clk(clk), .round_index(n1round + 1'b1), .sample(n1good),
    .isa(n1osa), .isb(n1osb), .isc(n1osc), .isd(n1osd), .ise(n1ose),
    .ogood(n2good), .oround(n2round),
    .osa(n2osa), .osb(n2osb), .osc(n2osc), .osd(n2osd), .ose(n2ose)
);

wire[63:0] n3osa[5], n3osb[5], n3osc[5], n3osd[5], n3ose[5];
wire n3good;
wire[4:0] n3round;
sha3_iterable_round r6n3(
    .clk(clk), .round_index(n2round + 1'b1), .sample(n2good),
    .isa(n2osa), .isb(n2osb), .isc(n2osc), .isd(n2osd), .ise(n2ose),
    .ogood(n3good), .oround(n3round),
    .osa(n3osa), .osb(n3osb), .osc(n3osc), .osd(n3osd), .ose(n3ose)
);

wire[63:0] n4osa[5], n4osb[5], n4osc[5], n4osd[5], n4ose[5];
wire n4good;
wire[4:0] n4round;
sha3_iterable_round r6n4(
    .clk(clk), .round_index(n3round + 1'b1), .sample(n3good),
    .isa(n3osa), .isb(n3osb), .isc(n3osc), .isd(n3osd), .ise(n3ose),
    .ogood(n4good), .oround(n4round),
    .osa(n4osa), .osb(n4osb), .osc(n4osc), .osd(n4osd), .ose(n4ose)
);

if (ROUND_COUNT == 6) begin : sixth
    if (LAST_ROUND_IS_PROPER) begin
        sha3_iterable_round r6n5_proper(
            .clk(clk), .round_index(n4round + 1'b1), .sample(n4good),
            .isa(n4osa), .isb(n4osb), .isc(n4osc), .isd(n4osd), .ise(n4ose),
            .ogood(ogood), .oround(oround),
            .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
        );
    end
    else begin
        sha3_iterable_semiround r6n5_quirky(
            .clk(clk), .round_index(n4round + 1'b1), .sample(n4good),
            .isa(n4osa), .isb(n4osb), .isc(n4osc), .isd(n4osd), .ise(n4ose),
            .ogood(ogood), .oround(oround),
            .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
        );
    end
end
else if (ROUND_COUNT == 12) begin : twelve // those could also be generated but for what it takes, they are not.
    wire[63:0] n5osa[5], n5osb[5], n5osc[5], n5osd[5], n5ose[5];
    wire n5good;
    wire[4:0] n5round;
    sha3_iterable_round r6n5(
        .clk(clk), .round_index(n4round + 1'b1), .sample(n4good),
        .isa(n4osa), .isb(n4osb), .isc(n4osc), .isd(n4osd), .ise(n4ose),
        .ogood(n5good), .oround(n5round),
        .osa(n5osa), .osb(n5osb), .osc(n5osc), .osd(n5osd), .ose(n5ose)
    );
    
    wire[63:0] n6osa[5], n6osb[5], n6osc[5], n6osd[5], n6ose[5];
    wire n6good;
    wire[4:0] n6round;
    sha3_iterable_round r6n6(
        .clk(clk), .round_index(n5round + 1'b1), .sample(n5good),
        .isa(n5osa), .isb(n5osb), .isc(n5osc), .isd(n5osd), .ise(n5ose),
        .ogood(n6good), .oround(n6round),
        .osa(n6osa), .osb(n6osb), .osc(n6osc), .osd(n6osd), .ose(n6ose)
    );
    
    wire[63:0] n7osa[5], n7osb[5], n7osc[5], n7osd[5], n7ose[5];
    wire n7good;
    wire[4:0] n7round;
    sha3_iterable_round r6n7(
        .clk(clk), .round_index(n6round + 1'b1), .sample(n6good),
        .isa(n6osa), .isb(n6osb), .isc(n6osc), .isd(n6osd), .ise(n6ose),
        .ogood(n7good), .oround(n7round),
        .osa(n7osa), .osb(n7osb), .osc(n7osc), .osd(n7osd), .ose(n7ose)
    );
    
    wire[63:0] n8osa[5], n8osb[5], n8osc[5], n8osd[5], n8ose[5];
    wire n8good;
    wire[4:0] n8round;
    sha3_iterable_round r6n8(
        .clk(clk), .round_index(n7round + 1'b1), .sample(n7good),
        .isa(n7osa), .isb(n7osb), .isc(n7osc), .isd(n7osd), .ise(n7ose),
        .ogood(n8good), .oround(n8round),
        .osa(n8osa), .osb(n8osb), .osc(n8osc), .osd(n8osd), .ose(n8ose)
    );
    
    wire[63:0] n9osa[5], n9osb[5], n9osc[5], n9osd[5], n9ose[5];
    wire n9good;
    wire[4:0] n9round;
    sha3_iterable_round r6n9(
        .clk(clk), .round_index(n8round + 1'b1), .sample(n8good),
        .isa(n8osa), .isb(n8osb), .isc(n8osc), .isd(n8osd), .ise(n8ose),
        .ogood(n9good), .oround(n9round),
        .osa(n9osa), .osb(n9osb), .osc(n9osc), .osd(n9osd), .ose(n9ose)
    );
    
    wire[63:0] nAosa[5], nAosb[5], nAosc[5], nAosd[5], nAose[5];
    wire nAgood;
    wire[4:0] nAround;
    sha3_iterable_round r6nA(
        .clk(clk), .round_index(n9round + 1'b1), .sample(n9good),
        .isa(n9osa), .isb(n9osb), .isc(n9osc), .isd(n9osd), .ise(n9ose),
        .ogood(nAgood), .oround(nAround),
        .osa(nAosa), .osb(nAosb), .osc(nAosc), .osd(nAosd), .ose(nAose)
    );
	
	  if (LAST_ROUND_IS_PROPER) begin
        sha3_iterable_round r6nB_proper(
            .clk(clk), .round_index(nAround + 1'b1), .sample(nAgood),
            .isa(nAosa), .isb(nAosb), .isc(nAosc), .isd(nAosd), .ise(nAose),
            .ogood(ogood), .oround(oround),
            .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
        );
	  end
	  else begin
        sha3_iterable_semiround r6nB_quirky(
            .clk(clk), .round_index(nAround + 1'b1), .sample(nAgood),
            .isa(nAosa), .isb(nAosb), .isc(nAosc), .isd(nAosd), .ise(nAose),
            .ogood(ogood), .oround(oround),
            .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
        );
	  end
end
else begin
    initial begin
        $display("Round count unsupported.");
        $finish;
    end
end

endmodule
