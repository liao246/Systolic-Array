`timescale 1ns / 10ps

module full_array_activator #(
    // parameters
) (
    input logic clk, n_rst,
    input logic load, inf_running,
    input logic [1:0] activation_mode,
    input logic [63:0] inp,
    input logic [63:0] bias,
    output logic [63:0] out,
    output logic inf_result, nan_result,
    output logic output_ready
    
);
    logic [127:0] int_out;
    array a1(.clk(clk), .n_rst(n_rst), .inp(inp), .load(load), .inf_started(inf_running), .out(int_out));
    bias_adder_activator b1(.clk(clk), .n_rst(n_rst), .arr_inp(int_out), .bias(bias), .activ_ctrl(activation_mode), .inf_running(inf_running), .out(out), .inf_result(inf_result), .nan_result(nan_result), .output_ready(output_ready));

endmodule

