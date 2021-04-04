`timescale 1ns / 1ps

// This SHA3 core is a bit more problematic than usual.
// A- you give this new values to churn only when gimme is high.
// B- if gimme is high, then take sample hi and keep it high for XXXXX clocks.
// C- each clock sample is hi, provide a matrix to churn (gimme will go low when no more can be accepted).
// D- Wait until good becomes high. Results will come in bursts.
//
// Using a 12-rounds deep pipeline means each hash must be adjusted and fed back only once,
// this has some minor advantages and it's still pretty small. 
module sha3_iterating_pipe12 #(
    FEEDBACK_MUX_STYLE = "fabric",
    LAST_ROUND_IS_PROPER = 1,
    ROUND_OUTPUT_BUFFER = 24'b0000_0000_0000_1000_0010_0000
) (
    input clk, 
    input sample,
    input[63:0] rowa[5], rowb[5], rowc[5], rowd[5], rowe[5],
    output gimme, 
    output ogood,
    output[63:0] oa[5], ob[5], oc[5], od[5], oe[5]
);

// Everything is based on bursting inside inputs as long as the outputs don't come out.
// If the outputs start flowing back, it's time to feedback them!
// Keep accepting new values until the feedback mux needs to take the back-routed values,
// this keeps the pipeline busy for a while!
localparam FEEDBACK_MUX_LATENCY = FEEDBACK_MUX_STYLE == "fabric" ? 1 : 2;
localparam bit[4:0] burst_len_and_delay = 5'd24 + $countones(ROUND_OUTPUT_BUFFER) + FEEDBACK_MUX_LATENCY;

bit waiting_input = 1'b1;
bit buff_gimme = 1'b1;
bit consume_iterated = 1'b0;
bit[4:0] input_divide = 5'b0;
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
            consume_iterated <= 1'b1;
        end
    end
    else begin // the system is backfeeding itself, just get along by the pulse
        if (input_divide != burst_len_and_delay) input_divide <= input_divide + 1'b1;
        else begin
            input_divide <= 5'b0;
            consume_iterated <= 1'b0;
            buff_gimme <= 1'b1;
            waiting_input <= 1'b1;
        end
    end
end
assign gimme = buff_gimme;

localparam bit[4:0] start_rounds[2] = '{ 5'd0, 5'd12 };
wire[4:0] round_base = start_rounds[consume_iterated];

wire[63:0] tomuxa[5], tomuxb[5], tomuxc[5], tomuxd[5], tomuxe[5];
wire[63:0] muxoa[5], muxob[5], muxoc[5], muxod[5], muxoe[5];
wire[4:0] round_after_mux;
wire muxo_good;
wire mux_sample = waiting_input ? sample : (gimme | consume_iterated);
mux1600 #(
    .STYLE(FEEDBACK_MUX_STYLE)
) uglee(
    .clk(clk),
    .sample(mux_sample), .selector(consume_iterated), .round(round_base),
    .a('{
        rowa[0], rowa[1], rowa[2], rowa[3], rowa[4],
        rowb[0], rowb[1], rowb[2], rowb[3], rowb[4],
        rowc[0], rowc[1], rowc[2], rowc[3], rowc[4],
        rowd[0], rowd[1], rowd[2], rowd[3], rowd[4],
        rowe[0], rowe[1], rowe[2], rowe[3], rowe[4]
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
sha3_iterating_semipack #(
    .ROUND_COUNT(12),
    .LAST_ROUND_IS_PROPER(LAST_ROUND_IS_PROPER),
    .ROUND_OUTPUT_BUFFER(ROUND_OUTPUT_BUFFER)
) crunchy (
    .clk(clk),
    .isa(muxoa), .isb(muxob), .isc(muxoc), .isd(muxod), .ise(muxoe),
    .base_round(round_after_mux), .sample(muxo_good),
    .osa(rndoa), .osb(rndob), .osc(rndoc), .osd(rndod), .ose(rndoe),
    .ogood(rndo_good)
);

longint unsigned buffa[5], buffb[5], buffc[5], buffd[5], buffe[5]; // output and feedback buffers
for (genvar comp = 0; comp < 5; comp++) begin
    always_ff @(posedge clk) buffa[comp] <= rndoa[comp];
    always_ff @(posedge clk) buffb[comp] <= rndob[comp];
    always_ff @(posedge clk) buffc[comp] <= rndoc[comp];
    always_ff @(posedge clk) buffd[comp] <= rndod[comp];
    always_ff @(posedge clk) buffe[comp] <= rndoe[comp];
end


bit result_iteration = 1'b0;
bit[4:0] result_divide = 5'b0;
always_ff @(posedge clk) if(rndo_good) begin
    if (result_divide != burst_len_and_delay) result_divide <= result_divide + 1'b1;
    else begin
        result_divide <= 5'd0;
        result_iteration <= ~result_iteration;
    end
end

bit was_result_iteration = 1'h0;
always_ff @(posedge clk) was_result_iteration <= result_iteration;

bit into_adjuster = 1'b0;
always_ff @(posedge clk) into_adjuster <= rndo_good & ~result_iteration;

if (LAST_ROUND_IS_PROPER) begin : properly
    assign tomuxa = '{ buffa[0], buffa[1], buffa[2], buffa[3],buffa[4] };
    assign tomuxb = '{ buffb[0], buffb[1], buffb[2], buffb[3],buffb[4] };
    assign tomuxc = '{ buffc[0], buffc[1], buffc[2], buffc[3],buffc[4] };
    assign tomuxd = '{ buffd[0], buffd[1], buffd[2], buffd[3],buffd[4] };
    assign tomuxe = '{ buffe[0], buffe[1], buffe[2], buffe[3],buffe[4] };
    assign oa = tomuxa;
    assign ob = tomuxb;
    assign oc = tomuxc;
    assign od = tomuxd;
    assign oe = tomuxe;
    
    bit was_rndo_good = 1'b0;
    always_ff @(posedge clk) was_rndo_good <= rndo_good;
    assign ogood = was_rndo_good & was_result_iteration == 1'b1;
end
else begin : quirky
    // Adjusting the feed-back value. ------------------------------------------------------------------------
    wire[63:0] toiotaa[5], toiotab[5], toiotac[5], toiotad[5], toiotae[5];
    wire fetch_iota;
    sha3_chi #(
        .STYLE("basic"),
        .OUTPUT_BUFFER(0),
        .INPUT_BUFFER(0) // it is critical CHI+IOTA have latency 0 or the last round will go awry
    ) chi (
        .clk(clk),
        .isa(buffa), .isb(buffb), .isc(buffc), .isd(buffd), .ise(buffe), .sample(into_adjuster),
        .osa(toiotaa), .osb(toiotab), .osc(toiotac), .osd(toiotad), .ose(toiotae), .ogood(fetch_iota)
    );
        
    sha3_iota #(
       .VALUE(64'h000000008000000a), // rc[11]
       .OUTPUT_BUFFER(0)
    ) iota (
       .clk(clk),
       .isa(toiotaa), .isb(toiotab), .isc(toiotac), .isd(toiotad), .ise(toiotae), .sample(fetch_iota),
       .osa(tomuxa), .osb(tomuxb), .osc(tomuxc), .osd(tomuxd), .ose(tomuxe) /* .ogood unused - no latency*/
    );
    
    bit into_finalizer = 1'b0;
    always_ff @(posedge clk) into_finalizer <= rndo_good & result_iteration;
    
    sha3_finalizer #(
        .OUTPUT_BUFFER(0),
        .VALUE(64'h8000000080008008) // rc[23]
    ) finalizer(
        .clk(clk), .sample(into_finalizer),
        .isa(buffa), .isb(buffb), .isc(buffc), .isd(buffd), .ise(buffe),
        .osa(oa), .osb(ob), .osc(oc), .osd(od), .ose(oe),
        .ogood(ogood)
    );
end

endmodule
