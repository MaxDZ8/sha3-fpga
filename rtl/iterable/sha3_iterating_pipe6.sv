`timescale 1ns / 1ps

// This SHA3 core is a bit more problematic than usual.
// A- you give this new values to churn only when gimme is high.
// B- if gimme is high, then take sample hi and keep it high for XXXXX clocks.
// C- each clock sample is hi, provide a matrix to churn (gimme will go low when no more can be accepted).
// D- Wait until good becomes high. Results will come in bursts.
module sha3_iterating_pipe6(
    input clk, sample,
    input[63:0] ina[5], inb[5], inc[5], ind[5], ine[5],
    output gimme, good,
    input[63:0] oa[5], ob[5], oc[5], od[5], oe[5]
);

// Everything is based on bursting inside inputs as long as the outputs don't come out.
// If the outputs start flowing back, it's time to feedback them!
localparam bit[3:0] burst_len_and_delay = 4'd14;

bit waiting_input = 1'b1;
bit buff_gimme = 1'b1;
bit[1:0] input_iteration = 2'b0;
bit[5:0] input_divide = 6'b0;
always_ff @(posedge clk)  begin
    if(waiting_input) begin
        if(sample) begin
            input_divide <= 1'b1;
            waiting_input <= 1'b0;
        end
    end
    else begin
        if (input_divide != burst_len_and_delay) input_divide <= input_divide + 1'b1;
        else begin
            input_divide <= 5'b0;
            if(input_iteration == 3'd3) begin
                input_iteration <= 2'h0;
                buff_gimme <= 1'b1;
            end
            else begin
                input_iteration <= input_iteration + 1'b1;
                buff_gimme <= 1'b0;
                waiting_input <= 1'b1;
            end
        end
    end
end
assign gimme = buff_gimme;

localparam bit[5:0] start_rounds[4] = '{ 0, 6, 12, 18 };
wire[5:0] round_base = start_rounds[input_iteration];

wire consume_iterated = input_iteration != 5'd0;
wire[63:0] feeda[5], feedb[5], feedc[5], feedd[5], feede[5];
wire[63:0] muxoa[5], muxob[5], muxoc[5], muxod[5], muxoe[5];
wire[4:0] round_after_mux;
wire muxo_good;
mux1600 uglee(
    .clk(clk),
    .sample(sample), .selector(consume_iterated), .round(round_base),
    .a('{
        ina[0], ina[1], ina[2], ina[3], ina[4],
        inb[0], inb[1], inb[2], inb[3], inb[4],
        inc[0], inc[1], inc[2], inc[3], inc[4],
        ind[0], ind[1], ind[2], ind[3], ind[4],
        ine[0], ine[1], ine[2], ine[3], ine[4]
    }),
    .b('{
        feeda[0], feeda[1], feeda[2], feeda[3], feeda[4],
        feedb[0], feedb[1], feedb[2], feedb[3], feedb[4],
        feedc[0], feedc[1], feedc[2], feedc[3], feedc[4],
        feedd[0], feedd[1], feedd[2], feedd[3], feedd[4],
        feede[0], feede[1], feede[2], feede[3], feede[4]
    }),
    .ogood(muxo_good),
    .o('{
        muxoa[0], muxoa[1], muxoa[2], muxoa[3], muxoa[4],
        muxob[0], muxob[1], muxob[2], muxob[3], muxob[4],
        muxoc[0], muxoc[1], muxoc[2], muxoc[3], muxoc[4],
        muxod[0], muxod[1], muxod[2], muxod[3], muxod[4],
        muxoe[0], muxoe[1], muxoe[2], muxoe[3], muxoe[4]
    }),
    .oround(round_after_mux)
);

wire[63:0] rndoa[5], rndob[5], rndoc[5], rndod[5], rndoe[5];

sha3_iterating_pack crunchy (
    .clk(clk),
    .isa(muxoa), .isb(muxob), .isc(muxoc), .isd(muxod), .ise(muxoe),
    .base_round(round_after_mux), .sample(muxo_good),
    .osa(rndoa), .osb(rndob), .osc(rndoc), .osd(rndod), .ose(rndoe),
    .ogood(rndo_good)
);

longint unsigned buffa[5], buffb[5], buffc[5], buffd[5], buffe[5];
for (genvar comp = 0; comp < 5; comp++) begin
    always_ff @(posedge clk) if(rndo_good) buffa[comp] <= rndoa[comp];
    always_ff @(posedge clk) if(rndo_good) buffb[comp] <= rndob[comp];
    always_ff @(posedge clk) if(rndo_good) buffc[comp] <= rndoc[comp];
    always_ff @(posedge clk) if(rndo_good) buffd[comp] <= rndod[comp];
    always_ff @(posedge clk) if(rndo_good) buffe[comp] <= rndoe[comp];
    
    assign feeda[comp] = buffa[comp];
    assign feedb[comp] = buffb[comp];
    assign feedc[comp] = buffc[comp];
    assign feedd[comp] = buffd[comp];
    assign feede[comp] = buffe[comp];
    assign oa[comp] = buffa[comp];
    assign ob[comp] = buffb[comp];
    assign oc[comp] = buffc[comp];
    assign od[comp] = buffd[comp];
    assign oe[comp] = buffe[comp];
end

bit[1:0] result_iteration = 2'b0;
bit[5:0] result_divide = 6'b0;
always_ff @(posedge clk) if(rndo_good) begin
    if (result_divide != burst_len_and_delay) result_divide <= result_divide + 1'b1;
    else begin
        result_divide <= 6'd0;
        result_iteration <= result_iteration + 1'b1;
    end
end

bit buff_good = 1'b0;
always_ff @(posedge clk) buff_good <= rndo_good & result_iteration == 2'h3;
assign good = buff_good;

endmodule
