`timescale 1ns / 1ps

// Evaluating theta-elts is better done for all the slices toghether: produce 5 temporary terms, each used twice.
// We start doing some logic here so this buffers its inputs before everything.
// This assumes you buffered the various inputs yourself real close.
module sha3_theta_elts(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] oelt[5]
);

// The term computation. The various elements in a slice are just to be xor'ed together.
// The result goes in its flip-flop for better timing. 
longint unsigned term[5];
genvar geni;
for (geni = 0; geni < 5; geni++) begin
    always_ff @(posedge clk) term[geni] <= isa[geni] ^ isb[geni] ^ isc[geni] ^ isd[geni] ^ ise[geni];
end

sha3_theta_elt_evaluator rotxor(
    .clk(clk), .term(term), .elt(oelt)
);

endmodule
