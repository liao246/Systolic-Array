`timescale 1ns / 10ps

module bias_adder_activator #(
    // parameters
) (
    input logic clk, n_rst,
    input logic [127:0] arr_inp,
    input logic [63:0] bias,
    input logic inf_running,
    input logic [1:0] activ_ctrl,
    output logic [63:0] out,
    output logic output_ready,
    output logic inf_result, nan_result
);


    //logic [127:0] stored_inp;

    // always_ff@(posedge clk or negedge n_rst) begin
    //     if(~n_rst) begin
    //         stored_inp <= '0;
    //     end
    //     else begin
    //         stored_inp <= arr_inp;
    //     end
    // end


    logic [7:0][15:0] big_bias;
    genvar i;
    generate
	    for(i = 0; i < 8; i++) begin	
		    assign big_bias[i] = bias[8*i+7:8*i] == 8'b0 ? 16'b0 : bias[8*i+6:8*i] > 7'h78 ? {bias[8*i+7], 5'h1F, 10'h200} : bias[8*i+6:8*i] == 7'h78 ? {bias[8*i+7], 5'h1F, 10'b0} : {bias[8*i+7], {1'b0, bias[8*i+6:8*i+3]} + 5'h08, bias[8*i+2:8*i], 7'b0};
	    end
    endgenerate

    logic [15:0] int_out_adder [7:0];
    logic [7:0] int_out_activ [7:0];
    generate
        for(i = 0; i < 8; i++) begin
            // float_adder fa(.a(stored_inp[16*i+15:16*i]), .b(big_bias[7-i]), .sum(int_out_adder[7-i]));
            // activator16to8 ac(.in(int_out_adder[7-i]), .out(int_out_activ[7-i]), .activ_ctrl(activ_ctrl));
            float_adder fa(.a(arr_inp[16*i+15:16*i]), .b(big_bias[7-i]), .sum(int_out_adder[7-i]));
            activator16to8 ac(.in(int_out_adder[7-i]), .out(int_out_activ[7-i]), .activ_ctrl(activ_ctrl));
        end
    endgenerate

    logic rflag1, rflag2, rflag3;
    logic [3:0] count2, count3;
    logic [4:0] count1;
    flex_counter #(.SIZE(5)) f1(.clk(clk), .n_rst(n_rst), .clear(~inf_running), .count_enable(inf_running && ~rflag1), .rollover_val(5'h10), .count_out(count1), .rollover_flag(rflag1));
    flex_counter #(.SIZE(4)) f2(.clk(clk), .n_rst(n_rst), .clear(~inf_running), .count_enable(count1 >= 5'h0c), .rollover_val(4'h8), .count_out(count2), .rollover_flag(rflag2));
    flex_counter #(.SIZE(4)) f3(.clk(clk), .n_rst(n_rst), .clear(~inf_running), .count_enable(rflag1), .rollover_val(4'h8), .count_out(count3), .rollover_flag(rflag3));

    logic skip_first, n_skip_first;
    always_comb begin
        n_skip_first = skip_first;
        if(~inf_running) begin
            n_skip_first = 1'b0;
        end
        else if(count3 == 4'h1 && !skip_first) begin
            n_skip_first = 1'b1;
        end
    end

    always_ff@(posedge clk or negedge n_rst) begin
        if(~n_rst) begin
            skip_first <= '0;
        end
        else begin
            skip_first <= n_skip_first;
        end
    end

    logic reg1_done, reg0_done;
    logic [63:0] next_reg1, next_reg0, reg0, reg1;
    always_comb begin
        reg0_done = 1'b0;
        reg1_done = 1'b0;
        case(count2)
            4'h1: begin
                    next_reg0 = {int_out_activ[7], reg0[55:0]};
                    reg0_done = skip_first ? 1'b1 : 1'b0;
                end
            4'h2: next_reg0 = {reg0[63:56], int_out_activ[6], reg0[47:0]};
            4'h3: next_reg0 = {reg0[63:48], int_out_activ[5], reg0[39:0]};
            4'h4: next_reg0 = {reg0[63:40], int_out_activ[4], reg0[31:0]};
            4'h5: next_reg0 = {reg0[63:32], int_out_activ[3], reg0[23:0]};
            4'h6: next_reg0 = {reg0[63:24], int_out_activ[2], reg0[15:0]};
            4'h7: next_reg0 = {reg0[63:16], int_out_activ[1], reg0[7:0]};
            4'h8: next_reg0 = {reg0[63:8], int_out_activ[0]};
                    
            default: next_reg0 = reg0;
        endcase
        
        case(count3) 
            4'h1: begin
                    next_reg1 = {int_out_activ[7], reg1[55:0]};
                    reg1_done = skip_first ? 1'b1 : 1'b0;
                end
            4'h2: next_reg1 = {reg1[63:56], int_out_activ[6], reg1[47:0]};
            4'h3: next_reg1 = {reg1[63:48], int_out_activ[5], reg1[39:0]};
            4'h4: next_reg1 = {reg1[63:40], int_out_activ[4], reg1[31:0]};
            4'h5: next_reg1 = {reg1[63:32], int_out_activ[3], reg1[23:0]};
            4'h6: next_reg1 = {reg1[63:24], int_out_activ[2], reg1[15:0]};
            4'h7: next_reg1 = {reg1[63:16], int_out_activ[1], reg1[7:0]};
            4'h8: next_reg1 = {reg1[63:8], int_out_activ[0]};
            default: next_reg1 = reg1;
        endcase
    end

    logic [63:0] next_out, out_reg;
    logic n_output_ready, o_r;

    always_comb begin
	    n_output_ready = (count2 == 4'h8 || count3 == 4'h8) | (reg1_done | reg0_done) & skip_first;
	    next_out = out_reg;
	    if(reg1_done) begin
		    next_out = reg1;
        end
	    if(reg0_done) begin
		    next_out = reg0;
        end
    end


    logic [7:0] inf_reg0, nan_reg0, inf_reg1, nan_reg1;
    logic next_nan_result, next_inf_result, s_nan_result, s_inf_result;


    always_ff@(posedge clk or negedge n_rst) begin
        if(~n_rst) begin
            reg0 <= '0;
            reg1 <= '0;
            out_reg <= '0;
            o_r <= '0;
            s_inf_result <= '0;
            s_nan_result <= '0;
        end
        else begin
            reg0 <= next_reg0;
            reg1 <= next_reg1;
            out_reg <= next_out;
            o_r <= n_output_ready;
            s_nan_result <= next_nan_result;
            s_inf_result <= next_inf_result;
        end
    end

    generate
        for(i = 0; i < 8; i++) begin
            assign inf_reg0[i] = reg0[8*i+6:8*i] == 7'h78;
            assign nan_reg0[i] = reg0[8*i+6:8*i] > 7'h78;
            assign inf_reg1[i] = reg1[8*i+6:8*i] == 7'h78;
            assign nan_reg1[i] = reg1[8*i+6:8*i] > 7'h78;
        end
    endgenerate
    assign next_inf_result = n_output_ready ? (reg1_done && (|inf_reg1) || reg0_done && (|inf_reg0)) : s_inf_result;
    assign next_nan_result = n_output_ready ? (reg1_done && (|nan_reg1) || reg0_done && (|nan_reg0)) : s_nan_result;
    
    assign inf_result = s_inf_result;
    assign nan_result = s_nan_result;

    assign out = reg0_done ? reg0 : reg1_done ? reg1 : out_reg;
    assign output_ready = o_r | n_output_ready;


endmodule

