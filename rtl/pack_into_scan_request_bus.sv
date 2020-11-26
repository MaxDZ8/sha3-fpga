`timescale 1ns / 1ps

module pack_into_scan_request_bus(
    input start,
    input[31:0] blobby[24],
    input[63:0] threshold,
    
    i_sha3_scan_request_bus.producer as
);

assign as.start = start;
assign as.threshold = threshold;
assign as.blockTemplate = '{
    blobby[ 0], blobby[ 1], blobby[ 2], blobby[ 3], blobby[ 4], blobby[ 5], blobby[ 6], blobby[ 7],
    blobby[ 8], blobby[ 9], blobby[10], blobby[11], blobby[12], blobby[13], blobby[14], blobby[15],
    blobby[16], blobby[17], blobby[18], blobby[19], blobby[20], blobby[21], blobby[22], blobby[23]
};
endmodule
