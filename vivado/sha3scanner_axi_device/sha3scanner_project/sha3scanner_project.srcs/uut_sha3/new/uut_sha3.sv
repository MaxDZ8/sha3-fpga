`timescale 1ns / 1ps

// In this testbench I focus on correctness of the SHA3 core.
// In this first test I only go for the generic non-last round.
// Also useful to observe latency.
module uut_sha3();

localparam IMPL_NAME = "SHA3-1600 (fully parallel, fully pipelined)";

wire clk;
i_sha3_1600_row_bus inputBus();

sha_round_dispatch_logic #(
    .TESTBENCH_NAME(IMPL_NAME)
) driver(
    .clock(clk), .hasher_can_take(1'b1),
    .toCrunch(inputBus)
);

i_sha3_1600_row_bus resbus();
sha3 #(
    .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
    .CHI_MODIFY_STYLE("basic"),
    .IOTA_STYLE("basic"),
    .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011)
) hasher(
    .clk(clk),
    .busin(inputBus), .busout(resbus)
);


sha3_1600_results_checker #(
    .TESTBENCH_NAME(IMPL_NAME)
) result_checker (
    .clk(clk),
    .crunched(resbus)
);
  
endmodule
