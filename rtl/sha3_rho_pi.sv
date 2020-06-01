`timescale 1ns / 1ps

module sha3_rho_pi #(
    // 0 = just rename the wires. No latency but not reccomended.
    // 1 = bufferize the outputs
    // 2 = bufferize both inputs and outputs
    // OTHER = error
    BUFFERIZATION = 1
)(
    input clk, rst,
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
    output good
);

if (BUFFERIZATION < 0 || BUFFERIZATION > 2) $error("Unsupported buffer level");

wire[63:0] valuein[5][5];
wire captured;
if (BUFFERIZATION < 2) begin : no_in_buff
    assign valuein[0] = isa;
    assign valuein[1] = isb;
    assign valuein[2] = isc;
    assign valuein[3] = isd;
    assign valuein[4] = ise;
    assign captured = sample;
end
else begin : inbuff
    longint unsigned ib[5][5];
    bit buffcaptured = 1'b0;
    always_ff @(posedge clk) if(captured) begin
        ib[0] <= '{ isa[0][0], isa[0][1], isa[0][2], isa[0][3], isa[0][4] };
        ib[1] <= '{ isb[1][0], isb[1][1], isb[1][2], isb[1][3], isb[1][4] };
        ib[2] <= '{ isc[2][0], isc[2][1], isc[2][2], isc[2][3], isc[2][4] };
        ib[3] <= '{ isd[3][0], isd[3][1], isd[3][2], isd[3][3], isd[3][4] };
        ib[4] <= '{ ise[4][0], ise[4][1], ise[4][2], ise[4][3], ise[4][4] };
        buffcaptured <= sample;
    end
    assign captured = buffcaptured;
    for (genvar slice = 0; slice < 5; slice++) begin
        for (genvar comp = 0; comp < 5; comp++) assign valuein[slice][comp] = ib[slice][comp];
    end
end


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

wire[63:0] rotating[5][5], rotated[5][5];
wire postrot;

assign rotating[0] = '{         valuein[0][0] , rotl_44(valuein[1][1]), rotl_43(valuein[2][2]), rotl_21(valuein[3][3]), rotl_14(valuein[4][4]) }; // diagonal
assign rotating[1] = '{ rotl_28(valuein[0][3]), rotl_20(valuein[1][4]), rotl__3(valuein[2][0]), rotl_45(valuein[3][1]), rotl_61(valuein[4][2]) }; // diag+1
assign rotating[2] = '{ rotl__1(valuein[0][1]), rotl__6(valuein[1][2]), rotl_25(valuein[2][3]), rotl__8(valuein[3][4]), rotl_18(valuein[4][0]) }; // +2
assign rotating[3] = '{ rotl_27(valuein[0][4]), rotl_36(valuein[1][0]), rotl_10(valuein[2][1]), rotl_15(valuein[3][2]), rotl_56(valuein[4][3]) }; // +3
assign rotating[4] = '{ rotl_62(valuein[0][2]), rotl_55(valuein[1][3]), rotl_39(valuein[2][4]), rotl_41(valuein[3][0]), rotl__2(valuein[4][1]) }; // diag+4
    
if (BUFFERIZATION == 0) begin : no_out_buff
    assign postrot = captured;
    assign rotated[0] = rotating[0];
    assign rotated[1] = rotating[1];
    assign rotated[2] = rotating[2];
    assign rotated[3] = rotating[3];
    assign rotated[4] = rotating[4];
end
else begin : outbuff
    longint unsigned ob[5][5];
    bit buffgood = 1'b0;
    always_ff @(posedge clk) if(captured) begin
        ob[0] <= '{ rotating[0][0], rotating[0][1], rotating[0][2], rotating[0][3], rotating[0][4] };
        ob[1] <= '{ rotating[1][0], rotating[1][1], rotating[1][2], rotating[1][3], rotating[1][4] };
        ob[2] <= '{ rotating[2][0], rotating[2][1], rotating[2][2], rotating[2][3], rotating[2][4] };
        ob[3] <= '{ rotating[3][0], rotating[3][1], rotating[3][2], rotating[3][3], rotating[3][4] };
        ob[4] <= '{ rotating[4][0], rotating[4][1], rotating[4][2], rotating[4][3], rotating[4][4] };
        buffgood <= captured;
    end
    assign postrot = buffgood;
    for (genvar slice = 0; slice < 5; slice++) begin
        for (genvar comp = 0; comp < 5; comp++) assign rotated[slice][comp] = ob[slice][comp];
    end
end

assign osa = '{ rotated[0][0], rotated[0][1], rotated[0][2], rotated[0][3], rotated[0][4] };
assign osb = '{ rotated[1][0], rotated[1][1], rotated[1][2], rotated[1][3], rotated[1][4] };
assign osc = '{ rotated[2][0], rotated[2][1], rotated[2][2], rotated[2][3], rotated[2][4] };
assign osd = '{ rotated[3][0], rotated[3][1], rotated[3][2], rotated[3][3], rotated[3][4] };
assign ose = '{ rotated[4][0], rotated[4][1], rotated[4][2], rotated[4][3], rotated[4][4] };
assign good = postrot;

endmodule
