`timescale 1ns / 1ps

// Repack the bits in 48-bit busses so they can be fed to DSP48 with ease.
module sha3_state_vector_to_48(
    input[63:0] state[25],
    input[15:0] ispare,
    output[47:0] ovector[34]
);

sha3_state_slice_to_48 really (
    .isa('{ state[ 0], state[ 1], state[ 2], state[ 3], state[ 4] }),
    .isb('{ state[ 5], state[ 6], state[ 7], state[ 8], state[ 9] }),
    .isc('{ state[10], state[11], state[12], state[13], state[14] }),
    .isd('{ state[15], state[16], state[17], state[18], state[19] }),
    .ise('{ state[20], state[21], state[22], state[23], state[24] }),
    .ispare(ispare),
    .ovector(ovector)
);

endmodule
