`timescale 1ns / 1ps

module uut_sha3_scanner();

localparam IMPL_NAME = "SHA3 scanner (fully pipelined and parallel)";
localparam TEST_MODE = "short";
localparam ALGO_IS_PROPER = 1;

wire start;
wire[31:0] blockTemplate[ALGO_IS_PROPER ? 20 : 24];
wire[63:0] threshold;
wire[31:0] scan_count;
sha3_scanner_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE),
    .ALGO_IS_PROPER(ALGO_IS_PROPER)
) driver (
    .clk(clk),
    .start(start), .threshold(threshold), .blockTemplate(blockTemplate),
    
    .scan_count(scan_count)
);


wire ready, dispatching, evaluating;
wire found;
wire[63:0] hash[25];
wire[31:0] nonce;
sha3_scanner_instantiator #(
    .STYLE("fully-unrolled-fully-parallel"),
    .PROPER(ALGO_IS_PROPER)
) thing (
    .clk(clk), .rst(1'b0),
    .start(start), .threshold(threshold), .blobby(blockTemplate),
    .found(found), .nonce(nonce), .hash(hash),
    .dispatching(dispatching), .evaluating(evaluating), .ready(ready),
    
    .scan_count(scan_count)
);

sha3_scanner_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE),
    .ALGO_IS_PROPER(ALGO_IS_PROPER)
) result_checker (
    .clk(clk),
    .found(found), .hash(hash), .nonce(nonce)
);
  
endmodule
