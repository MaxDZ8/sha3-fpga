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
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 }
    }
};

bit start = 1'b0;
int dispatch_index = 0;
wire[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5];
generate
    for (genvar loop = 0; loop < 5; loop++) begin
        assign feeda[loop] = give[dispatch_index][loop][0];
        assign feedb[loop] = give[dispatch_index][loop][1]; 
        assign feedc[loop] = give[dispatch_index][loop][2]; 
        assign feedd[loop] = give[dispatch_index][loop][3]; 
        assign feede[loop] = give[dispatch_index][loop][4]; 
    end
endgenerate 

wire[63:0] result[5][5];
wire good;

sha3_5x5_pipelined_round #(.ROUND_INDEX( 0)) round00(
    .clk(clk), .rst(reset),
    .isa(feeda), .isb(feedb), .isc(feedc), .isd(feedd), .ise(feede),
    .sample(start),
    .osa(result[0]), .osb(result[1]), .osc(result[2]), .osd(result[3]), .ose(result[4]),
    .good(good)
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
            start = dispatch_index == 0 | good;
        end
    end
end


localparam longint unsigned expected_result[1][5][5] = '{
    '{
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 },
        '{ 64'b0, 64'b0, 64'b0, 64'b0, 64'b0 }
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
    $display("SHA3-1600 round GOOD");
    $finish;
  end
end
  
endmodule
