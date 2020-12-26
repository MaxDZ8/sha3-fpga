`timescale 1ns / 1ps

// IOTA taking a round number 0..23 by port.
// Internally selects its magic number to XOR into el[0].
module sha3_iterable_iota(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input[4:0] round_index,
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood
);

localparam longint unsigned rc[24] = {
    64'h0000000000000001, 64'h0000000000008082, 64'h800000000000808a, 64'h8000000080008000,
    64'h000000000000808b, 64'h0000000080000001, 64'h8000000080008081, 64'h8000000000008009,
    64'h000000000000008a, 64'h0000000000000088, 64'h0000000080008009, 64'h000000008000000a,
    64'h000000008000808b, 64'h800000000000008b, 64'h8000000000008089, 64'h8000000000008003,
    64'h8000000000008002, 64'h8000000000000080, 64'h000000000000800a, 64'h800000008000000a,
    64'h8000000080008081, 64'h8000000000008080, 64'h0000000080000001, 64'h8000000080008008
};
wire[63:0] magic = rc[round_index];

assign ogood = sample;

assign osa[0] = isa[0] ^ magic;
assign osa[1] = isa[1];
assign osa[2] = isa[2];
assign osa[3] = isa[3];
assign osa[4] = isa[4];

for (genvar comp = 0; comp < 5; comp++) begin
    assign osb[comp] = isb[comp];
    assign osc[comp] = isc[comp];
    assign osd[comp] = isd[comp];
    assign ose[comp] = ise[comp];
end


endmodule
