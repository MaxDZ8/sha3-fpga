`timescale 1ns / 1ps

(* use_dsp = "logic" *)
module inferred_dsp48_xor #(
    AB_COUNT = 2
)(
    input clk,
    input[47:0] one, two,
    output[47:0] res
);

bit[47:0] creg;
always_ff @(posedge clk) creg <= two;

bit[47:0] preg;
assign res = preg;

if (AB_COUNT == 0) begin // not really a good idea
    assign res = one ^ two; 
end
else if(AB_COUNT == 1) begin
    bit[47:0] buffabi;
    always_ff @(posedge clk) buffabi <= one;
    always_ff @(posedge clk) preg <= buffabi ^ creg;
end
else begin
    bit[47:0] buffabi, buffabii;
    always_ff @(posedge clk) begin
        buffabi <= one;
        buffabii <= buffabi;
    end
    always_ff @(posedge clk) preg <= buffabii ^ creg;
end


endmodule
