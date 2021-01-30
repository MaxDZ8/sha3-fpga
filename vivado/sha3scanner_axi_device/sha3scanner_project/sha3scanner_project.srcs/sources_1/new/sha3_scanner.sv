`timescale 1ns / 1ps

module sha3_scanner #(
    THETA_UPDATE_BY_DSP = 24'b0010_0010_0010_0010_0010_0010,
    CHI_MODIFY_STYLE = "basic",
    IOTA_STYLE = "basic",
    ROUND_OUTPUT_BUFFERED = 24'b1111_1111_1111_1111_1111_1111,
    PROPER = 1,
    localparam ULONG_COUNT = PROPER ? 10 : 12
)(
    input clk, rst,
    input start,
    
    // "Difficulty"
    input[63:0] threshold,
    /*
    When PROPER: 20 uints, last one being the nonce to start testing.
    When NOT proper (see cpu miner) the nonce goes in ulong[12] instead, blobby[20] is the start nonce (would need to be further tested).
    In both cases = ul the i-th ulong is { blobby[i*2 + 1], blobby[i * 2] }.
    Only a part of the inital state is to be provided, the other bits are built internally (and most are constant anyway)
    */
	  input[31:0] blobby[ULONG_COUNT * 2],
	  
	  output dispatching, evaluating, found, ready,
	  output[31:0] nonce,
	  output[63:0] hash[25]
);

wire capture = start & ready;
longint unsigned rowa[5], rowb[5]; // those are captured from blobby input, completely defined.
longint unsigned rowc[2]; // only two entries in the third row are defined by block input, the others are magic or constants
always_ff @(posedge clk) if(capture) begin
    rowa[0] <= { blobby[ 1], blobby[ 0] };
    rowa[1] <= { blobby[ 3], blobby[ 2] };
    rowa[2] <= { blobby[ 5], blobby[ 4] };
    rowa[3] <= { blobby[ 7], blobby[ 6] };
    rowa[4] <= { blobby[ 9], blobby[ 8] };
    rowb[0] <= { blobby[11], blobby[10] };
    rowb[1] <= { blobby[13], blobby[12] };
    rowb[2] <= { blobby[15], blobby[14] };
    rowb[3] <= { blobby[17], blobby[16] };
    rowb[4] <= { blobby[19], blobby[18] };
    rowc[0] <= { blobby[21], blobby[20] };
    rowc[1] <= { blobby[23], blobby[22] };
end

wire[31:0] scan_start = rowc[0][63:32];
int unsigned dispatch_iterator = 32'b0, next_nonce = 32'b0;
bit buff_dispatching = 1'b0;
always_ff @(posedge clk) if(rst) begin
    buff_dispatching <= 1'b0;
    dispatch_iterator <= 32'b0;
    next_nonce <= 32'b0;
end
else begin
    if (buff_dispatching) begin
        buff_dispatching <= dispatch_iterator < 32'hFFFFFFFF & ~found;
        dispatch_iterator <= dispatch_iterator + 1'b1;
        next_nonce <= next_nonce + 1;
    end
    else begin
        buff_dispatching <= capture;
        dispatch_iterator <= 32'b0;
        next_nonce <= scan_start;
    end
end
assign dispatching = buff_dispatching;


wire[63:0] rowc2 = {
    32'h00000006, // this is block finalization from SHA3, it should be the whole ulong ^ 64'h00000006_00000000 but I cut it easy 
    next_nonce
};

localparam longint unsigned rowc_final[2] = '{ 64'h0, 64'h0 };
localparam longint unsigned rowd_final[5] = '{ 64'h0, 64'h80000000_00000000, 64'h0, 64'h0, 64'h0 };
localparam longint unsigned rowe_final[5] = '{ 64'h0, 64'h0, 64'h0, 64'h0, 64'h0 };

wire resgood;
wire[63:0] resa[5], resb[5], resc[5], resd[5], rese[5];
sha3 #(
    .THETA_UPDATE_BY_DSP(THETA_UPDATE_BY_DSP),
    .ROUND_OUTPUT_BUFFERED(ROUND_OUTPUT_BUFFERED),
    .LAST_ROUND_IS_PROPER(PROPER)
) hasher(
    .clk(clk),
    .sample(buff_dispatching),
    .rowa(rowa), .rowb(rowb),
    .rowc('{ rowc[0], rowc[1], rowc2, rowc_final[0], rowc_final[1] }),
    .rowd('{ rowd_final[0], rowd_final[1], rowd_final[2], rowd_final[3], rowd_final[4] }),
    .rowe('{ rowe_final[0], rowe_final[1], rowe_final[2], rowe_final[3], rowe_final[4] }),
    .ogood(resgood),
    .oa(resa), .ob(resb), .oc(resc), .od(resd), .oe(rese)
);

assign evaluating = resgood;
wire[63:0] hash_diff = {
    resa[0][7:0], resa[0][15:8], resa[0][23:16], resa[0][31:24], resa[0][39:32],
    resa[0][47:40], resa[0][55:48], resa[0][63:56]
};
wire good_enough = evaluating & $unsigned(hash_diff) < $unsigned(threshold);

int unsigned result_iterator = 32'b0;
bit buff_found = 1'b0;
always_ff @(posedge clk) if(rst) begin
    buff_found <= 1'b0;
    result_iterator <= 32'b0;
end
else begin
    if (ready) begin
        if (capture) begin
            buff_found <= 1'b0;
            result_iterator <= 32'b0;
        end
    end
    else buff_found <= buff_found | good_enough;
    if(evaluating) result_iterator <= result_iterator + 1'b1;
end
assign found = buff_found;

int unsigned good_nonce = 32'b0;
longint unsigned good_hash[25];
always_ff @(posedge clk) if(rst) begin
    good_nonce <= 1'b0;
    good_hash <= '{ 25{ 64'b0 } };
end
else begin
    if(good_enough) begin
        good_nonce <= result_iterator;
        good_hash <= '{
            resa[0], resa[1], resa[2], resa[3], resa[4],
            resb[0], resb[1], resb[2], resb[3], resb[4],
            resc[0], resc[1], resc[2], resc[3], resc[4],
            resd[0], resd[1], resd[2], resd[3], resd[4],
            rese[0], rese[1], rese[2], rese[3], rese[4]
        };
    end
end
assign nonce = good_nonce;
for (genvar loop = 0; loop < 25; loop++) begin
    assign hash[loop] = good_hash[loop];
end


bit was_evaluating = 1'b0;
always_ff @(posedge clk) was_evaluating <= evaluating;
wire empty_pipeline = was_evaluating & ~evaluating;
assign ready = result_iterator == dispatch_iterator & ~dispatching;

endmodule
