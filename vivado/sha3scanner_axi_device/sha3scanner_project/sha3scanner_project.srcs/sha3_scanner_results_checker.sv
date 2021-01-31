`timescale 1ns / 1ps

// Check the result from the scan is nice!
module sha3_scanner_results_checker #(
    TESTBENCH_NAME = "<forgot to set>",
    TEST_MODE = "short",
    ALGO_IS_PROPER = 1
)(
    input clk,
    input found,
    input[63:0] hash[25],
    input[31:0] nonce
);

wire[63:0] short_hash[25], long_hash[25];
wire[63:0] short_nonce, long_nonce;
if (ALGO_IS_PROPER) begin : proper
    initial begin
        $display("TODO");
        $finish();
    end
end
else begin : quirky
    assign short_hash = '{
        64'hb319dc707b8f2201, 64'h4fb59867f9b9083f, 64'hde52c0ad68ecbc9b, 64'h30672bf6dc8de8fa, 64'h032a8c1b7d177282,
        64'h94e7991e8c180cb6, 64'hb0f071d458870b2c, 64'h215b9f5c71767a9b, 64'hc45a22850ae3479a, 64'hdd71c69fd64b790d,
        64'h60bf2838a75eaaba, 64'h423e8d95c57139d9, 64'h1d61b705cc06da38, 64'h3cdb6837e0771716, 64'h4fb10f99f2ba6eac,
        64'h6f13ec4619144b09, 64'h8d5b272e40c7e0f8, 64'h6d17f10957e93166, 64'h70d9c050187189ae, 64'hc7354da06a9e9960,
        64'h65ba5184b70f9627, 64'ha02723ec6bc3e8f3, 64'h14babc6c14deb190, 64'h27a9109c781732f6, 64'h2d04a997ad22222a
    };
    assign short_nonce = 234; // NOTE: scan_hash in legacy miners would return 235
    
    
    assign long_hash = '{
        64'h6a4e218fc8a10000, 64'ha99c2f4c5c17f865, 64'h3ef0b70e32cbab15, 64'ha799551a987f59ef, 64'h2be1aeaf67c21f9d,
        64'h30f154dff3907e5f, 64'hc1fb321a97bdcafe, 64'h25c6fce84e8ca737, 64'h87c300dc93d3ad3d, 64'h1de478d1e6d77335,
        64'h25cdde2c8246619a, 64'hb4426015fbeae22b, 64'he3a288675c1f0e75, 64'hb5c5d7a4a55f1a5e, 64'h3f9b670a6d418780,
        64'hf0cae5cc32f1e3e0, 64'h494a9810b0bb0000, 64'h6b9058a97d081735, 64'hb06cccdf08572775, 64'h752de3cc7aee6c0a,
        64'h524c190f0d6d7b76, 64'hf85626e278e33590, 64'h4b4e64b3556d524b, 64'hb203ba745d1514dd, 64'hf19aa1eb27a7bd38
    };
    assign long_nonce = 16855; // remember scan_hash in legacy returns count of hashes done so +1
end


function longint unsigned expected_hash(input int index);
    if(TEST_MODE == "short") return short_hash[index];
    return long_hash[index];
endfunction

function longint unsigned expected_nonce();
    if(TEST_MODE == "short") return short_nonce;
    return long_nonce;
endfunction


always @(posedge clk) if(found) begin
  for (int loop = 0; loop < 25; loop++) begin
      if (hash[loop] != expected_hash(loop)) begin
        $display("Result[%d] !! FAILED !! (expected %h, found %h)", loop, expected_hash(loop), hash[loop]);
        $fatal;
        $finish;
      end
  end
  if (nonce != expected_nonce()) begin
        $display("Iteration count differs !! FAILED !! (expected %h, found %h)", expected_nonce(), nonce);
        $fatal;
        $finish;
  end
  $display("Result @ %t nonce = %d 0x%h", $realtime, nonce, nonce);
  $display("%s scanner GOOD", TESTBENCH_NAME);
  $finish;
end

endmodule
