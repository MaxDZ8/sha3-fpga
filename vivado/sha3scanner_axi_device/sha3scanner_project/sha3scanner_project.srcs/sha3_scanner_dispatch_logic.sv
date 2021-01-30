`timescale 1ns / 1ps

module sha3_scanner_dispatch_logic #(
    TESTBENCH_NAME = "<forgot to set>",
    TEST_MODE = "short",
    ALGO_IS_PROPER = 1,
    localparam ULONG_COUNT = ALGO_IS_PROPER ? 10 : 12
)(
    output clk,
    // Scan request
    output start,
    output[63:0] threshold,
    output[31:0] blockTemplate[ULONG_COUNT * 2]
);

localparam CLOCK_RATE = 100_000_000;
localparam PERIOD = 1_000_000_000.0 / CLOCK_RATE;

bit buff_clk = 1'b0, reset = 1;

initial begin
  buff_clk = 0;
  forever begin
    #(PERIOD/2.0) buff_clk = ~buff_clk;
  end
end
assign clk = buff_clk;

if (ALGO_IS_PROPER) begin : proper
    initial begin
        $display("TODO");
        $finish();
    end
end
else begin : quirky
    // This represents a work->data from legacy miners, where it is usually uint[48].
    // For SHA3, only the first 24 values are used, the others can be trashed.
    // Entry [21] is special because it is the 'scan start'. It works in a weird way, it's not just a nonce increment
    // but also embedded in the block itself so it is not really an offset as hash is a non-linear function.
    // Scan-hash in this block is 0. All others are 1024*1024+i.
    assign blockTemplate = '{
        32'h00100000, 32'h00100001, 32'h00100002, 32'h00100003, 32'h00100004, 32'h00100005, 32'h00100006, 32'h00100007,
        32'h00100008, 32'h00100009, 32'h0010000a, 32'h0010000b, 32'h0010000c, 32'h0010000d, 32'h0010000e, 32'h0010000f,
        32'h00100010, 32'h00100011, 32'h00100012, 32'h00100013, 32'h00100014, 32'h00000000, 32'h00100016, 32'h00100017
    };
    
    // In legacy miners this is usually work->target[6,7]. They are two uints, loaded as an ulong.
    // Now if each uint is assigned 64*1024*1024 + 1024+i you get those magic values.
    // This will find a nonce in 56 scans.
    localparam longint unsigned short_threshold = 64'h0400040704000406;
    
    // A lower difficulty results in less nonces found. Here you will need to scan the above block template
    // until testing nonce 61855. It's quite excessive for behavioural simulation.
    localparam longint unsigned long_threshold = 64'h0005000000060000;
    
    assign threshold = TEST_MODE == "short" ? short_threshold : long_threshold;
end


bit dispatching = 1'b0;

initial begin
  $timeformat(-9,2," ns",14);
  $display("scanner start %s", TESTBENCH_NAME);
  #150 // wait for GSR and other nonsense.
  reset = 0;
  #50
  $display("signals considered settled");
  dispatching = 1;
end

  
bit buff_start = 1'b0, pulsed = 1'b0;
always_ff @(posedge clk) begin
    if (dispatching) begin
        buff_start <= ~buff_start & ~pulsed;
        if (!pulsed) pulsed <= 1'b1;
    end
end

assign start = buff_start;

endmodule
