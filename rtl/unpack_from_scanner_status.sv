`timescale 1ns / 1ps

module unpack_from_scanner_status(
    i_scanner_status.consumer from,
    output dispatching, evaluating, ready
);

assign dispatching = from.dispatching;
assign evaluating = from.evaluating;
assign ready = from.ready;

endmodule
