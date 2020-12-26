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
    .TESTBENCH_NAME(IMPL_NAME)
) driver(
    .clock(clk), .hasher_can_take(1'b1),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe)
);

wire[63:0] resa[5], resb[5], resc[5], resd[5], rese[5];
wire resgood;
sha3 #(
    .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
    .CHI_MODIFY_STYLE("basic"),
    .IOTA_STYLE("basic"),
    .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011)
) hasher(
    .clk(clk),
    .sample(sample), .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .ogood(resgood), .oa(resa), .ob(resb), .oc(resc), .od(resd), .oe(rese)
);


sha3_1600_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME)
) result_checker (
    .clk(clk),
    .sample(resgood), .rowa(resa), .rowb(resb), .rowc(resc), .rowd(resd), .rowe(rese)
);
  
endmodule
