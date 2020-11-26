`timescale 1ns / 1ps

// 25 ulongs in lines of 5 to the hasher interface.
module pack_lines_into_1600_row_bus(
    input[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5],
    input sample,
    i_sha3_1600_row_bus.controller as
);

assign as.sample = sample;
assign as.rowa = rowa;
assign as.rowb = rowb;
assign as.rowc = rowc;
assign as.rowd = rowd;
assign as.rowe = rowe;
    
endmodule
