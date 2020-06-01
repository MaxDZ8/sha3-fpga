`timescale 1ns / 1ps

// Evaluating theta-elts is better done for all the slices toghether: produce 5 temporary terms, each used twice.
// We start doing some logic here so this buffers its inputs before everything.
module sha3_theta_elts(
    input clk, rst,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output[63:0] oelt[5]
);

// Dear PaR, feel free to relocate me.
longint unsigned buffin[5][5];
always_ff @(posedge clk) if(sample) begin
    for (int copy = 0; copy < 5; copy++) begin
        buffin[0][copy] <= isa[copy];
        buffin[1][copy] <= isb[copy];
        buffin[2][copy] <= isc[copy];
        buffin[3][copy] <= isd[copy];
        buffin[4][copy] <= ise[copy]; 
    end
end

// The term computation. The various elements in a slice are just to be xor'ed together.
// The result goes in its flip-flop for better timing. 
longint unsigned term[5];
genvar geni;
for (geni = 0; geni < 5; geni++) begin
    always_ff @(posedge clk) term[geni] <= buffin[0][geni] ^ buffin[1][geni] ^ buffin[2][geni] ^ buffin[3][geni] ^ buffin[4][geni];
end

sha3_theta_elt_evaluator rotxor(
    .clk(clk), .rst(rst),
    .term(term), .elt(oelt)
);

endmodule
