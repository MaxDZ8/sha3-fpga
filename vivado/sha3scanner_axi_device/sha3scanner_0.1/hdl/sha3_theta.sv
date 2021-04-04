`timescale 1ns / 1ps

// Computing theta function can be divided in two main parts
// A- xor the various slices together and produce an elt each
// B- update each slice xor'ing in the elt.
module sha3_theta #(
  UPDATE_LOGIC_STYLE = "basic",
  CAPTURE_CONTINUOUSLY = 1
)(
    input clk,
    input[63:0] isa[5],
    input[63:0] isb[5],
    input[63:0] isc[5],
    input[63:0] isd[5],
    input[63:0] ise[5],
    input sample,
    output[63:0] osa[5],
    output[63:0] osb[5],
    output[63:0] osc[5],
    output[63:0] osd[5],
    output[63:0] ose[5],
    output good
);

// Ok, it is said a good practice is to buffer inputs and outputs... and maybe add some pipeline registers as well.
// The reality is I need to cut on flip-flops. A lot. It also happens the inputs to Theta are always buffered somehow,
// either by the hasher or the previous round so instead of buffering compute elt terms right away.
longint unsigned term[5];
for (genvar comp = 0; comp < 5; comp++) begin : xor5
    always_ff @(posedge clk) term[comp] <= isa[comp] ^ isb[comp] ^ isc[comp] ^ isd[comp] ^ ise[comp];
end


wire fetched;
wire[63:0] buffa[5], buffb[5], buffc[5], buffd[5], buffe[5];
sha3_state_capture #(
    .CAPTURE_CONTINUOUSLY(CAPTURE_CONTINUOUSLY)
) bufferize(
    .clk(clk),
    .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(fetched),
    .osa(buffa), .osb(buffb), .osc(buffc), .osd(buffd), .ose(buffe)
);

// This is the first proper computation so I let the elts buffer once to separate me from the previous round.
// This module itself does not buffer... kinda.
wire[63:0] elt[5];
sha3_theta_elts #(.OUTPUT_BUFFER(0)) eltificator (
    .clk(clk), .iterm(term), .oelt(elt)
);

// Now elts and state come at the same clock so this isn't necessary anymore.
wire[63:0] od[5][5];
wire sample_delayed;
sha3_state_delayer#( .DELAY(0) ) delay (
    .clk(clk),
    .sample(fetched), .isa(buffa), .isb(buffb), .isc(buffc), .isd(buffd), .ise(buffe),
    .oda(od[0]), .odb(od[1]), .odc(od[2]), .odd(od[3]), .ode(od[4]),
    .good(sample_delayed)
);

// Let's just put the things together. Again, I don't buffer the outputs here, everything is delegated.
sha3_theta_updater#(
    .LOGIC_STYLE(UPDATE_LOGIC_STYLE),
    .AB_COMPENSATE(0)
) slice_xorrer (
    .clk(clk),
    .sample(sample_delayed), .isa(od[0]), .isb(od[1]), .isc(od[2]), .isd(od[3]), .ise(od[4]),
    .elt(elt),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose),
    .ogood(good)
);


endmodule
