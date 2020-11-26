`timescale 1ns / 1ps

module uut_sha3_packed6_scanner();

localparam IMPL_NAME = "SHA3 scanner (packed by 6)";
localparam TEST_MODE = "short";

i_sha3_scan_request_bus inputBus();
sha3_scanner_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE)
) driver (
    .clk(clk),
    .data(inputBus)
);

i_sha3_scan_result_bus outputBus();
wire oready, odispatching, oevaluating;
sha3_packed6_scanner testing (
    .clk(clk),
    .irequest(inputBus),
    .oresults(outputBus),
    .oready(oready), .odispatching(odispatching), .oevaluating(oevaluating)
);

sha3_scanner_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME),
    .TEST_MODE(TEST_MODE)
) result_checker (
    .clk(clk),
    .validate(outputBus)
);
  
endmodule
