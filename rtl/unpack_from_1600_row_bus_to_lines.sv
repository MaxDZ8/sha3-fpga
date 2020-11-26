`timescale 1ns / 1ps

// Unpack the bus into 5 lines of 5 plus the good signal.
module unpack_from_1600_row_bus_to_lines(
    i_sha3_1600_row_bus.periph from,
    output sample,
    output[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5]
);

assign sample = from.sample;
assign rowa = from.rowa;
assign rowb = from.rowb;
assign rowc = from.rowc;
assign rowd = from.rowd;
assign rowe = from.rowe;

endmodule
