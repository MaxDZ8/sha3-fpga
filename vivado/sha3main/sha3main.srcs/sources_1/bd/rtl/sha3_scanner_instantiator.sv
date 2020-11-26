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
    output[63:0] hash[25],
    output[31:0] nonce
);
	
if (STYLE == "fully-unrolled-fully-parallel") begin : hiperf
    // Lowest overhead, maximum resource utilization and performance. 1 result/clock.
    assign ready = 1'b1;
    sha3_scanner #(
      .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
      .CHI_MODIFY_STYLE("basic"),
      .IOTA_STYLE("basic"),
      .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011)
    ) scanner(
      .clk(clk), .rst(rst),
      .start(start), .dispatching(dispatching), .evaluating(evaluating), .found(found),
      .threshold(threshold),
      
      .blobby(blobby),  .nonce(nonce),
      .hash(hash)
    );
end
else if (STYLE == "iterate-four-times") begin : smallish
    // Small overhead by iterating on a 6-round-deep pipeline. The pipeline itself does 1 result clock
    // but results come in bursts so effectively 4 clocks per hash overall.
    sha3_packed6_scanner nice_deal (
        .clk(clk),
        .start(start), .threshold(threshold), .blockTemplate(blobby),
        .ofound(found), .ohash(hash), .ononce(nonce),
        .oready(ready), .odispatching(dispatching), .oevaluating(evaluating)
    );
end
	
endmodule
