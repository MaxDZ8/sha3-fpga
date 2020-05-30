`timescale 1ns / 1ps

module sha3_chi #(
    MODIFY_STYLE = "basic"
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

// STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB STUB    
// TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
longint unsigned inbuff[5][5];

always_ff @(posedge clk) if(rst) begin
    inbuff[0] <= '{ 5{ 64'b0 } };
    inbuff[1] <= '{ 5{ 64'b0 } };
    inbuff[2] <= '{ 5{ 64'b0 } };
    inbuff[3] <= '{ 5{ 64'b0 } };
    inbuff[4] <= '{ 5{ 64'b0 } };
end
else if (sample) begin
    inbuff[0] <= '{ isa[0], isa[1], isa[2], isa[3], isa[4] };
    inbuff[1] <= '{ isb[0], isb[1], isb[2], isb[3], isb[4] };
    inbuff[2] <= '{ isc[0], isc[1], isc[2], isc[3], isc[4] };
    inbuff[3] <= '{ isd[0], isd[1], isd[2], isd[3], isd[4] };
    inbuff[4] <= '{ ise[0], ise[1], ise[2], ise[3], ise[4] };
end 

bit inflow = 1'b0;
always_ff @(posedge clk) if (rst) inflow <= 1'b0;
else inflow <= sample;

assign osa = '{ inbuff[0][0], inbuff[0][1], inbuff[0][2], inbuff[0][3], inbuff[0][4] };
assign osb = '{ inbuff[1][0], inbuff[1][1], inbuff[1][2], inbuff[1][3], inbuff[1][4] };
assign osc = '{ inbuff[2][0], inbuff[2][1], inbuff[2][2], inbuff[2][3], inbuff[2][4] };
assign osd = '{ inbuff[3][0], inbuff[3][1], inbuff[3][2], inbuff[3][3], inbuff[3][4] };
assign ose = '{ inbuff[4][0], inbuff[4][1], inbuff[4][2], inbuff[4][3], inbuff[4][4] };
assign good = inflow;

endmodule
