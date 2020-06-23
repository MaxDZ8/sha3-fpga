`timescale 1ns / 1ps

// Performs wire renaming opposite to sha3_state_slice_to_48
module sha3_state_merge_from_48(
    input[47:0] ivector[34],
    output[63:0] osa[5], osb[5], osc[5], osd[5], ose[5],
    output[15:0] ospare
);

assign osa[0] = { ivector[0], ivector[1][47:32] };
assign osa[1] = { ivector[1][31:0], ivector[2][47:16] };
assign osa[2] = { ivector[2][15:0], ivector[3] };

assign osa[3] = { ivector[4], ivector[5][47:32] };
assign osa[4] = { ivector[5][31:0], ivector[6][47:16] };
assign osb[0] = { ivector[6][15:0], ivector[7] };

assign osb[1] = { ivector[8], ivector[9][47:32] };
assign osb[2] = { ivector[9][31:0], ivector[10][47:16] };
assign osb[3] = { ivector[10][15:0], ivector[11] };

assign osb[4] = { ivector[12], ivector[13][47:32] };
assign osc[0] = { ivector[13][31:0], ivector[14][47:16] };
assign osc[1] = { ivector[14][15:0], ivector[15] };

assign osc[2] = { ivector[16], ivector[17][47:32] };
assign osc[3] = { ivector[17][31:0], ivector[18][47:16] };
assign osc[4] = { ivector[18][15:0], ivector[19] };

assign osd[0] = { ivector[20], ivector[21][47:32] };
assign osd[1] = { ivector[21][31:0], ivector[22][47:16] };
assign osd[2] = { ivector[22][15:0], ivector[23] };

assign osd[3] = { ivector[24], ivector[25][47:32] };
assign osd[4] = { ivector[25][31:0], ivector[26][47:16] };
assign ose[0] = { ivector[26][15:0], ivector[27] };

assign ose[1] = { ivector[28], ivector[29][47:32] };
assign ose[2] = { ivector[29][31:0], ivector[30][47:16] };
assign ose[3] = { ivector[30][15:0], ivector[31] };

assign ose[4] = { ivector[32], ivector[33][47:32] };

assign ospare = ivector[33][15:0];

endmodule
