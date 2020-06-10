`timescale 1ns / 1ps

module sha3 #(
    THETA_UPDATE_LOGIC_STYLE = "basic",
    CHI_MODIFY_STYLE = "basic",
    IOTA_STYLE = "basic"
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

wire feed_next[23];
wire[63:0] chain[23][5][5];
sha3_round_function #(
    .THETA_UPDATE_LOGIC_STYLE(THETA_UPDATE_LOGIC_STYLE),
    .CHI_MODIFY_STYLE(CHI_MODIFY_STYLE),
    .IOTA_STYLE(IOTA_STYLE),
    .ROUND_INDEX(0)
) first_round (
    .clk(clk),
    .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(feed_next[0]), .osa(chain[0][0]),  .osb(chain[0][1]),  .osc(chain[0][2]),  .osd(chain[0][3]),  .ose(chain[0][4]) 
);

for (genvar intermediate = 1; intermediate < 23; intermediate++) begin : similarly
    localparam previously = intermediate - 1; 
    wire fetch = feed_next[previously];
    wire[63:0] ina[5] = chain[previously][0];
    wire[63:0] inb[5] = chain[previously][1];
    wire[63:0] inc[5] = chain[previously][2];
    wire[63:0] ind[5] = chain[previously][3];
    wire[63:0] ine[5] = chain[previously][4];
    sha3_round_function #(
        .THETA_UPDATE_LOGIC_STYLE(THETA_UPDATE_LOGIC_STYLE),
        .CHI_MODIFY_STYLE(CHI_MODIFY_STYLE),
        .IOTA_STYLE(IOTA_STYLE),
        .ROUND_INDEX(intermediate)
    ) cruncher (
        .clk(clk),
        .sample(fetch), .isa(ina), .isb(inb), .isc(inc), .isd(ind), .ise(ine),
        .ogood(feed_next[intermediate]),
        .osa(chain[intermediate][0]),  .osb(chain[intermediate][1]),  .osc(chain[intermediate][2]),  .osd(chain[intermediate][3]),  .ose(chain[intermediate][4]) 
    );
end

sha3_round_function #(
    .THETA_UPDATE_LOGIC_STYLE(THETA_UPDATE_LOGIC_STYLE),
    .CHI_MODIFY_STYLE(CHI_MODIFY_STYLE),
    .IOTA_STYLE(IOTA_STYLE),
    .ROUND_INDEX(23)
) last_round (
    .clk(clk),
    .sample(feed_next[22]),
    .isa(chain[22][0]), .isb(chain[22][1]), .isc(chain[22][2]), .isd(chain[22][3]), .ise(chain[22][4]),
    .ogood(ogood), .osa(osa),  .osb(osb),  .osc(osc),  .osd(osd),  .ose(ose) 
);

endmodule
