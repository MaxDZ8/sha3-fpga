`timescale 1ns / 1ps

module sha3_scanner_instantiator #(
    STYLE = "fully-unrolled-fully-parallel"
) (
    input clk, rst,

    input start,
    input[63:0] threshold,
    input[31:0] blobby[24],
    
    output dispatching, evaluating,
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
    i_sha3_scan_request_bus request();
    i_sha3_scan_result_bus result();
    i_scanner_status status();
    
    for (genvar loop = 0; loop < 25; loop++) begin
        assign hash[loop * 2    ] = result.hash[loop][63:32];
        assign hash[loop * 2 + 1] = result.hash[loop][31: 0];
    end
    
    pack_into_scan_request_bus make_request(
        .start(start), .blobby(blobby), .threshold(max_diff),
        .as(request)
    );
    
    sha3_packed6_scanner nice_deal (
        .clk(clk),
        .irequest(request), .oresults(result), .ostatus(status)
    );
    
    unpack_from_scan_result_bus from_result(
        .from(result),
        .found(found), .hash(hash), .nonce(nonce)
    );
    
    unpack_from_scanner_status from_status(
        .from(status),
        .dispatching(dispatching), .evaluating(evaluating), .ready(ready)
    );
end
	
endmodule
