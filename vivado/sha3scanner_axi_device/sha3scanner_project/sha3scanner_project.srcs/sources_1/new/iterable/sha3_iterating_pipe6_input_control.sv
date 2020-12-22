`timescale 1ns / 1ps

module sha3_iterating_pipe6_input_control(
    input clk, sample,
    output ogimme, oiterate,
    output[4:0] oround
);

enum bit[2:0] {   
    s_waiting     = 3'b001,
    s_feeding     = 3'b010,
    s_iterating   = 3'b100
} state = s_waiting;

bit[4:0] buff_round = 5'b0;
assign oround = buff_round;

bit[5:0] element = 6'b0;
localparam bit[5:0] DELAY = 6'd18;

localparam last_sha_round = 6'd23;
localparam last_dispatched_pack = last_sha_round - 6'd6;

always_ff @(posedge clk) case(state)
    s_waiting: if(sample) begin
        element <= element + 1'b1;
        state <= s_feeding;
    end
    s_feeding: begin
        if (element != DELAY) element <= element + 1'b1;
        else begin
            element <= 6'b0;
            buff_round <= buff_round + 6'd6;
            state <= s_iterating;
        end
    end
    s_iterating: begin
        if (element != DELAY) element <= element + 1'b1;
        else begin
            element <= 6'b0;
            buff_round <= buff_round + 6'd6;
            if (buff_round != last_dispatched_pack) buff_round <= buff_round + 6'd6;
            else begin
                buff_round <= 6'd0;
                state <= s_waiting;
            end
        end
    end
endcase

assign ogimme = state[0];
assign oiterate = state[1] | state[2];


endmodule
