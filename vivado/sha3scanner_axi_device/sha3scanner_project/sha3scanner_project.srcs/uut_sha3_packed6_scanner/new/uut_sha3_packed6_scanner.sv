`timescale 1ns / 1ps

module uut_sha3_packed6_scanner();

localparam IMPL_NAME = "SHA3 scanner (packed by 6)";
localparam TEST_MODE = "short";

wire start;
wire[31:0] blockTemplate[24];
wire[63:0] threshold;
sha3_scanner_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE)
) driver (
    .clk(clk),
    .start(start), .threshold(threshold), .blockTemplate(blockTemplate)
);


wire oready, odispatching, oevaluating;
wire found;
wire[63:0] hash[25];
wire[31:0] nonce;
sha3_packed6_scanner testing (
    .clk(clk),
    .start(start), .threshold(threshold), .blockTemplate(blockTemplate),
    .ofound(found), .ohash(hash), .ononce(nonce),
    .oready(oready), .odispatching(odispatching), .oevaluating(oevaluating)
);

sha3_scanner_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE)
) result_checker (
    .clk(clk),
    .found(found), .hash(hash), .nonce(nonce)
);
  
endmodule
