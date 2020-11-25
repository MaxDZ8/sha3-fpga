`timescale 1ns / 1ps

// Running a scanner is the process of
// A- waiting for input
// B- scanning until something found
// C- wait for the pipeline to be flushed = akin to reset.
//
// No need to be performant here, the scan operation is supposed to be long-term taking over 500ms
// so there's no point of optimizing multi-flush or all the things.
module sha3_scanner_control(
    input clk,
    i_sha3_scan_request_bus.consumer irequest,
    i_sha3_scan_result_bus.producer oresults,
    i_scanner_status.producer ostatus,
    
    wire hasher_ready,
    i_sha3_1600_row_bus.controller crunch,
    i_sha3_1600_row_bus.periph hash
);

assign ostatus.evaluating = oresults.start;

enum bit[2:0] {   
    s_waiting     = 3'b001,
    s_dispatching = 3'b010,
    s_flushing    = 3'b100
} state = s_waiting;

assign ostatus.ready = state[0];
assign ostatus.dispatching = state[1];
assign crunch.sample = state[1];

int unsigned dispatch_iterator = 32'b0, next_nonce = 32'b0;
localparam int unsigned SCAN_LIMIT = 32'hFFFFFFFF;
wire exhausted = dispatch_iterator == SCAN_LIMIT;

longint unsigned rowa[5], rowb[5]; // those are captured from blobby input, completely defined.
longint unsigned rowc[2]; // only two entries in the third row are defined by block input, the others are magic or constants
wire[31:0] scan_start = rowc[0][63:32];

wire[63:0] rowc2 = {
    32'h00000006, // this is block finalization from SHA3, it should be the whole ulong ^ 64'h00000006_00000000 but I cut it easy 
    next_nonce
};

localparam longint unsigned rowc_final[2] = '{ 64'h0, 64'h0 };
localparam longint unsigned rowd_final[5] = '{ 64'h0, 64'h80000000_00000000, 64'h0, 64'h0, 64'h0 };
localparam longint unsigned rowe_final[5] = '{ 64'h0, 64'h0, 64'h0, 64'h0, 64'h0 };

assign crunch.rowa = rowa;
assign crunch.rowb = rowb;
assign crunch.rowc = '{ rowc[0], rowc[1], rowc2, rowc_final[0], rowc_final[1] };
assign crunch.rowd = '{ rowd_final[0], rowd_final[1], rowd_final[2], rowd_final[3], rowd_final[4] };
assign crunch.rowe = '{ rowe_final[0], rowe_final[1], rowe_final[2], rowe_final[3], rowe_final[4] };

bit buff_found = 1'b0;
int unsigned good_scan = 32'b0;
longint unsigned good_hash[25];

assign oresults.found = buff_found;
assign oresults.nonce = good_scan; // lying big way. This is nonce from given start, not nonce absolutely
for (genvar loop = 0; loop < 25; loop++) assign oresults.hash[loop] = good_hash[loop];

bit hash_observed = 1'b0;

always_ff @(posedge clk) case(state)
    s_waiting: if(irequest.start) begin
        rowa[0] <= { irequest.blockTemplate[ 1], irequest.blockTemplate[ 0] };
        rowa[1] <= { irequest.blockTemplate[ 3], irequest.blockTemplate[ 2] };
        rowa[2] <= { irequest.blockTemplate[ 5], irequest.blockTemplate[ 4] };
        rowa[3] <= { irequest.blockTemplate[ 7], irequest.blockTemplate[ 6] };
        rowa[4] <= { irequest.blockTemplate[ 9], irequest.blockTemplate[ 8] };
        rowb[0] <= { irequest.blockTemplate[11], irequest.blockTemplate[10] };
        rowb[1] <= { irequest.blockTemplate[13], irequest.blockTemplate[12] };
        rowb[2] <= { irequest.blockTemplate[15], irequest.blockTemplate[14] };
        rowb[3] <= { irequest.blockTemplate[17], irequest.blockTemplate[16] };
        rowb[4] <= { irequest.blockTemplate[19], irequest.blockTemplate[18] };
        rowc[0] <= { irequest.blockTemplate[21], irequest.blockTemplate[20] };
        rowc[1] <= { irequest.blockTemplate[23], irequest.blockTemplate[22] };
        next_nonce <= scan_start;
        dispatch_iterator <= 1'b0;
        state <= s_dispatching;
    end
    s_dispatching: begin
        if(exhausted | oresults.found) state <= s_flushing;
        else if (hasher_ready) begin
            next_nonce <= next_nonce + 1'b1;
            dispatch_iterator <= dispatch_iterator + 1'b1;
        end
    end
    s_flushing: begin
        if (hash_observed & ~hash.sample) state <= s_waiting;
    end
endcase

// The process of evaluating results is fully reactive.
// No need to sync on the FSM or anything. We'll be wasting a few hundred clocks but what's the issue really?
// For first, I help the FSM by monitoring hash output.
always_ff @(posedge clk) begin
    if (ostatus.ready) hash_observed <= 1'b0;
    else if(~hash_observed) hash_observed <= hash.sample;
end

// The real deal. Mangle the results and select a good hash.
// Takes some extra care as we must reboot on need!
wire[63:0] hash_diff = {
    hash.rowa[0][ 7: 0], hash.rowa[0][15: 8], hash.rowa[0][23:16], hash.rowa[0][31:24],
    hash.rowa[0][39:32], hash.rowa[0][47:40], hash.rowa[0][55:48], hash.rowa[0][63:56]
};
wire good_enough = oresults.start & $unsigned(hash_diff) < $unsigned(irequest.threshold);

int unsigned result_iter = 32'b0;

always_ff @(posedge clk) begin
    if(ostatus.ready) begin
        if(irequest.start) begin
            buff_found <= 1'b0;
            good_scan <= 32'b0;
            good_hash <= '{ 50{ 32'b0 } };
            result_iter <= 32'b0;
        end
    end
    else if(hash.sample) begin
        result_iter <= result_iter + 1'b1;
        if(~buff_found & good_enough) begin
            buff_found <= 1'b1;
            good_scan <= result_iter;
            good_hash <= '{
                hash.rowa[0], hash.rowa[1], hash.rowa[2], hash.rowa[3], hash.rowa[4],
                hash.rowb[0], hash.rowb[1], hash.rowb[2], hash.rowb[3], hash.rowb[4],
                hash.rowc[0], hash.rowc[1], hash.rowc[2], hash.rowc[3], hash.rowc[4],
                hash.rowd[0], hash.rowd[1], hash.rowd[2], hash.rowd[3], hash.rowd[4],
                hash.rowe[0], hash.rowe[1], hash.rowe[2], hash.rowe[3], hash.rowe[4]
            };
        end
    end
end


endmodule
