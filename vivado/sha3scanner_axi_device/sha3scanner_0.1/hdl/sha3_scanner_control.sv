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
    output ofound,
    output[63:0] ohash[25],
    output[31:0] ononce,
    
    // Status
    output odispatching, oevaluating, oready,
    
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


enum bit[2:0] {   
    s_waiting     = 3'b001,
    s_dispatching = 3'b010,
    s_flushing    = 3'b100
} state = s_waiting;

assign oready = state[0];
assign odispatching = state[1] & hasher_ready; // the hasher will not really care but I like to see movement in waves
assign oevaluating = hashgood; 

assign feedgood = state[1];

wire capture = start & oready;
wire[31:0] scan_start;
longint unsigned rowa[5]; // always completely captured in both formulations
always_ff @(posedge clk) if(capture) begin
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
always_ff @(posedge clk) case(state)
    s_waiting: if(start) begin
        dispatch_iterator <= 1'b0;
        state <= s_dispatching;
    end
    s_dispatching: begin
        if(exhausted | ofound) state <= s_flushing;
        else if (hasher_ready) begin
            dispatch_iterator <= dispatch_iterator + 1'b1;
        end
    end
    s_flushing: begin
        if (hash_observed & ~hashgood) state <= s_waiting;
    end
endcase

int unsigned nonce_base = 32'b0;
always_ff @(posedge clk) if(capture) nonce_base <= scan_start;
wire[31:0] testing_nonce = nonce_base + dispatch_iterator;

if (PROPER) begin : proper
    assign scan_start = blockTemplate[19];
    longint unsigned buff_rowb[4]; // the last entry is magic
    int unsigned lorowblast = 32'b0;
    always_ff @(posedge clk) if(capture) begin
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
    always_ff @(posedge clk) if(capture) begin
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

bit buff_found = 1'b0;
int unsigned good_scan = 32'b0;
longint unsigned good_hash[25];

assign ofound = buff_found;
assign ononce = good_scan; // lying big way. This is nonce from given start, not nonce absolutely
for (genvar loop = 0; loop < 25; loop++) assign ohash[loop] = good_hash[loop];

// The process of evaluating results is fully reactive.
// No need to sync on the FSM or anything. We'll be wasting a few hundred clocks but what's the issue really?
// For first, I help the FSM by monitoring hash output.
always_ff @(posedge clk) begin
    if (oready) hash_observed <= 1'b0;
    else if(~hash_observed) hash_observed <= hashgood;
end

wire[63:0] hash_diff;
if (PROPER) assign hash_diff = hasha[3];
else assign hash_diff = {
    hasha[0][ 7: 0], hasha[0][15: 8], hasha[0][23:16], hasha[0][31:24],
    hasha[0][39:32], hasha[0][47:40], hasha[0][55:48], hasha[0][63:56]
};
wire good_enough = hashgood & ($unsigned(hash_diff) <= $unsigned(threshold));

int unsigned result_iter = 32'b0;

always_ff @(posedge clk) begin
    if(oready) begin
        if(start) begin
            buff_found <= 1'b0;
            good_scan <= 32'b0;
            good_hash <= '{ 25{ 64'b0 } };
            result_iter <= 32'b0;
        end
    end
    else if(hashgood) begin
        result_iter <= result_iter + 1'b1;
        if(~buff_found & good_enough) begin
            buff_found <= 1'b1;
            good_scan <= result_iter;
            good_hash <= '{
                hasha[0], hasha[1], hasha[2], hasha[3], hasha[4],
                hashb[0], hashb[1], hashb[2], hashb[3], hashb[4],
                hashc[0], hashc[1], hashc[2], hashc[3], hashc[4],
                hashd[0], hashd[1], hashd[2], hashd[3], hashd[4],
                hashe[0], hashe[1], hashe[2], hashe[3], hashe[4]
            };
        end
    end
end


endmodule