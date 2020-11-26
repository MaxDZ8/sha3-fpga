`timescale 1ns / 1ps

/*
A sha-3 round. You give it a 5x5 input matrix and it mangles it.
There's no permutation here, it is processed as given.

There is a thing called 'interface' which could group stuff but for simple grouping
I have not found them to be so convenient and they don't quite interact well with the debugger/analyzer.

So there are two groups of signals: consider your input matrix as a vector containing 5 elements,
each one being a row counting 5 cells. .isa is the top row, .ise is the bottom. Those signals
are captured when .sample is high.

The result is more or less the same, it is given to you when .good is high.
*/
module sha3_round_function #(
    THETA_UPDATE_LOGIC_STYLE = "basic",
    /* Rho-pi rotates each state element and permutates the various elements.
    For high-clock rate, it seems a good 'do nothing' step to inject a self-contained pipeline buffer
    which can help P&R relocate to somewhere less congested. Valid values:
    <=0 - Rho_pi will be a pure wire rename
    >=1 - buffers outputs
    >=2 - buffers both outputs and inputs
    */
    RHOPI_BUFFERS = 0,
    CHI_MODIFY_STYLE = "basic",
    IOTA_STYLE = "basic",
    ROUND_INDEX = 0, // 0..23 integer
    // If true-ish my final theta will also buffer, otherwise flow right away to next round.
    OUTPUT_BUFFERED = 1'b1
)(
    input clk,
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
    output ogood
);

wire[63:0] rina[0:4], rinb[0:4], rinc[0:4], rind[0:4], rine[0:4];
wire rho_fetch;

sha3_theta #(
    .UPDATE_LOGIC_STYLE(THETA_UPDATE_LOGIC_STYLE)
) theta (
    .clk(clk),
    .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise), .sample(sample),
    .osa(rina), .osb(rinb), .osc(rinc), .osd(rind), .ose(rine), .good(rho_fetch)
);

wire[63:0] china[0:4], chinb[0:4], chinc[0:4], chind[0:4], chine[0:4];
wire chi_fetch;

sha3_rho_pi #(
    .OUTPUT_BUFFER(RHOPI_BUFFERS >= 1 ? 1 : 0),
    .INPUT_BUFFER(RHOPI_BUFFERS >= 2 ? 1 : 0)
) rhopi(
    .clk(clk),
    .isa(rina), .isb(rinb), .isc(rinc), .isd(rind), .ise(rine), .sample(rho_fetch),
    .osa(china), .osb(chinb), .osc(chinc), .osd(chind), .ose(chine), .ogood(chi_fetch)
);

localparam longint unsigned rc[24] = {
    64'h0000000000000001, 64'h0000000000008082, 64'h800000000000808a, 64'h8000000080008000,
    64'h000000000000808b, 64'h0000000080000001, 64'h8000000080008081, 64'h8000000000008009,
    64'h000000000000008a, 64'h0000000000000088, 64'h0000000080008009, 64'h000000008000000a,
    64'h000000008000808b, 64'h800000000000008b, 64'h8000000000008089, 64'h8000000000008003,
    64'h8000000000008002, 64'h8000000000000080, 64'h000000000000800a, 64'h800000008000000a,
    64'h8000000080008081, 64'h8000000000008080, 64'h0000000080000001, 64'h8000000080008008
};
if(ROUND_INDEX < 0 || ROUND_INDEX > 23) begin
    initial begin
        $display("SHA3 round index is integer 0..23 extremes included");
        $finish;
    end
end
localparam longint unsigned IOTA_VALUE = rc[ROUND_INDEX];


if (ROUND_INDEX < 23) begin : std_round
    wire[63:0] ioina[0:4], ioinb[0:4], ioinc[0:4], ioind[0:4], ioine[0:4];
    wire io_fetch;
    sha3_chi #(
        .STYLE(CHI_MODIFY_STYLE),
        .OUTPUT_BUFFER(0)
    ) chi (
        .clk(clk),
        .isa(china), .isb(chinb), .isc(chinc), .isd(chind), .ise(chine), .sample(chi_fetch),
        .osa(ioina), .osb(ioinb), .osc(ioinc), .osd(ioind), .ose(ioine), .ogood(io_fetch)
    );
    
    sha3_iota #(
       .VALUE(IOTA_VALUE),
       .OUTPUT_BUFFER(OUTPUT_BUFFERED)
    ) iota (
       .clk(clk),
       .isa(ioina), .isb(ioinb), .isc(ioinc), .isd(ioind), .ise(ioine), .sample(io_fetch),
       .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ogood(ogood)
  );
end
else begin : last_round
    sha3_finalizer #(
        .VALUE(IOTA_VALUE),
        .OUTPUT_BUFFER(OUTPUT_BUFFERED)
    ) finalizer (
        .clk(clk),
        .isa(china), .isb(chinb), .isc(chinc), .isd(chind), .ise(chine), .sample(chi_fetch),
        .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ogood(ogood)
    );
end




endmodule
