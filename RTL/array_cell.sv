`timescale 1ns / 10ps

module array_cell #(
    // parameters
) (
    input logic clk, n_rst,
    input logic load,
    input logic [15:0] inp, prev_output,
    output logic [15:0] pass_input, out
);
    logic [15:0] weight, in, output_reg;
    logic [15:0] next_w, next_in;

    logic [15:0] intm_out;
    logic [15:0] next_out;

    always_ff @(posedge clk or negedge n_rst) begin
        if(~n_rst) begin
            weight <= 16'b0;
            in <= 16'b0;
            output_reg <= 16'b0;
        end
        else begin
            weight <= next_w;
            in <= next_in;
            output_reg <= next_out;
        end
    end

    always_comb begin
        next_in = in;
        next_w = weight;
        if(load) begin
            next_w = inp;
        end
        else begin
            next_in = inp;
        end
    end

    always_comb begin
        pass_input = 0;
        if(load) begin
            pass_input = weight;
        end
        else begin
            pass_input = in;
        end
    end


    multiplier mult(.a(weight), .b(next_in), .out(intm_out));
    float_adder fa(.a(intm_out), .b(prev_output), .sum(next_out));
    assign out = output_reg;




endmodule

