`timescale 1ns / 1ps

// In this testbench I focus on correctness of the SHA3 core.
// In this first test I only go for the generic non-last round.
// Also useful to observe latency.
module uut_sha3_round();

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

localparam string THETA_BINARY_LOGIC_STYLE = "basic";
localparam string CHI_MODIFY_STYLE = "basic";

localparam longint unsigned give[1][5][5] = '{
    '{
        '{ 64'hed349f06686d8027, 64'h5fe39318706f6195, 64'h3c9888ad4a48c9f1, 64'h38fa73ea4c9f9798, 64'h577448dae745d880 },
        '{ 64'h49792b67cac2f946, 64'hcd1a3fc1b41acdca, 64'hae2cd84fdb59063e, 64'h8c0234bf0c1ed004, 64'h1dafb8edafddfbeb },
        '{ 64'h93b31c29b20290fb, 64'h35515c75e658acd0, 64'h14ac15b25cbc4129, 64'h0266d39310eb3bfd, 64'hfea7541b24a81f65 },
        '{ 64'hf81be0e996675e9a, 64'hf67a9fcc3213c8c9, 64'h63daa8873cca44cd, 64'h4891eb737aa589a4, 64'h0df5cd949a60cf42 },
        '{ 64'h4276a89b66dfb20c, 64'hff424609842e8507, 64'h99b6e18804c0ebdf, 64'h763d01802ba7c838, 64'h04152aba945ff0b3 }
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
wire ogood;

sha3_round_function #(.ROUND_INDEX( 0)) round00(
    .clk(clk),
    .isa(feeda), .isb(feedb), .isc(feedc), .isd(feedd), .ise(feede),
    .sample(start),
    .osa(result[0]), .osb(result[1]), .osc(result[2]), .osd(result[3]), .ose(result[4]),
    .ogood(ogood)
);


initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start SHA3-1600 round (non-last, correctness, observe latency)");
  #150 // wait for GSR and other nonsense.
  reset = 0;
  #50
  $display("signals considered settled");
  dispatching = 1;
end
  

always @(posedge clk) if(dispatching) begin
    if(dispatch_index != $size(give, 1)) begin
        if (start) begin // 1 clock sample pulse
            start = 1'b0;
            dispatch_index++;
        end
        else begin // when starting just pulse the first, then pulse after a result is received
            start = dispatch_index == 0 | ogood;
        end
    end
end


localparam longint unsigned expected_result[1][5][5] = '{
    '{
        '{ 64'hee849a87e0439d59, 64'h1cb389032d9c3a58, 64'he38a0910c6118a13, 64'h2d896905f7ebe3b7, 64'h350cf4476de1a764 },
        '{ 64'h87fa6d1a32fb6b80, 64'h6b5379dcec79c8a0, 64'h3c502956936854bf, 64'h02d799682d52433a, 64'hccecc675b2409b8c },
        '{ 64'hd57073127e6a1a51, 64'h5632035364bc8308, 64'h954a87bb61085d93, 64'hf063906170d0e25e, 64'hc72bb3c1adc6aa2e },
        '{ 64'h7131ff6f258b5fb4, 64'h1a9617abac4085ff, 64'haba2e33ecda8c168, 64'hfec25b751d1aef87, 64'h3db7710b434abea6 },
        '{ 64'h108b57cb3e4313d2, 64'h074e2b5e749c83f3, 64'hdd7472b4e96023f4, 64'h5196c978cdc241e8, 64'h2fa25a267dcbcfa7 }
    }
};

int result_index = 0;

always @(posedge clk) if(ogood) begin
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
    $display("SHA3-1600 round GOOD");
    $finish;
  end
end
  
endmodule
