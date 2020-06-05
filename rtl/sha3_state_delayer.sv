`timescale 1ns / 1ps

// A bunch of buffers to delay 25 ulongs a few clocks!
module sha3_state_delayer #(
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
    longint unsigned buffin[5][5];
    bit goodbuff = 1'b0;
    for (comp = 0; comp < 5; comp++) begin
        always_ff @(posedge clk) if (sample) begin
            buffin[0][comp] <= isa[comp];
            buffin[1][comp] <= isb[comp];
            buffin[2][comp] <= isc[comp];
            buffin[3][comp] <= isd[comp];
            buffin[4][comp] <= ise[comp];
        end
        assign oda[comp] = buffin[0][comp];
        assign odb[comp] = buffin[1][comp];
        assign odc[comp] = buffin[2][comp];
        assign odd[comp] = buffin[3][comp];
        assign ode[comp] = buffin[4][comp];
    end
    always_ff @(posedge clk) goodbuff <= sample;
    assign good = goodbuff;
end
else if(DELAY == 2) begin : iobuff // copy input buffer to output buffer
    bit[1:0] delayed_good = 2'b0;
    always_ff @(posedge clk) delayed_good <= { delayed_good[0], sample };
    assign good  = delayed_good[1];
    
    longint unsigned buffin[5][5];
    longint unsigned buffout[5][5];
    for (comp = 0; comp < 5; comp++) begin
        always_ff @(posedge clk) if (sample) begin
            buffin[0][comp] <= isa[comp];
            buffin[1][comp] <= isb[comp];
            buffin[2][comp] <= isc[comp];
            buffin[3][comp] <= isd[comp];
            buffin[4][comp] <= ise[comp];
        end
        always_ff @(posedge clk) begin
            buffout[0][comp] <= buffin[0][comp];
            buffout[1][comp] <= buffin[1][comp];
            buffout[2][comp] <= buffin[2][comp];
            buffout[3][comp] <= buffin[3][comp];
            buffout[4][comp] <= buffin[4][comp];
        end
        assign oda[comp] = buffout[0][comp];
        assign odb[comp] = buffout[1][comp];
        assign odc[comp] = buffout[2][comp];
        assign odd[comp] = buffout[3][comp];
        assign ode[comp] = buffout[4][comp];
    end
end
else begin // generic delay, one input, one output and something between
    longint unsigned buff[DELAY][5][5];
    genvar lateness;
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
        for (lateness = 0; lateness < DELAY - 1; lateness++) begin
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

        bit[(DELAY - 1):0] delayed_good = 0;
        always_ff @(posedge clk) delayed_good <= { delayed_good[(DELAY - 2):0], sample };
        assign good  = delayed_good[DELAY - 1];
    end
end

endmodule
