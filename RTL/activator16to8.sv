`timescale 1ns / 10ps

module activator16to8 #(
    // parameters
) (
    input logic [1:0] activ_ctrl,
    input logic [15:0] in,
    output logic [7:0] out
);
    logic [15:0] int_out;
    always_comb begin
        if(in[14:10] == 5'h1F && in[9:0] != 10'b0) begin
            int_out = in;
        end
        else begin
            case(activ_ctrl)
                2'b00: int_out = in[15] ? 16'b0 : in;
                2'b01: int_out = (in[15] || !(|in[14:0])) ? 16'b0 : 16'h3C00;
                2'b10: int_out = in;
                2'b11: int_out = in[15] ? {in[15], (in[14:10] > 5'h02) ? in[14:10] - 5'h02 : 5'b0, (in[14:10] > 5'h02) ? in[9:0] : 10'b0} : in;
            endcase
        end
    end     


    logic [3:0] fin_exp;
    logic [3:0] fin_mant;
    logic is_inf;
    always_comb begin
        is_inf = 0;
        fin_exp = 0;
        fin_mant = 0;
        if(in[14:10] == 5'h1F && in[9:0] != 10'b0) begin
            out = {int_out[15], 7'h7F};
        end
        else begin
            if(int_out[14:10] > 5'h16) begin
                out = {int_out[15], 4'hF, 3'b0};
                is_inf = 1'b1;
            end
            else if(int_out[14:10] < 5'h08) begin
                out = {int_out[15], 7'b0};
            end
            else begin
                fin_exp = int_out[14:10] - 5'h08;
                if(int_out[6]) begin
                    if(int_out[5:0] == 6'b0 && ~int_out[7]) begin
                        fin_mant = {1'b0, int_out[9:7]};
                    end 
                    else begin	
                        fin_mant = {1'b0, int_out[9:7]} + 4'b01;
                        if(fin_mant[3]) begin
                            if(int_out[14:10] - 5'h08 == 5'h0E) begin
                                is_inf = 1'b1;
                            end else begin
                                fin_exp = int_out[14:10] - 5'h07;
                            end
                        end
                    end
                end else begin
                    fin_mant = {1'b0, int_out[9:7]};
                end
                if(is_inf) begin
                    out = {int_out[15], 4'hF, 3'b0};
                end else begin
                    out = {int_out[15], fin_exp, fin_mant[2:0]};
                end
            end
        end
    end


endmodule

