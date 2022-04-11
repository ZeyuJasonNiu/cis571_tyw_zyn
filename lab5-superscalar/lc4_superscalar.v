// ~~~~~~~~~~~ Team Info ~~~~~~~~~~~ //
// ~~~~ Tianyi Wu  &&  Zeyu Niu ~~~~ //
// ~~~~~~  wubill  &&  zyniu  ~~~~~~ //

`timescale 1ns / 1ps
// Prevent implicit wire declaration
// `default_nettype none
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
    //************************************************************************************//
    //****************************     LAB-5 CODE BEGINS       ***************************//
    //************************************************************************************//
    assign led_data = switch_data; 


    // ************ Instruction Registers ************ //
    wire [15:0] d_i_bus_A, d2x_bus_tmp_A, d_i_bus_B, d2x_bus_tmp_B;
    wire [33:0] d2x_bus_A, d2x_bus_final_A, x2m_bus_A, m2w_bus_A, w_o_bus_A;
    wire [33:0] d2x_bus_B, d2x_bus_final_B, x2m_bus_B, m2w_bus_B, w_o_bus_B;

    wire x_br_taken_or_ctrl_A, branch_taken_A, x_br_taken_or_ctrl_B, branch_taken_B; 
    wire pipe_switch;
    Nbit_reg #(16, 16'b0) d_insn_reg_A (.in(d_i_bus_A), .out(d2x_bus_tmp_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | d_flush_A));
    Nbit_reg #(34, 34'b0) x_insn_reg_A (.in(d2x_bus_A), .out(x2m_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_A));
    Nbit_reg #(34, 34'b0) m_insn_reg_A (.in(x2m_bus_A), .out(m2w_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(1'b0));
    Nbit_reg #(34, 34'b0) w_insn_reg_A (.in(m2w_bus_A), .out(w_o_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(1'b0));

    Nbit_reg #(16, 16'b0) d_insn_reg_B (.in(d_i_bus_B), .out(d2x_bus_tmp_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | d_flush_B));
    Nbit_reg #(34, 34'b0) x_insn_reg_B (.in(d2x_bus_B), .out(x2m_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_B));
    Nbit_reg #(34, 34'b0) m_insn_reg_B (.in(x2m_bus_B), .out(m2w_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | m_flush_B));
    Nbit_reg #(34, 34'b0) w_insn_reg_B (.in(m2w_bus_B), .out(w_o_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(1'b0));



    // ************ Pipe Switching and LTU Classifier ************ //
    wire    LTU_A, LTU_B, LTU_within_A, LTU_within_B, LTU_between_XA_DB, LTU_between_XB_DA, LTU_between_DA_DB;
    wire    mem_hazard, B_need_A;
    wire    LTBr_A, LTBr_B;
    assign pipe_switch =    ~x_flush_A && 
                            (B_need_A || mem_hazard || (LTU_B && ~B_need_A && ~mem_hazard) || LTBr_B);           // Case for Pipe Switching

    //~~~~~~~~~~~~ Instruction input of stage-D should depend on pipe switch situation ~~~~~~~~~~~~ //
    assign  d_i_bus_A = pipe_switch ? d2x_bus_tmp_B : 
                       stall_A ? d2x_bus_tmp_A :
                       i_cur_insn_A;
    assign  d_i_bus_B =  pipe_switch ? i_cur_insn_A : 
                        stall_A ? d2x_bus_tmp_B :
                        i_cur_insn_B;
    
    assign  LTU_between_XB_DA = (x2m_bus_B[19]) && 
                               (((d2x_bus_A[24]) && (d2x_bus_A[33:31] == x2m_bus_B[27:25])) || 
                               ((d2x_bus_A[23]) && (d2x_bus_A[30:28] == x2m_bus_B[27:25]) && (~d2x_bus_A[18])) || (d2x_bus_A[15:12]==4'b0));

    assign  LTU_within_A = (x2m_bus_A[19]) && 
                          (((d2x_bus_A[24]) && (d2x_bus_A[33:31] == x2m_bus_A[27:25])) || 
                          ((d2x_bus_A[23]) && (d2x_bus_A[30:28] == x2m_bus_A[27:25]) && (~d2x_bus_A[18])) || (d2x_bus_A[15:12]==4'b0)) &&
                          (~LTU_between_XB_DA);

    assign  LTU_within_B = (x2m_bus_B[19]) && 
                          (((d2x_bus_B[24]) && (d2x_bus_B[33:31] == x2m_bus_B[27:25])) || 
                          ((d2x_bus_B[23]) && (d2x_bus_B[30:28] == x2m_bus_B[27:25]) && (~d2x_bus_B[18])) || (d2x_bus_B[15:12]==4'b0)) 
                          && (~B_need_A);

    assign  LTU_between_XA_DB = (x2m_bus_A[19]) && 
                               (((d2x_bus_B[24]) && (d2x_bus_B[33:31] == x2m_bus_A[27:25])) || 
                               ((d2x_bus_B[23]) && (d2x_bus_B[30:28] == x2m_bus_A[27:25]) && (~d2x_bus_B[18])) || (d2x_bus_B[15:12]==4'b0)) &&
                               (~LTU_within_B) && 
                               (~B_need_A);

    //~~~~~~~~~~~~ LTU situations is in general 4-types ~~~~~~~~~~~~ //
    assign  LTU_A =  LTU_within_A || LTU_between_XB_DA;                  // Case1: LTU in Pipe-A
    assign  LTU_B =  LTU_within_B || LTU_between_XA_DB;                  // Case2: LTU in Pipe-B

    // assign  B_need_A =   ((d2x_bus_A[27:25] == d2x_bus_B[33:31]) && d2x_bus_B[24] && d2x_bus_A[22]) || 
    //                     ((d2x_bus_A[27:25] == d2x_bus_B[30:28]) && d2x_bus_B[23] && ~d2x_bus_B[18] && d2x_bus_A[22]) || 
    //                     (d2x_bus_B[17] && d2x_bus_A[21]);               // Case3: Pipe_B.D depends on data from Pipe A.D

    assign  B_need_A =   ((d2x_bus_A[27:25] == d2x_bus_B[33:31]) && d2x_bus_B[24]) || 
                        (d2x_bus_A[27:25] == d2x_bus_B[30:28] && d2x_bus_B[23] && ~d2x_bus_B[18] && d2x_bus_A[22]) || 
                        (d2x_bus_A[17] && d2x_bus_A[21]);               // Case3: Pipe_B.D depends on data from Pipe A.D

    assign  mem_hazard = (d2x_bus_A[19] || d2x_bus_A[18]) && (d2x_bus_B[19] || d2x_bus_B[18]);           // Case4: Both A & B are dmem instrucitons

    // ~~~~~~~~~~~~ Pipe X.A /B IS A LDR, which is used by a following BR insns D.A ~~~~~~~~~~~~ //
    assign  LTBr_A = d2x_bus_A[17] && ((x2m_bus_A[19] && ~x2m_bus_B[21]) | x2m_bus_B[19]);
    assign  LTBr_B = d2x_bus_B[17] && ((x2m_bus_A[19] && ~x2m_bus_B[21]) | x2m_bus_B[19]); 

   


    // ************************ Stall Registers ************************ //
    wire [1:0]  d_stall_i_A, d_stall_o_A, x_stall_i_A, x_stall_o_A, m_stall_o_A;
    wire [1:0]  d_stall_i_B, d_stall_o_B, x_stall_i_B, x_stall_o_B, m_stall_i_B, m_stall_o_B;
    wire stall_A, stall_B;

    Nbit_reg #(2, 2'b10) d_stall_reg_A (.in(d_stall_i_A), .out(d_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_br_taken_or_ctrl_A));
    Nbit_reg #(2, 2'b10) x_stall_reg_A (.in(x_stall_i_A), .out(x_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_br_taken_or_ctrl_A));
    Nbit_reg #(2, 2'b10) m_stall_reg_A (.in(x_stall_o_A), .out(m_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) w_stall_reg_A (.in(m_stall_o_A), .out(test_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(2, 2'b10) d_stall_reg_B (.in(d_stall_i_B), .out(d_stall_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_br_taken_or_ctrl_B));
    Nbit_reg #(2, 2'b10) x_stall_reg_B (.in(x_stall_i_B), .out(x_stall_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_br_taken_or_ctrl_B));
    Nbit_reg #(2, 2'b10) m_stall_reg_B (.in(m_stall_i_B), .out(m_stall_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) w_stall_reg_B (.in(m_stall_o_B), .out(test_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign  d_stall_i_A = (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? 2'd2 :
                         (LTU_A || LTBr_A) ? 2'd3 :
                         2'd0;
    assign  d_stall_i_B = (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? 2'd2 :
                         (LTU_A || LTBr_A || B_need_A || mem_hazard) ? 2'd1 :
                         (LTU_B || LTBr_B) ? 2'd3 :
                         2'd0;
    assign stall_A = d_stall_i_A == 2'd3 || d_stall_i_A == 2'd1 || LTBr_A;
    assign stall_B = (d_stall_i_B == 2'd3) | (d_stall_i_B == 2'd1) | LTBr_A | LTBr_B;

    assign x_stall_i_A = ((d2x_bus_A[15:0] == 16'h0000) && (d2x_pc_A == 16'h0000)) ? 2'd2 : d_stall_i_A;
    assign x_stall_i_B = ((d2x_bus_B[15:0] == 16'h0000) && (d2x_pc_B == 16'h0000)) ? 2'd2 : d_stall_i_B;
    assign m_stall_i_B = (x_br_taken_or_ctrl_A == 1) ? 2'd2 : x_stall_o_B;



    // ************************ Flush Logics ************************ //
    wire    d_flush_A, x_flush_A, d_flush_B, x_flush_B, m_flush_B;

    assign d_flush_A = x_br_taken_or_ctrl_A | x_br_taken_or_ctrl_B;
    assign d_flush_B = x_br_taken_or_ctrl_B | x_br_taken_or_ctrl_A;
    assign x_flush_A = stall_A | x_br_taken_or_ctrl_A | x_br_taken_or_ctrl_B;
    assign x_flush_B = stall_B | x_br_taken_or_ctrl_B | pipe_switch | x_br_taken_or_ctrl_A;
    assign m_flush_B = x_br_taken_or_ctrl_A;
   


    // ************************ PC Registers ************************ //
    wire [15:0] next_pc_A, f2d_pc_A, d_i_pc_A, d2x_pc_A, x2m_pc_A, m2w_pc_A, w_o_pc_A; 
    wire [15:0] d_i_pc_B, d2x_pc_B, x2m_pc_B, m2w_pc_B, w_o_pc_B;
    wire [15:0] f2d_pc_plus_one_A, f2d_pc_plus_two_A;
    Nbit_reg #(16, 16'h8200) f_pc_reg_A (.in(next_pc_A), .out(f2d_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0)    d_pc_reg_A (.in(d_i_pc_A), .out(d2x_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | d_flush_A));
    Nbit_reg #(16, 16'b0)    x_pc_reg_A (.in(d2x_pc_A), .out(x2m_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_A));
    Nbit_reg #(16, 16'b0)    m_pc_reg_A (.in(x2m_pc_A), .out(m2w_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(1'b0));
    Nbit_reg #(16, 16'b0)    w_pc_reg_A (.in(m2w_pc_A), .out(w_o_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(1'b0));

    Nbit_reg #(16, 16'b0)    d_pc_reg_B (.in(d_i_pc_B), .out(d2x_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | d_flush_B));
    Nbit_reg #(16, 16'b0)    x_pc_reg_B (.in(d2x_pc_B), .out(x2m_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_B));
    Nbit_reg #(16, 16'b0)    m_pc_reg_B (.in(x2m_pc_B), .out(m2w_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | m_flush_B));
    Nbit_reg #(16, 16'b0)    w_pc_reg_B (.in(m2w_pc_B), .out(w_o_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(1'b0));

    cla16 Pipeline_A_PC_Inc_One(.a(f2d_pc_A), .b(16'b0), .cin(1'b1), .sum(f2d_pc_plus_one_A));
    cla16 Pipeline_A_PC_Inc_Two(.a(f2d_pc_plus_one_A), .b(16'b0), .cin(1'b1), .sum(f2d_pc_plus_two_A));



    // ************************ Branch Prediction ************************ //
    wire [2:0] is_all_zero_A, is_all_zero_B;
    wire [2:0] o_nzp_reg_val_A, o_nzp_reg_val_B;

    assign is_all_zero_A = o_nzp_reg_val_A & x2m_bus_A[11:9];
    assign branch_taken_A = ((is_all_zero_A != 3'b0) && (x2m_bus_A[17] == 1)) ? 1'b1 : 1'b0;
    assign x_br_taken_or_ctrl_A = branch_taken_A || x2m_bus_A[16];

    assign next_pc_A =  x_br_taken_or_ctrl_A ? o_alu_result_A :
                        x_br_taken_or_ctrl_B ? o_alu_result_B : 
                        stall_A ? f2d_pc_A :
                        pipe_switch ? f2d_pc_plus_one_A :
                        f2d_pc_plus_two_A;
    
    assign d_i_pc_A = (pipe_switch) ? d2x_pc_B :  
                      stall_A ? d2x_pc_A :
                      f2d_pc_A;
    assign d_i_pc_B = (pipe_switch) ? f2d_pc_A :  
                      stall_B ? d2x_pc_B :
                      f2d_pc_plus_one_A;

    assign is_all_zero_B = o_nzp_reg_val_B & x2m_bus_B[11:9];
    assign branch_taken_B = ((is_all_zero_B != 3'b0) && (x2m_bus_B[17] == 1)) ? 1'b1 : 1'b0;
    assign x_br_taken_or_ctrl_B = branch_taken_B || x2m_bus_B[16];
    
    assign d2x_bus_A[15:0] = d2x_bus_tmp_A;
    assign d2x_bus_B[15:0] = d2x_bus_tmp_B;
    // assign d2x_bus_final_B = ((LTU_A | LTU_B | x_br_taken_or_ctrl_A | x_br_taken_or_ctrl_B) == 1) ? {34{1'b0}} : d2x_bus_B;



    // ************************ A, B, O, D Registers ************************ //
    wire [15:0] x_A_i_A, x_A_o_A, x_B_i_A, x_B_o_A,
                m_B_o_A, m_O_i_A, m_O_o_A, 
                w_O_o_A, w_D_i_A, w_D_o_A;
    wire [15:0] x_A_i_B, x_A_o_B, x_B_i_B, x_B_o_B,
                m_B_o_B, m_O_i_B, m_O_o_B, 
                w_O_o_B, w_D_i_B, w_D_o_B;
    wire [15:0] write_back_A, write_back_B;                  // Determine the value that writes back to the Regfiles //
                    
    Nbit_reg #(16, 16'b0) x_A_reg_A (.in(x_A_i_A), .out(x_A_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_A));
    Nbit_reg #(16, 16'b0) x_B_reg_A (.in(x_B_i_A), .out(x_B_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_A));
    Nbit_reg #(16, 16'b0) m_B_reg_A (.in(rt_bypass_res_A), .out(m_B_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) m_O_reg_A (.in(m_O_i_A), .out(m_O_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_O_reg_A (.in(m_O_o_A), .out(w_O_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_D_reg_A (.in(i_cur_dmem_data), .out(w_D_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'b0) x_A_reg_B (.in(x_A_i_B), .out(x_A_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_B));
    Nbit_reg #(16, 16'b0) x_B_reg_B (.in(x_B_i_B), .out(x_B_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | x_flush_B));
    Nbit_reg #(16, 16'b0) m_B_reg_B (.in(rt_bypass_res_B), .out(m_B_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | m_flush_B));
    Nbit_reg #(16, 16'b0) m_O_reg_B (.in(m_O_i_B), .out(m_O_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | m_flush_B));
    Nbit_reg #(16, 16'b0) w_O_reg_B (.in(m_O_o_B), .out(w_O_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) w_D_reg_B (.in(i_cur_dmem_data), .out(w_D_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    // assign  x_A_i_A = ((w_o_bus_A[27:25] == d2x_bus_A[33:31]) && w_o_bus_A[22]) ? write_back_A : o_regfile_rs_A; 
    // assign  x_B_i_A = ((w_o_bus_A[27:25] == d2x_bus_A[30:28]) && w_o_bus_A[22]) ? write_back_A : o_regfile_rt_A;
    // assign  x_A_i_B = ((w_o_bus_B[27:25] == d2x_bus_B[33:31]) && w_o_bus_B[22]) ? write_back_B : o_regfile_rs_B; 
    // assign  x_B_i_B = ((w_o_bus_B[27:25] == d2x_bus_B[30:28]) && w_o_bus_B[22]) ? write_back_B : o_regfile_rt_B;
    // assign  m_O_i_A = (d2x_bus_A[16] == 1) ? d2x_pc_A : o_alu_result_A; 
    // assign  m_O_i_B = (d2x_bus_B[16] == 1) ? d2x_pc_B : o_alu_result_B;
    assign  x_A_i_A = o_regfile_rs_A;
    assign  x_B_i_A = o_regfile_rt_A;
    assign  x_A_i_B = o_regfile_rs_B; 
    assign  x_B_i_B = o_regfile_rt_B;
    assign  m_O_i_A = o_alu_result_A; 
    assign  m_O_i_B = o_alu_result_B;
    assign  write_back_A = (w_o_bus_A[19] == 1) ? w_D_o_A: w_O_o_A;
    assign  write_back_B = (w_o_bus_B[19] == 1) ? w_D_o_B: w_O_o_B;



    // ************************ Superscaler Decoders ************************ //
    wire [15:0] o_regfile_rs_A, o_regfile_rs_B, o_regfile_rt_A, o_regfile_rt_B;             //output of ALU

    lc4_decoder Decoder_Pipe_A(
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
        .is_branch(d2x_bus_A[17]), 
        .is_control_insn(d2x_bus_A[16]),
        .insn(d2x_bus_tmp_A)
        );
    
    lc4_decoder Decoder_Pipe_B(
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
        .insn(d2x_bus_tmp_B)
        );
    


    // ************************ Superscaler Regfile ************************ // 
    lc4_regfile_ss Superscaler_Regfile(
        .clk(clk),
        .gwe(gwe),
        .rst(rst),
        .i_rs_A(d2x_bus_A[33:31]),
        .i_rt_A(d2x_bus_A[30:28]),
        .o_rs_data_A(o_regfile_rs_A),
        .o_rt_data_A(o_regfile_rt_A),
        .i_rs_B(d2x_bus_B[33:31]),
        .i_rt_B(d2x_bus_B[30:28]),
        .o_rs_data_B(o_regfile_rs_B),
        .o_rt_data_B(o_regfile_rt_B),
        .i_rd_A(w_o_bus_A[27:25]),
        .i_wdata_A(write_back_A),
        .i_rd_we_A(w_o_bus_A[22]),
        .i_rd_B(w_o_bus_B[27:25]),
        .i_wdata_B(write_back_B),
        .i_rd_we_B(w_o_bus_B[22])
        );



    // ************************ Superscaler ALUs ************************ // 
    wire [15:0] o_alu_result_A, o_alu_result_B;

    lc4_alu ALU_Pipe_A( 
        .i_insn(x2m_bus_A[15:0]),
        .i_pc(x2m_pc_A),
        .i_r1data(rs_bypass_res_A),
        .i_r2data(rt_bypass_res_A),
        .o_result(o_alu_result_A)
        );
    
    lc4_alu ALU_Pipe_B( 
        .i_insn(x2m_bus_B[15:0]),
        .i_pc(x2m_pc_B),
        .i_r1data(rs_bypass_res_B),
        .i_r2data(rt_bypass_res_B),
        .o_result(o_alu_result_B)
        );


    
    // ************************ Dmem-related Situations ************************//
    // wire [15:0] i_cur_dmem_data_A, i_cur_dmem_data_B;
    assign test_dmem_we_A = m2w_bus_A[18];
    assign test_dmem_we_B = m2w_bus_B[18];
    assign o_dmem_we = test_dmem_we_A || test_dmem_we_B;
    assign test_dmem_addr_A = ((m2w_bus_A[19] == 1) || (m2w_bus_A[18] == 1)) ? m_O_o_A : 16'b0;
    assign test_dmem_addr_B = ((m2w_bus_B[19] == 1) || (m2w_bus_B[18] == 1)) ? m_O_o_B : 16'b0;
    assign o_dmem_addr = test_dmem_addr_A | test_dmem_addr_B; 
    // assign i_cur_dmem_data_A = test_dmem_addr_A ? i_cur_dmem_data : 16'b0; 
    // assign i_cur_dmem_data_B = test_dmem_addr_B ? i_cur_dmem_data : 16'b0;    
    assign test_dmem_data_A = (m2w_bus_A[19] == 1) ? i_cur_dmem_data :
                              (m2w_bus_A[18] == 1) ? wm_bypass_res_A : 16'b0; 
    assign test_dmem_data_B = (m2w_bus_B[19] == 1) ? i_cur_dmem_data :
                              (m2w_bus_B[18] == 1) ? wm_or_mm_bypass_res_B : 16'b0;    
    


    // ************************ NZP Registers ************************ //
    Nbit_reg Superscalar_NZP_Reg_A(
        .in(i_regfile_wdata_sign_A), 
        .out(o_nzp_reg_val_A),
        .clk(clk),
        .we(x2m_bus_A[21]),
        .gwe(gwe),
        .rst(rst)
        );
    defparam Superscalar_NZP_Reg_A.n = 3;

    Nbit_reg Superscalar_NZP_Reg_B(
        .in(i_regfile_wdata_sign_B), 
        .out(o_nzp_reg_val_B),
        .clk(clk),
        .we(x2m_bus_B[21]),
        .gwe(gwe),
        .rst(rst)
        );
    defparam Superscalar_NZP_Reg_B.n = 3;



    // ************************ M/W Stage NZP Decoders ************************ //
    wire [2:0] i_regfile_wdata_sign_A, m_nzp_o_A, w_nzp_i_A,
               i_regfile_wdata_sign_B, m_nzp_o_B, w_nzp_i_B;
    wire [2:0] nzp_alu_A, nzp_ld_A, nzp_trap_A,
               nzp_alu_B, nzp_ld_B, nzp_trap_B;
    Nbit_reg #(3, 3'b0) m_nzp_reg_A (.in(i_regfile_wdata_sign_A), .out(m_nzp_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'b0) w_nzp_reg_A (.in(w_nzp_i_A), .out(test_nzp_new_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'b0) m_nzp_reg_B (.in(i_regfile_wdata_sign_B), .out(m_nzp_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst | m_flush_B));
    Nbit_reg #(3, 3'b0) w_nzp_reg_B (.in(w_nzp_i_B), .out(test_nzp_new_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    //Pipe-A//
    assign w_nzp_i_A = ((m2w_bus_A[19]==1)) ? nzp_ld_A : m_nzp_o_A;
    assign nzp_alu_A = ($signed(o_alu_result_A) > 0) ? 3'b001 : 
                       (o_alu_result_A == 0) ? 3'b010 : 
                       3'b100;
    assign nzp_ld_A = ($signed(i_cur_dmem_data) > 0) ? 3'b001 :
                      (i_cur_dmem_data == 0) ? 3'b010 : 
                      3'b100;  
    assign nzp_trap_A = ($signed(x2m_pc_A) > 0) ? 3'b001:
                        (x2m_pc_A == 0) ? 3'b010: 
                        3'b100;  
    assign i_regfile_wdata_sign_A = (x2m_bus_A[15:12] == 4'b1111) ? nzp_trap_A :  
                                    ((m2w_bus_A[19] == 1) && (x_stall_o_A == 2'd3)) ? nzp_ld_A : 
                                    nzp_alu_A;
    //Pipe-B//
    assign w_nzp_i_B = ((m2w_bus_B[19]==1)) ? nzp_ld_B : m_nzp_o_B;
    assign nzp_alu_B = ($signed(o_alu_result_B) > 0) ? 3'b001 : 
                       (o_alu_result_B == 0) ? 3'b010 : 
                       3'b100;
    assign nzp_ld_B = ($signed(i_cur_dmem_data) > 0) ? 3'b001 :
                      (i_cur_dmem_data == 0) ? 3'b010 : 
                      3'b100;  
    assign nzp_trap_B = ($signed(x2m_pc_B) > 0) ? 3'b001:
                        (x2m_pc_B == 0) ? 3'b010: 
                        3'b100;  
    assign i_regfile_wdata_sign_B = (x2m_bus_B[15:12] == 4'b1111) ? nzp_trap_B :  
                                    ((m2w_bus_B[19]==1) && (x_stall_o_B == 2'd3)) ? nzp_ld_B : 
                                    nzp_alu_B;


    
    // ************************ MX/WX bypass situation classifier ************************ //
    wire [15:0] rs_bypass_res_A, rs_bypass_res_B, 
                rt_bypass_res_A, rt_bypass_res_B;               // Bypass Result for ALU input
    wire        rs_MB_XA_bypass, rs_MA_XA_bypass, rs_WB_XA_bypass, rs_WA_XA_bypass, 
                rt_MB_XA_bypass, rt_MA_XA_bypass, rt_WB_XA_bypass, rt_WA_XA_bypass,
                rs_MB_XB_bypass, rs_MA_XB_bypass, rs_WB_XB_bypass, rs_WA_XB_bypass,
                rt_MB_XB_bypass, rt_MA_XB_bypass, rt_WB_XB_bypass, rt_WA_XB_bypass;             // Bypass Cases
    
    assign rs_MB_XA_bypass = (x2m_bus_A[33:31] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1) && (x2m_bus_A[24]);
    assign rs_MA_XA_bypass = (x2m_bus_A[33:31] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1) && (x2m_bus_A[24]);
    assign rs_WB_XA_bypass = (x2m_bus_A[33:31] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1) && (x2m_bus_A[24]);
    assign rs_WA_XA_bypass = (x2m_bus_A[33:31] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1) && (x2m_bus_A[24]);

    assign rt_MB_XA_bypass = (x2m_bus_A[30:28] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1) && (x2m_bus_A[23]);
    assign rt_MA_XA_bypass = (x2m_bus_A[30:28] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1) && (x2m_bus_A[23]);
    assign rt_WB_XA_bypass = (x2m_bus_A[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1) && (x2m_bus_A[23]);
    assign rt_WA_XA_bypass = (x2m_bus_A[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1) && (x2m_bus_A[23]);

    assign rs_MB_XB_bypass = (x2m_bus_B[33:31] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1) && (x2m_bus_B[24]);
    assign rs_MA_XB_bypass = (x2m_bus_B[33:31] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1) && (x2m_bus_B[24]);
    assign rs_WB_XB_bypass = (x2m_bus_B[33:31] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1) && (x2m_bus_B[24]);
    assign rs_WA_XB_bypass = (x2m_bus_B[33:31] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1) && (x2m_bus_B[24]);

    assign rt_MB_XB_bypass = (x2m_bus_B[30:28] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1) && (x2m_bus_B[23]);
    assign rt_MA_XB_bypass = (x2m_bus_B[30:28] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1) && (x2m_bus_B[23]);
    assign rt_WB_XB_bypass = (x2m_bus_B[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1) && (x2m_bus_B[23]);
    assign rt_WA_XB_bypass = (x2m_bus_B[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1) && (x2m_bus_B[23]);
    
    assign rs_bypass_res_A = rs_MB_XA_bypass ? m_O_o_B :
                             rs_MA_XA_bypass ? m_O_o_A :
                             rs_WB_XA_bypass ? write_back_B :
                             rs_WA_XA_bypass ? write_back_A : 
                             x_A_o_A;
    assign rt_bypass_res_A = rt_MB_XA_bypass ? m_O_o_B :
                             rt_MA_XA_bypass ? m_O_o_A :
                             rt_WB_XA_bypass ? write_back_B :
                             rt_WA_XA_bypass ? write_back_A :
                             x_B_o_A;
    assign rs_bypass_res_B = rs_MB_XB_bypass ? m_O_o_B :
                             rs_MA_XB_bypass ? m_O_o_A :
                             rs_WB_XB_bypass ? write_back_B :
                             rs_WA_XB_bypass ? write_back_A :
                             x_A_o_B;
    assign rt_bypass_res_B = rt_MB_XB_bypass ? m_O_o_B :
                             rt_MA_XB_bypass ? m_O_o_A :
                             rt_WB_XB_bypass ? write_back_B :
                             rt_WA_XB_bypass ? write_back_A :
                             x_B_o_B;
    
   
   
    // ************************ WM/MM bypass classifier ************************ //
    wire [15:0]     wm_bypass_res_A, wm_or_mm_bypass_res_B;                                     // Bypass Result for ALU input
    wire            WB_MA_bypass, WA_MA_bypass, WB_MB_bypass, WA_MB_bypass, MA_MB_bypass;       // Bypass cases

    assign WB_MA_bypass = (m2w_bus_A[18]) && (m2w_bus_A[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22]);
    assign WA_MA_bypass = (m2w_bus_A[18]) && (m2w_bus_A[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22]);
    assign WB_MB_bypass = (m2w_bus_B[18]) && (m2w_bus_B[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22]);
    assign WA_MB_bypass = (m2w_bus_B[18]) && (m2w_bus_B[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22]);
    assign MA_MB_bypass = (m2w_bus_B[18]) && (m2w_bus_B[30:28] == m2w_bus_A[27:25]) && (m2w_bus_A[22]);

    assign wm_bypass_res_A = WB_MA_bypass ? write_back_B :
                             WA_MA_bypass ? write_back_A :
                             m_B_o_A;
    assign wm_or_mm_bypass_res_B = WB_MB_bypass ? write_back_B :
                             WA_MB_bypass ? write_back_A :
                             MA_MB_bypass ? m_B_o_A :
                             m_B_o_B;



    // ************************ Test Wire Assignment ************************ //
    assign o_cur_pc = f2d_pc_A;
    assign o_dmem_towrite = test_dmem_addr_A ? wm_bypass_res_A : wm_or_mm_bypass_res_B;

    assign test_cur_pc_A = w_o_pc_A;
    assign test_cur_pc_B = w_o_pc_B;
    assign test_cur_insn_A = w_o_bus_A[15:0];
    assign test_cur_insn_B = w_o_bus_B[15:0];
    assign test_regfile_we_A = w_o_bus_A[22];
    assign test_regfile_we_B = w_o_bus_B[22];
    assign test_regfile_wsel_A = w_o_bus_A[27:25];
    assign test_regfile_wsel_B = w_o_bus_B[27:25];
    assign test_regfile_data_A =  write_back_A;
    assign test_regfile_data_B =  write_back_B;
    assign test_nzp_we_A = w_o_bus_A[21];
    assign test_nzp_we_B = w_o_bus_B[21];



    //************************************************************************************//
    //*****************************     LAB-5 CODE ENDS       ****************************//
    //************************************************************************************//




   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
   always @(posedge gwe) begin
    //    if ($time >= 1100 && $time <=1600) begin
    //     $display("=============================================");
    //     $display("Time = %d, test_stall_A = %h, test_stall_B = %h, o_cur_pc = %h, next_pc_A %h, i_cur_insn_A = %h, i_cur_insn_B = %h, test_cur_insn_A = %h, test_cur_insn_B = %h \n", 
    //             $time, test_stall_A, test_stall_B, o_cur_pc, next_pc_A, i_cur_insn_A, i_cur_insn_B, test_cur_insn_A, test_cur_insn_B);
    //     $display("d_stall_i_A %d, d_stall_i_B %d, test_regfile_data_A %h, test_regfile_data_B %h, i_cur_dmem_data %h, o_alu_result_A %h, o_alu_result_B %h \n", 
    //             d_stall_i_A, d_stall_i_B, test_regfile_data_A, test_regfile_data_B, i_cur_dmem_data, o_alu_result_A, o_alu_result_B);
    //     $display("STALL_B: %b, %b, %b, %b \n", d_stall_o_B, x_stall_o_B, m_stall_o_B, test_stall_B);
    //     $display("INSTR_B: %h, %h, %h, %h \n", d2x_bus_tmp_B, x2m_bus_B, m2w_bus_B, w_o_bus_B);
    //     $display("x_flush_B %b, stall_B %b,  pipe_switch %b, x_br_taken_or_ctrl_B %b, x_br_taken_or_ctrl_A %b, LTBr_A %b, LTBr_B %b", x_flush_B, stall_B,  pipe_switch, x_br_taken_or_ctrl_B, x_br_taken_or_ctrl_A, LTBr_A, LTBr_B);
    //     $display("LTU_A %b, LTBr_A %b, B_need_A %b, mem_hazard %b", LTU_A, LTBr_A, B_need_A, mem_hazard);
        // $display("rs_bypass_res_A %h, rs_bypass_res_B %h, rt_bypass_res_A %h, rt_bypass_res_B %h \n", rs_bypass_res_A, rs_bypass_res_B, rt_bypass_res_A, rt_bypass_res_B);
        // $display("m_O_o_A %h, m_O_o_B %h, write_back_A %h, write_back_B %h, x_A_o_A %h \n" ,m_O_o_A, m_O_o_B, write_back_A, write_back_B, x_A_o_A);
    //    end
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