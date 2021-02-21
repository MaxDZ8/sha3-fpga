`timescale 1ns / 1ps

// Ugly copypasta from the 'standard' fully unrolled SHA3.
// Goal is to check latencies and balance the signals.
module uut_sha3_packed6();

localparam IMPL_NAME = "SHA3-1600 (pipeline folded to 1/4, 6 pipelined rounds)";

wire hasher_ready, clk;
wire sample;
wire[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5];
sha_round_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TESTS_EACH_BURST(14)
) driver(
    .clock(clk), .hasher_can_take(hasher_ready),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe)
);


wire[63:0] qresa[5], qresb[5], qresc[5], qresd[5], qrese[5];
wire qresgood;
sha3_iterating_pipe6 #(
    .LAST_ROUND_IS_PROPER(0)
) quirky (
    .clk(clk),
    // TODO: in line of principle I should be binding this to both and have two dispatchers... but they should have the same latency anyway
    .gimme(hasher_ready),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .ogood(qresgood), .oa(qresa), .ob(qresb), .oc(qresc), .od(qresd), .oe(qrese)
);


wire[63:0] respa[5], respb[5], respc[5], respd[5], respe[5];
wire respgood;
sha3_iterating_pipe6 #(
    .LAST_ROUND_IS_PROPER(1)
) proper (
    .clk(clk),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .ogood(respgood), .oa(respa), .ob(respb), .oc(respc), .od(respd), .oe(respe)
);




sha3_1600_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TESTS_EACH_BURST(14)
) result_checker (
    .clk(clk),
    .qsample(qresgood), .qrowa(qresa), .qrowb(qresb), .qrowc(qresc), .qrowd(qresd), .qrowe(qrese),
    .samplep(respgood), .rowpa(respa), .rowpb(respb), .rowpc(respc), .rowpd(respd), .rowpe(respe)
);
  
endmodule
