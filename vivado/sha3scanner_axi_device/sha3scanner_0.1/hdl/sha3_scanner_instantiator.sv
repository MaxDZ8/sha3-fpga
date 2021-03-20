`timescale 1ns / 1ps

module sha3_scanner_instantiator #(
    STYLE = "fully-unrolled-fully-parallel",
    FEEDBACK_MUX_STYLE = "fabric",
    PROPER = 1
) (
    input clk, rst,

    input start,
    input[63:0] threshold,
    input[31:0] blobby[PROPER ? 20 : 24],
    
    output dispatching, evaluating, ready,
    output found,
    output[63:0] hash[25],
    output[31:0] nonce,
    
	  /*
	  This is a constant signal to let you better evaluate the amount of work to ask.
	  How many nonces does this crunch before asking for more? It will test at most this amount
	  but will usually stop much before, as you get to match the threshold.
	  */
	  output[31:0] scan_count
);
	
if (STYLE == "fully-unrolled-fully-parallel") begin : hiperf
    // Lowest overhead, maximum resource utilization and performance. 1 result/clock.
    sha3_scanner #(
      .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
      .CHI_MODIFY_STYLE("basic"),
      .IOTA_STYLE("basic"),
      .ROUND_OUTPUT_BUFFERED(24'b1110_1010_1010_1010_1010_1011),
      .PROPER(PROPER)
    ) scanner(
      .clk(clk), .rst(rst),
      .ready(ready),
      .start(start), .dispatching(dispatching), .evaluating(evaluating), .found(found),
      .threshold(threshold),
      
      .blobby(blobby),  .nonce(nonce),
      .hash(hash),
      
      .scan_count(scan_count)
    );
end
else if (STYLE == "iterate-four-times" | STYLE == "iterate-twice") begin : smallish
    // Small overhead by iterating on a 6-round-deep pipeline. The pipeline itself does 1 result clock
    // but results come in bursts so effectively 4 clocks per hash overall.
    // 12-round deep pipe very nice, even lower overhead to drive twice the cores, minor advantages.
    localparam ROUND_DEPTH = STYLE == "iterate-twice" ? 12 : 6; 
    sha3_packed_pipeline_scanner #(
        .FEEDBACK_MUX_STYLE(FEEDBACK_MUX_STYLE),
        .PIPE_ROUNDS(ROUND_DEPTH),
        .PROPER(PROPER)
    ) nice_deal (
        .clk(clk),
        .start(start), .threshold(threshold), .blockTemplate(blobby),
        .ofound(found), .ohash(hash), .ononce(nonce),
        .oready(ready), .odispatching(dispatching), .oevaluating(evaluating),
      
        .scan_count(scan_count)
    );
end
else begin
    initial begin
        $display("Round count unsupported.");
        $finish;
    end
end
	
endmodule
