`timescale 1ns / 1ps

// A scanner dealing with the SHA3-packed-by-6 iterative hasher needs to be quite smarter than just dispatch
// like there's no tomorrow.
module sha3_packed_pipeline_scanner #(
    FEEDBACK_MUX_STYLE = "fabric",
    PIPE_ROUNDS = 6,
    PROPER = 1,
	localparam INPUT_ELEMENTS = PROPER ? 20 : 24
) (
    input clk,
    input[63:0] threshold,
    input start,
    input[31:0] blobby[INPUT_ELEMENTS],
	  
    output odispatching, oawaiting, oevaluating,
	
    output ocapture,
    output[31:0] ononce,
    output[63:0] ohash[25],
	  
    output[31:0] scan_count
);

wire feedgood, hasher_can_take, hashgood;
wire[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5];
wire[63:0] hasha[5], hashb[5], hashc[5], hashd[5], hashe[5];
sha3_scanner_control #(
    .PROPER(PROPER),
    .PIPE_PERF_LEVEL(PIPE_ROUNDS)
) fsm (
    .clk(clk),
    .start(start), .threshold(threshold), .blockTemplate(blobby),
    .ocapture(ocapture), .ohash(ohash), .ononce(ononce),
    .odispatching(odispatching), .oawaiting(oawaiting), .oevaluating(oevaluating),
    
    .hasher_ready(hasher_can_take),
    .feedgood(feedgood),
    .feeda(feeda), .feedb(feedb), .feedc(feedc), .feedd(feedd), .feede(feede),
    .hashgood(hashgood),
    .hasha(hasha), .hashb(hashb), .hashc(hashc), .hashd(hashd), .hashe(hashe),
    
    .scan_count(scan_count)
);


if (PIPE_ROUNDS == 6) begin : tiny
    sha3_iterating_pipe6 #(
        .FEEDBACK_MUX_STYLE(FEEDBACK_MUX_STYLE), 
        .LAST_ROUND_IS_PROPER(PROPER)
    ) hasher (
        .clk(clk),
        .sample(feedgood),
        .rowa(feeda), .rowb(feedb), .rowc(feedc), .rowd(feedd), .rowe(feede),
        .gimme(hasher_can_take),
        .ogood(hashgood),
        .oa(hasha), .ob(hashb), .oc(hashc), .od(hashd), .oe(hashe)
  );
end
else if(PIPE_ROUNDS == 12) begin : nice
    sha3_iterating_pipe12 #(
        .FEEDBACK_MUX_STYLE(FEEDBACK_MUX_STYLE), 
        .LAST_ROUND_IS_PROPER(PROPER)
    ) hasher (
        .clk(clk),
        .sample(feedgood),
        .rowa(feeda), .rowb(feedb), .rowc(feedc), .rowd(feedd), .rowe(feede),
        .gimme(hasher_can_take),
        .ogood(hashgood),
        .oa(hasha), .ob(hashb), .oc(hashc), .od(hashd), .oe(hashe)
  );
end
else begin
    initial begin
        $display("Pipeline depth unsupported.");
        $finish;
    end
end


endmodule
