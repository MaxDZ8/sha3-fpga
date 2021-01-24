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
int qdispatch_index = 0;
wire[63:0] qfeeda[5], qfeedb[5], qfeedc[5], qfeedd[5], qfeede[5];
generate
    for (genvar loop = 0; loop < 5; loop++) begin
        assign qfeeda[loop] = give[qdispatch_index][0][loop];
        assign qfeedb[loop] = give[qdispatch_index][1][loop]; 
        assign qfeedc[loop] = give[qdispatch_index][2][loop]; 
        assign qfeedd[loop] = give[qdispatch_index][3][loop]; 
        assign qfeede[loop] = give[qdispatch_index][4][loop];
    end
endgenerate 

wire[63:0] qresult[5][5];
wire qogood;

sha3_round_function #(
    .ROUND_INDEX(23),
    .LAST_ROUND_IS_PROPER(0)
) quirky23 (
    .clk(clk),
    .isa(qfeeda), .isb(qfeedb), .isc(qfeedc), .isd(qfeedd), .ise(qfeede),
    .sample(start),
    .osa(qresult[0]), .osb(qresult[1]), .osc(qresult[2]), .osd(qresult[3]), .ose(qresult[4]),
    .ogood(qogood)
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
  

always @(posedge clk) if(dispatching) begin : disp_quirky
    if(qdispatch_index != $size(give, 1)) begin
        if (start) begin // 1 clock sample pulse
            start = 1'b0;
            qdispatch_index++;
        end
        else begin // when starting just pulse the first, then pulse after a result is received
            start = qdispatch_index == 0 | qogood;
        end
    end
end
  

localparam longint unsigned qexpected_result[1][5][5] = '{ // theta, rho+pi, finalizer. NO CHI
    '{
        '{ 64'h6e849a8760431d50, 64'h1cb389032d9c3a58, 64'he3bc9d52c6058e53, 64'h25096395f5e9fbac, 64'h253e954771d5e5c0 },
        '{ 64'h17d26b1933fb6f9b, 64'h6ad6e9fcc0f8eba0, 64'h98786fc7c1684c3b, 64'h11c5b0602ce92729, 64'ha4e8469172401bac },
        '{ 64'h5530d73af6684ee2, 64'h36035313664c2104, 64'h9042a43bec0a54b3, 64'he073d45b22f8a69e, 64'he528b3c0adc28b2a },
        '{ 64'hd1303f7b26230fb4, 64'h0ed603aa9c53ab68, 64'haa93c3b40fa8d100, 64'h3ec25505393bee97, 64'h3371718bdb1a1eee },
        '{ 64'he09b176bb7223fd2, 64'h07c5a75f721ed3fb, 64'hf51440b6d9752df2, 64'h918fcc314fe271b8, 64'h28e6fa323dd70f8e }
    }
};

int qresult_index = 0;

always @(posedge clk) if(qogood) begin
  for (int loop = 0; loop < 5; loop++) begin
      for (int comp = 0; comp < 5; comp++) begin
          if (qresult[loop][comp] != qexpected_result[qresult_index][loop][comp]) begin
            $display("Result[%d][%d][%d] !! FAILED !! (expected %d, found %d)",
                     qresult_index, loop, comp, qexpected_result[qresult_index][loop][comp], qresult[loop][comp]);
            $fatal;
            $finish;
          end
      end
  end
  $display("Result[%d] %t", qresult_index, $realtime);
  qresult_index++;
  if(qresult_index == $size(qexpected_result, 1)) begin
    $display("SHA3-1600 round GOOD (QUIRKY)");
    $finish;
  end
end
  
endmodule
