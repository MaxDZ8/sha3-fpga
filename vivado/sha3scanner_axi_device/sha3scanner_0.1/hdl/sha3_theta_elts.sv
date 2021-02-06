`timescale 1ns / 1ps

// Evaluating theta-elts is better done for all the slices toghether: produce 5 temporary terms, each used twice.
// We start doing some logic here so this buffers its inputs before everything.
// This assumes you buffered the various inputs yourself real close.
module sha3_theta_elts #(
    STYLE = "basic",
    OUTPUT_BUFFER = 1
)(
    input clk,
    input[63:0] iterm[5],
    input sample,
    output[63:0] oelt[5]
);

// Elt = termA ^ rotate(termB, amount=1, direction=left).
// Again, this is best done in a large chunk so in the future I can pack bits with ease.
function longint unsigned roltl_1(input longint unsigned value);
    return { value[62:0], value[63] };
endfunction

wire[63:0] rotated[5], result[5];
for (genvar comp = 0; comp < 5; comp++) begin : lane
    assign rotated[comp] = roltl_1(iterm[comp]);
    assign result[comp] = iterm[(comp + 4) % 5] ^ rotated[(comp + 1) % 5];
end

if (STYLE == "basic") begin
    // The simplest form, I just let inference do its job.
    if (OUTPUT_BUFFER) begin : flipflops
        longint unsigned eltbuff[5];
        always_ff @(posedge clk) begin
            eltbuff[0] <= result[0];
            eltbuff[1] <= result[1];
            eltbuff[2] <= result[2];
            eltbuff[3] <= result[3];
            eltbuff[4] <= result[4];
        end
        for (genvar comp = 0; comp < 5; comp++) assign oelt[comp] = eltbuff[comp];
    end
    else begin : direct
        for (genvar comp = 0; comp < 5; comp++) assign oelt[comp] = result[comp];
    end
end
else begin
    // Another candidate is: DSP48
    initial begin
        $display("Logic style unsupported.");
        $finish;
    end
end

endmodule
