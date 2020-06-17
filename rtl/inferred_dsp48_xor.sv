`timescale 1ns / 1ps

(* use_dsp = "logic" *)
module inferred_dsp48_xor(
    input clk,
    input[47:0] one, two,
    output[47:0] res
);

bit[47:0] abi, abii;
bit[47:0] creg;

always_ff @(posedge clk) begin
    abi <= one;
    abii <= abi;
    creg <= two;
end

bit[47:0] preg;
always_ff @(posedge clk) preg <= abii ^ creg;
assign res = preg;

endmodule
