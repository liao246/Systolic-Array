`timescale 1ns / 10ps

module top_level #(
    // parameters
) (
    input logic clk, n_rst,
    input logic hsel, 
    input logic [9:0] haddr,
    input logic [1:0] htrans,
    input logic [1:0] hsize,
    input logic hwrite,
    input logic [63:0] hwdata,
    output logic [63:0] hrdata,
    output logic hready, hresp
);

    logic output_ready, inf_result, nan_result;
    logic [63:0] out;
    logic [63:0] inp;
    logic write_input, write_weight, load_weights, inf_out, nan_out, load, read_output, weights_done, inf_running;
    logic[7:0] control_status, control_r;
    logic[63:0] weight_r, input_r;
    logic buffer_error, inference_complete, overrun_error;
    logic[63:0] sram_output;
    logic [1:0] activ_ctrl;
    logic [63:0] bias;  

    ai_controller #() controller (
        // input
        .clk(clk),
        .n_rst(n_rst),
        .write_input(write_input),
        .write_weight(write_weight),
        .read_output(read_output),
        .output_ready(output_ready),
        .input_r(input_r),
        .weight_r(weight_r),
        .out(out),
        .control_r(control_r),

        // outputs
        .overrun_error(overrun_error),
        .buffer_error(buffer_error),
        .control_status(control_status),
        .weights_done(weights_done),
        .inf_running(inf_running),
        .load(load),
        .inp(inp),
        .sram_output(sram_output)
    );

    full_array_activator array (
        .clk(clk),
        .n_rst(n_rst),
        .load(load),
        .inf_running(inf_running),
        .activation_mode(activ_ctrl),
        .inp(inp),
        .bias(bias),
        .out(out),
        .inf_result(inf_result),
        .nan_result(nan_result),
        .output_ready(output_ready)
    );

    ahb ahb_subord (
        .clk(clk),
        .n_rst(n_rst),
        .hsel(hsel),
        .haddr(haddr),
        .htrans(htrans),
        .hsize(hsize),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hready(hready),
        .hresp(hresp),
        
        .inf_result(inf_result),
        .nan_result(nan_result),
        .overrun_error(overrun_error),
        .buffer_error(buffer_error),
        .sram_output(sram_output),
        .control_status(control_status),
        .weights_done(weights_done),
        
        .weight_r(weight_r),
        .input_r(input_r),
        .read_output(read_output),
        .write_input(write_input),
        .write_weight(write_weight),
        .control_r(control_r),
        
        .activation_mode(activ_ctrl),
        .bias(bias)
    );


endmodule

