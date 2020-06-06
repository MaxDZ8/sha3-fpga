`timescale 1ns / 1ps

// A bunch of buffers to delay 25 ulongs a few clocks!
module sha3_state_delayer #(
    unsigned DELAY = 4
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

if (DELAY < 0) $error("DELAY must be at least 0");
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
    sha3_state_delayer delayin(
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
    longint unsigned buff[DELAY][5][5];
    for (comp = 0; comp < 5; comp++) begin
        // let's start with the inputs.
        always_ff @(posedge clk) if (sample) begin
            buff[0][0][comp] <= isa[comp];
            buff[0][1][comp] <= isb[comp];
            buff[0][2][comp] <= isc[comp];
            buff[0][3][comp] <= isd[comp];
            buff[0][4][comp] <= ise[comp];
        end
        // the in-between shift
        for (genvar lateness = 0; lateness < DELAY - 1; lateness++) begin
            always_ff @(posedge clk) begin
                buff[lateness + 1][0][comp] <= buff[lateness][0][comp]; 
                buff[lateness + 1][1][comp] <= buff[lateness][1][comp]; 
                buff[lateness + 1][2][comp] <= buff[lateness][2][comp]; 
                buff[lateness + 1][3][comp] <= buff[lateness][3][comp]; 
                buff[lateness + 1][4][comp] <= buff[lateness][4][comp]; 
            end
        end
        assign oda[comp] = buff[DELAY - 1][0][comp];
        assign odb[comp] = buff[DELAY - 1][1][comp];
        assign odc[comp] = buff[DELAY - 1][2][comp];
        assign odd[comp] = buff[DELAY - 1][3][comp];
        assign ode[comp] = buff[DELAY - 1][4][comp];
    end

    bit[(DELAY - 1):0] delayed_good = 0;
    always_ff @(posedge clk) delayed_good <= { delayed_good[(DELAY - 2):0], sample };
    assign good  = delayed_good[DELAY - 1];
end

endmodule
