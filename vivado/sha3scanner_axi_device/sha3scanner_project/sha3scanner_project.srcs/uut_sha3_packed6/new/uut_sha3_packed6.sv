`timescale 1ns / 1ps

// Ugly copypasta from the 'standard' fully unrolled SHA3.
// Goal is to check latencies and balance the signals.
module uut_sha3_packed6();

localparam IMPL_NAME = "SHA3-1600 (pipeline folded to 1/4, 6 pipelined rounds)";

wire hasher_ready, clk;
wire sample;
wire[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5];
sha_round_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME)
) driver(
    .clock(clk), .hasher_can_take(hasher_ready),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe)
);

wire[63:0] resa[5], resb[5], resc[5], resd[5], rese[5];
wire resgood;
sha3_iterating_pipe6 hasher(
    .clk(clk),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .gimme(hasher_ready),
    .ogood(resgood), .oa(resa), .ob(resb), .oc(resc), .od(resd), .oe(rese)
);


sha3_1600_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME)
) result_checker (
    .clk(clk),
    .sample(resgood), .rowa(resa), .rowb(resb), .rowc(resc), .rowd(resd), .rowe(rese)
);
  
endmodule
