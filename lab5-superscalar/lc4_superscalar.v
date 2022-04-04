`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/


    // PC fetch and plus one before D stage //
    wire    [15:0] f2d_pc_plus_one;
    cla16 Pipeline_PC_Inc(.a(f2d_pc), .b(16'd2), .cin(1'b0), .sum(f2d_pc_plus_one));

    // Register file for Pipelned Datapath //
    wire [15:0] o_regfile_rs_A, o_regfile_rt_A, o_regfile_rs_B, o_regfile_rt_B; 

    lc4_regfile_ss Superscaler_Regfile (
            .clk(clk),
            .gwe(gwe),
            .rst(rst),

            .i_rs_A(d2x_bus_A[33:31]),
            .i_rs_B(d2x_bus_B[33:31]), 
            .o_rs_data_A(o_regfile_rs_A),
            .o_rs_data_B(o_regfile_rs_B),

            .i_rt_A(d2x_bus_A[30:28]),
            .i_rt_B(d2x_bus_B[30:28]), 
            .o_rt_data_A(o_regfile_rt_A),
            .o_rt_data_B(o_regfile_rt_B),

            .i_rd_A(w_o_bus_A[27:25]), 
            .i_rd_B(w_o_bus_B[27:25]),            
            .i_rd_we_A(w_o_bus_A[22]),
            .i_rd_we_B(w_o_bus_B[22]),
            .i_wdata_A(write_back_A),
            .i_wdata_B(write_back_B)
    );
    
    // lc4_regfile Pipeline_Regfile (
    //         .clk(clk),
    //         .gwe(gwe),
    //         .rst(rst),
    //         .i_rs(d2x_bus[33:31]), 
    //         .o_rs_data(o_regfile_rs),
    //         .i_rt(d2x_bus[30:28]), 
    //         .o_rt_data(o_regfile_rt),
    //         .i_rd(w_o_bus[27:25]), 
    //         .i_wdata(write_back), 
    //         .i_rd_we(w_o_bus[22])
    // );

    /**** Registers for Intermediate States ****/

    // Intermediate PC registers //
    wire [15:0]     next_pc_A, next_pc_;
    wire [15:0]     f2d_pc, d2x_pc, x2m_pc, m2w_pc, w_o_pc; 

    Nbit_reg #(16, 16'h8200) f_pc_reg (.in(next_pc), .out(f2d_pc), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)    d_pc_reg (.in(f2d_pc), .out(d2x_pc), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)    x_pc_reg (.in(d2x_pc), .out(x2m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)    m_pc_reg (.in(x2m_pc), .out(m2w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)    w_pc_reg (.in(m2w_pc), .out(w_o_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


    // Instructions registers //
    wire            x_br_taken_or_ctrl_A, branch_taken_A,
                    x_br_taken_or_ctrl_B, branch_taken_B;                              // Taking branch or control instruction will flush the current cycle
    wire            load2use_A, load2use_B;                                             // Judge whether there is a load-to-use stall
    wire [15:0]     d_i_bus_A, d2x_bus_tmp_A, d_i_bus_B, d2x_bus_tmp_B;                 // PC bus at D and pre_X stage
    wire [33:0]     d2x_bus_A, d2x_bus_final_A, x2m_bus_A, m2w_bus_A, w_o_bus_A,
                    d2x_bus_B, d2x_bus_final_B, x2m_bus_B, m2w_bus_B, w_o_bus_B;        // Intermediate buses 

    Nbit_reg #(16, 16'b0) d_insn_reg_A (.in(d_i_bus_A), .out(d2x_bus_tmp_A), .clk(clk), .we(~load2use_A), .gwe(gwe), .rst(rst));
    Nbit_reg #(34, 34'b0) x_insn_reg_A (.in(d2x_bus_final_A), .out(x2m_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(34, 34'b0) m_insn_reg_A (.in(x2m_bus_A), .out(m2w_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(34, 34'b0) w_insn_reg_A (.in(m2w_bus_A), .out(w_o_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'b0) d_insn_reg_B (.in(d_i_bus_B), .out(d2x_bus_tmp_B), .clk(clk), .we(~load2use_B), .gwe(gwe), .rst(rst));
    Nbit_reg #(34, 34'b0) x_insn_reg_B (.in(d2x_bus_final_B), .out(x2m_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(34, 34'b0) m_insn_reg_B (.in(x2m_bus_B), .out(m2w_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(34, 34'b0) w_insn_reg_B (.in(m2w_bus_B), .out(w_o_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign  d_i_bus_A = (x_br_taken_or_ctrl_A == 1) ? {16{1'b0}} : i_cur_insn_A;
    assign  d_i_bus_A = (x_br_taken_or_ctrl_B == 1) ? {16{1'b0}} : i_cur_insn_B;                        // misprediction and control signal causes flush
    assign  d2x_bus_A[15:0] = d2x_bus_tmp_A;
    assign  d2x_bus_B[15:0] = d2x_bus_tmp_B;
    assign  d2x_bus_final_A = ((load2use_A | x_br_taken_or_ctrl_A) == 1) ? {34{1'b0}} : d2x_bus_A;
    assign  d2x_bus_final_B = ((load2use_B | x_br_taken_or_ctrl_B) == 1) ? {34{1'b0}} : d2x_bus_B;      // load2use also causes flush, but only judged after D stage//


    // Wires to calculating br_predict and next PC //
    wire [2:0]      is_all_zero;                                        
    wire [2:0]      o_nzp_reg_val;

    assign  is_all_zero = o_nzp_reg_val & x2m_bus[11:9];
    assign  branch_taken = ((is_all_zero != 3'b0) && (x2m_bus[17] == 1)) ? 1'b1 : 1'b0;
    assign  x_br_taken_or_ctrl = branch_taken || x2m_bus[16];
    assign  next_pc = (x_br_taken_or_ctrl == 1) ? o_alu_result : f2d_pc_plus_one;


    // Regiters for Intermediate A, B, O, D Input/Output //
    wire [15:0]     x_A_i_A, x_A_o_A, x_B_i_A, x_B_o_A, m_B_o_A, 
                    m_O_i_A, m_O_o_A, w_O_o_A, w_D_i_A, w_D_o_A,
                    x_A_i_B, x_A_o_B, x_B_i_B, x_B_o_B, m_B_o_B, 
                    m_O_i_B, m_O_o_B, w_O_o_B, w_D_i_B, w_D_o_B;
    wire [15:0]     write_back_A, write_back_B;                  // Determine the value that writes back to the Regfiles //
                    
    Nbit_reg #(16, 16'b0) x_A_reg_A (.in(x_A_i_A), .out(x_A_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) x_B_reg_A (.in(x_B_i_A), .out(x_B_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) m_B_reg_A (.in(rt_bypass_res_A), .out(m_B_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) m_O_reg_A (.in(m_O_i_A), .out(m_O_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_O_reg_A (.in(m_O_o_A), .out(w_O_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_D_reg_A (.in(i_cur_dmem_data_A), .out(w_D_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(16, 16'b0) x_A_reg_B (.in(x_A_i_B), .out(x_A_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) x_B_reg_B (.in(x_B_i_B), .out(x_B_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) m_B_reg_B (.in(rt_bypass_res_B), .out(m_B_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) m_O_reg_B (.in(m_O_i_B), .out(m_O_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_O_reg_B (.in(m_O_o_B), .out(w_O_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_D_reg_B (.in(i_cur_dmem_data_B), .out(w_D_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    assign  x_A_i_A = ((w_o_bus_A[27:25] == d2x_bus_A[33:31]) && w_o_bus_A[22]) ? write_back_A : o_regfile_rs_A; 
    assign  x_B_i_A = ((w_o_bus_A[27:25] == d2x_bus_A[30:28]) && w_o_bus_A[22]) ? write_back_A : o_regfile_rt_A;   
    assign  x_A_i_B = ((w_o_bus_B[27:25] == d2x_bus_B[33:31]) && w_o_bus_B[22]) ? write_back_B : o_regfile_rs_B; 
    assign  x_B_i_B = ((w_o_bus_B[27:25] == d2x_bus_B[30:28]) && w_o_bus_B[22]) ? write_back_B : o_regfile_rt_B;

    assign  m_O_i_A = (x2m_bus_A[16] == 1) ? d2x_pc_A : o_alu_result_A;
    assign  m_O_i_B = (x2m_bus_B[16] == 1) ? d2x_pc_B : o_alu_result_B; 

    assign  write_back_A = (w_o_bus_A[19] == 1) ? w_D_o : w_O_o;
    assign  write_back_B = (w_o_bus_B[19] == 1) ? w_D_o : w_O_o                 // Write back to register


    // Registers for stall cycle //
    wire[1:0]   d_stall_i, d_stall_o, x_stall_i, 
                x_stall_o, m_stall_o;

    Nbit_reg #(2, 2'b10) d_stall_reg (.in(d_stall_i), .out(d_stall_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) x_stall_reg (.in(x_stall_i), .out(x_stall_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) m_stall_reg (.in(x_stall_o), .out(m_stall_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) w_stall_reg (.in(m_stall_o), .out(test_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign  d_stall_i = (x_br_taken_or_ctrl == 1) ? 2'd2 : 2'd0;
    assign  x_stall_i = (load2use == 1) ? 2'd3 :                    // load2use only judged after the Decoder stage
                        (x_br_taken_or_ctrl == 1) ? 2'd2 :          // (Initial predict all set Not-Taken) Wrong predic and control both cause flush
                        d_stall_o;


    // Registers for NZP values //
    wire [2:0] i_regfile_wdata_sign, m_nzp_o, w_nzp_i;
    wire [2:0] nzp_alu, nzp_ld, nzp_trap;

    Nbit_reg #(3, 3'b0) m_nzp_reg (.in(i_regfile_wdata_sign), .out(m_nzp_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'b0) w_nzp_reg (.in(w_nzp_i), .out(test_nzp_new_bits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign w_nzp_i =    ((m2w_bus[19]==1)) ? nzp_ld : m_nzp_o;          // For load insn, nzp_ld are independently calculated
    assign nzp_alu =    ($signed(o_alu_result) > 0) ? 3'b001: 
                        (o_alu_result == 0) ? 3'b010: 
                        3'b100;
    assign nzp_ld  =    ($signed(i_cur_dmem_data) > 0) ? 3'b001:
                        (i_cur_dmem_data == 0) ? 3'b010: 
                        3'b100;  
    assign nzp_trap =   ($signed(x2m_pc) > 0) ? 3'b001:
                        (x2m_pc == 0) ? 3'b010: 
                        3'b100;  
    // NZP has 3 different possible sources: output of ALU, Output of dataMemory, PC from X stage 
    assign i_regfile_wdata_sign =   (x2m_bus[15:12] == 4'b1111) ? nzp_trap :  
                                    ((m2w_bus[19]==1) && (x_stall_o==2'd3) ) ? nzp_ld : 
                                    nzp_alu;


    //  Register for memory operationss  //
    wire [15:0] w_dmem_data;

    Nbit_reg #(1, 1'b0)     w_dmem_we_reg (.in(o_dmem_we), .out(test_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)   w_dmem_addr_reg (.in(o_dmem_addr), .out(test_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)   w_dmem_data_reg (.in(w_dmem_data), .out(test_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign w_dmem_data =    (m2w_bus[19] == 1) ? i_cur_dmem_data :
                            (m2w_bus[18] == 1) ? wm_bypass_res : 16'b0;

    //**** Intermediate State Registers END ****/


    // NZP Register //
    Nbit_reg Pipeline_NZP_Reg (
            .in(i_regfile_wdata_sign), 
            .out(o_nzp_reg_val),
            .clk(clk),
            .we(x2m_bus[21]),
            .gwe(gwe),
            .rst(rst)
    );
    defparam Pipeline_NZP_Reg.n = 3;


    /***** Pipeline Stage2: Decoder *****/
    lc4_decoder PipeA_Decoder (
            .r1sel(d2x_bus_A[33:31]), 
            .r2sel(d2x_bus_A[30:28]),
            .wsel(d2x_bus_A[27:25]),
            .r1re(d2x_bus_A[24]),
            .r2re(d2x_bus_A[23]),
            .regfile_we(d2x_bus_A[22]),
            .nzp_we(d2x_bus_A[21]), 
            .select_pc_plus_one(d2x_bus_A[20]),
            .is_load(d2x_bus_A[19]), 
            .is_store(d2x_bus_A[18]),
            .is_branch(d2x_bus_a_A[17]), 
            .is_control_insn(d2x_bus_a_A[16]),
            .insn(d2x_bus_a_A[15:0])
    );
    
    lc4_decoder PipeB_Decoder (
            .r1sel(d2x_bus_B[33:31]), 
            .r2sel(d2x_bus_B[30:28]),
            .wsel(d2x_bus_B[27:25]),
            .r1re(d2x_bus_B[24]),
            .r2re(d2x_bus_B[23]),
            .regfile_we(d2x_bus_B[22]),
            .nzp_we(d2x_bus_B[21]), 
            .select_pc_plus_one(d2x_bus_B[20]),
            .is_load(d2x_bus_B[19]), 
            .is_store(d2x_bus_B[18]),
            .is_branch(d2x_bus_B[17]), 
            .is_control_insn(d2x_bus_B[16]),
            .insn(d2x_bus_B[15:0])
    );
    
    /***** Pipeline Stage3: Execute (ALU) *****/
    wire    [15:0]  o_alu_result_A, rs_bypass_res_A, rt_bypass_res_A, wm_bypass_res_A,
                    o_alu_result_B, rs_bypass_res_B, rt_bypass_res_B, wm_bypass_res_B;

    lc4_alu PipeA_Alu ( 
            .i_insn(x2m_bus_A[15:0]),
            .i_pc(x2m_pc_A),
            .i_r1data(rs_bypass_res_A),
            .i_r2data(rt_bypass_res_A),
            .o_result(o_alu_result_B)
    );

    lc4_alu PipeB_Alu ( 
            .i_insn(x2m_bus_B[15:0]),
            .i_pc(x2m_pc_B),
            .i_r1data(rs_bypass_res_B),
            .i_r2data(rt_bypass_res_B),
            .o_result(o_alu_result_B)
    );

    
    // Bypass results assignment//
    assign rs_bypass_res =  ((x2m_bus[33:31] == m2w_bus[27:25]) && (m2w_bus[22] == 1)) ? m_O_o:         // MX for ALU input rs_data
                            ((x2m_bus[33:31] == w_o_bus[27:25]) && w_o_bus[22] == 1) ? write_back:      // WX for ALU input rs_data
                            x_A_o;

    assign rt_bypass_res =  ((x2m_bus[30:28] == m2w_bus[27:25]) && (m2w_bus[22] == 1)) ? m_O_o:          // MX for ALU input rt_data
                            ((x2m_bus[30:28] == w_o_bus[27:25]) && w_o_bus[22] == 1) ? write_back:       // WX for ALU input rt_data
                            x_B_o;

    assign wm_bypass_res = ((m2w_bus[18]) && (m2w_bus[30:28] == w_o_bus[27:25]) && (w_o_bus[22])) ? write_back : m_B_o;     // WM Bypass

    assign load2use   =     (x2m_bus[19]) && 
                            (((d2x_bus[24]) && (d2x_bus[33:31] == x2m_bus[27:25])) || 
                            ((d2x_bus[23]) && (d2x_bus[30:28] == x2m_bus[27:25]) && (~d2x_bus[18])) || (d2x_bus[15:12]==4'b0));

    
    //**** Test Wire Assignment ****//
    assign o_cur_pc =           f2d_pc;
    assign o_dmem_addr =        ((m2w_bus[19] == 1) || (m2w_bus[18] == 1)) ? m_O_o : 16'b0;                   
    assign o_dmem_we =          m2w_bus[18];
    assign o_dmem_towrite =     wm_bypass_res;

    assign test_cur_pc =        w_o_pc;
    assign test_cur_insn =      w_o_bus[15:0];
    assign test_regfile_we =    w_o_bus[22];
    assign test_regfile_wsel =  w_o_bus[27:25];
    assign test_regfile_data =  write_back;
    assign test_nzp_we =        w_o_bus[21];
    //**** Test Wire Assignment END ****//






   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
   always @(posedge gwe) begin
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display();
   end
endmodule
