`timescale 1ns / 1ps

// A scanner dealing with the SHA3-packed-by-6 iterative hasher needs to be quite smarter than just dispatch
// like there's no tomorrow.
module sha3_packed6_scanner(
    input clk,
    i_sha3_scan_request_bus.consumer irequest,
    i_sha3_scan_result_bus.producer oresults,
    i_scanner_status.producer ostatus
);

i_sha3_1600_row_bus crunch(), hash();
wire hasher_can_take;
sha3_scanner_control fsm (
    .clk(clk),
    .irequest(irequest), .oresults(oresults), .ostatus(ostatus),
    
    .hasher_ready(hasher_can_take),
    .crunch(crunch), .hash(hash)
);


sha3_iterating_pipe6 hasher (
    .clk(clk),
    .busin(crunch),
    .gimme(hasher_can_take),
    .busout(hash)    
);


endmodule
