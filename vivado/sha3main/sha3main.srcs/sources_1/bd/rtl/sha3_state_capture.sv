`timescale 1ns / 1ps

// Help other modules supporting bufferized input.
// Two operation modes: bufferize into FF or simply rename wires.
module sha3_state_capture #(
    BUFFERIZE = 1 // 0 = wire rename >0 = 1 clock delay buffer <0 error
)(
    input clk,
    input[63:0] isa[5], isb[5], isc[5], isd[5], ise[5],
    input sample,
    output ogood,
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5]
);

if (BUFFERIZE < 0) $error("Valid values are 0,1");
else if (BUFFERIZE == 0) begin : rename
    assign ogood = sample;
    assign osa = isa;
    assign osb = isb;
    assign osc = isc;
    assign osd = isd;
    assign ose = ise;
end
else begin : buffin
    longint unsigned ib[5][5];
    always_ff @(posedge clk) if(sample) begin
        ib[0] <= '{ isa[0], isa[1], isa[2], isa[3], isa[4] };
        ib[1] <= '{ isb[0], isb[1], isb[2], isb[3], isb[4] };
        ib[2] <= '{ isc[0], isc[1], isc[2], isc[3], isc[4] };
        ib[3] <= '{ isd[0], isd[1], isd[2], isd[3], isd[4] };
        ib[4] <= '{ ise[0], ise[1], ise[2], ise[3], ise[4] };
    end
    bit captured = 1'b0;
    always_ff @(posedge clk) captured <= sample;
    assign ogood = captured;
    
    for (genvar comp = 0; comp < 5; comp++) begin
        assign osa[comp] = ib[0][comp];
        assign osb[comp] = ib[1][comp];
        assign osc[comp] = ib[2][comp];
        assign osd[comp] = ib[3][comp];
        assign ose[comp] = ib[4][comp];
    end
end

endmodule
