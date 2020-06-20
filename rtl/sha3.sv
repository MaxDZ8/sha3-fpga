`timescale 1ns / 1ps

module sha3 #(
    THETA_UPDATE_BY_DSP = 24'b0010_0010_0010_0010_0010_0010,
    /* See also sha3_round_function RHOPI_BUFFERS */
    RHOPI_BUFFERS = 0,
    CHI_MODIFY_STYLE = "basic",
    IOTA_STYLE = "basic",
    ROUND_OUTPUT_BUFFERED = 24'b1111_1111_1111_1111_1111_1111
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
    output ogood
);

localparam first_theta_style = THETA_UPDATE_BY_DSP[0] ? "instantiated-dsp" : "basic";
localparam first_round_buffered = ROUND_OUTPUT_BUFFERED[0];
wire feed_next[23];
wire[63:0] chain[23][5][5];
sha3_round_function #(
    .THETA_UPDATE_LOGIC_STYLE(first_theta_style),
    .CHI_MODIFY_STYLE(CHI_MODIFY_STYLE),
    .IOTA_STYLE(IOTA_STYLE),
    .OUTPUT_BUFFERED(first_round_buffered),
    .ROUND_INDEX(0)
) first_round (
    .clk(clk),
    .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(feed_next[0]), .osa(chain[0][0]),  .osb(chain[0][1]),  .osc(chain[0][2]),  .osd(chain[0][3]),  .ose(chain[0][4]) 
);

for (genvar intermediate = 1; intermediate < 23; intermediate++) begin : similarly
    localparam theta_style = THETA_UPDATE_BY_DSP[intermediate] ? "instantiated-dsp" : "basic";
    localparam output_buffered = ROUND_OUTPUT_BUFFERED[intermediate];
    localparam previously = intermediate - 1; 
    wire fetch = feed_next[previously];
    wire[63:0] ina[5] = chain[previously][0];
    wire[63:0] inb[5] = chain[previously][1];
    wire[63:0] inc[5] = chain[previously][2];
    wire[63:0] ind[5] = chain[previously][3];
    wire[63:0] ine[5] = chain[previously][4];
    sha3_round_function #(
        .THETA_UPDATE_LOGIC_STYLE(theta_style),
        .CHI_MODIFY_STYLE(CHI_MODIFY_STYLE),
        .IOTA_STYLE(IOTA_STYLE),
        .ROUND_INDEX(intermediate),
        .OUTPUT_BUFFERED(output_buffered)
    ) cruncher (
        .clk(clk),
        .sample(fetch), .isa(ina), .isb(inb), .isc(inc), .isd(ind), .ise(ine),
        .ogood(feed_next[intermediate]),
        .osa(chain[intermediate][0]),  .osb(chain[intermediate][1]),  .osc(chain[intermediate][2]),  .osd(chain[intermediate][3]),  .ose(chain[intermediate][4]) 
    );
end

localparam last_theta_style = THETA_UPDATE_BY_DSP[23] ? "instantiated-dsp" : "basic";
localparam last_round_buffered = ROUND_OUTPUT_BUFFERED[23];
sha3_round_function #(
    .THETA_UPDATE_LOGIC_STYLE(last_theta_style),
    .CHI_MODIFY_STYLE(CHI_MODIFY_STYLE),
    .IOTA_STYLE(IOTA_STYLE),
    .ROUND_INDEX(23),
    .OUTPUT_BUFFERED(last_round_buffered)
) last_round (
    .clk(clk),
    .sample(feed_next[22]),
    .isa(chain[22][0]), .isb(chain[22][1]), .isc(chain[22][2]), .isd(chain[22][3]), .ise(chain[22][4]),
    .ogood(ogood), .osa(osa),  .osb(osb),  .osc(osc),  .osd(osd),  .ose(ose) 
);

endmodule
