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
	  output[63:0] hash[25],
	  
	  output[31:0] scan_count
);

wire capture = start & ready;
wire[31:0] scan_start;
longint unsigned rowa[5]; // always completely captured in both formulations
always_ff @(posedge clk) if(capture) begin
    rowa[0] <= { blobby[ 1], blobby[ 0] };
    rowa[1] <= { blobby[ 3], blobby[ 2] };
    rowa[2] <= { blobby[ 5], blobby[ 4] };
    rowa[3] <= { blobby[ 7], blobby[ 6] };
    rowa[4] <= { blobby[ 9], blobby[ 8] };
end

assign scan_count = 32'h8000_0000; // exit on 31st bit high...
int unsigned dispatch_iterator = 32'b0;
bit buff_dispatching = 1'b0;
always_ff @(posedge clk) if(rst) begin
    buff_dispatching <= 1'b0;
    dispatch_iterator <= 32'b0;
end
else begin
    if (buff_dispatching) begin
        buff_dispatching <= ~dispatch_iterator[31] & ~found; // ... 31st bit high
        dispatch_iterator <= dispatch_iterator + 1'b1;
    end
    else begin
        buff_dispatching <= capture;
        dispatch_iterator <= 32'b0;
    end
end
assign dispatching = buff_dispatching;

int unsigned nonce_base = 32'b0;
always_ff @(posedge clk) if(capture) nonce_base <= scan_start;
wire[31:0] testing_nonce = nonce_base + dispatch_iterator;

wire[63:0] rowb[5], rowc[5], rowd[5], rowe[5];

if (PROPER) begin : proper
    assign scan_start = blobby[19];
    longint unsigned buff_rowb[4]; // the last entry is magic
    int unsigned lorowblast = 32'b0;
    always_ff @(posedge clk) if(capture) begin
        buff_rowb[0] <= { blobby[11], blobby[10] };
        buff_rowb[1] <= { blobby[13], blobby[12] };
        buff_rowb[2] <= { blobby[15], blobby[14] };
        buff_rowb[3] <= { blobby[17], blobby[16] };
        lorowblast   <=               blobby[18];
    end
    wire[63:0] rowb4 = { testing_nonce, lorowblast };
    assign rowb = '{ buff_rowb[0], buff_rowb[1],         buff_rowb[2], buff_rowb[3], rowb4 };
    assign rowc = '{ 64'h1,        64'h0,                64'h0,        64'h0,        64'h0 };
    assign rowd = '{ 64'h0,        64'h8000000000000000, 64'h0,        64'h0,        64'h0 };
    assign rowe = '{ 64'h0,        64'h0,                64'h0,        64'h0,        64'h0 };
end
else begin : quirky
    assign scan_start = blobby[21];
    longint unsigned buff_rowb[5], buff_rowc[2]; // only two entries in the third row are defined by block input, the others are magic or constants
    always_ff @(posedge clk) if(capture) begin
        buff_rowb[0] <= { blobby[11], blobby[10] };
        buff_rowb[1] <= { blobby[13], blobby[12] };
        buff_rowb[2] <= { blobby[15], blobby[14] };
        buff_rowb[3] <= { blobby[17], blobby[16] };
        buff_rowb[4] <= { blobby[19], blobby[18] };
        buff_rowc[0] <= { scan_start, blobby[20] };
        buff_rowc[1] <= { blobby[23], blobby[22] };
    end
    wire[63:0] rowc2 = { 32'h06, testing_nonce };
    assign rowb = '{ buff_rowb[0], buff_rowb[1],          buff_rowb[2], buff_rowb[3], buff_rowb[4] };
    assign rowc = '{ buff_rowc[0], buff_rowc[1],          rowc2,        64'h0,        64'h0 };
    assign rowd = '{ 64'h0,        64'h80000000_00000000, 64'h0,        64'h0,        64'h0 };
    assign rowe = '{ 64'h0,        64'h0,                 64'h0,        64'h0,        64'h0 };
end

wire resgood;
wire[63:0] resa[5], resb[5], resc[5], resd[5], rese[5];
sha3 #(
    .THETA_UPDATE_BY_DSP(THETA_UPDATE_BY_DSP),
    .ROUND_OUTPUT_BUFFERED(ROUND_OUTPUT_BUFFERED),
    .LAST_ROUND_IS_PROPER(PROPER)
) hasher(
    .clk(clk),
    .sample(buff_dispatching),
    .rowa(rowa), .rowb(rowb), .rowc(rowc), .rowd(rowd), .rowe(rowe),
    .ogood(resgood),
    .oa(resa), .ob(resb), .oc(resc), .od(resd), .oe(rese)
);

assign evaluating = resgood;


wire[63:0] hash_diff;
if (PROPER) assign hash_diff = resa[3];
else assign hash_diff = {
    resa[0][ 7: 0], resa[0][15: 8], resa[0][23:16], resa[0][31:24],
    resa[0][39:32], resa[0][47:40], resa[0][55:48], resa[0][63:56]
};
wire good_enough = evaluating & ($unsigned(hash_diff) <= $unsigned(threshold));

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
