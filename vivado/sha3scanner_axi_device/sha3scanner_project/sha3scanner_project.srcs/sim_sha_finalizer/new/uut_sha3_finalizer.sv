`timescale 1ns / 1ps

module uut_sha3_finalizer();

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

bit clk = 1'b0, reset = 1, dispatching = 1'b0;

initial begin
  clk = 0;
  forever begin
    #(PERIOD/2.0) clk = ~clk;
  end
end

localparam longint unsigned give[1][5][5] = '{ // outputs from a last round rho-pi
    '{
        '{ 64'hb4de1272e9397f58, 64'hf3a1f5742180949d, 64'h14304698fc873745, 64'h9e7b50fc25013fb8, 64'h0a1483c12b5b5961 },
        '{ 64'hd8e7f6d215d229d3, 64'h92a2f9afcb663415, 64'hf036c837dacda4bb, 64'hcc2632255c7d22fa, 64'h022f6573a5529bef },
        '{ 64'h6f606d3b08cc0104, 64'h792fdba4cda71275, 64'h233c03b41c6fbea5, 64'hdfdc342dc3a4b5a3, 64'h6ac91551d4697bbf },
        '{ 64'hde475fe966a50a67, 64'hfc06155570883c4e, 64'h25d165155ea74c6b, 64'h1ad4a3f9835660c2, 64'h8a67bd6b602c5e10 },
        '{ 64'hefdb1ed57de12ae1, 64'hb6115f4bf24c97f1, 64'h1fb5f3161977b3f5, 64'hba6d3df1947ac665, 64'ha962c442470ad990 }
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

sha3_finalizer #(
    .OUTPUT_BUFFER(1), .VALUE(64'h8000000080008008)
) testing(
    .clk(clk), .rst(reset),
    .isa(feeda), .isb(feedb), .isc(feedc), .isd(feedd), .ise(feede),
    .sample(start),
    .osa(result[0]), .osb(result[1]), .osc(result[2]), .osd(result[3]), .ose(result[4]),
    .ogood(good)
);


initial begin
  $timeformat(-9,2," ns",14);
  $display("testbench start SHA3-1600 FINALIZER (correctness, observe latency)");
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


localparam longint unsigned expected_result[1][2] = '{
    '{ 64'h30ce10fab53edc10, 64'h79eae51020809c25 }
};

int result_index = 0;

function longint unsigned golden(input int slice, input int component);
    if (slice == 0 && component < 2) begin
        return expected_result[result_index][component];
    end 
    return give[result_index][slice][component]; 
endfunction

always @(posedge clk) if(good) begin
  for (int loop = 0; loop < 5; loop++) begin
      for (int comp = 0; comp < 5; comp++) begin
          if (result[loop][comp] != golden(loop, comp)) begin
            $display("Result[%d][%d][%d] !! FAILED !! (expected %d, found %d)",
                     result_index, loop, comp, golden(loop, comp), result[loop][comp]);
            $fatal;
            $finish;
          end
      end
  end
  $display("Result[%d] %t", result_index, $realtime);
  result_index++;
  if(result_index == $size(expected_result, 1)) begin
    $display("SHA3-1600 FINALIZER GOOD");
    $finish;
  end
end
  
endmodule
