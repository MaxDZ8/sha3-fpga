`timescale 1ns / 1ps

// In this testbench I focus on correctness of the SHA3 core.
// In this first test I only go for the generic non-last round.
// Also useful to observe latency.
module uut_sha3_rho_pi();

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

localparam longint unsigned give[1][5][5] = '{ // outputs from a theta
    '{
        '{ 64'h0d888ed72242195b, 64'h2a986b9d7b342771, 64'h826c5daedc88ff4b, 64'h3fb6f9b17d26b193, 64'hc461f69a2607ef64 },
        '{ 64'ha9c53ab680ed603a, 64'hb861c744bf418b2e, 64'h10d80d4c4d993084, 64'h8b4ebee43da7f60f, 64'h8eba06ad6e9fcc0f },
        '{ 64'h730f0df8f82d0987, 64'h402aa4f0ed03ea34, 64'haa58c0b1ca7c7793, 64'h052a59c821521df6, 64'h6db2ea5be5ea2881 },
        '{ 64'h18a7f138dc48c7e6, 64'h8301674939488e2d, 64'hdd2e7d84aa0a7277, 64'h4fdd61284b1cafaf, 64'h9ee073d45b22f8a6 },
        '{ 64'ha2cab94a2cf02b70, 64'h8a39be8c8f75c3e3, 64'h2742348b9200dd65, 64'h71718bdb1a1eee33, 64'h970094fa551dc757 }
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

sha3_rho_pi testing(
    .clk(clk),
    .isa(feeda), .isb(feedb), .isc(feedc), .isd(feedd), .ise(feede),
    .sample(start),
    .osa(result[0]), .osb(result[1]), .osc(result[2]), .osd(result[3]), .ose(result[4]),
    .ogood(good)
);


initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start SHA3-1600 RHO (correctness, observe latency)");
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
        '{ 64'h0d888ed72242195b, 64'h18b2eb861c744bf4, 64'he3bc9d52c6058e53, 64'h25096395f5e9fbac, 64'h253e954771d5e5c0 },
        '{ 64'h17d26b1933fb6f9b, 64'h6ad6e9fcc0f8eba0, 64'h98786fc7c1684c3b, 64'h11c5b0602ce92729, 64'ha4e8469172401bac },
        '{ 64'h5530d73af6684ee2, 64'h36035313664c2104, 64'h9042a43bec0a54b3, 64'he073d45b22f8a69e, 64'he528b3c0adc28b2a },
        '{ 64'hd1303f7b26230fb4, 64'h0ed603aa9c53ab68, 64'haa93c3b40fa8d100, 64'h3ec25505393bee97, 64'h3371718bdb1a1eee },
        '{ 64'he09b176bb7223fd2, 64'h07c5a75f721ed3fb, 64'hf51440b6d9752df2, 64'h918fcc314fe271b8, 64'h28e6fa323dd70f8e }
    }
};

int result_index = 0;

always @(posedge good)
begin
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
    $display("SHA3-1600 RHO GOOD");
    $finish;
  end
end
  
endmodule
