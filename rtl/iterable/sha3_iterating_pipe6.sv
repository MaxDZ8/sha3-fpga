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
// Keep accepting new values until the feedback mux needs to take the back-routed values,
// this keeps the pipeline busy for a while!
localparam bit[3:0] burst_len_and_delay = 4'd15;

bit waiting_input = 1'b1;
bit buff_gimme = 1'b1;
bit[1:0] input_iteration = 2'b0;
bit[5:0] input_divide = 6'b0;
always_ff @(posedge clk)  begin
    if(waiting_input) begin // start the burst. I will fetch myself as much as I can, no matter what!
        if(sample) begin
            input_divide <= 1'b1;
            waiting_input <= 1'b0;
        end
    end
    else if(buff_gimme) begin // bursting in the values! I am driving the feed to the 6-pack
        if (input_divide != burst_len_and_delay) input_divide <= input_divide + 1'b1;
        else begin
            input_divide <= 5'b0;
            buff_gimme <= 1'b0;
            input_iteration <= 1'b1;
        end
    end
    else begin // the system is backfeeding itself, just get along by the pulse
        if (input_divide != burst_len_and_delay) input_divide <= input_divide + 1'b1;
        else begin
            input_divide <= 5'b0;
            input_iteration <= input_iteration + 1'b1;
            if (input_iteration == 2'h3) begin
                buff_gimme <= 1'b1;
                waiting_input <= 1'b1;
            end
        end
    end
end
assign gimme = buff_gimme;

localparam bit[4:0] start_rounds[4] = '{ 5'd0, 5'd6, 5'd12, 5'd18 };
wire[4:0] round_base = start_rounds[input_iteration];

wire[63:0] tomuxa[5], tomuxb[5], tomuxc[5], tomuxd[5], tomuxe[5];
wire[63:0] muxoa[5], muxob[5], muxoc[5], muxod[5], muxoe[5];
wire[4:0] round_after_mux;
wire muxo_good;
wire consume_iterated = input_iteration != 2'h0;
wire mux_sample = waiting_input ? sample : (gimme | consume_iterated);
mux1600 uglee(
    .clk(clk),
    .sample(mux_sample), .selector(consume_iterated), .round(round_base),
    .a('{
        ina[0], ina[1], ina[2], ina[3], ina[4],
        inb[0], inb[1], inb[2], inb[3], inb[4],
        inc[0], inc[1], inc[2], inc[3], inc[4],
        ind[0], ind[1], ind[2], ind[3], ind[4],
        ine[0], ine[1], ine[2], ine[3], ine[4]
    }),
    .b('{
        tomuxa[0], tomuxa[1], tomuxa[2], tomuxa[3], tomuxa[4],
        tomuxb[0], tomuxb[1], tomuxb[2], tomuxb[3], tomuxb[4],
        tomuxc[0], tomuxc[1], tomuxc[2], tomuxc[3], tomuxc[4],
        tomuxd[0], tomuxd[1], tomuxd[2], tomuxd[3], tomuxd[4],
        tomuxe[0], tomuxe[1], tomuxe[2], tomuxe[3], tomuxe[4]
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

wire rndo_good;
wire[63:0] rndoa[5], rndob[5], rndoc[5], rndod[5], rndoe[5];
sha3_iterating_6pack crunchy (
    .clk(clk),
    .isa(muxoa), .isb(muxob), .isc(muxoc), .isd(muxod), .ise(muxoe),
    .base_round(round_after_mux), .sample(muxo_good),
    .osa(rndoa), .osb(rndob), .osc(rndoc), .osd(rndod), .ose(rndoe),
    .ogood(rndo_good)
);

longint unsigned buffa[5], buffb[5], buffc[5], buffd[5], buffe[5]; // output and feedback buffers
for (genvar comp = 0; comp < 5; comp++) begin
    always_ff @(posedge clk) if(rndo_good) buffa[comp] <= rndoa[comp];
    always_ff @(posedge clk) if(rndo_good) buffb[comp] <= rndob[comp];
    always_ff @(posedge clk) if(rndo_good) buffc[comp] <= rndoc[comp];
    always_ff @(posedge clk) if(rndo_good) buffd[comp] <= rndod[comp];
    always_ff @(posedge clk) if(rndo_good) buffe[comp] <= rndoe[comp];
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

bit[1:0] was_result_iteration = 2'h0;
always_ff @(posedge clk) was_result_iteration <= result_iteration;

bit into_adjuster = 1'b0;
always_ff @(posedge clk) into_adjuster <= rndo_good & result_iteration != 2'h3;

localparam bit[4:0] result_rounds[4] = '{ 5'd5, 5'd11, 5'd17, 5'd23 };
wire[4:0] last_result_round = result_rounds[was_result_iteration];

sha3_generic_round_second_half adjust (
    .clk(clk),
    .round_index(last_result_round),
    .sample(into_adjuster),
    .isa(buffa), .isb(buffb), .isc(buffc), .isd(buffd), .ise(buffe),
    .osa(tomuxa), .osb(tomuxb), .osc(tomuxc), .osd(tomuxd), .ose(tomuxe)
);

bit into_finalizer = 1'b0;
always_ff @(posedge clk) into_finalizer <= rndo_good & result_iteration == 2'h3;

sha3_finalizer #(
    .OUTPUT_BUFFER(0),
    .VALUE(64'h8000000080008008) // rc[23]
) finalizer(
    .clk(clk), .sample(into_finalizer),
    .isa(buffa), .isb(buffb), .isc(buffc), .isd(buffd), .ise(buffe),
    .osa(oa), .osb(ob), .osc(oc), .osd(od), .ose(oe),
    .ogood(good)
);

endmodule
