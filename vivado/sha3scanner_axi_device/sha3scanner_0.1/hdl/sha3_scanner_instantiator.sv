`timescale 1ns / 1ps

/**
  My primary goal is to instantiate the correct variation of the scanners BUT...
  It happens I'm also the best place to provide some extra buffering as well as
  documenting scanner's expected protocol.
  
  Control logic modules can get crazy with wire renaming and everything so I'll be doing all those things here,
  even though it doesn't sound like a great idea.
*/
module sha3_scanner_instantiator #(
    STYLE = "fully-unrolled-fully-parallel",
    FEEDBACK_MUX_STYLE = "fabric",
    PROPER = 1,
    ENABLE_FSTCLK = 0,
    ROUND_OUTPUT_BUFFER = 24'b0000_0000_0000_0000_0000_0000,

    localparam INPUT_ELEMENTS = PROPER ? 20 : 24
) (
    input clk, rst,
    
    // The port is always present so you can (and should always) tie it to something.
    // It is suggested to tie it to clk unless you have another synchronous clock to feed me.
    // Only used if ENABLE_FSTCLK, otherwise aliased to clk.
    input fstclk,

    // You can .start me only if I am .idle. Strobing .start latches .blobby
    input start,
    input[31:0] blobby[INPUT_ELEMENTS],
	
    // Buffered continuously.
    input[63:0] threshold,
    
	  // Goes low when .start to signal I have captured values and I'll be crunching them.
	  // Back high when scanner is done awaiting (with or without a result).
    output idle,
	
    // Goes high after (or together with) .idle to signal the hasher is actively testing nonces.
    // Goes low when the scanner gives up testing other nonces (exhausted range) or found a result.
    // Dispatching means "i am working" or "there's more work to do".
    output dispatching,
	
    // As soon as scanner dispatch, they have values in the pipelines to await.
    // So, awaiting goes high together with dispatching, and goes low when the last result pours out of the
    // pipeline. The last result is easy to determine: it is the result getting out of the pipeline when dispatching
    // is low. Awaiting can go low when the internal "result good" signal goes back low so iterative scanners don't have
    // much of an issue either.
    output awaiting,
	
    // High if testing a result for difficulty this clock.
    // Note .evaluating goes up and down in a pattern depending on the instantiated hasher. It is meant as a way
    // to count the hashes being effectively tested. By contrast, awaiting is slower to change and stays high as long
    // as there are (expected) results to be tested.
    output evaluating,
	
    // Signals validity of data by .hash and .nonce
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

wire crunch_clock = ENABLE_FSTCLK ? fstclk : clk;
wire start_strobe = idle & start;

bit buff_idle = 1'b1;
always_ff @(posedge clk) begin
    if(buff_idle) buff_idle <= ~awaiting;
    else buff_idle <= start_strobe;
end
assign idle = buff_idle;

longint unsigned buff_threshold = 64'b0;
always_ff @(posedge clk) buff_threshold <= threshold;

int unsigned buff_blobby[INPUT_ELEMENTS];
for (genvar el = 0; el < INPUT_ELEMENTS; el++) begin
    always_ff @(posedge clk) buff_blobby[el] <= blobby[el];
end

bit was_start_strobe = 1'b0;
always_ff @(posedge clk) was_start_strobe <= start_strobe;

// Similarly, buffer the outputs/results.
// Note result validity is now managed here, scanners just need to tell me if I need to capture and are therefore simplified.
wire capture_found;
bit buff_found = 1'b0;
always_ff @(posedge crunch_clock) begin
    if(buff_found) buff_found <= ~start_strobe;
	else buff_found <= capture_found;
end
assign found = buff_found;

wire[63:0] good_hash[25];
longint unsigned buff_hash[25];
for (genvar el = 0; el < 25; el++) begin
    always_ff @(posedge crunch_clock) if(capture_found) buff_hash[el] <= good_hash[el];
	assign hash[el] = buff_hash[el];
end

wire[31:0] good_nonce;
int unsigned buff_nonce;
always_ff @(posedge crunch_clock) if(capture_found) buff_nonce <= good_nonce;
assign nonce = buff_nonce;

	
if (STYLE == "fully-unrolled-fully-parallel") begin : hiperf
    // Lowest overhead, maximum resource utilization and performance. 1 result/clock.
    sha3_scanner #(
        .THETA_UPDATE_BY_DSP(24'b0000_1000_0001_0000_0001_0000),
        .CHI_MODIFY_STYLE("basic"),
        .IOTA_STYLE("basic"),
        .ROUND_OUTPUT_BUFFER(24'b1110_1010_1010_1010_1010_1011),
        .PROPER(PROPER)
    ) scanner(
      .clk(crunch_clock), .rst(rst),
	  
	  .threshold(buff_threshold),
	  .start(was_start_strobe), .blobby(buff_blobby),
	  
	  .ocapture(capture_found), .ohash(good_hash), .ononce(good_nonce),
	  
	  .odispatching(dispatching), .oawaiting(awaiting), .oevaluating(evaluating),
      
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
        .PROPER(PROPER),
        .ROUND_OUTPUT_BUFFER(ROUND_OUTPUT_BUFFER)
    ) nice_deal (
        .clk(crunch_clock),
	  
	    .threshold(buff_threshold),
	    .start(was_start_strobe), .blobby(buff_blobby),
	  
	    .ocapture(capture_found), .ohash(good_hash), .ononce(good_nonce),

	    .odispatching(dispatching), .oawaiting(awaiting), .oevaluating(evaluating),
      
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
