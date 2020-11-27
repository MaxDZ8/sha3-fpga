`timescale 1ns / 1ps

module mux1600_by_dsp48(
    input clk, sample, selector,
    input[4:0] round,
    input[63:0] a[25],
    input[63:0] b[25],
    output ogood,
    output[63:0] o[25],
    output[4:0] oround
);

bit[1:0] buff_ogood;
always_ff @(posedge clk) buff_ogood <= { buff_ogood[0], sample };
assign ogood = buff_ogood[1];

wire[47:0] easyab[34], easyc[34];
sha3_state_vector_to_48 splita (
    .state(a), .ispare({ 11'b0, round }),
    .ovector(easyab)
);

sha3_state_vector_to_48 splitb (
    .state(b), .ispare({ 11'b0, round }),
    .ovector(easyc)
);

wire[6:0] muxmode = selector ? 7'b011_00_00 : 7'b000_00_11;

wire[47:0] pout[34];
for (genvar comp = 0; comp < 34; comp++) begin : bunch
    DSP48E1 #(
      .USE_MULT("NONE"), // I just disable the multiplier, everything else is good by default.
      .MREG(0)
   )
   DSP48E1_inst (
      .CLK(clk),
      .CEA2(sample), .CEB2(sample), .CEC(sample),
      .A(easyab[comp][47:18]), .B(easyab[comp][17:0]), .C(easyc[comp]),
      .OPMODE(muxmode), // X=0 if selector, otherwise X=AB, Y=0, Z=C if selector, else Z=0 
      .ALUMODE(4'b0100), // P=X^Z, or is also good but it's always three way xor I guess
      .CEALUMODE(1'b1), .CECTRL(1'b1), // for the lack of a better idea
      .P(pout[comp]),
      .CEP(1'b1), // gating by ABC is enough.

      // Unused.
      .ACIN(30'b0), .BCIN(18'b0),
      .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0), .PCIN(48'b0), .CARRYINSEL(4'b0), .CARRYIN(1'b0),
      .INMODE(5'b0), .D(25'b0),
      
      // Unused. Really. By datasheet the AB1 register comes before A2 but it's enabled when buff level = 2
      .CEA1(1'b0), .CEB1(1'b0),
      .CEAD(1'b0), .CECARRYIN(1'b0), .CED(1'b0), .CEINMODE(1'b0), .CEM(1'b0),
      
      // Resets. All unused.
      .RSTA(1'b0), .RSTALLCARRYIN(1'b0), .RSTALUMODE(1'b0), .RSTB(1'b0), .RSTC(1'b0), .RSTCTRL(1'b0),
      .RSTD(1'b0), .RSTINMODE(1'b0), .RSTM(1'b0), .RSTP(1'b0)
   );
end

wire[15:0] ospare;
sha3_merge_48x34_into_64x25 merge (
    .ivector(pout),
    .o(o), .ospare(ospare)
);
assign oround = ospare[4:0];

endmodule
