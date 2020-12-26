`timescale 1ns / 1ps

// Select one of two 1600-bit sparse busses.
// Also flow a round counter with the same latency.
// When selector is hi, input is taken from b.
module mux1600 #(
    STYLE = "fabric"
)(
    input clk, sample, selector,
    input[4:0] round,
    input[63:0] a[25],
    input[63:0] b[25],
    output ogood,
    output[63:0] o[25],
    output[4:0] oround
);

if (STYLE == "fabric") begin : fabric
    longint unsigned obuff[25];
    for (genvar comp = 0; comp < 25; comp++) begin
        always_ff @(posedge clk) if(sample) obuff[comp] = selector? b[comp] : a[comp];
        assign o[comp] = obuff[comp];
    end
    
    bit[4:0] buff_oround = 6'b0;
    always_ff @(posedge clk) if (sample) buff_oround <= round;
    assign oround = buff_oround;
    
    bit buff_ogood = 1'b0;
    always_ff @(posedge clk) buff_ogood <= sample;
    assign ogood = buff_ogood;
end
else if (STYLE == "DSP") begin : dsp
    mux1600_by_dsp48 silly(
        .clk(clk),
        .sample(sample), .selector(selector), .round(round),
        .a(a), .b(b),
        .ogood(ogood),
        .oround(oround),
        .o(o)
    );
end


endmodule
