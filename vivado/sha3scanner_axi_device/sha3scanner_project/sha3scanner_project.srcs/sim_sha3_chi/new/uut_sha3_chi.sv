`timescale 1ns / 1ps


module uut_sha3_chi();

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

localparam longint unsigned give[1][5][5] = '{ // outputs from a rho-pi
    '{
        '{ 64'h0d888ed72242195b, 64'h18b2eb861c744bf4, 64'he3bc9d52c6058e53, 64'h25096395f5e9fbac, 64'h253e954771d5e5c0 },
        '{ 64'h17d26b1933fb6f9b, 64'h6ad6e9fcc0f8eba0, 64'h98786fc7c1684c3b, 64'h11c5b0602ce92729, 64'ha4e8469172401bac },
        '{ 64'h5530d73af6684ee2, 64'h36035313664c2104, 64'h9042a43bec0a54b3, 64'he073d45b22f8a69e, 64'he528b3c0adc28b2a },
        '{ 64'hd1303f7b26230fb4, 64'h0ed603aa9c53ab68, 64'haa93c3b40fa8d100, 64'h3ec25505393bee97, 64'h3371718bdb1a1eee },
        '{ 64'he09b176bb7223fd2, 64'h07c5a75f721ed3fb, 64'hf51440b6d9752df2, 64'h918fcc314fe271b8, 64'h28e6fa323dd70f8e }
    }
};

bit start = 1'b0;
int dispatch_index = 0;
wire[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5];
generate
    for (genvar loop = 0; loop < 5; loop++) begin
        assign feeda[loop] = give[dispatch_index][0][loop];
        assign feedb[loop] = give[dispatch_index][1][loop]; 
        assign feedc[loop] = give[dispatch_index][2][loop]; 
        assign feedd[loop] = give[dispatch_index][3][loop]; 
        assign feede[loop] = give[dispatch_index][4][loop]; 
    end
endgenerate 

wire[63:0] result[5][5];
wire good;

sha3_chi testing(
    .clk(clk),
    .isa(feeda), .isb(feedb), .isc(feedc), .isd(feedd), .ise(feede),
    .sample(start),
    .osa(result[0]), .osb(result[1]), .osc(result[2]), .osd(result[3]), .ose(result[4]),
    .ogood(good)
);


initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start SHA3-1600 CHI (correctness, observe latency)");
  #150 // wait for GSR and other nonsense.
  reset = 0;
  #50
  $display("signals considered settled");
  dispatching = 1;
end
  

always @(posedge clk) if(dispatching) begin
    if(dispatch_index != $size(give, 1)) begin
        if (start) begin // 1 clock sample pulse
            start <= 1'b0;
            dispatch_index <= dispatch_index + 1;
        end
        else begin // when starting just pulse the first, then pulse after a result is received
            start <= dispatch_index == 0 | good;
        end
    end
end


localparam longint unsigned expected_result[1][5][5] = '{
    '{
        '{ 64'hee849a87e0439d58, 64'h1cb389032d9c3a58, 64'he38a0910c6118a13, 64'h2d896905f7ebe3b7, 64'h350cf4476de1a764 },
        '{ 64'h87fa6d1a32fb6b80, 64'h6b5379dcec79c8a0, 64'h3c502956936854bf, 64'h02d799682d52433a, 64'hccecc675b2409b8c },
        '{ 64'hd57073127e6a1a51, 64'h5632035364bc8308, 64'h954a87bb61085d93, 64'hf063906170d0e25e, 64'hc72bb3c1adc6aa2e },
        '{ 64'h7131ff6f258b5fb4, 64'h1a9617abac4085ff, 64'haba2e33ecda8c168, 64'hfec25b751d1aef87, 64'h3db7710b434abea6 },
        '{ 64'h108b57cb3e4313d2, 64'h074e2b5e749c83f3, 64'hdd7472b4e96023f4, 64'h5196c978cdc241e8, 64'h2fa25a267dcbcfa7 }
    }
};

int result_index = 0;

always @(posedge clk) if(good) begin
  for (int loop = 0; loop < 5; loop++) begin
      for (int comp = 0; comp < 5; comp++) begin
          if (result[loop][comp] != expected_result[result_index][loop][comp]) begin
            $display("Result[%d][%d][%d] !! FAILED !! (expected %d, found %d)",
                     result_index, loop, comp, expected_result[result_index][loop][comp], result[loop][comp]);
            $fatal;
            $finish;
          end
      end
  end
  $display("Result[%d] %t", result_index, $realtime);
  result_index++;
  if(result_index == $size(expected_result, 1)) begin
    $display("SHA3-1600 CHI GOOD");
    $finish;
  end
end
  
endmodule
