`timescale 1ns / 1ps

// Elt = termA ^ rotate(termB, amount=1, direction=left).
// Again, this is best done in a large chunk so in the future I can pack bits with ease.
module sha3_theta_elt_evaluator
#(
    STYLE = "basic"
)(
    input clk, rst,
    input wire[63:0] term[5],
    output wire[63:0] elt[5]
);

function longint unsigned roltl_1(input longint unsigned value);
    return { value[62:0], value[63] };
endfunction

wire[63:0] rotated[5];
for (genvar comp = 0; comp < 5; comp++) assign rotated[comp] = roltl_1(term[comp]);

if (STYLE == "basic") begin
    // The simplest form, I just let inference do its job.
    longint unsigned eltbuff[5];
    always_ff @(posedge clk) begin
        eltbuff[0] <= term[4] ^ rotated[1];
        eltbuff[1] <= term[0] ^ rotated[2];
        eltbuff[2] <= term[1] ^ rotated[3];
        eltbuff[3] <= term[2] ^ rotated[4];
        eltbuff[4] <= term[3] ^ rotated[0];
    end
    for (genvar comp = 0; comp < 5; comp++) assign elt[comp] = eltbuff[comp];
end
else begin
    // Another candidate is: DSP48
    $error("Logic style unsupported.");
end

endmodule
