`timescale 1ns / 10ps

module flex_counter #(SIZE = 8) (
    input logic clk, n_rst, clear, count_enable,
    input logic [SIZE - 1: 0] rollover_val,
    output logic [SIZE - 1: 0] count_out,
    output logic rollover_flag
);

    logic[SIZE - 1: 0] count_next;
    logic rollover_next;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            count_out <= '0;
            rollover_flag <= 1'b0;
        end else begin
            count_out <= count_next;
            rollover_flag <= rollover_next;
        end
    end

    always_comb begin
        
        count_next = count_out;
        
        if (clear) begin
            count_next = '0;
        end else if ((count_out >= rollover_val) & count_enable) begin
            count_next = {{SIZE - 1{1'b0}}, 1'b1};
         
        end else if (count_enable) begin
            count_next = {{SIZE - 1{1'b0}}, 1'b1} + count_out; //add 1 via concat
        end
        
    end

    always_comb begin
        rollover_next = '0;
        // if (count_next >= rollover_val || count_out >= rollover_val) begin
        if (count_next >= rollover_val) begin
            rollover_next = '1;
        end
    end


endmodule

