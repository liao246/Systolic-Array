`timescale 1ns / 10ps

module float_adder #(
    // parameters
) (
    input logic [15:0] a, b,
    output logic [15:0] sum
); 
    
    logic is_posinf, is_neginf, is_NaN;
    logic [15:0] nan_out;
    always_comb begin
        is_posinf = 0;
        is_neginf = 0;
        is_NaN = 0;
        nan_out = 0;
        if((a[15] == b[15]) && (a[14:0] == 15'h7C00) && (b[14:0] == 15'h7C00)) begin
            if(a[15]) begin
                is_neginf = 1'b1;
            end
            else begin
                is_posinf = 1'b1;
            end
        end
        else if((a[14:0] == 15'h7C00 && b[14:0] < 15'h7C00) || (b[14:0] == 15'h7C00 && a[14:0] < 15'h7C00)) begin
            is_neginf = a[14:0] == 15'h7C00 ? a[15] : b[15];
            is_posinf = a[14:0] == 15'h7C00 ? ~a[15] : ~b[15];
        end
        else if((a[15] != b[15]) && (a[14:0] == 15'h7C00) && (b[14:0] == 15'h7C00)) begin
            is_NaN = 1'b1;
        end
        else if(a[14:0] > 15'h7C00 || b[14:0] > 15'h7C00) begin
            is_NaN = 1'b1;
            nan_out = a[14:0] > 15'h7C00 ? a : b;
        end
    end



    logic [44:0] intm_acc;
    logic [4:0] exp_diff;
    logic [42:0] shifted_inp;
    logic [4:0] exp_out;
    
    always_comb begin
        if(a[14:10] > b[14:10]) begin
            exp_out = a[14:10];
            exp_diff = a[14:10] - b[14:10];
            shifted_inp = {1'b1, b[9:0], 32'b0} >> exp_diff;
            case({a[15], b[15]}) 
                2'b00: intm_acc = {2'b0, 1'b1, a[9:0], 32'b0} + {2'b0, shifted_inp};
                2'b01: intm_acc = {2'b0, 1'b1, a[9:0], 32'b0} - {2'b0, shifted_inp};
                2'b10: intm_acc = {2'b0, shifted_inp} - {2'b0, 1'b1, a[9:0], 32'b0};
                2'b11: intm_acc = 45'b0 - {2'b0, 1'b1, a[9:0], 32'b0} - {2'b0, shifted_inp};
            endcase
        end
        else begin
            exp_out = b[14:10];
            exp_diff = b[14:10] - a[14:10];
            shifted_inp = {1'b1, a[9:0], 32'b0} >> exp_diff;
            case({a[15], b[15]}) 
                2'b00: intm_acc = {2'b0, 1'b1, b[9:0], 32'b0} + {2'b0, shifted_inp};
                2'b01: intm_acc = {2'b0, shifted_inp} - {2'b0, 1'b1, b[9:0], 32'b0};
                2'b10: intm_acc = {2'b0, 1'b1, b[9:0], 32'b0} - {2'b0, shifted_inp};
                2'b11: intm_acc = 45'b0 - {2'b0, 1'b1, b[9:0], 32'b0} - {2'b0, shifted_inp};
            endcase
        end
    end



    logic [44:0] uint;
    logic [4:0] leading_zeroes;
    logic [9:0] mantissa;
    logic [5:0] exp;
    logic [44:0] temp;
    logic sign;
    logic[10:0] rounded_mantissa;
    
    always_comb begin
        rounded_mantissa = '0;
        uint = 45'b0;
        temp = 45'b0;
        leading_zeroes = 5'b0;
        if(intm_acc[44]) begin
            uint = ~intm_acc + 45'h000000000001;
            if(uint[43]) begin
                rounded_mantissa = {1'b0, uint[42:33]} + 11'h001;
                if(uint[32] && (|uint[31:0] || uint[33])) begin
                    if(rounded_mantissa[10]) begin
                        exp = {1'b0, exp_out} + 6'h02;
                        mantissa = rounded_mantissa[9:0];
                    end
                    else begin
                        exp = {1'b0, exp_out} + 6'h01;
                        mantissa = rounded_mantissa[9:0];
                    end
                end
                else begin
                    exp = {1'b0, exp_out} + 6'h01;
                    mantissa = uint[42:33];
                end
                sign = 1'b1;
            end
            else begin
                casez(uint[42:12])
                    31'b1??????????????????????????????: leading_zeroes = 5'h0;
                    31'b01?????????????????????????????: leading_zeroes = 5'h01;
                    31'b001????????????????????????????: leading_zeroes = 5'h02;
                    31'b0001???????????????????????????: leading_zeroes = 5'h03;
                    31'b00001??????????????????????????: leading_zeroes = 5'h04;
                    31'b000001?????????????????????????: leading_zeroes = 5'h05;
                    31'b0000001????????????????????????: leading_zeroes = 5'h06;
                    31'b00000001???????????????????????: leading_zeroes = 5'h07;
                    31'b000000001??????????????????????: leading_zeroes = 5'h08;
                    31'b0000000001?????????????????????: leading_zeroes = 5'h09;
                    31'b00000000001????????????????????: leading_zeroes = 5'h0a;
                    31'b000000000001???????????????????: leading_zeroes = 5'h0b;
                    31'b0000000000001??????????????????: leading_zeroes = 5'h0c;
                    31'b00000000000001?????????????????: leading_zeroes = 5'h0d;
                    31'b000000000000001????????????????: leading_zeroes = 5'h0e;
                    31'b0000000000000001???????????????: leading_zeroes = 5'h0f;
                    31'b00000000000000001??????????????: leading_zeroes = 5'h10;
                    31'b000000000000000001?????????????: leading_zeroes = 5'h11;
                    31'b0000000000000000001????????????: leading_zeroes = 5'h12;
                    31'b00000000000000000001???????????: leading_zeroes = 5'h13;
                    31'b000000000000000000001??????????: leading_zeroes = 5'h14;
                    31'b0000000000000000000001?????????: leading_zeroes = 5'h15;
                    31'b00000000000000000000001????????: leading_zeroes = 5'h16;
                    31'b000000000000000000000001???????: leading_zeroes = 5'h17;
                    31'b0000000000000000000000001??????: leading_zeroes = 5'h18;
                    31'b00000000000000000000000001?????: leading_zeroes = 5'h19;
                    31'b000000000000000000000000001????: leading_zeroes = 5'h1a;
                    31'b0000000000000000000000000001???: leading_zeroes = 5'h1b;
                    31'b00000000000000000000000000001??: leading_zeroes = 5'h1c;
                    31'b000000000000000000000000000001?: leading_zeroes = 5'h1d;
                    31'b0000000000000000000000000000001: leading_zeroes = 5'h1e;
                    default: leading_zeroes = 5'h1F;
                endcase
                if(leading_zeroes == 5'h1F || leading_zeroes > exp_out) begin
                    exp = |exp_diff ? exp_out : 6'b0;
                    mantissa = 10'b0;
                    sign = 1'b1;
                end
                else begin
                    temp = uint << (leading_zeroes + 5'h01);
                    rounded_mantissa = {1'b0, temp[42:33]} + 11'h001;
                    if(temp[32] && (|temp[31:0] || temp[33])) begin
                        if(rounded_mantissa[10]) begin
                            exp = {1'b0, exp_out} + 6'h01 - {1'b0, leading_zeroes};
                            mantissa = rounded_mantissa[9:0];
                        end
                        else begin
                            exp = {1'b0, exp_out} - {1'b0, leading_zeroes};
                            mantissa = rounded_mantissa[9:0];
                        end
                    end
                    else begin
                        exp = {1'b0, exp_out} - {1'b0, leading_zeroes};
                        mantissa = temp[42:33];
                    end

                    sign = 1'b1;
                    
                end
            end
        end
        else begin
            if(intm_acc[43]) begin
                rounded_mantissa = {1'b0, intm_acc[42:33]} + 11'h001;
                if(intm_acc[32] && (|intm_acc[31:0] || intm_acc[33])) begin
                    if(rounded_mantissa[10]) begin
                        exp = {1'b0, exp_out} + 6'h02;
                        mantissa = rounded_mantissa[9:0];
                    end
                    else begin
                        exp = {1'b0, exp_out} + 6'h01;
                        mantissa = rounded_mantissa[9:0];
                    end
                end
                else begin
                    exp = {1'b0, exp_out} + 6'h01;
                    mantissa = intm_acc[42:33];
                end
                sign = 1'b0;
            end
            else begin
                casez(intm_acc[42:12])
                    31'b1??????????????????????????????: leading_zeroes = 5'h0;
                    31'b01?????????????????????????????: leading_zeroes = 5'h01;
                    31'b001????????????????????????????: leading_zeroes = 5'h02;
                    31'b0001???????????????????????????: leading_zeroes = 5'h03;
                    31'b00001??????????????????????????: leading_zeroes = 5'h04;
                    31'b000001?????????????????????????: leading_zeroes = 5'h05;
                    31'b0000001????????????????????????: leading_zeroes = 5'h06;
                    31'b00000001???????????????????????: leading_zeroes = 5'h07;
                    31'b000000001??????????????????????: leading_zeroes = 5'h08;
                    31'b0000000001?????????????????????: leading_zeroes = 5'h09;
                    31'b00000000001????????????????????: leading_zeroes = 5'h0a;
                    31'b000000000001???????????????????: leading_zeroes = 5'h0b;
                    31'b0000000000001??????????????????: leading_zeroes = 5'h0c;
                    31'b00000000000001?????????????????: leading_zeroes = 5'h0d;
                    31'b000000000000001????????????????: leading_zeroes = 5'h0e;
                    31'b0000000000000001???????????????: leading_zeroes = 5'h0f;
                    31'b00000000000000001??????????????: leading_zeroes = 5'h10;
                    31'b000000000000000001?????????????: leading_zeroes = 5'h11;
                    31'b0000000000000000001????????????: leading_zeroes = 5'h12;
                    31'b00000000000000000001???????????: leading_zeroes = 5'h13;
                    31'b000000000000000000001??????????: leading_zeroes = 5'h14;
                    31'b0000000000000000000001?????????: leading_zeroes = 5'h15;
                    31'b00000000000000000000001????????: leading_zeroes = 5'h16;
                    31'b000000000000000000000001???????: leading_zeroes = 5'h17;
                    31'b0000000000000000000000001??????: leading_zeroes = 5'h18;
                    31'b00000000000000000000000001?????: leading_zeroes = 5'h19;
                    31'b000000000000000000000000001????: leading_zeroes = 5'h1a;
                    31'b0000000000000000000000000001???: leading_zeroes = 5'h1b;
                    31'b00000000000000000000000000001??: leading_zeroes = 5'h1c;
                    31'b000000000000000000000000000001?: leading_zeroes = 5'h1d;
                    31'b0000000000000000000000000000001: leading_zeroes = 5'h1e;
                    default: leading_zeroes = 5'h1F;
                endcase
                if(leading_zeroes == 5'h1F || leading_zeroes > exp_out) begin
                    exp = |exp_diff ? exp_out : 6'b0;
                    mantissa = 10'b0;
                    sign = 1'b0;
                end
                else begin
                    
                    temp = intm_acc << (leading_zeroes + 5'h01);

                    rounded_mantissa = {1'b0, temp[42:33]} + 11'h001;
                    if(temp[32] && (|temp[31:0] || temp[33])) begin
                        if(rounded_mantissa[10]) begin
                            exp = {1'b0, exp_out} + 6'h01 - {1'b0, leading_zeroes};
                            mantissa = rounded_mantissa[9:0];
                        end
                        else begin
                            exp = {1'b0, exp_out} - {1'b0, leading_zeroes};
                            mantissa = rounded_mantissa[9:0];
                        end
                    end
                    else begin
                        exp = {1'b0, exp_out} - {1'b0, leading_zeroes};
                        mantissa = temp[42:33];
                    end
                    sign = 1'b0;
                end
            end
        end
    end


    always_comb begin
        if(is_posinf || is_neginf) begin
            sum = {is_neginf, 5'h1F, 10'b0};
        end
        else if(is_NaN) begin
            sum = nan_out == 0 ? {1'b0, 5'h1F, 10'h200} : nan_out;
        end
        else begin
            if(exp > 6'h1E) begin
                sum = {sign, 5'h1F, 10'b0};
            end
            else begin
                sum = {sign, exp[4:0], mantissa};
            end
        end
    end



endmodule

