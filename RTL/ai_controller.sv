`timescale 1ns / 10ps

module ai_controller #(
    // parameters
) (
    input logic clk, n_rst,
    input logic write_input, write_weight, read_output, output_ready,
    input logic[7:0] control_r,
    input logic[63:0] out,
    input logic[63:0] input_r, weight_r,

    
    output logic overrun_error, buffer_error,
    output logic inf_running, load, weights_done,
    output logic[7:0] control_status,
    output logic[63:0] inp,
    output logic[63:0] sram_output
);

//1).
//need to change input occupancy full and weight occupancy full to buffer error

//2).
// need to output weight done
//weight_load_rollover --> weights_done


//3).
//need to output 8 bit control status 
//Bit 0 → inference_complete
//Bit 1 → modwait


//sram_out_data << data from output SRAM given to AHB
//inp << data from SRAM given to array

//data >> data given by AHB
//weight_r
//input_r
//output_array >> data given by array

typedef enum logic [1:0] {IDLE_M, BUSY, ACCESS, ERROR} memory_state;
typedef enum logic [5:0] {IDLE,
 INPUT_WRITE, INCR_INPUT, INPUT_WAIT, INPUT_OCCUP_FULL,
 WEIGHT_WRITE, INCR_WEIGHT, WEIGHT_WAIT,
 INPUT_LOAD, INCR_INPUT_LOAD, INPUT_LOAD_WAIT,
 WEIGHT_LOAD, INCR_WEIGHT_LOAD, WEIGHT_LOAD_WAIT,
 OUTPUT_LOAD, INCR_OUTPUT_LOAD, OUTPUT_LOAD_WAIT,
 INFERENCE_WAIT, BUFFER_INPUT, BUFFER_WEIGHT} state_t;

 typedef enum logic [4:0] {IDLE_OUT,
 OUTPUT_WRITE, INCR_OUTPUT, OUTPUT_WAIT,
 INFERENCE_COMPLETE, OUTPUT_WRITE_1, OUTPUT_WRITE_2, OUTPUT_WRITE_OVERRUN} state_t_out;

state_t state, next_state;
state_t_out state_out, next_state_out;

logic outputs_pending;
logic next_inf_running_normal, next_inf_running_output;
logic next_modwait_n, next_modwait_out;
logic next_modwait, next_inf_running, next_outputs_pending;
logic weight_write_en;
logic weight_read_en;
logic input_write_en;
logic input_read_en;
logic output_read_en;
logic output_write_en;
logic modwait, inference_complete;

//counter signals
logic weight_cnt_en, weight_clr, weight_rollover;
logic[7:0] weight_cnt_out;

logic weight_load_cnt_en, weight_load_clr;
logic[7:0] weight_load_cnt_out;

logic input_cnt_en, input_clr, input_rollover;
logic[7:0] input_cnt_out;

logic input_load_cnt_en, input_load_clr, input_load_rollover;
logic[7:0] input_load_cnt_out;

logic output_cnt_en, output_clr, output_rollover;
logic[7:0] output_cnt_out;

logic output_load_cnt_en, output_load_clr, output_load_rollover;
logic[7:0] output_load_cnt_out;

logic access_cnt_en, access_clr, access_rollover;
logic[7:0] access_cnt_out;

logic access_out_cnt_en, access_out_clr, access_out_rollover;
logic[7:0] access_out_cnt_out;

//sram signals
logic[1:0] sram_state;
logic[1:0] sram_out_state;

logic sram_0_wen, sram_0_ren;
logic[9:0] sram_0_addr;
logic[1:0] sram_0_state;
logic[31:0] sram_0_read_data, sram_0_write_data;

logic sram_1_wen, sram_1_ren;
logic[9:0] sram_1_addr;
logic[1:0] sram_1_state;
logic[31:0] sram_1_read_data, sram_1_write_data;

logic sram_2_wen, sram_2_ren;
logic[9:0] sram_2_addr;
logic[1:0] sram_2_state;
logic[31:0] sram_2_read_data, sram_2_write_data;

logic sram_3_wen, sram_3_ren;
logic[9:0] sram_3_addr;
logic[1:0] sram_3_state;
logic[31:0] sram_3_read_data, sram_3_write_data;

logic inference_done;
logic next_inference_complete;
always_comb begin
    control_status = 8'd0;
    if (modwait) begin
        control_status[1] = 1'b1;
    end 

    if (inference_complete) begin
        control_status[0] = 1'b1;
    end
end

always_ff @(posedge clk, negedge n_rst) begin
    if (!n_rst) begin
        inference_complete <= 1'b0;
    end else begin
        inference_complete <= next_inference_complete;
    end
end

always_comb begin
    next_inference_complete = inference_complete;
    if (inference_done) begin
        next_inference_complete = 1'b1;
    end else if (state == OUTPUT_LOAD | control_r[0]) begin
        next_inference_complete = 1'b0;
    end
end

always_ff @(posedge clk, negedge n_rst) begin
    if (!n_rst) begin
        state <= IDLE;
        modwait <= 1'b0;
        //inf_running <= 1'b0;
        outputs_pending <= 1'b0;
        state_out <= IDLE_OUT;
    end else begin
        state <= next_state;
        modwait <= next_modwait;
        //inf_running <= next_inf_running;
        outputs_pending <= next_outputs_pending;
        state_out <= next_state_out;
    end
end

always_comb begin
    next_state_out = state_out;
    case (state_out)
        IDLE_OUT: begin
            if (output_ready & !outputs_pending) begin
                next_state_out = OUTPUT_WRITE;
            end else if (output_ready & outputs_pending) begin
                next_state_out = OUTPUT_WRITE_OVERRUN;
            end
        end

        OUTPUT_WRITE_1: next_state_out = OUTPUT_WRITE_2;
        
        OUTPUT_WRITE_2: next_state_out = INCR_OUTPUT;

        //Write Outputs to SRAM

        OUTPUT_WRITE_OVERRUN: begin
            if (access_out_rollover) begin
                next_state_out = INCR_OUTPUT;
            end
        end

        OUTPUT_WRITE: begin
            if (access_out_rollover) begin
                next_state_out = INCR_OUTPUT;
            end
        end

        INCR_OUTPUT: begin
            next_state_out = OUTPUT_WAIT;
        end

        OUTPUT_WAIT: begin
            next_state_out = OUTPUT_WRITE;
            if (output_rollover) begin
                next_state_out = INFERENCE_COMPLETE;
            end
        end

        INFERENCE_COMPLETE: begin
            next_state_out = IDLE_OUT;
        end 

        default: next_state_out = IDLE_OUT;
    endcase
end


always_comb begin
    output_write_en = 1'b0;
    access_out_cnt_en = 1'b0;
    access_out_clr = 1'b0;
    output_cnt_en = 1'b0;
    //next_inference_complete = 1'b0;
    next_inf_running_output = 1'b0;
    overrun_error = 1'b0;
    input_clr = 1'b0;
    input_load_clr = 1'b0;
    weight_clr = 1'b0;
    weight_load_clr = 1'b0;
    inference_done = 1'b0;
    output_clr = 1'b0;
    output_load_clr = 1'b0;
    case (state_out)
        IDLE_OUT: begin
            access_out_clr = 1'b0;
            output_write_en = 1'b0;
            access_out_cnt_en = 1'b0;
            output_cnt_en = 1'b0;
            //next_inference_complete = 1'b0;
            next_inf_running_output = 1'b0;
            overrun_error = 1'b0;
        end

        //Writing outputs into SRAM

        // OUTPUT_WRITE_1: begin
        //     output_write_en = 1'b1;
        //     access_out_cnt_en = 1'b1;
        //     output_cnt_en = 1'b0;
        //     next_inf_running_output = 1'b1;
        // end

        // OUTPUT_WRITE_2: begin
        //     output_write_en = 1'b1;
        //     access_out_cnt_en = 1'b1;
        //     output_cnt_en = 1'b0;
        //     next_inf_running_output = 1'b1;
        // end

        OUTPUT_WRITE_OVERRUN: begin
            output_write_en = 1'b1;
            overrun_error = 1'b1;
            access_out_cnt_en = 1'b1;
            output_cnt_en = 1'b0;
            next_inf_running_output = 1'b1;
        end

        OUTPUT_WRITE: begin
            output_write_en = 1'b1;
            access_out_cnt_en = 1'b1;
            output_cnt_en = 1'b0;
            next_inf_running_output = 1'b1;
        end

        INCR_OUTPUT: begin
            output_write_en = 1'b1;
            output_cnt_en = 1'b1;
            access_out_clr = 1'b1;
            next_inf_running_output = 1'b1;
        end

        OUTPUT_WAIT: begin
            output_write_en = 1'b1;
            output_cnt_en = 1'b0;
            next_inf_running_output = 1'b1;
            access_out_cnt_en = 1'b1;
            inference_done = 1'b0;
            if (output_rollover) begin
                inference_done = 1'b1;
            end
        end
        
        INFERENCE_COMPLETE: begin
            inference_done = 1'b1;
            next_inf_running_output = 1'b0;
            access_out_cnt_en = 1'b0;
            access_out_clr = 1'b1;
            input_clr = 1'b1;
            input_load_clr = 1'b1;
            weight_clr = 1'b1;
            weight_load_clr = 1'b1;
            output_clr = 1'b1;
            output_load_clr = 1'b1;
        end


        default: begin
            output_write_en = 1'b0;
            access_out_cnt_en = 1'b0;
            access_out_clr = 1'b0;
            output_cnt_en = 1'b0;
            next_inf_running_output = 1'b0;
            //next_inference_complete = 1'b0;
            overrun_error = 1'b0;
        end
    endcase
end
    

//How to choose next state
always_comb begin
    next_state = state;
    case (state)
        IDLE: begin

            if (write_input & (!input_rollover)) begin
                next_state = INPUT_WRITE;
            end

            // if (write_input & input_rollover) begin
            //     next_state = BUFFER_INPUT;
            // end

            if (write_weight & (!weight_rollover)) begin
                next_state = WEIGHT_WRITE;
            end

            // if (write_input & weight_rollover) begin
            //     next_state = BUFFER_WEIGHT;
            // end

            if (control_r[0] & (state_out == IDLE_OUT)) begin
                next_state = INPUT_LOAD;
            end

            if (control_r[1]) begin
                next_state = WEIGHT_LOAD;
            end

            if (read_output) begin
                next_state = OUTPUT_LOAD;
            end
            
        end

        //Write inputs to SRAM
        INPUT_WRITE: begin
            if (access_rollover) begin
                next_state = INCR_INPUT;
            end
        end
       
        INCR_INPUT: begin
            next_state = IDLE;
        end

        // BUFFER_INPUT: begin
        //     next_state = IDLE;
        // end

        //Write weights to SRAM

        WEIGHT_WRITE: begin
            if (access_rollover) begin
                next_state = INCR_WEIGHT;
            end
        end

        INCR_WEIGHT: begin
            next_state = IDLE;
        end

        // WEIGHT_WAIT: begin
        //     next_state = IDLE;
        // end

        //Write Outputs to SRAM

        // OUTPUT_WRITE: begin
        //     if (access_rollover) begin
        //         next_state = INCR_OUTPUT;
        //     end
        // end

        // INCR_OUTPUT: begin
        //     next_state = OUTPUT_WAIT;
        // end

        // OUTPUT_WAIT: begin
        //     if (!output_rollover & output_done) begin
        //         next_state = OUTPUT_WRITE;
        //     end else if (output_rollover) begin
        //         next_state = INFERENCE_COMPLETE;
        //     end
        // end

        //Loading in Inputs
        //need to 
        INPUT_LOAD: begin
            if (access_rollover) begin
                next_state = INCR_INPUT_LOAD;
            end
        end

        INCR_INPUT_LOAD: begin
            next_state = INPUT_LOAD_WAIT;
        end

        INPUT_LOAD_WAIT: begin
            next_state = IDLE;
            if (!input_load_rollover) begin
                next_state = INPUT_LOAD;
            end
        end

        //Loading in Weights

        WEIGHT_LOAD: begin
            if (access_rollover) begin
                next_state = INCR_WEIGHT_LOAD;
            end
        end

        INCR_WEIGHT_LOAD: begin
            next_state = WEIGHT_LOAD_WAIT;
        end

        WEIGHT_LOAD_WAIT: begin
            next_state = IDLE;
            if (!weights_done) begin
                next_state = WEIGHT_LOAD;
            end
        end

        //Loading in Outputs

        OUTPUT_LOAD: begin
            if (access_rollover) begin
                next_state = INCR_OUTPUT_LOAD;
            end
        end

        INCR_OUTPUT_LOAD: begin
            next_state = IDLE;
        end

        //unused
        OUTPUT_LOAD_WAIT: begin
            next_state = IDLE;
        end

        //INFERENCE SIGNALS

        // INFERENCE_WAIT: begin
        //     if (output_done & !outputs_pending) begin
        //         next_state = OUTPUT_WRITE;
        //     end
        // end 

        // INFERENCE_COMPLETE: begin
        //     next_state = IDLE;
        // end 


        default: next_state = IDLE;
    endcase
end


always_comb begin
    {weight_cnt_en, weight_write_en, weight_read_en, weight_load_cnt_en, load} = 5'd0;
    {input_cnt_en, input_write_en, input_read_en, input_load_cnt_en} = 4'd0;
    {access_clr, access_cnt_en, output_read_en} = 3'd0;
    output_load_cnt_en = 1'd0;
    next_inf_running_normal = 1'b0;
    // output_clr = 1'b0;
    // output_load_clr = 1'b0;
   // close_inference = 1'b0;
    case (state)
        IDLE: begin
            {weight_cnt_en, weight_write_en, weight_read_en, weight_load_cnt_en, load} = 5'd0;
            access_clr = 1'b1;
            next_inf_running_normal = 1'b0;
            {input_cnt_en, input_write_en} = 2'd0;
        end

        //Writing inputs into SRAM
        INPUT_WRITE: begin
            input_write_en = 1'b1;
            access_cnt_en = 1'b1;
            input_cnt_en = 1'b0;
        end

        INCR_INPUT: begin
            input_write_en = 1'b1;
            input_cnt_en = 1'b1;
            access_clr = 1'b1;
        end

        // INPUT_WAIT: begin
        //     input_write_en = 1'b1;
        //     load = 1'b1; //unnecessary but keeping for now
        //     access_cnt_en = 1'b1;
        // end

        //Writing weights into SRAM
        WEIGHT_WRITE: begin
            weight_write_en = 1'b1;
            access_cnt_en = 1'b1;
            weight_cnt_en = 1'b0;
        end

        INCR_WEIGHT: begin
            weight_write_en = 1'b1;
            weight_cnt_en = 1'b1;
            access_clr = 1'b1;
        end

        // WEIGHT_WAIT: begin
        //     weight_write_en = 1'b0;
        //     load = 1'b1; //unnecessary but keeping for now
        //     access_cnt_en = 1'b0;
        // end

        //Writing outputs into SRAM

        // OUTPUT_WRITE: begin
        //     output_write_en = 1'b1;
        //     access_cnt_en = 1'b1;
        //     output_cnt_en = 1'b0;
        // end

        // INCR_OUTPUT: begin
        //     output_write_en = 1'b1;
        //     output_cnt_en = 1'b1;
        //     access_clr = 1'b1;
        // end

        // OUTPUT_WAIT: begin
        //     output_write_en = 1'b1;
        //     //load = 1'b1;
        //     access_cnt_en = 1'b1;
        // end

        //Loading in weights
        WEIGHT_LOAD: begin
            weight_read_en = 1'b1;
            access_cnt_en = 1'b1;
            weight_load_cnt_en = 1'b0;
        end

        INCR_WEIGHT_LOAD: begin
            weight_read_en = 1'b1;
            weight_load_cnt_en = 1'b1;
            access_clr = 1'b1;
        end

        WEIGHT_LOAD_WAIT: begin
            weight_read_en = 1'b1;
            load = 1'b1;
            weight_load_cnt_en = 1'b0;
            access_cnt_en = 1'b1;
        end

        //loading in inputs
        INPUT_LOAD: begin
            input_read_en = 1'b1;
            access_cnt_en = 1'b1;
            input_load_cnt_en = 1'b0;
            next_inf_running_normal = 1'b1;
        end

        INCR_INPUT_LOAD: begin
            input_read_en = 1'b1;
            input_load_cnt_en = 1'b1;
            access_clr = 1'b1;
            next_inf_running_normal = 1'b1;
        end

        INPUT_LOAD_WAIT: begin
            input_read_en = 1'b1;
            //load = 1'b1;
            input_load_cnt_en = 1'b0;
            access_cnt_en = 1'b1;
            next_inf_running_normal = 1'b1;
        end

        //Loading in Outputs

        OUTPUT_LOAD: begin
            output_read_en = 1'b1;
            access_cnt_en = 1'b1;
            output_load_cnt_en = 1'b0;
            //ference = 1'b1;
        end

        INCR_OUTPUT_LOAD: begin
            output_read_en = 1'b1;
            output_load_cnt_en = 1'b1;
            access_clr = 1'b1;
        end

        OUTPUT_LOAD_WAIT: begin
            output_read_en = 1'b1;
            load = 1'b1;
            output_load_cnt_en = 1'b0;
            access_cnt_en = 1'b1;
        end

        //inference signals
        INFERENCE_WAIT: begin
            access_clr = 1'b1;
            // input_clr = 1'b1;
            // input_load_clr = 1'b1;
        end

        // INFERENCE_COMPLETE: begin
        //     inference_complete = 1'b1;
        // end

        default: begin
            {weight_cnt_en, weight_write_en, weight_read_en, weight_load_cnt_en, load} = 5'd0;
            {input_cnt_en, input_write_en, input_read_en, input_load_cnt_en} = 4'd0;
            {access_clr, access_cnt_en, output_read_en} = 3'd0;
            output_load_cnt_en = 1'd0;
            next_inf_running_normal = 1'b0;
        end
    endcase
end


//register modwait directly on Q output of FF
always_comb begin
    next_modwait_n = 1'b1;
    case (next_state)
        IDLE: next_modwait_n = 1'b0;

        default: next_modwait_n = 1'b1;
    endcase
end

always_comb begin
    next_modwait_out = 1'b1;
    case (next_state_out)
        IDLE_OUT: next_modwait_out = 1'b0;

        default: next_modwait_out = 1'b1;
    endcase
end

always_comb begin
    next_modwait = 1'b0;
    if (next_modwait_out | next_modwait_n) begin
        next_modwait = 1'b1;
    end
end

always_comb begin
    inf_running = 1'b0;
    if (next_inf_running_normal | next_inf_running_output) begin
        inf_running = 1'b1;
    end
end


//SRAM 0 & 1 Combinational Logic

always_comb begin
    sram_0_wen = '0;
    sram_0_ren = '0;
    sram_0_write_data = '0;
    sram_0_addr = '0;


    sram_1_wen = '0;
    sram_1_write_data = '0;
    sram_1_addr = '0;
    sram_1_ren = '0;


    if (weight_write_en) begin
        sram_0_wen = 1'b1;
        sram_0_write_data = weight_r[31:0];
        sram_0_addr = {6'd0, weight_cnt_out[3:0]};


        sram_1_wen = 1'b1;
        sram_1_write_data = weight_r[63:32];
        sram_1_addr =  {6'd0, weight_cnt_out[3:0]};

    end else if (weight_read_en) begin
        sram_0_ren = 1'b1;
        sram_0_addr =  {6'd0, weight_load_cnt_out[3:0]};

        sram_1_ren = 1'b1;
        sram_1_addr =  {6'd0, weight_load_cnt_out[3:0]};

    end else if (input_write_en) begin
        sram_0_wen = 1'b1;
        sram_0_write_data = input_r[31:0];
        sram_0_addr = {6'd2, input_cnt_out[3:0]};

        sram_1_wen = 1'b1;
        sram_1_write_data = input_r[63:32];
        sram_1_addr =  {6'd2, input_cnt_out[3:0]};
        
    end else if (input_read_en) begin
        sram_0_ren = 1'b1;
        sram_0_addr =  {6'd2, input_load_cnt_out[3:0]};

        sram_1_ren = 1'b1;
        sram_1_addr =  {6'd2, input_load_cnt_out[3:0]};
    end
    
end


always_comb begin
    inp = {sram_1_read_data, sram_0_read_data};
end


always_comb begin
    sram_state = 2'd1;

    if ((sram_1_state == 2'd2) && (sram_0_state == 2'd2)) begin
        sram_state = 2'd2;
    end else if ((sram_1_state == 2'd0) && (sram_0_state == 2'd0)) begin
        sram_state = 2'd0;
    end else if ((sram_1_state == 2'd3) | (sram_0_state == 2'd3)) begin
        sram_state = 2'd3;
    end
end


//SRAM 2 & 3 Combinational Logic

always_comb begin
    sram_2_wen = '0;
    sram_2_ren = '0;
    sram_2_write_data = '0;
    sram_2_addr = '0;

    sram_3_wen = '0;
    sram_3_write_data = '0;
    sram_3_addr = '0;
    sram_3_ren = '0;

    if (output_write_en) begin
        sram_2_wen = 1'b1;
        sram_2_write_data = out[31:0];
        sram_2_addr = {6'd1, output_cnt_out[3:0]};

        sram_3_wen = 1'b1;
        sram_3_write_data = out[63:32];
        sram_3_addr =  {6'd1, output_cnt_out[3:0]};

    end else if (output_read_en) begin
        sram_2_ren = 1'b1;
        sram_2_addr =  {6'd1, output_load_cnt_out[3:0]};

        sram_3_ren = 1'b1;
        sram_3_addr =  {6'd1, output_load_cnt_out[3:0]};
    end
    
end

always_comb begin
    sram_output = {sram_3_read_data, sram_2_read_data};
end

always_comb begin
    sram_out_state = 2'd1;
    if ((sram_2_state == 2'd2) && (sram_3_state == 2'd2)) begin
        sram_out_state = 2'd2;
    end else if ((sram_2_state == 2'd0) && (sram_3_state == 2'd0)) begin
        sram_out_state = 2'd0;
    end else if ((sram_2_state == 2'd3) | (sram_3_state == 2'd3)) begin
        sram_out_state = 2'd3;
    end
end


always_comb begin
    next_outputs_pending = outputs_pending;
    if (inference_complete) begin
        next_outputs_pending = 1'b1;
    end else if (output_load_rollover) begin
        next_outputs_pending = 1'b0;
    end
end


always_comb begin
    buffer_error = 1'b0;
    if (write_weight & weight_rollover) begin
        buffer_error = 1'b1;
    end

    if (write_input & input_rollover) begin
        buffer_error = 1'b1;
    end
end

logic[7:0] input_load_val;
logic[7:0] output_load_val;

always_comb begin
    input_load_val = input_cnt_out;
    if (input_cnt_out == 8'd0) begin
        input_load_val = 8'd8;
    end
end

always_comb begin
    output_load_val = output_cnt_out;
    if (output_cnt_out == 8'd0) begin
        output_load_val = 8'd8;
    end
end


flex_counter access_inst(.clk(clk), .n_rst(n_rst), .clear(access_clr), .count_enable(access_cnt_en), .rollover_val(8'd2), .count_out(access_cnt_out), .rollover_flag(access_rollover));

flex_counter access_out_inst(.clk(clk), .n_rst(n_rst), .clear(access_out_clr), .count_enable(access_out_cnt_en), .rollover_val(8'd2), .count_out(access_out_cnt_out), .rollover_flag(access_out_rollover));

flex_counter weight_inst(.clk(clk), .n_rst(n_rst), .clear(weight_clr), .count_enable(weight_cnt_en), .rollover_val(8'd8), .count_out(weight_cnt_out), .rollover_flag(weight_rollover));

flex_counter input_inst(.clk(clk), .n_rst(n_rst), .clear(input_clr), .count_enable(input_cnt_en), .rollover_val(8'd8), .count_out(input_cnt_out), .rollover_flag(input_rollover));

flex_counter output_inst(.clk(clk), .n_rst(n_rst), .clear(output_clr), .count_enable(output_cnt_en), .rollover_val(input_load_val), .count_out(output_cnt_out), .rollover_flag(output_rollover));

flex_counter load_weight_inst(.clk(clk), .n_rst(n_rst), .clear(weight_load_clr), .count_enable(weight_load_cnt_en), .rollover_val(8'd8), .count_out(weight_load_cnt_out), .rollover_flag(weights_done));

flex_counter load_input_inst(.clk(clk), .n_rst(n_rst), .clear(input_load_clr), .count_enable(input_load_cnt_en), .rollover_val(input_load_val), .count_out(input_load_cnt_out), .rollover_flag(input_load_rollover));

flex_counter load_output_inst(.clk(clk), .n_rst(n_rst), .clear(output_load_clr), .count_enable(output_load_cnt_en), .rollover_val(output_load_val), .count_out(output_load_cnt_out), .rollover_flag(output_load_rollover));

sram1024x32_wrapper sram_0(.clk(clk), .n_rst(n_rst), .address(sram_0_addr), .read_enable(sram_0_ren), .write_enable(sram_0_wen), .write_data(sram_0_write_data), .read_data(sram_0_read_data), .sram_state(sram_0_state));

sram1024x32_wrapper sram_1(.clk(clk), .n_rst(n_rst), .address(sram_1_addr), .read_enable(sram_1_ren), .write_enable(sram_1_wen), .write_data(sram_1_write_data), .read_data(sram_1_read_data), .sram_state(sram_1_state));

sram1024x32_wrapper sram_2(.clk(clk), .n_rst(n_rst), .address(sram_2_addr), .read_enable(sram_2_ren), .write_enable(sram_2_wen), .write_data(sram_2_write_data), .read_data(sram_2_read_data), .sram_state(sram_2_state));

sram1024x32_wrapper sram_3(.clk(clk), .n_rst(n_rst), .address(sram_3_addr), .read_enable(sram_3_ren), .write_enable(sram_3_wen), .write_data(sram_3_write_data), .read_data(sram_3_read_data), .sram_state(sram_3_state));

endmodule
