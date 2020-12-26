`timescale 1ns / 1ps

// Performs THETA, RHO+PI.
// This is always executed into all round and is round-independant but will flow the round index according to its latency.
module sha3_iterable_semiround (
    input clk,
    input[4:0] round_index,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output[4:0] oround,
    output ogood
);


wire[63:0] rina[0:4], rinb[0:4], rinc[0:4], rind[0:4], rine[0:4];
wire rho_fetch;

sha3_theta #(
    .UPDATE_LOGIC_STYLE("basic")
) theta (
    .clk(clk),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise), .sample(sample),
    .osa(rina), .osb(rinb), .osc(rinc), .osd(rind), .ose(rine), .good(rho_fetch)
);

sha3_rho_pi #(
    .OUTPUT_BUFFER(0),
    .INPUT_BUFFER(0)
) rhopi(
    .clk(clk),
    .isa(rina), .isb(rinb), .isc(rinc), .isd(rind), .ise(rine), .sample(rho_fetch),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ogood(ogood)
);

bit[4:0] round_index_delayed = 5'b0;
always_ff @(posedge clk) if(sample) round_index_delayed <= round_index; // theta building its elts

bit[4:0] round_index_after_rhopi = 5'b0;
always_ff @(posedge clk) round_index_after_rhopi <= round_index_delayed; // theta outputting, rhopi is wire rename.
assign oround = round_index_after_rhopi;

endmodule
