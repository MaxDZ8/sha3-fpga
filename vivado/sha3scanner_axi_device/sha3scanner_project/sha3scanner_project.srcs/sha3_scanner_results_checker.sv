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
        64'hd1a8bd39a62c7301, 64'h0c27714aa1d395c4, 64'hbb1c1c5c70f6246a, 64'h33c1bd22d85e31dc, 64'h2687dc79a0864a5f,
        64'hd841d964ba7aeb5e, 64'h3f3cd2e460a055f4, 64'h272ee53c700af7a4, 64'h52b9090fd15778b6, 64'hb38235c32d28d9c3,
        64'h9816ea680c109ebe, 64'h24fa8d19b3b32462, 64'hd1b0d2ac6cee1e22, 64'ha4abd968b969d2b9, 64'hff329e31d83cda62,
        64'h325b8d98168382a5, 64'h96a8aed4a23e081a, 64'h30934e6194879742, 64'hee9538aa987e326c, 64'h2ae78d38d38203dc,
        64'h7e4710a4891383f6, 64'h72c6aa131bd18fd6, 64'h67cb52177f28e29a, 64'h90971806cef30b2a, 64'hf94ed2f472ea6f59
    };
    assign short_nonce = 55; // NOTE: scan_hash in legacy miners would return 56
    
    
    assign long_hash = '{
        64'ha05c614d02110400, 64'h4ad565d35b796818, 64'hd5047964213164b2, 64'hc71db42361703d68, 64'hd93819a3c8a2de5d,
        64'hce4199f33c2e703b, 64'h76e73458248e23f9, 64'h5d22b12a85dacb7d, 64'hf3476db037c28b0f, 64'hbad3ea429e0a34a8,
        64'hcd54ca9be7fea14d, 64'hb6619224b88aa4bd, 64'h55513b675b00a282, 64'h45a6f08b54eb14cc, 64'hc2214ca9082e4c2e,
        64'h1754758408491211, 64'hb12fa77789e6baa3, 64'hf61ca1980788d79c, 64'h86e853bd93da3e70, 64'h1f89bf63af0c3f51,
        64'h42b388df80fe3c76, 64'h787858f32ab2f323, 64'he19e24e99b695fb0, 64'h823ced538edb8f0a, 64'h153f38c09a81684a
    };
    assign long_nonce = 161639; // remember scan_hash in legacy returns count of hashes done so +1
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
        $display("Nonce differs !! FAILED !! (expected %h, found %h)", expected_nonce(), nonce);
        $fatal;
        $finish;
  end
  $display("Result @ %t nonce = %d 0x%h", $realtime, nonce, nonce);
  $display("%s scanner GOOD", TESTBENCH_NAME);
  $finish;
end

endmodule
