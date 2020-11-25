`timescale 1ns / 1ps

// Ugly copypasta from the 'standard' fully unrolled SHA3.
// Goal is to check latencies and balance the signals.
module uut_sha3_packed6();

localparam IMPL_NAME = "SHA3-1600 (pipeline folded to 1/4, 6 pipelined rounds)";

wire hasher_ready, clk;
i_sha3_1600_row_bus inputBus();

sha_round_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME)
) driver(
    .clock(clk), .hasher_can_take(hasher_ready),
    .toCrunch(inputBus)
);

i_sha3_1600_row_bus resbus();
sha3_iterating_pipe6 hasher(
    .clk(clk),
    .busin(inputBus),
    .gimme(hasher_ready),
    .busout(resbus)
);


sha3_1600_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME)
) result_checker (
    .clk(clk),
    .crunched(resbus)
);
  
endmodule
