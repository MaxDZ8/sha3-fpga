`timescale 1ns / 1ps

// Check the result from the scan is nice!
module sha3_scanner_results_checker #(
    TESTBENCH_NAME = "<forgot to set>",
    TEST_MODE = "short"
)(
    input clk,
    i_sha3_scan_result_bus.consumer validate
);


localparam longint unsigned short_hash[25] = '{
    64'hd1a8bd39a62c7301, 64'h0c27714aa1d395c4, 64'hbb1c1c5c70f6246a, 64'h33c1bd22d85e31dc, 64'h2687dc79a0864a5f,
    64'hd841d964ba7aeb5e, 64'h3f3cd2e460a055f4, 64'h272ee53c700af7a4, 64'h52b9090fd15778b6, 64'hb38235c32d28d9c3,
    64'h9816ea680c109ebe, 64'h24fa8d19b3b32462, 64'hd1b0d2ac6cee1e22, 64'ha4abd968b969d2b9, 64'hff329e31d83cda62,
    64'h325b8d98168382a5, 64'h96a8aed4a23e081a, 64'h30934e6194879742, 64'hee9538aa987e326c, 64'h2ae78d38d38203dc,
    64'h7e4710a4891383f6, 64'h72c6aa131bd18fd6, 64'h67cb52177f28e29a, 64'h90971806cef30b2a, 64'hf94ed2f472ea6f59
};
localparam longint unsigned short_nonce = 55; // NOTE: scan_hash in legacy miners would return 56


localparam longint unsigned long_hash[25] = '{
    64'h8c6497333bf0600, 64'h3f0191abab17029, 64'ha4e95e1d037ee98, 64'h03f3c3a05bae7ba, 64'h1ace62e0314fd98,
    64'h6eba51026524539, 64'ha7b72892679212f, 64'h0e08f9fad233445, 64'h7c6c8bc84070a32, 64'he13ff443162a018,
    64'h32a7af4473da4a2, 64'hcfaf557cdc5ab9d, 64'h2f5fecce8b864cb, 64'h6af9c1b1a2f217f, 64'h1bf3838216a029f,
    64'habb45c48e248076, 64'hfe5664f4d03a4b0, 64'h3d5a56330548eef, 64'h7a258259bb0d2cd, 64'h1ae69eeed21744d,
    64'h0fd711ebcc5d45f, 64'h9fcebe5166ab01e, 64'ha574eed4d6df9ae, 64'hb6efcd50e6d2e80, 64'hc9818df1d4f8128
};
localparam longint unsigned long_nonce = 132091; // remember scan_hash in legacy returns count of hashes done so +1


function longint unsigned expected_hash(input int index);
    if(TEST_MODE == "short") return short_hash[index];
    return long_hash[index];
endfunction

function longint unsigned expected_nonce();
    if(TEST_MODE == "short") return short_nonce;
    return long_nonce;
endfunction


always @(posedge clk) if(validate.found) begin
  for (int loop = 0; loop < 25; loop++) begin
      if (validate.hash[loop] != expected_hash(loop)) begin
        $display("Result[%d] !! FAILED !! (expected %h, found %h)", loop, expected_hash(loop), validate.hash[loop]);
        $fatal;
        $finish;
      end
  end
  if (validate.nonce != expected_nonce()) begin
        $display("Nonce differs !! FAILED !! (expected %h, found %h)", expected_nonce(), validate.nonce);
        $fatal;
        $finish;
  end
  $display("Result @ %t nonce = %d %h", $realtime, validate.nonce, validate.nonce);
  $display("%s scanner GOOD", TESTBENCH_NAME);
  $finish;
end

endmodule
