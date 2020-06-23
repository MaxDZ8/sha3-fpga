`timescale 1ns / 1ps

module sha3_rho_pi #(
    INPUT_BUFFER = 0,
    OUTPUT_BUFFER = 1
)(
    input clk,
    input[63:0] isa[5],
    input[63:0] isb[5],
    input[63:0] isc[5],
    input[63:0] isd[5],
    input[63:0] ise[5],
    input sample,
    output[63:0] osa[5],
    output[63:0] osb[5],
    output[63:0] osc[5],
    output[63:0] osd[5],
    output[63:0] ose[5],
    output ogood
);

wire[63:0] valuein[5][5];
wire captured;
sha3_state_capture#(
    .BUFFERIZE(INPUT_BUFFER)
) inbuff(
    .clk(clk),
    .sample(sample), .isa(isa), .isb(isb), .isc(isc), .isd(isd), .ise(ise),
    .ogood(captured),
    .osa(valuein[0]), .osb(valuein[1]), .osc(valuein[2]), .osd(valuein[3]), .ose(valuein[4])
);


function longint unsigned rotl_36(input longint unsigned value);    return { value[27:0], value[63:28] };    endfunction
function longint unsigned rotl__3(input longint unsigned value);    return { value[60:0], value[63:61] };    endfunction
function longint unsigned rotl_41(input longint unsigned value);    return { value[22:0], value[63:23] };    endfunction
function longint unsigned rotl_18(input longint unsigned value);    return { value[45:0], value[63:46] };    endfunction
function longint unsigned rotl__1(input longint unsigned value);    return { value[62:0], value[63   ] };    endfunction
function longint unsigned rotl_44(input longint unsigned value);    return { value[19:0], value[63:20] };    endfunction
function longint unsigned rotl_10(input longint unsigned value);    return { value[53:0], value[63:54] };    endfunction
function longint unsigned rotl_45(input longint unsigned value);    return { value[18:0], value[63:19] };    endfunction
function longint unsigned rotl__2(input longint unsigned value);    return { value[61:0], value[63:62] };    endfunction
function longint unsigned rotl_62(input longint unsigned value);    return { value[ 1:0], value[63: 2] };    endfunction
function longint unsigned rotl__6(input longint unsigned value);    return { value[57:0], value[63:58] };    endfunction
function longint unsigned rotl_43(input longint unsigned value);    return { value[20:0], value[63:21] };    endfunction
function longint unsigned rotl_15(input longint unsigned value);    return { value[48:0], value[63:49] };    endfunction
function longint unsigned rotl_61(input longint unsigned value);    return { value[ 2:0], value[63: 3] };    endfunction
function longint unsigned rotl_28(input longint unsigned value);    return { value[35:0], value[63:36] };    endfunction
function longint unsigned rotl_55(input longint unsigned value);    return { value[ 8:0], value[63: 9] };    endfunction
function longint unsigned rotl_25(input longint unsigned value);    return { value[38:0], value[63:39] };    endfunction
function longint unsigned rotl_21(input longint unsigned value);    return { value[42:0], value[63:43] };    endfunction
function longint unsigned rotl_56(input longint unsigned value);    return { value[ 7:0], value[63: 8] };    endfunction
function longint unsigned rotl_27(input longint unsigned value);    return { value[36:0], value[63:37] };    endfunction
function longint unsigned rotl_20(input longint unsigned value);    return { value[43:0], value[63:44] };    endfunction
function longint unsigned rotl_39(input longint unsigned value);    return { value[24:0], value[63:25] };    endfunction
function longint unsigned rotl__8(input longint unsigned value);    return { value[55:0], value[63:56] };    endfunction
function longint unsigned rotl_14(input longint unsigned value);    return { value[49:0], value[63:50] };    endfunction

wire[63:0] rotating[5][5];
wire postrot;

assign rotating[0] = '{         valuein[0][0] , rotl_44(valuein[1][1]), rotl_43(valuein[2][2]), rotl_21(valuein[3][3]), rotl_14(valuein[4][4]) }; // diagonal
assign rotating[1] = '{ rotl_28(valuein[0][3]), rotl_20(valuein[1][4]), rotl__3(valuein[2][0]), rotl_45(valuein[3][1]), rotl_61(valuein[4][2]) }; // diag+1
assign rotating[2] = '{ rotl__1(valuein[0][1]), rotl__6(valuein[1][2]), rotl_25(valuein[2][3]), rotl__8(valuein[3][4]), rotl_18(valuein[4][0]) }; // +2
assign rotating[3] = '{ rotl_27(valuein[0][4]), rotl_36(valuein[1][0]), rotl_10(valuein[2][1]), rotl_15(valuein[3][2]), rotl_56(valuein[4][3]) }; // +3
assign rotating[4] = '{ rotl_62(valuein[0][2]), rotl_55(valuein[1][3]), rotl_39(valuein[2][4]), rotl_41(valuein[3][0]), rotl__2(valuein[4][1]) }; // diag+4

sha3_state_capture#(
    .BUFFERIZE(OUTPUT_BUFFER)
) outbuff(
    .clk(clk),
    .sample(captured), .isa(rotating[0]), .isb(rotating[1]), .isc(rotating[2]), .isd(rotating[3]), .ise(rotating[4]),
    .ogood(ogood),
    .osa(osa), .osb(osb), .osc(osc), .osd(osd), .ose(ose)
);


endmodule
