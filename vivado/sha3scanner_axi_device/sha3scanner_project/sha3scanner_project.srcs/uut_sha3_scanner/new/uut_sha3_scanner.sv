`timescale 1ns / 1ps

module uut_sha3_scanner();

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

// This represents a work->data from legacy miners, where it is usually uint[48].
// For SHA3, only the first 24 values are used, the others can be trashed.
// Entry [21] is special because it is the 'scan start'. It works in a weird way, it's not just a nonce increment
// but also embedded in the block itself so it is not really an offset as hash is a non-linear function.
// Scan-hash in this block is 0. All others are 1024*1024+i.
localparam int unsigned block_template[24] = '{
    32'h00100000, 32'h00100001, 32'h00100002, 32'h00100003, 32'h00100004, 32'h00100005, 32'h00100006, 32'h00100007,
    32'h00100008, 32'h00100009, 32'h0010000a, 32'h0010000b, 32'h0010000c, 32'h0010000d, 32'h0010000e, 32'h0010000f,
    32'h00100010, 32'h00100011, 32'h00100012, 32'h00100013, 32'h00100014, 32'h00000000, 32'h00100016, 32'h00100017
};

localparam string test_mode = "short";

// In legacy miners this is usually work->target[6,7]. They are two uints, loaded as an ulong.
// Now if each uint is assigned 64*1024*1024 + 1024+i you get those magic values.
// This will find a nonce in 56 scans.
localparam longint unsigned short_threshold = 64'h0400040704000406;

// A lower difficulty results in less nonces found. Here you will need to scan the above block template
// until testing nonce 61855. It's quite excessive for behavioural simulation.
localparam longint unsigned long_threshold = 64'h0007000000060000;


localparam longint unsigned threshold = test_mode == "short" ? short_threshold : long_threshold;

bit start = 1'b0, pulsed = 1'b0;

wire scanning, evaluating, found, scanner_ready;
wire[31:0] good_enough;
wire[31:0] dwords[50];

sha3_scanner scanner(
    .clk(clk), .start(start),
    .threshold(threshold),
	  .blobby(block_template),
	  
	  .dispatching(scanning), .evaluating(evaluating), .found(found), .ready(scanner_ready),
	  .nonce(good_enough),
	  .hash(dwords)
);

wire[63:0] result[25] = '{
    { dwords[ 0], dwords[ 1] }, { dwords[ 2], dwords[ 3] }, { dwords[ 4], dwords[ 5] }, { dwords[ 6], dwords[ 7] },
    { dwords[ 8], dwords[ 9] }, { dwords[10], dwords[11] }, { dwords[12], dwords[13] }, { dwords[14], dwords[15] },
    { dwords[16], dwords[17] }, { dwords[18], dwords[19] }, { dwords[20], dwords[21] }, { dwords[22], dwords[23] },
    { dwords[24], dwords[25] }, { dwords[26], dwords[27] }, { dwords[28], dwords[29] }, { dwords[30], dwords[31] },
    { dwords[32], dwords[33] }, { dwords[34], dwords[35] }, { dwords[36], dwords[37] }, { dwords[38], dwords[39] },
    { dwords[40], dwords[41] }, { dwords[42], dwords[43] }, { dwords[44], dwords[45] }, { dwords[46], dwords[47] },
    { dwords[48], dwords[49] }
};


initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start SHA3-1600 scanner");
  #150 // wait for GSR and other nonsense.
  reset = 0;
  #50
  $display("signals considered settled");
  dispatching = 1;
end
  
always_ff @(posedge clk) begin
    if (dispatching) begin
        start <= ~start & ~pulsed;
        if (!pulsed) pulsed <= 1'b1;
    end
end

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
    if(test_mode == "short") return short_hash[index];
    return long_hash[index];
endfunction

function longint unsigned expected_nonce();
    if(test_mode == "short") return short_nonce;
    return long_nonce;
endfunction

always @(posedge clk) if(found) begin
  for (int loop = 0; loop < 25; loop++) begin
      if (result[loop] != expected_hash(loop)) begin
        $display("Result[%d] !! FAILED !! (expected %h, found %h)", loop, expected_hash(loop), result[loop]);
        $fatal;
        $finish;
      end
  end
  if (good_enough != expected_nonce()) begin
        $display("Nonce differs !! FAILED !! (expected %h, found %h)", expected_nonce(), good_enough);
        $fatal;
        $finish;
  end
  $display("Result @ %t nonce = %d %h", $realtime, good_enough, good_enough);
  $display("SHA3-1600 hasher GOOD");
  $finish;
end
  
endmodule
