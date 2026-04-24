`timescale 1ns / 10ps

module ahb #(
    // parameters
) (
    input logic clk, n_rst,
    input logic hsel, 
    input logic [9:0] haddr,
    input logic [1:0] htrans, hsize,
    input logic hwrite,
    input logic [63:0] hwdata,
    output logic [63:0] hrdata,
    output logic hready, hresp,
    
    // controller
    input logic inf_result, nan_result, overrun_error, buffer_error,
    input logic [63:0] sram_output,
    input logic [7:0] control_status,
    input logic weights_done,
    
    output logic [63:0] weight_r, input_r,
    output logic read_output, write_input, write_weight,
    output logic [7:0] control_r,
    // array
    output logic [1:0] activation_mode,
    output logic [63:0] bias
);



    logic [7:0] status_r;
    assign status_r = control_status;
    logic [15:0] error_r, next_error;
    logic hwrite_r, next_hwrite_r;
    logic [9:0] haddr_r, next_haddr_r;
    logic [1:0] hsize_r, next_hsize_r;

    logic [63:0] next_hrdata, hrdata_r;
    logic [1:0] htrans_r, next_htrans_r;
    logic hsel_r, next_hsel_r;
    logic transaction_error;

    logic [63:0] next_weight, next_input, next_bias, bias_r;
    logic [7:0] next_control, next_activation, activation_r, control_reg;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            error_r <= 0;
            hwrite_r <= 0;
            haddr_r <= 0;
            hsize_r <= 0;
            hrdata_r <= 0;
            htrans_r <= 0;
            hsel_r <= 0;
            weight_r <= 0;
            input_r <= 0;
            bias_r <= 0;
            control_reg <= 0;
            activation_r <= 0;
        end else begin
            error_r <= next_error;
            hwrite_r <= next_hwrite_r;
            haddr_r <= next_haddr_r;
            hsize_r <= next_hsize_r;
            hrdata_r <= next_hrdata;
            htrans_r <= next_htrans_r;
            hsel_r <= next_hsel_r;
            weight_r <= next_weight;
            input_r <= next_input;
            bias_r <= next_bias;
            control_reg <= next_control;
            activation_r <= next_activation;
        end
    end

    assign control_r = {control_reg[7:1], control_reg[0] || next_control[0]};
    always_comb begin
        if (hready) begin
            next_hwrite_r = hwrite;
            next_haddr_r = haddr;
            next_hsize_r = hsize;
            next_htrans_r = htrans;
            next_hsel_r = hsel;
        end else begin
            next_hwrite_r = hwrite_r;
            next_haddr_r = haddr_r;
            next_hsize_r = hsize_r;
            next_htrans_r = htrans_r;
            next_hsel_r = hsel_r;
        end
    end

    always_comb begin
        next_error = error_r;

        if (hsel && (htrans == 2'd2 || htrans == 2'd3) && !hwrite && haddr >= 10'h20 && haddr < 10'h22) begin // reading error reg
            next_error = 16'd0;
        end

        if (hsel && (htrans == 2'd2 || htrans == 2'd3)) begin
            if (!hwrite && haddr >= 10'h18 && haddr < 10'h20) begin // reading write only reg
                if (status_r[1]) begin
                    next_error[3] = 1'b1;
                end
            end
            if (hwrite && haddr >= 10'h0 && haddr < 10'h10) begin   // writing read only reg
                if (status_r[1]) begin
                    next_error[3] = 1'b1;
                end
            end
        end

        if (buffer_error) begin
            next_error[0] = 1'b1;
        end
        if (overrun_error) begin
            next_error[1] = 1'b1;
        end
        if (nan_result) begin
            next_error[8] = 1'b1;
        end
        if (inf_result) begin
            next_error[9] = 1'b1;
        end
    end

    // RAW and read
    always_comb begin
        next_hrdata = 64'd0;

        // read logic
        if (hsel && (htrans == 2'd2 || htrans == 2'd3)) begin
            if (!hwrite) begin
                if (haddr >= 10'h18 && haddr < 10'h20) begin // output register
                    next_hrdata = sram_output;
                end else if (haddr >= 10'h10 && haddr < 10'h18) begin
                    next_hrdata = bias_r;
                end else if (haddr >= 10'h20 && haddr <= 10'h24) begin
                    next_hrdata = {24'd0, activation_r, status_r, control_r, error_r};
                end
            end
        end

        // RAW hazard logic
        if (hsel && (htrans == 2'd2 || htrans == 2'd3) && !hwrite) begin
            if (hwrite_r && (haddr_r/8) == (haddr/8)) begin
                if (hsize_r == 2'd3) begin
                    next_hrdata = hwdata;
                end else if (hsize_r == 2'd2) begin
                    if ((haddr_r % 8) >= 4) begin
                        next_hrdata[63:32] = hwdata[63:32];
                    end else begin
                        next_hrdata[31:0] = hwdata[31:0];
                    end
                end else if (hsize_r == 2'd1) begin
                    if ((haddr_r % 8) >= 6) begin
                        next_hrdata[63:48] = hwdata[63:48];
                    end else if ((haddr_r % 8) >= 4) begin
                        next_hrdata[47:32] = hwdata[47:32];
                    end else if ((haddr_r % 8) >= 2) begin
                        next_hrdata[31:16] = hwdata[31:16];
                    end else begin
                        next_hrdata[15:0] = hwdata[15:0];
                    end
                end else if (hsize_r == 2'd0) begin
                    case (haddr % 8)
                        0: next_hrdata[7:0] = hwdata[7:0];
                        1: next_hrdata[15:8] = hwdata[15:8];
                        2: next_hrdata[23:16] = hwdata[23:16];
                        3: next_hrdata[31:24] = hwdata[31:24];
                        4: next_hrdata[39:32] = hwdata[39:32];
                        5: next_hrdata[47:40] = hwdata[47:40];
                        6: next_hrdata[55:48] = hwdata[55:48];
                        7: next_hrdata[63:56] = hwdata[63:56];
                    endcase
                end
            end
        end

    end

    
    // write logic
    always_comb begin
        next_weight = weight_r;
        next_input = input_r;
        next_bias = bias_r;
        next_control = control_reg;
        next_activation = activation_r;

        if (control_status[0]) begin
            next_control[0] = 0;
        end
        
        if (hsel_r && (htrans_r == 2'd2 || htrans_r == 2'd3) && hwrite_r) begin
            if (haddr_r >= 10'h0 && haddr_r < 10'h8 && !status_r[1]) begin // weight register
                if (hsize_r == 2'd3) begin
                    next_weight = hwdata;
                end else if (hsize_r == 2'd2) begin
                    if (haddr_r % 8 >= 4) begin
                        next_weight = {hwdata[63:32], 32'd0};
                    end else begin
                        next_weight = {32'd0, hwdata[31:0]};
                    end
                end else if (hsize_r == 2'd1) begin
                    if (haddr_r % 8 >= 6) begin
                        next_weight = {hwdata[63:48], 48'd0};
                    end else if (haddr_r % 8 >= 4) begin
                        next_weight = {16'd0, hwdata[47:32], 32'd0};
                    end else if (haddr_r % 8 >= 2) begin
                        next_weight = {32'd0, hwdata[31:16], 16'd0};
                    end else begin
                        next_weight = {48'd0, hwdata[15:0]};
                    end
                end else begin
                    case (haddr_r % 8)
                        0: next_weight = {56'd0, hwdata[7:0]};
                        1: next_weight = {48'd0, hwdata[15:8], 8'd0};
                        2: next_weight = {40'd0, hwdata[23:16], 16'd0};
                        3: next_weight = {32'd0, hwdata[31:24], 24'd0};
                        4: next_weight = {24'd0, hwdata[39:32], 32'd0};
                        5: next_weight = {16'd0, hwdata[47:40], 40'd0};
                        6: next_weight = {8'd0, hwdata[55:48], 48'd0};
                        7: next_weight = {hwdata[63:56], 56'd0};
                    endcase
                end
            end else if (haddr_r >= 10'h8 && haddr_r < 10'h10 && !status_r[1]) begin // input register
                if (hsize_r == 2'd3) begin
                    next_input = hwdata;
                end else if (hsize_r == 2'd2) begin
                    if (haddr_r % 8 >= 4) begin
                        next_input = {hwdata[63:32], 32'd0};
                    end else begin
                        next_input = {32'd0, hwdata[31:0]};
                    end
                end else if (hsize_r == 2'd1) begin
                    if (haddr_r % 8 >= 6) begin
                        next_input = {hwdata[63:48], 48'd0};
                    end else if (haddr_r % 8 >= 4) begin
                        next_input = {16'd0, hwdata[47:32], 32'd0};
                    end else if (haddr_r % 8 >= 2) begin
                        next_input = {32'd0, hwdata[31:16], 16'd0};
                    end else begin
                        next_input = {48'd0, hwdata[15:0]};
                    end
                end else begin
                    case (haddr_r % 8)
                        0: next_input = {56'd0, hwdata[7:0]};
                        1: next_input = {48'd0, hwdata[15:8], 8'd0};
                        2: next_input = {40'd0, hwdata[23:16], 16'd0};
                        3: next_input = {32'd0, hwdata[31:24], 24'd0};
                        4: next_input = {24'd0, hwdata[39:32], 32'd0};
                        5: next_input = {16'd0, hwdata[47:40], 40'd0};
                        6: next_input = {8'd0, hwdata[55:48], 48'd0};
                        7: next_input = {hwdata[63:56], 56'd0};
                    endcase
                end
            
            end else if (haddr_r >= 10'h10 && haddr_r < 10'h18) begin // bias register
                if (hsize_r == 2'd3) begin
                    next_bias = hwdata;
                end else if (hsize_r == 2'd2) begin
                    if (haddr_r % 8 >= 4) begin
                        next_bias = {hwdata[63:32], bias_r[31:0]};
                    end else begin
                        next_bias = {bias_r[63:32], hwdata[31:0]};
                    end
                end else if (hsize_r == 2'd1) begin
                    if (haddr_r % 8 >= 6) begin
                        next_bias = {hwdata[63:48], bias_r[47:0]};
                    end else if (haddr_r % 8 >= 4) begin
                        next_bias = {bias_r[63:48], hwdata[47:32], bias_r[31:0]};
                    end else if (haddr_r % 8 >= 2) begin
                        next_bias = {bias_r[63:32], hwdata[31:16], bias_r[15:0]};
                    end else begin
                        next_bias = {bias_r[63:16], hwdata[15:0]};
                    end
                end else begin
                    case (haddr_r % 8)
                        0: next_bias = {next_bias[63:8], hwdata[7:0]};
                        1: next_bias = {next_bias[63:16], hwdata[15:8], next_bias[7:0]};
                        2: next_bias = {next_bias[63:24], hwdata[23:16], next_bias[15:0]};
                        3: next_bias = {next_bias[63:32], hwdata[31:24], next_bias[23:0]};
                        4: next_bias = {next_bias[63:40], hwdata[39:32], next_bias[31:0]};
                        5: next_bias = {next_bias[63:48], hwdata[47:40], next_bias[39:0]};
                        6: next_bias = {next_bias[63:56], hwdata[55:48], next_bias[47:0]};
                        7: next_bias = {hwdata[63:56], next_bias[55:0]};
                    endcase
                end
            end else if (haddr_r >= 10'h22 && haddr_r < 10'h23) begin // control register
                if (hsize_r == 2'd0) begin
                    next_control = hwdata[23:16];
                end
            end else if (haddr_r == 10'h24) begin // activation register
                if (hsize_r == 2'd0) begin
                    next_activation = hwdata[39:32];
                end
            end
        end





        if (weights_done) begin
            next_control[1] = 0;
        end
    end


    typedef enum logic [2:0] {
        IDLE,
        WAIT_R,
        WAIT_R2,
        WAIT_R3,
        ERROR1,
        ERROR2
    } state_t;

    state_t state, next_state;

    // read for controller
    always_comb begin
        read_output = 0;
        if (state == WAIT_R) begin
            read_output = 1;
        end 
    end

    // weights or inputs for controller
    always_comb begin
        write_weight = 0;
        write_input = 0;
        if (hsel_r && (htrans_r == 2'd2 || htrans_r == 2'd3)) begin
            if (hwrite_r) begin
                if (haddr_r >= 10'h0 && haddr_r < 10'h8 && !status_r[1]) begin
                    write_weight = 1;
                end
                if (haddr_r >= 10'h8 && haddr_r < 10'h10 && !status_r[1]) begin
                    write_input = 1;
                end
            end
        end 
    end


    // error fsm
    always_comb begin
        transaction_error = (hwrite == 1 && ((haddr >= 10'h18 && haddr < 10'h20) || (haddr >= 10'h20 && haddr < 10'h22) || haddr == 10'h23)) || (hwrite == 0 && haddr < 10'h10) || (haddr > 10'h24) || ((haddr < 10'h10 || (haddr >= 10'h18 && haddr < 10'h20)) && status_r[1] == 1);

        case (state)
            IDLE: begin
                if (hsel && (htrans == 2'd2 || htrans == 2'd3) && transaction_error) begin
                    next_state = ERROR1;
                end else if (hsel && (htrans == 2'd2 || htrans == 2'd3) && !hwrite && (haddr >= 10'h18 && haddr < 10'h20)) begin
                    next_state = WAIT_R;
                end else begin
                    next_state = IDLE;
                end
            end
            ERROR1: next_state = ERROR2;
            ERROR2: next_state = IDLE;
            WAIT_R: next_state = WAIT_R2;
            WAIT_R2: next_state = WAIT_R3;
            WAIT_R3: begin
                if (!control_status[1]) begin
                    next_state = IDLE;
                end else begin
                    next_state = WAIT_R3;
                end
            end
            default: next_state = state;
        endcase

        case (state)
            IDLE: begin
                hresp = 0;
                hready = 1;
            end
            ERROR1: begin
                hresp = 1;
                hready = 0;
            end
            ERROR2: begin
                hresp = 1;
                hready = 1;
            end
            WAIT_R: begin
                hresp = 0;
                hready = 0;
            end
            WAIT_R2: begin
                hresp = 0;
                hready = 0;
            end
            WAIT_R3: begin
                hresp = 0;
                hready = ~control_status[1];
            end
            default: begin 
                hresp = 0; 
                hready = 1; 
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end


    assign activation_mode = activation_r[1:0];
    assign bias = bias_r;

    // sram read
    always_comb begin
        if (state == WAIT_R3) begin
            hrdata = sram_output;
        end else begin
            hrdata = hrdata_r;
        end
    end

endmodule
