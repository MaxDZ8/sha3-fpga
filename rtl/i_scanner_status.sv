`timescale 1ns / 1ps

// My scanners pour out a few status control signals.
// Mostly used for led blinking galore, .ready is important!
interface i_scanner_status();
    // True if you are scanning. You might be not scanning because A- idle or B- flushing pipe after nonce found
    wire dispatching;
    // Strobes 1clk when evaluating difficulty of a hash, even when later discarded.
    wire evaluating;
    // IMPORTANT
    // True if you can start a new scan. You might be idle or pipeline flushed after nonce found.
    wire ready;
    
    modport producer(output dispatching, evaluating, ready);
    modport consumer(input dispatching, evaluating, ready);
endinterface
