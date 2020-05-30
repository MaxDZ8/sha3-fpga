`timescale 1ns / 1ps

/*
A sha-3 round. Good for every non-last round. You give it a 5x5 input matrix and it mangles it.
There's no permutation here, it is processed as given.

There are a thing called 'interfaces' which could group stuff but for simple grouping
I have not found them to be so convenient and they don't quite interact well with the debugger/analyzer.

So there are two groups of signals: consider your input matrix as a vector containing 5 elements,
each one being a row counting 5 cells. .isa is the top row, .ise is the bottom. Those signals
are all good when .sample is high.

The result is more or less the same, it is given to you when .good is high.
*/
module sha3_5x5_pipelined_round #(
    THETA_BINARY_LOGIC_STYLE = "basic",
    CHI_MODIFY_STYLE = "basic",
    ROUND_INDEX = 0
)(
    input clk, rst,
    input[63:0] isa[5],
    input[63:0] isb[5],
    input[63:0] isc[5],
    input[63:0] isd[5],
    input[63:0] ise[5],
    input sample,
    output[63:0] osa[5],
    output[63:0] osb[5],
    output[63:0] osc[5],
    output[63:0] osd[5],
    output[63:0] ose[5],
    output good
);

wire[63:0] rina[0:4], rinb[0:4], rinc[0:4], rind[0:4], rine[0:4];
wire rho_fetch;

sha3_theta #(
    .BINARY_LOGIC_STYLE(THETA_BINARY_LOGIC_STYLE)
) theta (
    .clk(clk), .rst(rst),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise), .sample(good),
    .osa(rina), .osb(rinb), .osc(rinc), .osd(rind), .ose(rine), .good(rho_fetch)
);

wire[63:0] china[0:4], chinb[0:4], chinc[0:4], chind[0:4], chine[0:4];
wire chi_fetch;

sha3_rho rho(
    .clk(clk), .rst(rst),
    .isa(rina), .isb(rinb), .isc(rinc), .isd(rind), .ise(rine), .sample(rho_fetch),
    .osa(china), .osb(chinb), .osc(chinc), .osd(chind), .ose(chine), .good(chi_fetch)
);
    
wire[63:0] ioina[0:4], ioinb[0:4], ioinc[0:4], ioind[0:4], ioine[0:4];
wire io_fetch;

sha3_chi #(
    .MODIFY_STYLE(CHI_MODIFY_STYLE)
) chi (
    .clk(clk), .rst(rst),
    .isa(china), .isb(chinb), .isc(chinc), .isd(chind), .ise(chine), .sample(chi_fetch),
    .osa(ioina), .osb(ioinb), .osc(ioinc), .osd(ioind), .ose(ioine), .good(io_fetch)
);

sha3_iota #(
   .STYLE(IOTA_STYLE),
   .VALUE(IOTA_VALUE)
) iota (
   .clk(clk), .rst(rst),
   .isa(china), .isb(chinb), .isc(chinc), .isd(chind), .ise(chine), .sample(chi_fetch),
   .osa(ioina), .osb(ioinb), .osc(ioinc), .osd(ioind), .ose(ioine), .good(io_fetch)
);

endmodule
