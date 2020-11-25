`timescale 1ns / 1ps

interface iSha3_1600_BusIn();
    // When this is high, inX contains good data to be captured.
    wire sample;
    // The various rows of the SHA3 state.
    wire[63:0] ina[5], inb[5], inc[5], ind[5], ine[5];
    
    // "Consumer" of data
    modport periph(input sample, ina, inb, inc, ind, ine);
    // "Producer" of data to be sent to peripheral / inner module.
    modport controller(output sample, ina, inb, inc, ind, ine);
endinterface : iSha3_1600_BusIn
