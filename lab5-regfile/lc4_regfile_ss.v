`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */

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


module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/

    wire [15:0] rv0, rv1, rv2, rv3, rv4, rv5, rv6, rv7;
    wire [31:0] i_data;
    wire [16:0] i_data_r0, i_data_r1, i_data_r2, i_data_r3,
                i_data_r4, i_data_r5, i_data_r6, i_data_r7;
    wire [15:0] o_rs_A, o_rs_B, o_rt_A, o_rt_B;
    wire        we0, we1, we2, we3, we4, we5, we6, we7;
    wire        we_A;

    //Only write pipe_B for if PipeA and PipeB has same Rd values
    assign we_A = ((i_rd_A == i_rd_B) & i_rd_we_B) ? 1'b0 : i_rd_we_A;        

    // Choose which pipe to write
    assign i_data_r0 = (i_rd_A == 3'd0 & we_A) ? i_wdata_A : (i_rd_B == 3'd0 & i_rd_we_B) ? i_wdata_B : 16'b0; 
    assign i_data_r1 = (i_rd_A == 3'd1 & we_A) ? i_wdata_A : (i_rd_B == 3'd1 & i_rd_we_B) ? i_wdata_B : 16'b0;
    assign i_data_r2 = (i_rd_A == 3'd2 & we_A) ? i_wdata_A : (i_rd_B == 3'd2 & i_rd_we_B) ? i_wdata_B : 16'b0;
    assign i_data_r3 = (i_rd_A == 3'd3 & we_A) ? i_wdata_A : (i_rd_B == 3'd3 & i_rd_we_B) ? i_wdata_B : 16'b0;
    assign i_data_r4 = (i_rd_A == 3'd4 & we_A) ? i_wdata_A : (i_rd_B == 3'd4 & i_rd_we_B) ? i_wdata_B : 16'b0;
    assign i_data_r5 = (i_rd_A == 3'd5 & we_A) ? i_wdata_A : (i_rd_B == 3'd5 & i_rd_we_B) ? i_wdata_B : 16'b0;
    assign i_data_r6 = (i_rd_A == 3'd6 & we_A) ? i_wdata_A : (i_rd_B == 3'd6 & i_rd_we_B) ? i_wdata_B : 16'b0;
    assign i_data_r7 = (i_rd_A == 3'd7 & we_A) ? i_wdata_A : (i_rd_B == 3'd7 & i_rd_we_B) ? i_wdata_B : 16'b0;

    // Write enable setting
    assign we0 = ( ((i_rd_A == 3'd0) & we_A) || (i_rd_B == 3'd0)) ? 1'b1 : 1'b0;
    assign we1 = ( ((i_rd_A == 3'd1) & we_A) || (i_rd_B == 3'd1)) ? 1'b1 : 1'b0;
    assign we2 = ( ((i_rd_A == 3'd2) & we_A) || (i_rd_B == 3'd2)) ? 1'b1 : 1'b0;
    assign we3 = ( ((i_rd_A == 3'd3) & we_A) || (i_rd_B == 3'd3)) ? 1'b1 : 1'b0;
    assign we4 = ( ((i_rd_A == 3'd4) & we_A) || (i_rd_B == 3'd4)) ? 1'b1 : 1'b0;
    assign we5 = ( ((i_rd_A == 3'd5) & we_A) || (i_rd_B == 3'd5)) ? 1'b1 : 1'b0;
    assign we6 = ( ((i_rd_A == 3'd6) & we_A) || (i_rd_B == 3'd6)) ? 1'b1 : 1'b0;
    assign we7 = ( ((i_rd_A == 3'd7) & we_A) || (i_rd_B == 3'd7)) ? 1'b1 : 1'b0;

    // Registers to hold values
    Nbit_reg #(n,16'b0) r0 (.in(i_data_r0), .out(rv0), .clk(clk), .we(we0), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r1 (.in(i_data_r1), .out(rv1), .clk(clk), .we(we1), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r2 (.in(i_data_r2), .out(rv2), .clk(clk), .we(we2), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r3 (.in(i_data_r3), .out(rv3), .clk(clk), .we(we3), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r4 (.in(i_data_r4), .out(rv4), .clk(clk), .we(we4), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r5 (.in(i_data_r5), .out(rv5), .clk(clk), .we(we5), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r6 (.in(i_data_r6), .out(rv6), .clk(clk), .we(we6), .gwe(gwe), .rst(rst));
    Nbit_reg #(n,16'b0) r7 (.in(i_data_r7), .out(rv7), .clk(clk), .we(we7), .gwe(gwe), .rst(rst));

    // MUX for output value selection
    Mux8to1 mux_rs_A(.sel(i_rs_A), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), 
    .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rs_A));
    Mux8to1 mux_rt_A(.sel(i_rt_A), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), 
    .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rt_A));
    Mux8to1 mux_rs_B(.sel(i_rs_B), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), 
    .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rs_B));
    Mux8to1 mux_rt_B(.sel(i_rt_B), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), 
    .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rt_B));  

    //Bypass write-in value to output
    assign o_rs_data_A =    ((i_rs_A == i_rd_A) & we_A) ? i_wdata_A : 
                            ((i_rs_A == i_rd_B) & i_rd_we_B) ? i_wdata_B : o_rs_A;

    assign o_rt_data_A =    ((i_rt_A == i_rd_A) & we_A) ? i_wdata_A : 
                            ((i_rt_A == i_rd_B) & i_rd_we_B) ? i_wdata_B : o_rt_A;

    assign o_rs_data_B =    ((i_rs_B == i_rd_B) & i_rd_we_B) ? i_wdata_B : 
                            ((i_rs_B == i_rd_A) & i_rd_we_A) ? i_wdata_A : o_rs_B;

    assign o_rt_data_B =    ((i_rt_B == i_rd_B) & i_rd_we_B) ? i_wdata_B :
                            ((i_rt_B == i_rd_A) & i_rd_we_A) ? i_wdata_A : o_rt_B;

endmodule



// module lc4_regfile #(parameter n = 16)
//    (input  wire         clk,
//     input  wire         gwe,       // global write enable
//     input  wire         rst,       // restart
//     input  wire [  2:0] i_rs,      // rs selector
//     output wire [n-1:0] o_rs_data, // rs contents
//     input  wire [  2:0] i_rt,      // rt selector
//     output wire [n-1:0] o_rt_data, // rt contents
//     input  wire [  2:0] i_rd,      // rd selector
//     input  wire [n-1:0] i_wdata,   // data to write
//     input  wire         i_rd_we    // write enable
//     );

//    /***********************
//     * TODO YOUR CODE HERE *
//     ***********************/
//     wire [15:0] rv0, rv1, rv2, rv3, rv4, rv5, rv6, rv7;
    
//     Nbit_reg #(n) r0 (.in(i_wdata), .out(rv0), .clk(clk), .we((i_rd == 3'd0) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r1 (.in(i_wdata), .out(rv1), .clk(clk), .we((i_rd == 3'd1) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r2 (.in(i_wdata), .out(rv2), .clk(clk), .we((i_rd == 3'd2) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r3 (.in(i_wdata), .out(rv3), .clk(clk), .we((i_rd == 3'd3) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r4 (.in(i_wdata), .out(rv4), .clk(clk), .we((i_rd == 3'd4) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r5 (.in(i_wdata), .out(rv5), .clk(clk), .we((i_rd == 3'd5) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r6 (.in(i_wdata), .out(rv6), .clk(clk), .we((i_rd == 3'd6) & i_rd_we), .gwe(gwe), .rst(rst));
//     Nbit_reg #(n) r7 (.in(i_wdata), .out(rv7), .clk(clk), .we((i_rd == 3'd7) & i_rd_we), .gwe(gwe), .rst(rst));

//     Mux8to1 mux_rs(.sel(i_rs), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rs_data));
//     Mux8to1 mux_rt(.sel(i_rt), .rv0(rv0), .rv1(rv1), .rv2(rv2), .rv3(rv3), .rv4(rv4), .rv5(rv5), .rv6(rv6), .rv7(rv7), .o_data(o_rt_data));
// endmodule