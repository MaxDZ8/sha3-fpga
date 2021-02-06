`timescale 1ns / 1ps

// Updates the various slices by xorring their elements with the given elts.
// Each elt values goes into a different slice.
// I am the last operation in theta so I apply some kind of buffering to outputs.
module sha3_theta_updater #(
    // Valid values are:
    // "basic": most portable LUT-based version including an output buffer (FDRE),
    //          easiest to use.
    // "inferred-dsp": DSP48 in a portable way. Saves logic LUTs and consolidates result buffer into P.
    //                 This has a quirk: sample must go high when .isX are provided. Elts must come
    //                 one clock later. This extra latency helps balancing the pipeline latencies.
    //                 It turns out it doesn't quite work as expected; the pipeline balance register AB is only
    //                 absorbed once, therefore no savings appear. Maybe it'll change its mind in implementation
    //                 but I'd rather have the synth results be coherent.
    // "instantiated-dsp": instantiate DSP48E1 explicitly and be what I want!
    LOGIC_STYLE = "basic",
    AB_COMPENSATE = 1
)(
    input clk,
    input sample,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5], elt[5],
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output ogood
);
    
if (LOGIC_STYLE == "basic") begin
    // The simplest form, I just let inference do its job.
    longint unsigned buffa[5], buffb[5], buffc[5], buffd[5], buffe[5];
    genvar comp;
    for (comp = 0; comp < 5; comp++) begin
        always_ff @(posedge clk) if (sample) begin
            buffa[comp] <= isa[comp] ^ elt[comp];
            buffb[comp] <= isb[comp] ^ elt[comp];
            buffc[comp] <= isc[comp] ^ elt[comp];
            buffd[comp] <= isd[comp] ^ elt[comp];
            buffe[comp] <= ise[comp] ^ elt[comp];
        end
        assign osa[comp] = buffa[comp];
        assign osb[comp] = buffb[comp];
        assign osc[comp] = buffc[comp];
        assign osd[comp] = buffd[comp];
        assign ose[comp] = buffe[comp];
    end
    
    bit buffgood = 1'b0;
    always_ff @(posedge clk) buffgood <= sample;
    assign ogood = buffgood;
end
else if(LOGIC_STYLE == "inferred-dsp" || LOGIC_STYLE == "instantiated-dsp") begin
    localparam abcount = AB_COMPENSATE ? 2 : 1;
    wire[47:0] slices[34], elt48[34], updated[34];
    sha3_state_slice_to_48 splitter (
        .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise), .ispare({ sample, 15'b0 }),
        .ovector(slices)
    );
    sha3_elts_slice_to_48 split_n_dup (.ielt(elt), .spare(16'b0), .oelt(elt48));
    
    if (LOGIC_STYLE == "inferred-dsp") begin : inferred
        for (genvar loop = 0; loop < 34; loop++) begin : lane
            inferred_dsp48_xor #(.AB_COUNT(abcount)) xorring(
                .clk(clk), .one(slices[loop]), .two(elt48[loop]), .res(updated[loop])
            );
        end
    end
    else begin : instantiated
        for (genvar loop = 0; loop < 34; loop++) begin : lane
            instantiated_dsp48_xor #(.AB_COUNT(abcount)) xorring(
                .clk(clk), .one(slices[loop]), .two(elt48[loop]), .res(updated[loop])
            );
        end
    end
    
    wire[15:0] flowed;
    sha3_state_merge_from_48 canonicalize (
        .ivector(updated), .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose), .ospare(flowed)
    );
    assign ogood = flowed[15];
end
else begin
    // Another candidate is: DSP48 explicit
    initial begin
        $display("Logic style unsupported.");
        $finish;
    end
end

endmodule
