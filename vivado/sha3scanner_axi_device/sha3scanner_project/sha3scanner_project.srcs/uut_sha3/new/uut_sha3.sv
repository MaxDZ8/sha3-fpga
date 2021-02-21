`timescale 1ns / 1ps

// In this testbench I focus on correctness of the SHA3 core.
// In this first test I only go for the generic non-last round.
// Also useful to observe latency.
module uut_sha3();

localparam IMPL_NAME = "SHA3-1600 (fully parallel, fully pipelined)";

wire clk;
wire sample;
wire[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5];
sha_round_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TESTS_EACH_BURST(1)
) driver(
    .clock(clk), .hasher_can_take(1'b1),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe)
);

wire[63:0] qresa[5], qresb[5], qresc[5], qresd[5], qrese[5];
wire qresgood;
sha3 #(
    .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
    .CHI_MODIFY_STYLE("basic"),
    .IOTA_STYLE("basic"),
    .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011),
    .LAST_ROUND_IS_PROPER(0)
) quirky (
    .clk(clk),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .ogood(qresgood), .oa(qresa), .ob(qresb), .oc(qresc), .od(qresd), .oe(qrese)
);


wire[63:0] respa[5], respb[5], respc[5], respd[5], respe[5];
wire respgood;
sha3 #(
    .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
    .CHI_MODIFY_STYLE("basic"),
    .IOTA_STYLE("basic"),
    .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011),
    .LAST_ROUND_IS_PROPER(1)
) proper (
    .clk(clk),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .ogood(respgood), .oa(respa), .ob(respb), .oc(respc), .od(respd), .oe(respe)
);


sha3_1600_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TESTS_EACH_BURST(1)
) result_checker (
    .clk(clk),
    .qsample(qresgood), .qrowa(qresa), .qrowb(qresb), .qrowc(qresc), .qrowd(qresd), .qrowe(qrese),
    .samplep(respgood), .rowpa(respa), .rowpb(respb), .rowpc(respc), .rowpd(respd), .rowpe(respe)
);
  
endmodule
