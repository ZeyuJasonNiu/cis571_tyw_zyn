/* TODO: name and PennKeys of all group members here
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps
// Prevent implicit wire declaration
`default_nettype none


module Mux8to1(
    input wire [15:0] rv0, rv1, rv2, rv3, rv4, rv5, rv6, rv7,
    input wire [2:0] sel,
    output wire [15:0] o_data);

    assign o_data = (sel == 3'd0) ? rv0 :
                    (sel == 3'd1) ? rv1 :
                    (sel == 3'd2) ? rv2 :
                    (sel == 3'd3) ? rv3 :
                    (sel == 3'd4) ? rv4 :
                    (sel == 3'd5) ? rv5 :
                    (sel == 3'd6) ? rv6 :
                    rv7;
endmodule

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,       // global write enable
    input  wire         rst,       // restart
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

   /***********************
    * TODO YOUR CODE HERE *
    ***********************/
    wire [15:0] rv0, rv1, rv2, rv3, rv4, rv5, rv6, rv7;
    
    Nbit_reg #(n) r0 (.in(i_wdata), .out(rv0), .clk(clk), .we((i_rd == 3'd0) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r1 (.in(i_wdata), .out(rv1), .clk(clk), .we((i_rd == 3'd1) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r2 (.in(i_wdata), .out(rv2), .clk(clk), .we((i_rd == 3'd2) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r3 (.in(i_wdata), .out(rv3), .clk(clk), .we((i_rd == 3'd3) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r4 (.in(i_wdata), .out(rv4), .clk(clk), .we((i_rd == 3'd4) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r5 (.in(i_wdata), .out(rv5), .clk(clk), .we((i_rd == 3'd5) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r6 (.in(i_wdata), .out(rv6), .clk(clk), .we((i_rd == 3'd6) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(n) r7 (.in(i_wdata), .out(rv7), .clk(clk), .we((i_rd == 3'd7) & i_rd_we), .gwe(gwe), .rst(rst));

    Mux8to1 mux_rs(.sel(i_rs), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rs_data));
    Mux8to1 mux_rt(.sel(i_rt), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rt_data));
endmodule