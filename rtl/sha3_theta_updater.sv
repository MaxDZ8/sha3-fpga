`timescale 1ns / 1ps

// Updates the various slices by xorring their elements with the given elts.
// Each elt values goes into a different slice.
// I am the last operation in theta so I apply some kind of buffering to outputs.
module sha3_theta_updater #(
    LOGIC_STYLE = "basic"
)(
    input clk,
    input sample,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5], elt[5],
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5]
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
end
else begin
    // Another candidate is: DSP48
    $error("Logic style unsupported.");
end

endmodule
