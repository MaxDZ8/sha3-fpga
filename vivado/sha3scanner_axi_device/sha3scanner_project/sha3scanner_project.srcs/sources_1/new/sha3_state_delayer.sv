`timescale 1ns / 1ps

// A bunch of buffers to delay 25 ulongs a few clocks!
module sha3_state_delayer #(
    // Some values:
    // 0- just rename the wires
    // 1- FF-based delay
    // 2- FF-based delay
    // 3..16- 'generic' delay based on FIFO
    // >16 FAIL
    // <0 FAIL 
    DELAY = 4
)(
    input clk,
    // input slices
    input sample, // unused if DELAY = 0
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    // output delayed
    output[63:0] oda[5], odb[5], odc[5], odd[5], ode[5],
    output good
);


genvar comp;

if (DELAY < 0) begin
    initial begin
        $display("DELAY must be at least 0");
        $finish;
    end
end
else if(DELAY == 0) begin
    // Added to support some possible async module permutations w/o surprises, not expected to be used.
    for (comp = 0; comp < 5; comp++) begin
        assign oda[comp] = isa[comp];
        assign odb[comp] = isb[comp];
        assign odc[comp] = isc[comp];
        assign odd[comp] = isd[comp];
        assign ode[comp] = ise[comp];
    end
    assign good = sample;
end
else if(DELAY == 1) begin : just_buffin // Buffer the inputs.
    sha3_state_capture delayin(
        .clk(clk),
        .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
        .ogood(good),
        .osa(oda), .osb(odb), .osc(odc), .osd(odd), .ose(ode)
    );
end
else if (DELAY == 2) begin : iobuff // copy input buffer to output buffer
    wire[63:0] between[5][5];
    wire delayed;
    sha3_state_capture delay_before(
        .clk(clk),
        .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
        .ogood(delayed),
        .osa(between[0]), .osb(between[1]), .osc(between[2]), .osd(between[3]), .ose(between[4])
    );
    sha3_state_capture delay_later(
        .clk(clk),
        .sample(delayed),
        .isa(between[0]), .isb(between[1]), .isc(between[2]), .isd(between[3]), .ise(between[4]),
        .ogood(good),
        .osa(oda), .osb(odb), .osc(odc), .osd(odd), .ose(ode)
    );
end
else begin : generically // one input, one output and something between
    
    bit[(DELAY - 2):0] delay = 0;
    always_ff @(posedge clk) delay <= { delay[(DELAY - 3):0], sample };
    assign pullout = delay[DELAY - 2];

    wire[63:0] consolidated[25];
    for (genvar comp = 0; comp < 5; comp++) begin
        assign consolidated[0 * 5 + comp] = isa[comp]; 
        assign consolidated[1 * 5 + comp] = isb[comp]; 
        assign consolidated[2 * 5 + comp] = isc[comp]; 
        assign consolidated[3 * 5 + comp] = isd[comp]; 
        assign consolidated[4 * 5 + comp] = ise[comp]; 
    end
    wire[63:0] giving[25];
    for (genvar el = 0; el < 25; el++) begin : delayer
        // I can't get to infer LUTRAM so I'll just put there an XPM and call it day.
        // Plus, using an XPM (hardware?) fifo can harden the delay counter itself :-)
        wire[63:0] taking = consolidated[el];
        xpm_fifo_sync #(
            .FIFO_MEMORY_TYPE("auto"), // default, let vivado choose
            .FIFO_READ_LATENCY(1), // default, I'll read one clock first for best timing
            .FIFO_WRITE_DEPTH(16), // hopefully less, this is the minimum allowed by macro
            .READ_DATA_WIDTH(64), // default 32
            .SIM_ASSERT_CHK(1),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            .USE_ADV_FEATURES("0000"), // features: nothing
            .WRITE_DATA_WIDTH(64) // default 32
        )
        xpm_fifo (
          .wr_en(sample), .din(taking),
          .rd_en(pullout), .dout(giving[el]),
          .rst(1'b0), // well... that's weird, but I just keep it flowing.
          .sleep(1'b0), // as from documentation. It literally reads: "Tie to 1'b0". ^_^!
          .wr_clk(clk),
          
          .injectdbiterr(1'b0), .injectsbiterr(1'b0)
        );
    end
    for (genvar comp = 0; comp < 5; comp++) begin
        assign oda[comp] = giving[0 * 5 + comp]; 
        assign odb[comp] = giving[1 * 5 + comp]; 
        assign odc[comp] = giving[2 * 5 + comp]; 
        assign odd[comp] = giving[3 * 5 + comp]; 
        assign ode[comp] = giving[4 * 5 + comp]; 
    end
   
    bit buffo = 1'b0;
    always_ff @(posedge clk) buffo <= pullout;
    assign good = buffo;
end

endmodule
