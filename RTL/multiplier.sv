`timescale 1ns / 10ps

module multiplier #(
    // parameters
) (
    input logic [15:0] a, b,
    output logic [15:0] out
);
    logic [5:0] exp;
    logic [10:0] am, bm;
    logic sign;
    logic is_neginf, is_posinf, is_poszero, is_negzero, is_NaN;
    logic [15:0] nan_prop;
    always_comb begin
        nan_prop = 16'b0;
        is_neginf = 1'b0;
        is_posinf = 1'b0;
        is_NaN = 1'b0;
        is_poszero = 1'b0;
        is_negzero = 1'b0;
        am = {1'b1, a[9:0]};
        bm = {1'b1, b[9:0]};
        sign = a[15] ^ b[15];
        exp = ({1'b0, a[14:10]} - 6'hF) + {1'b0, b[14:10]};
        if(a[14:0] > 15'h7C00 || b[14:0] > 15'h7C00) begin
            is_NaN = 1'b1;
            nan_prop = a[14:0] > 15'h7C00 ? a : b;
        end 
        else if(a[14:0] == 15'b0 && b[14:0] == 15'h7C00) begin
            is_NaN = 1'b1;
        end
        else if(b[14:0] == 15'b0 && a[14:0] == 15'h7C00) begin
            is_NaN = 1'b1;
        end
        else if(b[14:0] == 15'h7C00 || a[14:0] == 15'h7C00) begin
            is_neginf = b[15] ^ a[15];
            is_posinf = b[15] ~^ a[15];
        end
        else if(b[14:0] == 0 || a[14:0] == 0) begin
            is_negzero = b[15] ^ a[15];
            is_poszero = b[15] ~^ a[15];
        end
    end  


    logic[21:0] result;
    logic[21:0] temp;
    logic[4:0] leading_zeroes;
    logic[10:0] rounded_mantissa;

    assign result = {11'b0, bm} * {11'b0, am};

    logic [5:0] exp_add;
    always_comb begin
        rounded_mantissa = 0;
        leading_zeroes = 0;
        temp = 0;
        exp_add = 0;
        if(is_NaN) begin
            out = |nan_prop ? nan_prop : {1'b0, 5'h1F, 10'h200};
        end
        else if(is_posinf || is_neginf) begin
            out = {is_neginf, 5'h1F, 10'b0};
        end
        else if(is_poszero || is_negzero) begin
            out = {is_negzero, 5'h0, 10'b0};
        end
        else begin
            if((exp > 6'h1E) || (result[21] && ((exp + 6'h01) > 6'h1E))) begin
                out = {sign, 5'h1F, 10'b0};
            end
            else begin
                if(result[21] == 1'b1) begin
                    exp_add = exp + 6'h01;
                    if(exp_add[5]) begin
                        out = {sign, 5'h1F, 10'b0};
                    end
                    else begin
                        rounded_mantissa = {1'b0, result[20:11]} + 11'h001;
                        if(result[10] && (|result[9:0] || result[11])) begin
                            if(rounded_mantissa[10]) begin
                                exp_add = exp - {1'b0, leading_zeroes} + 6'h02;
                                if(exp_add[5]) begin
                                    out = {sign, 5'h1F, 10'b0};
                                end
                                else begin
                                    out = {sign, exp_add[4:0], rounded_mantissa[9:0]};
                                end
                            end
                            else begin
                                exp_add = exp - {1'b0, leading_zeroes} + 6'h01;
                                out = {sign, exp_add[4:0], rounded_mantissa[9:0]};
                            end
                        end
                        else begin
                            exp_add = exp - {1'b0, leading_zeroes} + 6'h01;
                            out = {sign, exp_add[4:0], result[20:11]};
                        end
                    end
                end
                else begin
                    casez(result[20:0]) 
                        21'b1????????????????????: leading_zeroes = 5'h0;
                        21'b01???????????????????: leading_zeroes = 5'h01;
                        21'b001??????????????????: leading_zeroes = 5'h02;
                        21'b0001?????????????????: leading_zeroes = 5'h03;
                        21'b00001????????????????: leading_zeroes = 5'h04;
                        21'b000001???????????????: leading_zeroes = 5'h05;
                        21'b0000001??????????????: leading_zeroes = 5'h06;
                        21'b00000001?????????????: leading_zeroes = 5'h07;
                        21'b000000001????????????: leading_zeroes = 5'h08;
                        21'b0000000001???????????: leading_zeroes = 5'h09;
                        21'b00000000001??????????: leading_zeroes = 5'h0a;
                        21'b000000000001?????????: leading_zeroes = 5'h0b;
                        21'b0000000000001????????: leading_zeroes = 5'h0c;
                        21'b00000000000001???????: leading_zeroes = 5'h0d;
                        21'b000000000000001??????: leading_zeroes = 5'h0e;
                        21'b0000000000000001?????: leading_zeroes = 5'h0f;
                        21'b00000000000000001????: leading_zeroes = 5'h10;
                        21'b000000000000000001???: leading_zeroes = 5'h11;
                        21'b0000000000000000001??: leading_zeroes = 5'h12;
                        21'b00000000000000000001?: leading_zeroes = 5'h13;
                        21'b000000000000000000001: leading_zeroes = 5'h14;
                        default: leading_zeroes = 5'h1F;
                    endcase
                    if({1'b0, leading_zeroes} > exp) begin
                        out = {sign, 15'b0};
                    end
                    else begin
                        temp = result << {leading_zeroes + 5'h01};
                        rounded_mantissa = {1'b0, temp[20:11]} + 11'h001;
                        if(temp[10] && (|temp[9:0] || temp[11])) begin
                            if(rounded_mantissa[10]) begin
                                exp_add = exp - {1'b0, leading_zeroes} + 6'h01;
                                if(exp_add[5]) begin
                                    out = {sign, 5'h1F, 10'b0};
                                end
                                else begin
                                    out = {sign, exp_add[4:0], rounded_mantissa[9:0]};
                                end
                            end
                            else begin
                                exp_add = exp - {1'b0, leading_zeroes};
                                out = {sign, exp_add[4:0], rounded_mantissa[9:0]};
                            end
                        end
                        else begin
                            exp_add = exp - {1'b0, leading_zeroes};
                            out = {sign, exp_add[4:0], temp[20:11]};
                        end
                    end
                end
            end
        end
    end


endmodule

