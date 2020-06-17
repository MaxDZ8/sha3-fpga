`timescale 1ns / 1ps

// Renames and replicates wires so you can just xor them with those coming out of
// sha3_state_slice_to_48
module sha3_elts_slice_to_48(
    input[63:0] ielt[5],
    input[15:0] spare,
    output[47:0] oelt[34]
);

assign oelt[ 0] = ielt[0][63:16];
assign oelt[ 1] = { ielt[0][15:0], ielt[1][63:32] };
assign oelt[ 2] = { ielt[1][31:0], ielt[2][63:48] };
assign oelt[ 3] = ielt[2][47:0];

assign oelt[ 4] = ielt[3][63:16];
assign oelt[ 5] = { ielt[3][15:0], ielt[4][63:32] };
assign oelt[ 6] = { ielt[4][31:0], ielt[0][63:48] };
assign oelt[ 7] = ielt[0][47:0];

assign oelt[ 8] = ielt[1][63:16];
assign oelt[ 9] = { ielt[1][15:0], ielt[2][63:32] };
assign oelt[10] = { ielt[2][31:0], ielt[3][63:48] };
assign oelt[11] = ielt[3][47:0];

assign oelt[12] = ielt[4][63:16];
assign oelt[13] = { ielt[4][15:0], ielt[0][63:32] };
assign oelt[14] = { ielt[0][31:0], ielt[1][63:48] };
assign oelt[15] = ielt[1][47:0];

assign oelt[16] = ielt[2][63:16];
assign oelt[17] = { ielt[2][15:0], ielt[3][63:32] };
assign oelt[18] = { ielt[3][31:0], ielt[4][63:48] };
assign oelt[19] = ielt[4][47:0];

assign oelt[20] = oelt[ 0];
assign oelt[21] = oelt[ 1];
assign oelt[22] = oelt[ 2];
assign oelt[23] = oelt[ 3];

assign oelt[24] = oelt[ 4];
assign oelt[25] = oelt[ 5];
assign oelt[26] = oelt[ 6];
assign oelt[27] = oelt[ 7];

assign oelt[28] = oelt[ 8];
assign oelt[29] = oelt[ 9];
assign oelt[30] = oelt[10];
assign oelt[31] = oelt[11];

assign oelt[32] = oelt[12];
assign oelt[33] = { ielt[4][15:0], 16'b0, spare };

endmodule
