/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
//`default_nettype none

module comparator (input wire [15:0] zero,
                   input wire [15:0] i_divisor,
                   output wire Out);
      assign Out = (i_divisor == zero)?  1 : 0;
endmodule

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);
      // Student Code Start //
      wire [15:0] i_remainder;
      wire [15:0] i_quotient;
      wire [15:0] quotient_judge;
      wire [15:0] remainder_judge;
      assign i_remainder = 16'b0;
      assign i_quotient = 16'b0;

      wire [15:0] dividend_01;      wire [15:0] remainder_01;     wire [15:0] quotient_01;
      wire [15:0] dividend_12;      wire [15:0] remainder_12;     wire [15:0] quotient_12;     
      wire [15:0] dividend_23;      wire [15:0] remainder_23;     wire [15:0] quotient_23;
      wire [15:0] dividend_34;      wire [15:0] remainder_34;     wire [15:0] quotient_34;
      wire [15:0] dividend_45;      wire [15:0] remainder_45;     wire [15:0] quotient_45;
      wire [15:0] dividend_56;      wire [15:0] remainder_56;     wire [15:0] quotient_56;
      wire [15:0] dividend_67;      wire [15:0] remainder_67;     wire [15:0] quotient_67;
      wire [15:0] dividend_78;      wire [15:0] remainder_78;     wire [15:0] quotient_78;
      wire [15:0] dividend_89;      wire [15:0] remainder_89;     wire [15:0] quotient_89;
      wire [15:0] dividend_910;     wire [15:0] remainder_910;    wire [15:0] quotient_910;
      wire [15:0] dividend_1011;    wire [15:0] remainder_1011;   wire [15:0] quotient_1011;
      wire [15:0] dividend_1112;    wire [15:0] remainder_1112;   wire [15:0] quotient_1112;
      wire [15:0] dividend_1213;    wire [15:0] remainder_1213;   wire [15:0] quotient_1213;
      wire [15:0] dividend_1314;    wire [15:0] remainder_1314;   wire [15:0] quotient_1314;
      wire [15:0] dividend_1415;    wire [15:0] remainder_1415;   wire [15:0] quotient_1415;

      //wire mux_tmp;

      lc4_divider_one_iter iter0(.i_dividend(i_dividend), .i_divisor(i_divisor), .i_remainder(i_remainder), .i_quotient(i_quotient), 
      .o_dividend(dividend_01), .o_remainder(remainder_01), .o_quotient(quotient_01));

      lc4_divider_one_iter iter1(.i_dividend(dividend_01), .i_divisor(i_divisor), .i_remainder(remainder_01), .i_quotient(quotient_01), 
      .o_dividend(dividend_12), .o_remainder(remainder_12), .o_quotient(quotient_12));

      lc4_divider_one_iter iter2(.i_dividend(dividend_12), .i_divisor(i_divisor), .i_remainder(remainder_12), .i_quotient(quotient_12), 
      .o_dividend(dividend_23), .o_remainder(remainder_23), .o_quotient(quotient_23));

      lc4_divider_one_iter iter3(.i_dividend(dividend_23), .i_divisor(i_divisor), .i_remainder(remainder_23), .i_quotient(quotient_23), 
      .o_dividend(dividend_34), .o_remainder(remainder_34), .o_quotient(quotient_34));

      lc4_divider_one_iter iter4(.i_dividend(dividend_34), .i_divisor(i_divisor), .i_remainder(remainder_34), .i_quotient(quotient_34), 
      .o_dividend(dividend_45), .o_remainder(remainder_45), .o_quotient(quotient_45));

      lc4_divider_one_iter iter5(.i_dividend(dividend_45), .i_divisor(i_divisor), .i_remainder(remainder_45), .i_quotient(quotient_45), 
      .o_dividend(dividend_56), .o_remainder(remainder_56), .o_quotient(quotient_56));

      lc4_divider_one_iter iter6(.i_dividend(dividend_56), .i_divisor(i_divisor), .i_remainder(remainder_56), .i_quotient(quotient_56), 
      .o_dividend(dividend_67), .o_remainder(remainder_67), .o_quotient(quotient_67));

      lc4_divider_one_iter iter7(.i_dividend(dividend_67), .i_divisor(i_divisor), .i_remainder(remainder_67), .i_quotient(quotient_67), 
      .o_dividend(dividend_78), .o_remainder(remainder_78), .o_quotient(quotient_78));

      lc4_divider_one_iter iter8(.i_dividend(dividend_78), .i_divisor(i_divisor), .i_remainder(remainder_78), .i_quotient(quotient_78), 
      .o_dividend(dividend_89), .o_remainder(remainder_89), .o_quotient(quotient_89));

      lc4_divider_one_iter iter9(.i_dividend(dividend_89), .i_divisor(i_divisor), .i_remainder(remainder_89), .i_quotient(quotient_89), 
      .o_dividend(dividend_910), .o_remainder(remainder_910), .o_quotient(quotient_910));

      lc4_divider_one_iter iter10(.i_dividend(dividend_910), .i_divisor(i_divisor), .i_remainder(remainder_910), .i_quotient(quotient_910), 
      .o_dividend(dividend_1011), .o_remainder(remainder_1011), .o_quotient(quotient_1011));

      lc4_divider_one_iter iter11(.i_dividend(dividend_1011), .i_divisor(i_divisor), .i_remainder(remainder_1011), .i_quotient(quotient_1011), 
      .o_dividend(dividend_1112), .o_remainder(remainder_1112), .o_quotient(quotient_1112));

      lc4_divider_one_iter iter12(.i_dividend(dividend_1112), .i_divisor(i_divisor), .i_remainder(remainder_1112), .i_quotient(quotient_1112), 
      .o_dividend(dividend_1213), .o_remainder(remainder_1213), .o_quotient(quotient_1213));

      lc4_divider_one_iter iter13(.i_dividend(dividend_1213), .i_divisor(i_divisor), .i_remainder(remainder_1213), .i_quotient(quotient_1213), 
      .o_dividend(dividend_1314), .o_remainder(remainder_1314), .o_quotient(quotient_1314));

      lc4_divider_one_iter iter14(.i_dividend(dividend_1314), .i_divisor(i_divisor), .i_remainder(remainder_1314), .i_quotient(quotient_1314), 
      .o_dividend(dividend_1415), .o_remainder(remainder_1415), .o_quotient(quotient_1415));
        
      lc4_divider_one_iter final_iter(.i_dividend(dividend_1415), .i_divisor(i_divisor), .i_remainder(remainder_1415), 
      .i_quotient(quotient_1415), .o_dividend(), .o_remainder(remainder_judge), .o_quotient(quotient_judge));

      assign o_remainder = (i_divisor == 0) ? 16'b0 : remainder_judge;
      assign o_quotient = (i_divisor == 0) ? 16'b0 : quotient_judge;
      // student Code end //
endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);
      
      wire [15:0] tmp_remainder;
      
      assign tmp_remainder = (i_remainder << 1) | ((i_dividend >> 15) & 16'b1);
      assign o_dividend = i_dividend << 1;
      assign o_remainder =  (tmp_remainder < i_divisor) ? tmp_remainder : (tmp_remainder - i_divisor); 
      assign o_quotient = (tmp_remainder < i_divisor) ? (i_quotient << 1) : ((i_quotient << 1)|16'b1);
endmodule
