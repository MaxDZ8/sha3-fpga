`timescale 1ns / 1ps

// Rename wires from a few chunks of 64-bit busses to a single chunk of 48-bit busses.
// Since there are a few unused bits in the result, you get 16 bits to flow through as you please.
// They end in the lowest bits of ovector[33].
module sha3_state_slice_to_48(
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input[15:0] ispare,
    output[47:0] ovector[34]
);

assign ovector[ 0] = isa[0][63:16];
assign ovector[ 1] = { isa[0][15:0], isa[1][63:32] };
assign ovector[ 2] = { isa[1][31:0], isa[2][63:48] };
assign ovector[ 3] = isa[2][47:0];

assign ovector[ 4] = isa[3][63:16];
assign ovector[ 5] = { isa[3][15:0], isa[4][63:32] };
assign ovector[ 6] = { isa[4][31:0], isb[0][63:48] };
assign ovector[ 7] = isb[0][47:0];

assign ovector[ 8] = isb[1][63:16];
assign ovector[ 9] = { isb[1][15:0], isb[2][63:32] };
assign ovector[10] = { isb[2][31:0], isb[3][63:48] };
assign ovector[11] = isb[3][47:0];

assign ovector[12] = isb[4][63:16];
assign ovector[13] = { isb[4][15:0], isc[0][63:32] };
assign ovector[14] = { isc[0][31:0], isc[1][63:48] };
assign ovector[15] = isc[1][47:0];

assign ovector[16] = isc[2][63:16];
assign ovector[17] = { isc[2][15:0], isc[3][63:32] };
assign ovector[18] = { isc[3][31:0], isc[4][63:48] };
assign ovector[19] = isc[4][47:0];

assign ovector[20] = isd[0][63:16];
assign ovector[21] = { isd[0][15:0], isd[1][63:32] };
assign ovector[22] = { isd[1][31:0], isd[2][63:48] };
assign ovector[23] = isd[2][47:0];

assign ovector[24] = isd[3][63:16];
assign ovector[25] = { isd[3][15:0], isd[4][63:32] };
assign ovector[26] = { isd[4][31:0], ise[0][63:48] };
assign ovector[27] = ise[0][47:0];

assign ovector[28] = ise[1][63:16];
assign ovector[29] = { ise[1][15:0], ise[2][63:32] };
assign ovector[30] = { ise[2][31:0], ise[3][63:48] };
assign ovector[31] = ise[3][47:0];

assign ovector[32] = ise[4][63:16];
assign ovector[33] = { ise[4][15:0], 16'b0, ispare };

endmodule
