`timescale 1ns / 1ps

module instantiated_dsp48_xor #(
    AB_COUNT = 2
)(
    input clk,
    input[47:0] one, two,
    output[47:0] res
);

DSP48E1 #(
    .USE_MULT("NONE"), .MREG(0),
    .AREG(AB_COUNT), .BREG(AB_COUNT)
) widexor (
    .CLK(clk),
    .ALUMODE(4'b0100), // xor all the things
    .OPMODE(7'b011_00_11), // X=AB, Y=0, Z=C
    .A(one[47:18]), .B(one[17:0]), .C(two), .P(res),
    
    .CEA1(1'b1), .CEA2(1'b1), .CEB1(1'b1), .CEB2(1'b1), .CEC(1'b1), .CEP(1'b1),
    .CEALUMODE(1'b1), .CECTRL(1'b1), 
    .RSTALUMODE(1'b0), .RSTA(1'b0), .RSTB(1'b0), .RSTC(1'b0), .RSTCTRL(1'b0), .RSTP(1'b0),
    // Reset, but not really used.
    .RSTALLCARRYIN(1'b0), .RSTD(1'b0), .RSTINMODE(1'b0), .RSTM(1'b0),
    // Not used at all.
    .ACIN(30'b0), .BCIN(18'b0), .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0), .PCIN(48'b0), .CARRYINSEL(3'b0),
    .INMODE(5'b0), .CARRYIN(1'b0), .D(25'b0), .CEAD(1'b0), .CECARRYIN(1'b0), .CED(1'b0), .CEINMODE(1'b0), .CEM(1'b0)
);

endmodule
