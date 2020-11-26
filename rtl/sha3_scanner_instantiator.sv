`timescale 1ns / 1ps

module sha3_scanner_instantiator #(
    STYLE = "fully-unrolled-fully-parallel"
) (
    input clk, rst,

    input start,
    input[63:0] threshold,
    input[31:0] blobby[24],
    
    output dispatching, evaluating, ready,
    output found,
    output[31:0] hash[50],
    output[31:0] nonce
);
	
if (STYLE == "fully-unrolled-fully-parallel") begin : hiperf
    // Lowest overhead, maximum resource utilization and performance. 1 result/clock.

    sha3_scanner #(
      .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
      .CHI_MODIFY_STYLE("basic"),
      .IOTA_STYLE("basic"),
      .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011)
    ) scanner(
      .clk(S_AXI_ACLK), .rst(~S_AXI_ARESETN),
      .start(start), .dispatching(dispatching), .evaluating(evaluating), .found(found),
      .threshold(max_diff),
      
      .blobby(blobby),  .nonce(nonce),
      .hash(hash)
    );
end
else if (STYLE == "iterate-four-times") begin : smallish
    // Small overhead by iterating on a 6-round-deep pipeline. The pipeline itself does 1 result clock
    // but results come in bursts so effectively 4 clocks per hash overall.
    i_sha3_scan_result_bus result();
    
    sha3_packed6_scanner nice_deal (
        .clk(clk),
        .start(start), .threshold(max_diff), .blockTemplate(blobby),
        .oresults(result),
        .oready(ready), .odispatching(dispatching), .oevaluating(evaluating)
    );
    
    unpack_from_scan_result_bus from_result(
        .from(result),
        .found(found), .hash32_hilo(hash), .nonce(nonce)
    );
end
	
endmodule
