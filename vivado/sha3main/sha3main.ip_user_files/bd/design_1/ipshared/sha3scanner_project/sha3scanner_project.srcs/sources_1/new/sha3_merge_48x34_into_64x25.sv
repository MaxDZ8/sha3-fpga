`timescale 1ns / 1ps

module sha3_merge_48x34_into_64x25(
    input[47:0] ivector[34],
    output[63:0] o[25],
    output[15:0] ospare
);


assign o[ 0 + 0] = { ivector[0], ivector[1][47:32] };
assign o[ 0 + 1] = { ivector[1][31:0], ivector[2][47:16] };
assign o[ 0 + 2] = { ivector[2][15:0], ivector[3] };

assign o[ 0 + 3] = { ivector[4], ivector[5][47:32] };
assign o[ 0 + 4] = { ivector[5][31:0], ivector[6][47:16] };
assign o[ 5 + 0] = { ivector[6][15:0], ivector[7] };

assign o[ 5 + 1] = { ivector[8], ivector[9][47:32] };
assign o[ 5 + 2] = { ivector[9][31:0], ivector[10][47:16] };
assign o[ 5 + 3] = { ivector[10][15:0], ivector[11] };

assign o[ 5 + 4] = { ivector[12], ivector[13][47:32] };
assign o[10 + 0] = { ivector[13][31:0], ivector[14][47:16] };
assign o[10 + 1] = { ivector[14][15:0], ivector[15] };

assign o[10 + 2] = { ivector[16], ivector[17][47:32] };
assign o[10 + 3] = { ivector[17][31:0], ivector[18][47:16] };
assign o[10 + 4] = { ivector[18][15:0], ivector[19] };

assign o[15 + 0] = { ivector[20], ivector[21][47:32] };
assign o[15 + 1] = { ivector[21][31:0], ivector[22][47:16] };
assign o[15 + 2] = { ivector[22][15:0], ivector[23] };

assign o[15 + 3] = { ivector[24], ivector[25][47:32] };
assign o[15 + 4] = { ivector[25][31:0], ivector[26][47:16] };
assign o[20 + 0] = { ivector[26][15:0], ivector[27] };

assign o[20 + 1] = { ivector[28], ivector[29][47:32] };
assign o[20 + 2] = { ivector[29][31:0], ivector[30][47:16] };
assign o[20 + 3] = { ivector[30][15:0], ivector[31] };

assign o[20 + 4] = { ivector[32], ivector[33][47:32] };

assign ospare = ivector[33][15:0];


endmodule
