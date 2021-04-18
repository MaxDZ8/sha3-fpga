`timescale 1ns / 1ps

// IOTA taking a round number 0..23 by port.
// Internally selects its magic number to XOR into el[0].
module sha3_iterable_iota #(
    OUTPUT_BUFFER = 0
)(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input[4:0] round_index,
    input sample,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood,
    output[4:0] oround
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

wire[63:0] mangled[5] = '{ isa[0] ^ magic, isa[1], isa[2], isa[3], isa[4] };

sha3_state_capture#(
    .BUFFERIZE(OUTPUT_BUFFER)
) outbuff(
    .clk(clk),
    .sample(sample), .isa(mangled), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(ogood),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);

if (OUTPUT_BUFFER) begin
    bit[4:0] was_round;
    always_ff @(posedge clk) was_round <= round_index;
    assign oround = was_round;
end
else assign oround = round_index;

endmodule
