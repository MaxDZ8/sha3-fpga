`timescale 1ns / 1ps

// Running a scanner is the process of
// A- waiting for input
// B- scanning until something found
// C- wait for the pipeline to be flushed = akin to reset.
//
// No need to be performant here, the scan operation is supposed to be long-term taking over 500ms
// so there's no point of optimizing multi-flush or all the things.
module sha3_scanner_control #(
    PROPER = 1,
    PIPE_PERF_LEVEL = 6
) (
    input clk,
    // Scan request
    input start,
    input[63:0] threshold,
    input[31:0] blockTemplate[PROPER ? 20 : 24],
    
    // Results
    output ocapture,
    output[63:0] ohash[25],
    output[31:0] ononce,
    
    // Status
    output odispatching, oawaiting, oevaluating,
    
    input hasher_ready,
    output feedgood,
    output[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5],
    input hashgood,
    input[63:0] hasha[5], hashb[5], hashc[5], hashd[5], hashe[5],
    
	  /*
	  Tell the outer program how many nonces I test at most
	  (if I don't get a good enough nonce first)
	  */
	  output[31:0] scan_count
);

longint unsigned buff_threshold;
always_ff @(posedge clk) buff_threshold <= threshold;

enum bit[2:0] {   
    s_waiting     = 3'b001,
    s_dispatching = 3'b010,
    s_flushing    = 3'b100
} state = s_waiting;

assign feedgood = state[1];

wire[31:0] scan_start;
longint unsigned rowa[5]; // always completely captured in both formulations
always_ff @(posedge clk) if(start) begin
    rowa[0] <= { blockTemplate[ 1], blockTemplate[ 0] };
    rowa[1] <= { blockTemplate[ 3], blockTemplate[ 2] };
    rowa[2] <= { blockTemplate[ 5], blockTemplate[ 4] };
    rowa[3] <= { blockTemplate[ 7], blockTemplate[ 6] };
    rowa[4] <= { blockTemplate[ 9], blockTemplate[ 8] };
end
assign feeda = '{ rowa[0], rowa[1], rowa[2], rowa[3], rowa[4] };

localparam EXHAUST_BIT = PIPE_PERF_LEVEL == 12 ? 30 : 29;
assign scan_count = (32'b1 <<< EXHAUST_BIT); 

int unsigned dispatch_iterator = 32'b0; // I allocate full 32 bit for easiness anyway
wire exhausted = dispatch_iterator[EXHAUST_BIT];
bit hash_observed = 1'b0;
bit buff_dispatching = 1'b0, buff_awaiting = 1'b0;
bit found_strobe; // now comes two clock late but even if we dispatch a bit more it's still ok, this is a critical path!
always_ff @(posedge clk) case(state)
    s_waiting: if(start) begin
        dispatch_iterator <= 1'b0;
		buff_dispatching <= 1'b1;
		buff_awaiting <= 1'b1;
		hash_observed <= 1'b0;
        state <= s_dispatching;
    end
    s_dispatching: begin
        if(exhausted | found_strobe) begin
		    buff_dispatching <= 1'b0;
		    state <= s_flushing;
		end
        else if (hasher_ready) begin
            dispatch_iterator <= dispatch_iterator + 1'b1;
        end
		if(hashgood) hash_observed <= 1'b1;
    end
    s_flushing: begin
		if(hashgood) hash_observed <= 1'b1;
        if (hash_observed & ~hashgood) begin
		    buff_awaiting <= 1'b0;
		    state <= s_waiting;
		end
    end
endcase
assign odispatching = buff_dispatching;
assign oawaiting = buff_awaiting;

int unsigned nonce_base = 32'b0;
always_ff @(posedge clk) if(start) nonce_base <= scan_start;
wire[31:0] testing_nonce = nonce_base + dispatch_iterator;

if (PROPER) begin : proper
    assign scan_start = blockTemplate[19];
    longint unsigned buff_rowb[4]; // the last entry is magic
    int unsigned lorowblast = 32'b0;
    always_ff @(posedge clk) if(start) begin
        buff_rowb[0] <= { blockTemplate[11], blockTemplate[10] };
        buff_rowb[1] <= { blockTemplate[13], blockTemplate[12] };
        buff_rowb[2] <= { blockTemplate[15], blockTemplate[14] };
        buff_rowb[3] <= { blockTemplate[17], blockTemplate[16] };
        lorowblast   <=                      blockTemplate[18];
    end
    wire[63:0] rowb4 = { testing_nonce, lorowblast };
    assign feedb = '{ buff_rowb[0], buff_rowb[1],         buff_rowb[2], buff_rowb[3], rowb4 };
    assign feedc = '{ 64'h1,        64'h0,                64'h0,        64'h0,        64'h0 };
end
else begin : quirky
    assign scan_start = blockTemplate[21];
    longint unsigned buff_rowb[5], buff_rowc[2]; // only two entries in the third row are defined by block input, the others are magic or constants
    always_ff @(posedge clk) if(start) begin
        buff_rowb[0] <= { blockTemplate[11], blockTemplate[10] };
        buff_rowb[1] <= { blockTemplate[13], blockTemplate[12] };
        buff_rowb[2] <= { blockTemplate[15], blockTemplate[14] };
        buff_rowb[3] <= { blockTemplate[17], blockTemplate[16] };
        buff_rowb[4] <= { blockTemplate[19], blockTemplate[18] };
        buff_rowc[0] <= { scan_start,        blockTemplate[20] };
        buff_rowc[1] <= { blockTemplate[23], blockTemplate[22] };
    end
    wire[63:0] rowc2 = { 32'h06, testing_nonce };
    assign feedb = '{ buff_rowb[0], buff_rowb[1],          buff_rowb[2], buff_rowb[3], buff_rowb[4] };
    assign feedc = '{ buff_rowc[0], buff_rowc[1],          rowc2,        64'h0,        64'h0 };
end
assign feedd = '{ 64'h0,        64'h80000000_00000000, 64'h0,        64'h0,        64'h0 };
assign feede = '{ 64'h0,        64'h0,                 64'h0,        64'h0,        64'h0 };

// I have decided to evaluate this in two steps and route it by its own.
// Higher 16 bits are compared near hash generation.
wire[63:0] hash_diff;
if (PROPER) assign hash_diff = hasha[3];
else assign hash_diff = {
    hasha[0][ 7: 0], hasha[0][15: 8], hasha[0][23:16], hasha[0][31:24],
    hasha[0][39:32], hasha[0][47:40], hasha[0][55:48], hasha[0][63:56]
};
bit threshi_le;
always_ff @(posedge clk) threshi_le <= $unsigned(hash_diff[63:32]) <= $unsigned(buff_threshold[63:32]);

bit[31:0] threslo;
always_ff @(posedge clk) threslo <= hash_diff[31:0]; 

wire was_hashgood;
wire[63:0] was_hasha[5], was_hashb[5], was_hashc[5], was_hashd[5], was_hashe[5];
sha3_state_capture capture_hash (
    .clk(clk),
    .isa(hasha), .isb(hashb), .isc(hashc), .isd(hashd), .ise(hashe), .sample(hashgood),
    .ogood(was_hashgood), .osa(was_hasha), .osb(was_hashb), .osc(was_hashc), .osd(was_hashd), .ose(was_hashe)
);

// Note this is now a bit inaccurate as threshold might change between different clocks but that's rare enough I don't care.
wire good_enough = was_hashgood & threshi_le & ($unsigned(threslo) <= $unsigned(buff_threshold[47:0]));
always_ff @(posedge clk) found_strobe <= good_enough;

int unsigned result_iter = 32'b0;
always_ff @(posedge clk) begin
    if(start) result_iter <= 32'b0;
    else if(was_hashgood) result_iter <= result_iter + 1'b1;
end

bit buff_oevaluating = 1'b0;
always_ff @(posedge clk) buff_oevaluating <= was_hashgood;
assign oevaluating = buff_oevaluating;

bit buff_ocapture = 1'b0;
always_ff @(posedge clk) buff_ocapture <= good_enough;
assign ocapture = buff_ocapture;

int unsigned buff_ononce = 32'b0;
always_ff @(posedge clk) if(good_enough) buff_ononce <= result_iter;
assign ononce = buff_ononce; // lying big way. This is nonce from given start, not nonce absolutely

longint unsigned buff_ohash[25];
always_ff @(posedge clk) begin
	buff_ohash <= '{
		was_hasha[0], was_hasha[1], was_hasha[2], was_hasha[3], was_hasha[4],
		was_hashb[0], was_hashb[1], was_hashb[2], was_hashb[3], was_hashb[4],
		was_hashc[0], was_hashc[1], was_hashc[2], was_hashc[3], was_hashc[4],
		was_hashd[0], was_hashd[1], was_hashd[2], was_hashd[3], was_hashd[4],
		was_hashe[0], was_hashe[1], was_hashe[2], was_hashe[3], was_hashe[4]
	};
end
for (genvar loop = 0; loop < 25; loop++) assign ohash[loop] = buff_ohash[loop];

endmodule
