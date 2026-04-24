`timescale 1ns / 10ps

module array #(
    // parameters
) (
    input logic clk, n_rst,
    input logic load, inf_started,
    input logic [63:0] inp,
    output logic [127:0] out
);
    logic [8:0][7:0][15:0] int_out;
    logic [7:0][8:0][15:0] p_in;
    logic [127:0] ext_inp;

    typedef enum logic [3:0] {
        IDLE, WAIT1, WAIT2, WAIT3, LOAD, START1, START2, START3, START4
    } state_t;


    state_t state, n_state;
    logic [127:0] reg0, next_reg0;
    logic [63:0] reg1, next_reg1;

    always_ff@(posedge clk or negedge n_rst) begin
        if(~n_rst) begin
            state <= IDLE;
            reg0 <= '0;
            reg1 <= '0;
        end
        else begin
            state <= n_state;
            reg0 <= next_reg0;
            reg1 <= next_reg1;
        end
    end


    always_comb begin
        case(state)
            IDLE: n_state = inf_started ? 	START1 : state;
            START1: n_state = START2;
            START2: n_state = START3;
            START3: n_state = START4;
            START4: n_state = WAIT1;
            WAIT1: n_state = inf_started ? WAIT2 : IDLE;
            WAIT2: n_state = WAIT3;
            WAIT3: n_state = LOAD;
            LOAD: n_state = WAIT1;
            default: n_state = state;
        endcase
    end

    genvar i;
    generate
	    for(i = 0; i < 8; i++) begin	
		    assign ext_inp[16*i+15: 16*i] = load || inf_started ? 
                                            inp[8*i+7:8*i] == 8'b0 ? 16'b0 : inp[8*i+6:8*i] > 7'h78 ? {inp[8*i+7], 5'h1F, 10'h200} : inp[8*i+6:8*i] == 7'h78 ? {inp[8*i+7], 5'h1F, 10'b0} : {inp[8*i+7], {1'b0, inp[8*i+6:8*i+3]} + 5'h08, inp[8*i+2:8*i], 7'b0} : 16'b0;
	    end
    endgenerate

    always_comb begin
        if(state == START4) begin
            next_reg0 = ext_inp;
        end
        else if(state == LOAD) begin
            next_reg0[127:64] = ext_inp[127:64];
            next_reg0[63:0] = reg1[63:0];
            //next_reg0[63:0] = ext_inp[63:0];
            //next_reg0[127:64] = reg1[63:0];
        end
        else begin
            next_reg0 = reg0;
        end
    end

    always_comb begin
        if(state == START4) begin
            next_reg1 = ext_inp[63:0];
            //next_reg1 = ext_inp[127:64];
        end
        else if(state == LOAD) begin
            next_reg1 = ext_inp[63:0];
            //next_reg1 = ext_inp[127:64];
        end
        else begin
            next_reg1 = reg1;
        end
    end



    generate
	    for(i = 0; i < 8; i++) begin
            assign p_in[i][0] = !load ? reg0[127 - 16*i: 127 - 16 * i - 15] : ext_inp[127-16*i:127-16*i-15];	
            //assign p_in[i][0] = !load ? reg0[16*i+15 -: 16] : ext_inp[16*i+15 -: 16];	
            assign int_out[0][i] = 16'b0;
	    end
    endgenerate



    genvar j;
    generate
        for(i = 0; i < 8; i++) begin
            for(j = 0; j < 8; j++) begin
                array_cell a(.clk(clk), .n_rst(n_rst), .load(load), .inp(p_in[i][j]), .pass_input(p_in[i][j+1]), .prev_output(int_out[i][j]), .out(int_out[i+1][j]));
            end
        end
    endgenerate

    //assign out = {int_out[8][0], int_out[8][1], int_out[8][2], int_out[8][3], int_out[8][4], int_out[8][5], int_out[8][6], int_out[8][7]};
    assign out = int_out[8];

endmodule

