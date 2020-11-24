`timescale 1ns / 1ps

// SHA3 round function which can be iterated.
// There are two main variations. If this round MIGHT be last then you need to tell me by parameter.
// This will enable the optional finalizer.
module sha3_iterable_round #(
    MIGHT_BE_LAST = 1
) (
    input clk,
    input[4:0] round_index,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
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

wire[63:0] china[0:4], chinb[0:4], chinc[0:4], chind[0:4], chine[0:4];
wire rhopi_good;

sha3_rho_pi #(
    .OUTPUT_BUFFER(0),
    .INPUT_BUFFER(0)
) rhopi(
    .clk(clk),
    .isa(rina), .isb(rinb), .isc(rinc), .isd(rind), .ise(rine), .sample(rho_fetch),
    .osa(china), .osb(chinb), .osc(chinc), .osd(chind), .ose(chine), .ogood(rhopi_good)
);

bit[4:0] round_index_delayed, round_index_after_rhopi;
always_ff @(posedge clk) begin
    round_index_delayed <= round_index;
    round_index_after_rhopi <= round_index_delayed;
end

localparam FINALIZATION_ENABLED = |MIGHT_BE_LAST;
wire chi_fetch = FINALIZATION_ENABLED ? rhopi_good & round_index_after_rhopi != 5'd23 : rhopi_good;

wire[63:0] ioina[0:4], ioinb[0:4], ioinc[0:4], ioind[0:4], ioine[0:4];
wire chi_good;
sha3_chi #(
    .STYLE("basic"),
    .OUTPUT_BUFFER(0),
    .INPUT_BUFFER(0) // it is critical CHI+IOTA have latency 0 or the last round will go awry
) chi (
    .clk(clk),
    .isa(china), .isb(chinb), .isc(chinc), .isd(chind), .ise(chine), .sample(chi_fetch),
    .osa(ioina), .osb(ioinb), .osc(ioinc), .osd(ioind), .ose(ioine), .ogood(chi_good)
);

if (FINALIZATION_ENABLED) begin : quirky
   wire[63:0] muxoa[5], muxob[5], muxoc[5], muxod[5], muxoe[5];
   wire good_mux;
   wire[4:0] muxed_round;
    mux1600 ohno(
        .clk(clk),
        .sample(rhopi_good), .selector(chi_fetch),
        .round(round_index_after_rhopi),
        .a('{
            china[0], china[1], china[2], china[3], china[4],
            chinb[0], chinb[1], chinb[2], chinb[3], chinb[4],
            chinc[0], chinc[1], chinc[2], chinc[3], chinc[4],
            chind[0], chind[1], chind[2], chind[3], chind[4],
            chine[0], chine[1], chine[2], chine[3], chine[4]
        }),
        .b('{
            ioina[0], ioina[1], ioina[2], ioina[3], ioina[4],
            ioinb[0], ioinb[1], ioinb[2], ioinb[3], ioinb[4],
            ioinc[0], ioinc[1], ioinc[2], ioinc[3], ioinc[4],
            ioind[0], ioind[1], ioind[2], ioind[3], ioind[4],
            ioine[0], ioine[1], ioine[2], ioine[3], ioine[4]
        }),
        .o('{
            muxoa[0], muxoa[1], muxoa[2], muxoa[3], muxoa[4],
            muxob[0], muxob[1], muxob[2], muxob[3], muxob[4],
            muxoc[0], muxoc[1], muxoc[2], muxoc[3], muxoc[4],
            muxod[0], muxod[1], muxod[2], muxod[3], muxod[4],
            muxoe[0], muxoe[1], muxoe[2], muxoe[3], muxoe[4]
        }),
        .ogood(good_mux),
        .oround(muxed_round)
    );
    
    sha3_iterable_iota_or_finalizer #(
    ) finalizer (
       .clk(clk), .round_index(muxed_round),
       .isa(muxoa), .isb(muxob), .isc(muxoc), .isd(muxod), .ise(muxoe), .sample(good_mux),
       .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ogood(ogood)
  );
end
else begin : std_round
    sha3_iterable_iota iota (
       .clk(clk), .round_index(round_index_after_rhopi),
       .isa(ioina), .isb(ioinb), .isc(ioinc), .isd(ioind), .ise(ioine), .sample(chi_good),
       .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ogood(ogood)
  );
end

endmodule
