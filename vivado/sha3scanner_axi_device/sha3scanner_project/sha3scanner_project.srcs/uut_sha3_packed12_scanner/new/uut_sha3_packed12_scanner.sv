`timescale 1ns / 1ps

module uut_sha3_packed12_scanner();

localparam IMPL_NAME = "SHA3 scanner (packed by 12)";
localparam TEST_MODE = "long";
localparam FEEDBACK_MUX_STYLE = "fabric";
localparam ALGO_IS_PROPER = 1;
localparam FASTER_CRUNCHING = 1;

wire start, clk, fstclk;
wire[31:0] blockTemplate[ALGO_IS_PROPER ? 20 : 24];
wire[63:0] threshold;
wire[31:0] scan_count;
sha3_scanner_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE),
    .ALGO_IS_PROPER(ALGO_IS_PROPER),
    .FASTER_CRUNCHING(FASTER_CRUNCHING)
) driver (
    .clk(clk), .fstclk(fstclk),
    .start(start), .threshold(threshold), .blockTemplate(blockTemplate),
    
    .scan_count(scan_count)
);


wire ready, dispatching, evaluating;
wire found;
wire[63:0] hash[25];
wire[31:0] nonce;
sha3_scanner_instantiator #(
    .STYLE("iterate-twice"),
    .FEEDBACK_MUX_STYLE(FEEDBACK_MUX_STYLE),
    .PROPER(ALGO_IS_PROPER),
    .ENABLE_FSTCLK(FASTER_CRUNCHING)
) thing (
    .clk(clk), .fstclk(fstclk), .rst(1'b0),
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
