`timescale 1ns / 1ps

module sha3_chi #(
    INPUT_BUFFER = 0,
    OUTPUT_BUFFER = 1,
    STYLE = "basic"
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

wire[63:0] args[5][5];
wire green;
sha3_state_capture#(
    .BUFFERIZE(INPUT_BUFFER)
) inbuff(
    .clk(clk),
    .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(green),
    .osa(args[0]), .osb(args[1]), .osc(args[2]), .osd(args[3]), .ose(args[4])
);

wire[63:0] updated[5][5];
wire ready;
if (STYLE == "basic") begin : threeway
    assign ready = green;
    for (genvar slice = 0; slice < 5; slice++) begin
        for (genvar comp = 0; comp < 5; comp++) begin
            wire[63:0] argo = args[slice][comp];
            wire[63:0] arga = args[slice][(comp + 1) % 5];
            wire[63:0] argb = args[slice][(comp + 2) % 5];
            assign updated[slice][comp] = argo ^ ((~arga) & argb); 
        end
    end
end
else begin
    // in the future: inferred DSP? Cascaded DSP?
    $error("unsupported STYLE");
end

sha3_state_capture#(
    .BUFFERIZE(OUTPUT_BUFFER)
) outbuff(
    .clk(clk),
    .sample(ready), .isa(updated[0]), .isb(updated[1]), .isc(updated[2]), .isd(updated[3]), .ise(updated[4]),
    .ogood(ogood),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);

endmodule
