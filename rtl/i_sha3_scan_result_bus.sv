`timescale 1ns / 1ps

// Output from a scanner is a nonce and its resulting hash (for correctness computation).
// To be sampled only when .found is high.
interface i_sha3_scan_result_bus();
    // If low, following wires are irrelevant.
    wire found;
    wire[63:0] hash[25];
    wire[31:0] nonce;
    
    modport producer(input found, hash, nonce);
    modport consumer(output found, hash, nonce);
endinterface
