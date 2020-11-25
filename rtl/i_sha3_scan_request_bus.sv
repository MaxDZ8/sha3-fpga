`timescale 1ns / 1ps

// Request data to a SHA3 scanner.
// Give 24 uints for block template, element [20] is special: start nonce
// Explicitly sampled when .sample high.
//
// .threshold can change at will.
// 
// NOTE: start-ing busy peripherals will cause undefined results (at best, they are nop)
interface i_sha3_scan_request_bus();
    wire start;
    wire[31:0] blockTemplate[24];
    // aka 'difficulty'. Lower --> less nonces found.
    wire[63:0] threshold;
    
    modport consumer(input start, blockTemplate, threshold);
    modport producer(output start, blockTemplate, threshold);
endinterface
