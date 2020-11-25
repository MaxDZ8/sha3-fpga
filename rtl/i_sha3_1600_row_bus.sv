`timescale 1ns / 1ps

interface i_sha3_1600_row_bus();
    // When this is high, rowX contains good data to be captured.
    wire sample;
    // Rowa is top, usually row[0], rowe is bottom, usually row[4].
    wire[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5];
    
    // "Consumer" of data
    modport periph(input sample, rowa, rowb, rowc, rowd, rowe);
    // "Producer" of data to be sent to peripheral / inner module.
    modport controller(output sample, rowa, rowb, rowc, rowd, rowe);
endinterface : i_sha3_1600_row_bus
