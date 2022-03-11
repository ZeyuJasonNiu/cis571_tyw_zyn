/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
// `default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b, cin,
           output wire s, g, p);
    assign g = a & b;
    assign p = a | b;
    assign s = a ^ b ^ cin;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
	assign cout[0] = gin[0] | pin[0] & cin;
	assign cout[1] = gin[1] | pin[1] & gin[0] | pin[1] & pin[0] & cin;
	assign cout[2] = gin[2] | pin[2] & gin[1] | pin[2] & pin[1] & gin[0] | pin[2] & pin[1] & pin[0] & cin;
	assign gout = gin[3] | pin[3] & gin[2] | pin[3] & pin[2] & gin[1] | pin[3] & pin[2] & pin[1] & gin[0];
	assign pout = pin[3] & pin[2] & pin[1] & pin[0];
endmodule


module cla4(input wire [3:0] ain, bin,
			input wire cin,
			output wire [3:0] SO,
			output wire P, G);
	wire [2:0] CI;
	wire [3:0] Pi;
	wire [3:0] Gi;
	
	gp1 g0(.a(ain[0]), .b(bin[0]), .cin(cin), .s(SO[0]), .g(Gi[0]), .p(Pi[0]));
	gp1 g1(.a(ain[1]), .b(bin[1]), .cin(CI[0]), .s(SO[1]), .g(Gi[1]), .p(Pi[1]));
	gp1 g2(.a(ain[2]), .b(bin[2]), .cin(CI[1]), .s(SO[2]), .g(Gi[2]), .p(Pi[2]));
	gp1 g3(.a(ain[3]), .b(bin[3]), .cin(CI[2]), .s(SO[3]), .g(Gi[3]), .p(Pi[3]));

	gp4 gp0(.pin(Pi),.gin(Gi), .cin(cin), .cout(CI), .gout(G), .pout(P));
endmodule


/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16(input wire [15:0]  a, b,
             input wire         cin,
             output wire [15:0] sum);

	wire [3:0]	Gi;
	wire [3:0]	Pi;
	wire [2:0]	CI;
	 
	cla4 c0(.ain(a[3:0]), .bin(b[3:0]), .cin(cin), .SO(sum[3:0]), .G(Gi[0]), .P(Pi[0]));
	cla4 c1(.ain(a[7:4]), .bin(b[7:4]), .cin(CI[0]), .SO(sum[7:4]), .G(Gi[1]), .P(Pi[1]));
	cla4 c2(.ain(a[11:8]), .bin(b[11:8]), .cin(CI[1]), .SO(sum[11:8]), .G(Gi[2]), .P(Pi[2]));
	cla4 c3(.ain(a[15:12]), .bin(b[15:12]), .cin(CI[2]), .SO(sum[15:12]), .G(Gi[3]), .P(Pi[3]));
	 
	gp4 gp1(.pin(Pi), .gin(Gi), .cin(cin), .cout(CI));
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
	#(parameter N = 4)
	(input wire [N-1:0] gin, pin,
   	 input wire  cin,
     output wire gout, pout,
     output wire [N-2:0] cout);
	wire [N-2:0] G, P;
	assign cout[0] = gin[0] | pin[0] & cin;
	assign G[0] = gin[0];
	assign P[0] = pin[0];

	genvar i;
	for(i = 1; i < N - 1; i = i + 1) begin
		assign cout[i] = gin[i] | pin[i] & cout[i-1];
		assign P[i] = P[i-1] & pin[i];
		assign G[i] = gin[i] | pin[i] & G[i-1];
	end

	assign pout = P[N-2] & pin[N-1];
	assign gout = gin[N-1] | pin[N-1] & G[N-2];

endmodule
