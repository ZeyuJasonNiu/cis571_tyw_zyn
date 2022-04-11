
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

   // TEST ASSIGNMENT
   assign test_cur_pc_A = W_PC_A;
   assign test_cur_pc_B = W_PC_B;
   assign test_cur_insn_A = W_INSN_A;
   assign test_cur_insn_B = W_INSN_B;   
   assign test_regfile_we_A = W_Ctrl_RF_WE_A;
   assign test_regfile_we_B = W_Ctrl_RF_WE_B;

   assign test_regfile_wsel_A = In_Rd_A;
   assign test_regfile_wsel_B = In_Rd_B;

   assign test_regfile_data_A = I_RF_data_A;
   assign test_regfile_data_B = I_RF_data_B;

   assign test_nzp_we_A = W_Ctrl_Update_NZP_A;
   assign test_nzp_new_bits_A = W_Ctrl_NZP_A;
   
   assign test_nzp_we_B = W_Ctrl_Update_NZP_B;
   assign test_nzp_new_bits_B = W_Ctrl_NZP_B;

   assign test_dmem_we_A = W_insn_STR_A;   
   assign test_dmem_we_B = W_insn_STR_B;

   assign test_dmem_addr_A = W_dmem_addr_A;
   assign test_dmem_addr_B = W_dmem_addr_B;

   assign test_dmem_data_A = (W_insn_STR_A) ?  W_dmem_towrite_A: 
                           (W_insn_LDR_A) ? W_Mem_A:
                           16'h0000;     
   assign test_dmem_data_B = (W_insn_STR_B) ?  W_dmem_towrite_B: 
                           (W_insn_LDR_B) ? W_Mem_B:
                           16'h0000;                               
   // Define Control Signals
   wire D_Ctrl_W_R7_A;
   wire X_Ctrl_W_R7_A;
   wire M_Ctrl_W_R7_A;
   wire W_Ctrl_W_R7_A;

   wire D_Ctrl_RF_WE_A;
   wire X_Ctrl_RF_WE_A;
   wire M_Ctrl_RF_WE_A;  
   wire W_Ctrl_RF_WE_A;

   wire D_Ctrl_Update_NZP_A;
   wire X_Ctrl_Update_NZP_A;

   wire D_Ctrl_Control_insn_A;
   wire X_Ctrl_PC_JMP_A;
   wire X_Ctrl_BR_JMP_A;
   wire D_insn_BR_A;
   wire X_insn_BR_A;
   wire D_insn_LDR_A;
   wire X_insn_LDR_A;
   wire M_insn_LDR_A;
   wire W_insn_LDR_A;
   wire D_insn_STR_A;
   wire X_insn_STR_A;
   wire M_insn_STR_A;
   wire W_insn_STR_A;
   
   wire D_Ctrl_W_R7_B;
   wire X_Ctrl_W_R7_B;
   wire M_Ctrl_W_R7_B;
   wire W_Ctrl_W_R7_B;

   wire D_Ctrl_RF_WE_B;
   wire X_Ctrl_RF_WE_B;
   wire M_Ctrl_RF_WE_B;  
   wire W_Ctrl_RF_WE_B;

   wire D_Ctrl_Update_NZP_B;
   wire X_Ctrl_Update_NZP_B;

   wire D_Ctrl_Control_insn_B;
   wire X_Ctrl_PC_JMP_B;
   wire X_Ctrl_BR_JMP_B;
   wire D_insn_BR_B;
   wire X_insn_BR_B;
   wire D_insn_LDR_B;
   wire X_insn_LDR_B;
   wire M_insn_LDR_B;
   wire W_insn_LDR_B;
   wire D_insn_STR_B;
   wire X_insn_STR_B;
   wire M_insn_STR_B;
   wire W_insn_STR_B;


   // PC
   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // WHATS NEXT PC
   assign next_pc =
                  X_Ctrl_PC_JMP_A ? O_ALU_A :
                  X_Ctrl_PC_JMP_B ? O_ALU_B :  
                  Stall_A ? pc :
                  Pipe_Switch ? PC_ADD_ONE_A :
                  PC_ADD_ONE_B ;

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   assign o_cur_pc = pc;
   wire [15:0] D_PC_A;
   wire [15:0] D_I_PC_A;
   wire [15:0] D_PC_B;
   wire [15:0] D_I_PC_B;

   // PC adder
   wire [15:0] PC_ADD_ONE_A;
   wire [15:0] D_PC_ADD_ONE_A;
   wire [15:0] PC_ADD_ONE_B;
   wire [15:0] D_PC_ADD_ONE_B;
   cla16 PCadder_A(.a(pc), .b(16'h0000), .cin(1'b1), .sum(PC_ADD_ONE_A));
   cla16 PCadder_B(.a(PC_ADD_ONE_A), .b(16'h0000), .cin(1'b1), .sum(PC_ADD_ONE_B));

   // D Register

   wire [15:0] F_INSN_A;
   wire [15:0] F_INSN_B;

   // pipe line switching
   assign F_INSN_A = (Pipe_Switch) ? D_INSN_B :
                     (Stall_A) ? D_INSN_A : i_cur_insn_A;
   assign F_INSN_B = (Pipe_Switch) ? i_cur_insn_A :
                     (Stall_A) ? D_INSN_B : 
                     i_cur_insn_B;

   wire [15:0] D_INSN_A;
   //wire [15:0] D_I_INSN_A;
   wire [15:0] D_INSN_B;
   //wire [15:0] D_I_INSN_B;

   assign D_I_PC_A = (Pipe_Switch) ? D_PC_B :
                     (Stall_A) ? D_PC_A : pc;
   assign D_I_PC_ADD_ONE_A = (Pipe_Switch) ? D_PC_ADD_ONE_B :
                     (Stall_A) ? D_PC_ADD_ONE_A : PC_ADD_ONE_A;
   //assign D_I_INSN_A = (Stall_A) ? D_INSN_A : INSN_A;

   wire [15:0] D_I_PC_ADD_ONE_A;
   wire [15:0] D_I_PC_ADD_ONE_B;
   assign D_I_PC_B = (Pipe_Switch) ? pc :
                     (Stall_B) ? D_PC_B : PC_ADD_ONE_A;
   assign D_I_PC_ADD_ONE_B = (Pipe_Switch) ? PC_ADD_ONE_A:
                  (Stall_B) ? D_PC_ADD_ONE_B : PC_ADD_ONE_B;
   //assign D_I_INSN_B = (Stall_B) ? D_INSN_B : INSN_B;

   // D register 
   // A
   Nbit_reg #(16, 16'h0000) D_PC_Reg_A(.in(D_I_PC_A), .out( D_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_A | rst ));
   Nbit_reg #(16, 16'h0000) D_insn_Reg_A(.in(F_INSN_A), .out( D_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_A | rst  ));
   Nbit_reg #(16, 16'h0000) D_PC_ADD_ONE_Reg_A(.in(D_I_PC_ADD_ONE_A), .out( D_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_A | rst  ));
   // B
   Nbit_reg #(16, 16'h0000) D_PC_Reg_B(.in(D_I_PC_B), .out( D_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_B | rst ));
   Nbit_reg #(16, 16'h0000) D_insn_Reg_B(.in(F_INSN_B), .out( D_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_B | rst  ));
   Nbit_reg #(16, 16'h0000) D_PC_ADD_ONE_Reg_B(.in(D_I_PC_ADD_ONE_B), .out( D_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_B | rst  ));


   // decoder
   // TO DO: STALL SITUATIONS
   // A
   wire [2:0] Rd_A; // raw rd output from decoder; 
   wire [2:0] D_Rd_A; // valid only when RF_WE is enabled; to avoid false WX by pass
   assign D_Rd_A = (D_Ctrl_RF_WE_A)? Rd_A:3'b000;
   wire [2:0] D_Rs_A;
   wire [2:0] D_Rt_A;
   wire R1RE_A;
   wire R2RE_A;
   lc4_decoder decode_A(.insn(D_INSN_A),               // instruction
                   .r1sel(D_Rs_A),              // rs
                   .r1re(R1RE_A),               // does this instruction read from rs?
                   .r2sel(D_Rt_A),              // rt
                   .r2re(R2RE_A),               // does this instruction read from rt?
                   .wsel(Rd_A),               // rd
                   .regfile_we(D_Ctrl_RF_WE_A),         // does this instruction write to rd?
                   .nzp_we(D_Ctrl_Update_NZP_A),             // does this instruction write the NZP bits?
                   .select_pc_plus_one(D_Ctrl_W_R7_A), // write PC+1 to the regfile?
                   .is_load(D_insn_LDR_A),            // is this a load instruction?
                   .is_store(D_insn_STR_A),           // is this a store instruction?
                   .is_branch(D_insn_BR_A),          // is this a branch instruction?
                   .is_control_insn(D_Ctrl_Control_insn_A)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );

   //B
   wire [2:0] Rd_B; // raw rd output from decoder; 
   wire [2:0] D_Rd_B; // valid only when RF_WE is enabled; to avoid false WX by pass
   assign D_Rd_B = (D_Ctrl_RF_WE_B)? Rd_B:3'b000;
   wire [2:0] D_Rs_B;
   wire [2:0] D_Rt_B;
   wire R1RE_B;
   wire R2RE_B;
   lc4_decoder decode_B(.insn(D_INSN_B),               // instruction
                   .r1sel(D_Rs_B),              // rs
                   .r1re(R1RE_B),               // does this instruction read from rs?
                   .r2sel(D_Rt_B),              // rt
                   .r2re(R2RE_B),               // does this instruction read from rt?
                   .wsel(Rd_B),               // rd
                   .regfile_we(D_Ctrl_RF_WE_B),         // does this instruction write to rd?
                   .nzp_we(D_Ctrl_Update_NZP_B),             // does this instruction write the NZP bits?
                   .select_pc_plus_one(D_Ctrl_W_R7_B), // write PC+1 to the regfile?
                   .is_load(D_insn_LDR_B),            // is this a load instruction?
                   .is_store(D_insn_STR_B),           // is this a store instruction?
                   .is_branch(D_insn_BR_B),          // is this a branch instruction?
                   .is_control_insn(D_Ctrl_Control_insn_B)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );

   // Regfile

   // A
   wire [15:0] I_RF_data_A;
   wire [15:0] X_RF_data_A;
   wire [15:0] M_RF_data_A;
   wire [15:0] W_RF_data_A;
   wire [15:0] D_O_RF_R1_A;
   wire [15:0] D_O_RF_R2_A;
   wire [2:0] In_Rd_A;
   assign In_Rd_A = (W_Ctrl_W_R7_A) ? 3'h7 : W_Rd_A;
   // B
   wire [15:0] I_RF_data_B;
   wire [15:0] X_RF_data_B;
   wire [15:0] M_RF_data_B;
   wire [15:0] W_RF_data_B;
   wire [15:0] D_O_RF_R1_B;
   wire [15:0] D_O_RF_R2_B;
   wire [2:0] In_Rd_B;
   assign In_Rd_B = (W_Ctrl_W_R7_B) ? 3'h7 : W_Rd_B;

   lc4_regfile_ss #(16) myregfile
   (.clk(clk),
    .gwe(gwe),
    .rst(rst),

    .i_rs_A(D_Rs_A),      // pipe A: rs selector
    .o_rs_data_A(D_O_RF_R1_A), // pipe A: rs contents
    .i_rt_A(D_Rt_A),      // pipe A: rt selector
    .o_rt_data_A(D_O_RF_R2_A), // pipe A: rt contents

    .i_rs_B(D_Rs_B),      // pipe B: rs selector
    .o_rs_data_B(D_O_RF_R1_B), // pipe B: rs contents
    .i_rt_B(D_Rt_B),      // pipe B: rt selector
    .o_rt_data_B(D_O_RF_R2_B), // pipe B: rt contents

    .i_rd_A(In_Rd_A),     // pipe A: rd selector
    .i_wdata_A(I_RF_data_A),  // pipe A: data to write
    .i_rd_we_A(W_Ctrl_RF_WE_A),  // pipe A: write enable

    .i_rd_B(In_Rd_B),     // pipe B: rd selector
    .i_wdata_B(I_RF_data_B),  // pipe B: data to write
    .i_rd_we_B(W_Ctrl_RF_WE_B)   // pipe B: write enable
    );

   assign I_RF_data_A = W_Ctrl_W_R7_A ? W_PC_ADD_ONE_A : W_RF_IN_data_A;
   assign I_RF_data_B = W_Ctrl_W_R7_B ? W_PC_ADD_ONE_B : W_RF_IN_data_B;

   // X registers
   // A
   wire [15:0] X_PC_A;
   wire [15:0] X_INSN_A;
   wire [15:0] X_PC_ADD_ONE_A;
   wire [15:0] X_R1_A;
   wire [15:0] X_R2_A;   
   wire [2:0] X_Rs_A;
   wire [2:0] X_Rt_A;
   wire [2:0] X_Rd_A;
   wire X_Ctrl_Control_insn_A;

   Nbit_reg #(16, 16'h0000) X_PC_Reg_A(.in(D_PC_A), .out( X_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(16, 16'h0000) X_insn_Reg_A(.in(D_INSN_A), .out( X_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(16, 16'h0000) X_PC_ADD_One_Reg_A(.in(D_PC_ADD_ONE_A), .out( X_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   
   Nbit_reg #(16, 16'h0000) X_RF_Data_Reg_A(.in(I_RF_data_A), .out( X_RF_data_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));

   Nbit_reg #(16, 16'h0000) X_R1_Reg_A(.in(D_O_RF_R1_A), .out( X_R1_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(16, 16'h0000) X_R2_Reg_A(.in(D_O_RF_R2_A), .out( X_R2_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));

   wire X_R1RE_A;
   wire X_R2RE_A;
   Nbit_reg #(1, 1'b0) X_R1RE_Reg_A(.in(R1RE_A), .out( X_R1RE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(1, 1'b0) X_R2RE_Reg_A(.in(R2RE_A), .out( X_R2RE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));


   Nbit_reg #(1, 1'b0) X_STR_Reg_A(.in(D_insn_STR_A), .out( X_insn_STR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(1, 1'b0) X_LDR_Reg_A(.in(D_insn_LDR_A), .out( X_insn_LDR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   
   Nbit_reg #(1, 1'b0) X_insn_BR_Reg_A(.in(D_insn_BR_A), .out( X_insn_BR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_W_R7_Reg_A(.in(D_Ctrl_W_R7_A), .out( X_Ctrl_W_R7_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_RF_WE_Reg_A(.in(D_Ctrl_RF_WE_A), .out( X_Ctrl_RF_WE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_Control_Reg_A(.in(D_Ctrl_Control_insn_A), .out( X_Ctrl_Control_insn_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_Update_NZP_Reg_A(.in(D_Ctrl_Update_NZP_A), .out( X_Ctrl_Update_NZP_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));

   Nbit_reg #(3, 3'b000) X_Rs_Reg_A(.in(D_Rs_A), .out( X_Rs_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(3, 3'b000) X_Rt_Reg_A(.in(D_Rt_A), .out( X_Rt_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
   Nbit_reg #(3, 3'b000) X_Rd_Reg_A(.in(D_Rd_A), .out( X_Rd_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));

   // B
   wire [15:0] X_PC_B;
   wire [15:0] X_INSN_B;
   wire [15:0] X_PC_ADD_ONE_B;
   wire [15:0] X_R1_B;
   wire [15:0] X_R2_B;   
   wire [2:0] X_Rs_B;
   wire [2:0] X_Rt_B;
   wire [2:0] X_Rd_B;
   wire X_Ctrl_Control_insn_B;

   Nbit_reg #(16, 16'h0000) X_PC_Reg_B(.in(D_PC_B), .out( X_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(16, 16'h0000) X_insn_Reg_B(.in(D_INSN_B), .out( X_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(16, 16'h0000) X_PC_ADD_One_Reg_B(.in(D_PC_ADD_ONE_B), .out( X_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   
   Nbit_reg #(16, 16'h0000) X_RF_Data_Reg_B(.in(I_RF_data_B), .out( X_RF_data_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));

   Nbit_reg #(16, 16'h0000) X_R1_Reg_B(.in(D_O_RF_R1_B), .out( X_R1_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(16, 16'h0000) X_R2_Reg_B(.in(D_O_RF_R2_B), .out( X_R2_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));

   wire X_R1RE_B;
   wire X_R2RE_B;
   Nbit_reg #(1, 1'b0) X_R1RE_Reg_B(.in(R1RE_B), .out( X_R1RE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(1, 1'b0) X_R2RE_Reg_B(.in(R2RE_B), .out( X_R2RE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));


   Nbit_reg #(1, 1'b0) X_STR_Reg_B(.in(D_insn_STR_B), .out( X_insn_STR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(1, 1'b0) X_LDR_Reg_B(.in(D_insn_LDR_B), .out( X_insn_LDR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   
   Nbit_reg #(1, 1'b0) X_insn_BR_Reg_B(.in(D_insn_BR_B), .out( X_insn_BR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_W_R7_Reg_B(.in(D_Ctrl_W_R7_B), .out( X_Ctrl_W_R7_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_RF_WE_Reg_B(.in(D_Ctrl_RF_WE_B), .out( X_Ctrl_RF_WE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_Control_Reg_B(.in(D_Ctrl_Control_insn_B), .out( X_Ctrl_Control_insn_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_Update_NZP_Reg_B(.in(D_Ctrl_Update_NZP_B), .out( X_Ctrl_Update_NZP_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));

   Nbit_reg #(3, 3'b000) X_Rs_Reg_B(.in(D_Rs_B), .out( X_Rs_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(3, 3'b000) X_Rt_Reg_B(.in(D_Rt_B), .out( X_Rt_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
   Nbit_reg #(3, 3'b000) X_Rd_Reg_B(.in(D_Rd_B), .out( X_Rd_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));


   // ALU
   // A
   wire [2:0] WMX_Bypass_1_A;
   wire [2:0] WMX_Bypass_2_A;
   wire [15:0] O_ALU_A;
   wire [15:0] ALU_in1_A;
   wire [15:0] ALU_in2_A;  

   // B
   wire [2:0] WMX_Bypass_1_B;
   wire [2:0] WMX_Bypass_2_B;
   wire [15:0] O_ALU_B;
   wire [15:0] ALU_in1_B;
   wire [15:0] ALU_in2_B;  

   

   // WMX Bypass 
   // No passing: 0b000
   // MX from A: 0b001
   // WX from A: 0b010
   // MX from B: 0b101
   // WX from B: 0b110
   // A
   // input 1 of ALU for A:
   // preference: MX from B > MX from A > WX from B > WX from A
   assign WMX_Bypass_1_A = ((X_Rs_A == M_Rd_B) & M_Ctrl_RF_WE_B & X_R1RE_A) ? 3'b101 :
                        ((X_Rs_A == M_Rd_A) & M_Ctrl_RF_WE_A & X_R1RE_A) ? 3'b001 :
                        ((X_Rs_A == W_Rd_B) & W_Ctrl_RF_WE_B & X_R1RE_A) ? 3'b110 :
                        ((X_Rs_A == W_Rd_A) & W_Ctrl_RF_WE_A & X_R1RE_A) ? 3'b010 :
                        3'b000;
   assign WMX_Bypass_2_A = 
                        ((X_Rt_A == M_Rd_B) & M_Ctrl_RF_WE_B & X_R2RE_A) ? 3'b101 :
                        ((X_Rt_A == M_Rd_A) & M_Ctrl_RF_WE_A & X_R2RE_A) ? 3'b001 :
                        ((X_Rt_A == W_Rd_B) & W_Ctrl_RF_WE_B & X_R2RE_A) ? 3'b110 :
                        ((X_Rt_A == W_Rd_A) & W_Ctrl_RF_WE_A & X_R2RE_A) ? 3'b010 :
                        3'b000;

   assign ALU_in1_A = (WMX_Bypass_1_A == 3'b000)? X_R1_A:
                     (WMX_Bypass_1_A == 3'b001)? M_ALU_A:
                     (WMX_Bypass_1_A == 3'b010)? I_RF_data_A:
                     (WMX_Bypass_1_A == 3'b101)? M_ALU_B:
                     (WMX_Bypass_1_A == 3'b110)? I_RF_data_B:
                     16'h0000 ;

   assign ALU_in2_A = (WMX_Bypass_2_A == 3'b000)? X_R2_A:
                     (WMX_Bypass_2_A == 3'b001)? M_ALU_A:
                     (WMX_Bypass_2_A == 3'b010)? I_RF_data_A:
                     (WMX_Bypass_2_A == 3'b101)? M_ALU_B:
                     (WMX_Bypass_2_A == 3'b110)? I_RF_data_B:
                     16'h0000 ;

   lc4_alu myALU_A(.i_insn(X_INSN_A),
               .i_pc(X_PC_A),
               .i_r1data(ALU_in1_A),
               .i_r2data(ALU_in2_A),
               .o_result(O_ALU_A));

   wire [15:0] W_RF_IN_data_A;
   wire [15:0] M_PC_ADD_ONE_A;

   // B
   // No passing: 0b000
   // MX from A: 0b001
   // WX from A: 0b010
   // MX from B: 0b101
   // WX from B: 0b110
   // preference MX from B > MX from A > WX from B > WX from A
   assign WMX_Bypass_1_B = ((X_Rs_B == M_Rd_B) & M_Ctrl_RF_WE_B & X_R1RE_B) ? 3'b101 :
                        ((X_Rs_B == M_Rd_A) & M_Ctrl_RF_WE_A & X_R1RE_B) ? 3'b001 :
                        ((X_Rs_B == W_Rd_B) & W_Ctrl_RF_WE_B & X_R1RE_B) ? 3'b110 :
                        ((X_Rs_B == W_Rd_A) & W_Ctrl_RF_WE_A & X_R1RE_B) ? 3'b010 :
                        3'b000;
   assign WMX_Bypass_2_B =  ((X_Rt_B == M_Rd_B) & M_Ctrl_RF_WE_B & X_R2RE_B) ? 3'b101 :
                        ((X_Rt_B == M_Rd_A) & M_Ctrl_RF_WE_A & X_R2RE_B) ? 3'b001 :
                        ((X_Rt_B == W_Rd_B) & W_Ctrl_RF_WE_B & X_R2RE_B) ? 3'b110 :
                        ((X_Rt_B == W_Rd_A) & W_Ctrl_RF_WE_A & X_R2RE_B) ? 3'b010 :
                        3'b000;

   assign ALU_in1_B = (WMX_Bypass_1_B == 3'b000)? X_R1_B:
                     (WMX_Bypass_1_B == 3'b001)? M_ALU_A:
                     (WMX_Bypass_1_B == 3'b010)? I_RF_data_A:
                     (WMX_Bypass_1_B == 3'b101)? M_ALU_B:
                     (WMX_Bypass_1_B == 3'b110)? I_RF_data_B:
                     16'h0000 ;

   assign ALU_in2_B = (WMX_Bypass_2_B == 3'b000)? X_R2_B:
                     (WMX_Bypass_2_B == 3'b001)? M_ALU_A:
                     (WMX_Bypass_2_B == 3'b010)? I_RF_data_A:
                     (WMX_Bypass_2_B == 3'b101)? M_ALU_B:
                     (WMX_Bypass_2_B == 3'b110)? I_RF_data_B:
                     16'h0000 ;

   lc4_alu myALU_B(.i_insn(X_INSN_B),
               .i_pc(X_PC_B),
               .i_r1data(ALU_in1_B),
               .i_r2data(ALU_in2_B),
               .o_result(O_ALU_B));

   wire [15:0] W_RF_IN_data_B;
   wire [15:0] M_PC_ADD_ONE_B;

   // M register
   // A
   wire [15:0] M_PC_A;
   wire [15:0] M_ALU_A;
   wire [15:0] M_R2_A;

   wire [2:0] M_Rs_A;
   wire [2:0] M_Rt_A;
   wire [2:0] M_Rd_A;

   wire [15:0] M_INSN_A;
   Nbit_reg #(16, 16'h0000) M_PC_Reg_A(.in(X_PC_A), .out( M_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( M_Flush_A | rst ));
   Nbit_reg #(16, 16'h0000) M_ALU_Reg_A(.in(O_ALU_A), .out( M_ALU_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(16, 16'h0000) M_R2_Reg_A(.in(ALU_in2_A), .out( M_R2_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(16, 16'h0000) M_PC_ADD_One_Reg_A(.in(X_PC_ADD_ONE_A), .out( M_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(16, 16'h0000) M_INSN_Reg_A(.in(X_INSN_A), .out( M_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(16, 16'h0000) M_RF_Data_Reg_A(.in(X_RF_data_A), .out( M_RF_data_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));


   Nbit_reg #(1, 1'b0) M_STR_Reg_A(.in(X_insn_STR_A), .out( M_insn_STR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(1, 1'b0) M_LDR_Reg_A(.in(X_insn_LDR_A), .out( M_insn_LDR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));

   wire M_R1RE_A;
   wire M_R2RE_A;
   Nbit_reg #(1, 1'b0) M_R1RE_Reg_A(.in(X_R1RE_A), .out( M_R1RE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(1, 1'b0) M_R2RE_Reg_A(.in(X_R2RE_A), .out( M_R2RE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));

   wire M_Stall_A;
   Nbit_reg #(1, 1'b0) M_Stall_Sig_Reg_A(.in(Stall_A), .out( M_Stall_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));


   Nbit_reg #(1, 1'b0) M_CTRL_W_R7_Reg_A(.in(X_Ctrl_W_R7_A), .out( M_Ctrl_W_R7_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(1, 1'b0) M_CTRL_RF_WE_Reg_A(.in(X_Ctrl_RF_WE_A), .out( M_Ctrl_RF_WE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   
   wire M_Ctrl_Update_NZP_A;
   Nbit_reg #(1, 1'b0) M_CTRL_Update_NZP_Reg_A(.in(X_Ctrl_Update_NZP_A), .out( M_Ctrl_Update_NZP_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   
   wire [2:0] Mem_NZP_Update;
   wire [2:0]  M_Ctrl_NZP_out_A;
   assign M_Ctrl_NZP_A = (M_insn_LDR_A)? Mem_NZP_Update : M_Ctrl_NZP_out_A;
   Nbit_reg #(3, 3'b000) M_Ctrl_NZP_Reg_A(.in(Ctrl_NZP_A), .out( M_Ctrl_NZP_out_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(3, 3'b000) M_Rs_Reg_A(.in(X_Rs_A), .out( M_Rs_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(3, 3'b000) M_Rt_Reg_A(.in(X_Rt_A), .out( M_Rt_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
   Nbit_reg #(3, 3'b000) M_Rd_Reg_A(.in(X_Rd_A), .out( M_Rd_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));

   // B
   wire [15:0] M_PC_B;
   wire [15:0] M_ALU_B;
   wire [15:0] M_R2_B;

   wire [2:0] M_Rs_B;
   wire [2:0] M_Rt_B;
   wire [2:0] M_Rd_B;

   wire [15:0] M_INSN_B;
   Nbit_reg #(16, 16'h0000) M_PC_Reg_B(.in(X_PC_B), .out( M_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( M_Flush_B | rst ));
   Nbit_reg #(16, 16'h0000) M_ALU_Reg_B(.in(O_ALU_B), .out( M_ALU_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(16, 16'h0000) M_R2_Reg_B(.in(ALU_in2_B), .out( M_R2_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(16, 16'h0000) M_PC_ADD_One_Reg_B(.in(X_PC_ADD_ONE_B), .out( M_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(16, 16'h0000) M_INSN_Reg_B(.in(X_INSN_B), .out( M_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(16, 16'h0000) M_RF_Data_Reg_B(.in(X_RF_data_B), .out( M_RF_data_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


   Nbit_reg #(1, 1'b0) M_STR_Reg_B(.in(X_insn_STR_B), .out( M_insn_STR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(1, 1'b0) M_LDR_Reg_B(.in(X_insn_LDR_B), .out( M_insn_LDR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));

   wire M_R1RE_B;
   wire M_R2RE_B;
   Nbit_reg #(1, 1'b0) M_R1RE_Reg_B(.in(X_R1RE_B), .out( M_R1RE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(1, 1'b0) M_R2RE_Reg_B(.in(X_R2RE_B), .out( M_R2RE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));

   wire M_Stall_B;
   Nbit_reg #(1, 1'b0) M_Stall_Sig_Reg_B(.in(Stall_B), .out( M_Stall_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


   Nbit_reg #(1, 1'b0) M_CTRL_W_R7_Reg_B(.in(X_Ctrl_W_R7_B), .out( M_Ctrl_W_R7_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(1, 1'b0) M_CTRL_RF_WE_Reg_B(.in(X_Ctrl_RF_WE_B), .out( M_Ctrl_RF_WE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   
   wire M_Ctrl_Update_NZP_B;
   Nbit_reg #(1, 1'b0) M_CTRL_Update_NZP_Reg_B(.in(X_Ctrl_Update_NZP_B), .out( M_Ctrl_Update_NZP_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   
   wire [2:0]  M_Ctrl_NZP_out_B;
   assign M_Ctrl_NZP_B = (M_insn_LDR_B)? Mem_NZP_Update : M_Ctrl_NZP_out_B;
   Nbit_reg #(3, 3'b000) M_Ctrl_NZP_Reg_B(.in(Ctrl_NZP_B), .out( M_Ctrl_NZP_out_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(3, 3'b000) M_Rs_Reg_B(.in(X_Rs_B), .out( M_Rs_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(3, 3'b000) M_Rt_Reg_B(.in(X_Rt_B), .out( M_Rt_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
   Nbit_reg #(3, 3'b000) M_Rd_Reg_B(.in(X_Rd_B), .out( M_Rd_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


   // memory
   // TODO 
   // assign o_dmem_addr = (M_insn_LDR_A | M_insn_STR_A)? M_ALU_A :
   //                      (M_insn_LDR_B | M_insn_STR_B)? M_ALU_B :    16'h0000; 

   assign o_dmem_we = M_insn_STR_A | M_insn_STR_B;
   
   wire [15:0] o_dmem_addr_A;
   wire [15:0] o_dmem_addr_B;

   assign o_dmem_addr_A = (M_insn_LDR_A | M_insn_STR_A)? M_ALU_A :16'h0000;
   assign o_dmem_addr_B = (M_insn_LDR_B | M_insn_STR_B)? M_ALU_B :16'h0000;
   assign o_dmem_addr = (M_insn_LDR_A | M_insn_STR_A)? o_dmem_addr_A :
                        (M_insn_LDR_B | M_insn_STR_B)? o_dmem_addr_B :    16'h0000; 
                        
   wire [15:0] W_dmem_addr_A;
   wire [15:0] W_dmem_towrite_A;   
   wire [15:0] W_dmem_addr_B;
   wire [15:0] W_dmem_towrite_B;   

   // MM bypass
   // Passing M_ALU_O from pipe A to B for STR
   wire MM_Bypass;
   assign MM_Bypass = M_insn_STR_B & (M_Rt_B == M_Rd_A) & M_Ctrl_RF_WE_A;
   // WM bypass
   // no bypassing 2'b00
   // A bypassing 2'b01
   // B bypassing 2'b10
   wire [15:0] o_dmem_towrite_A;
   wire [15:0] o_dmem_towrite_B;   
   wire [1:0] WM_Bypass_A;
   // preference B > A
   // assign WM_Bypass_A = 2'b00;
   assign WM_Bypass_A = (M_insn_STR_A  & W_Ctrl_RF_WE_B & (M_Rt_A == W_Rd_B)) ? 2'b10 :
                        ((M_insn_STR_A  & W_Ctrl_RF_WE_A & (M_Rt_A == W_Rd_A))  ? 2'b01 : 2'b00);
   
   assign o_dmem_towrite_A = 
                           (WM_Bypass_A == 2'b10)? W_RF_IN_data_B: 
                           (WM_Bypass_A == 2'b01)? W_RF_IN_data_A:
                           (M_insn_STR_A) ? M_R2_A:
                           16'h0000;

   wire [1:0] WM_Bypass_B;
   // preference B>A
   assign WM_Bypass_B = (M_insn_STR_B & W_Ctrl_RF_WE_B & (M_Rt_B == W_Rd_B))? 2'b10 :
                        (M_insn_STR_B & W_Ctrl_RF_WE_A & (M_Rt_B == W_Rd_A))? 2'b01 : 
                        2'b00;

   // Preference MM_bypass > WM_Bypass_B > WM_Bypass_A
   assign o_dmem_towrite_B = (MM_Bypass) ? M_ALU_A :
                           (WM_Bypass_B == 2'b10)? W_RF_IN_data_B:
                           (WM_Bypass_B == 2'b01)? W_RF_IN_data_A:
                           (M_insn_STR_B) ? M_R2_B:
                           16'h0000;
   
   assign o_dmem_towrite = (M_insn_STR_A) ? o_dmem_towrite_A :
                           (M_insn_STR_B) ? o_dmem_towrite_B :
                           16'h0000;

   // W registers
   wire [15:0] O_Mem;
   assign O_Mem = i_cur_dmem_data;

   wire [15:0] W_ALU_A;
   wire [15:0] W_Mem_A;
   wire [15:0] W_PC_ADD_ONE_A;
   wire [2:0] W_Rd_A;
   wire [15:0] W_INSN_A;
   wire [15:0] W_PC_A;
   assign W_Flush_A = 1'b0;
   Nbit_reg #(16, 16'h0000) W_PC_Reg_A(.in(M_PC_A), .out( W_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(16, 16'h0000) W_ALU_Reg_A(.in(M_ALU_A), .out( W_ALU_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(16, 16'h0000) W_MEM_Reg_A(.in(O_Mem), .out( W_Mem_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(16, 16'h0000) W_PC_ADD_One_Reg_A(.in(M_PC_ADD_ONE_A), .out( W_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(16, 16'h0000) W_INSN_Reg_A(.in(M_INSN_A), .out( W_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(16, 16'h0000) W_RF_Data_Reg_A(.in(M_RF_data_A), .out( W_RF_data_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));

   Nbit_reg #(16, 16'h0000) W_mem_addr_Reg_A(.in(o_dmem_addr_A), .out( W_dmem_addr_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(16, 16'h0000) W_mem_towrite_Reg_A(.in(o_dmem_towrite_A), .out( W_dmem_towrite_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));


   Nbit_reg #(1, 1'b0) W_LDR_Reg_A(.in(M_insn_LDR_A), .out( W_insn_LDR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(1, 1'b0) W_STR_Reg_A(.in(M_insn_STR_A), .out( W_insn_STR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));

   Nbit_reg #(1, 1'b0) W_CTRL_W_R7_Reg_A(.in(M_Ctrl_W_R7_A), .out( W_Ctrl_W_R7_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(1, 1'b0) W_CTRL_RF_WE_Reg_A(.in(M_Ctrl_RF_WE_A), .out( W_Ctrl_RF_WE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));

   Nbit_reg #(3, 3'b000) W_Ctrl_NZP_Reg_A(.in(M_Ctrl_NZP_A), .out( W_Ctrl_NZP_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   Nbit_reg #(3, 3'b000) W_Rd_Reg_A(.in(M_Rd_A), .out( W_Rd_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
   wire W_Ctrl_Update_NZP_A;
   Nbit_reg #(1, 1'b0) W_CTRL_Update_NZP_Reg_A(.in(M_Ctrl_Update_NZP_A), .out( W_Ctrl_Update_NZP_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));



   assign W_RF_IN_data_A = (W_insn_LDR_A) ? W_Mem_A : W_ALU_A;

   wire [15:0] W_ALU_B;
   wire [15:0] W_Mem_B;
   wire [15:0] W_PC_ADD_ONE_B;
   wire [2:0] W_Rd_B;
   wire [15:0] W_INSN_B;
   wire [15:0] W_PC_B;
   assign W_Flush_B = 1'b0;
   Nbit_reg #(16, 16'h0000) W_PC_Reg_B(.in(M_PC_B), .out( W_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(16, 16'h0000) W_BLU_Reg_B(.in(M_ALU_B), .out( W_ALU_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(16, 16'h0000) W_MEM_Reg_B(.in(O_Mem), .out( W_Mem_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(16, 16'h0000) W_PC_ADD_One_Reg_B(.in(M_PC_ADD_ONE_B), .out( W_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(16, 16'h0000) W_INSN_Reg_B(.in(M_INSN_B), .out( W_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(16, 16'h0000) W_RF_Data_Reg_B(.in(M_RF_data_B), .out( W_RF_data_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));

   Nbit_reg #(16, 16'h0000) W_mem_addr_Reg_B(.in(o_dmem_addr_B), .out( W_dmem_addr_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(16, 16'h0000) W_mem_towrite_Reg_B(.in(o_dmem_towrite_B), .out( W_dmem_towrite_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));


   Nbit_reg #(1, 1'b0) W_LDR_Reg_B(.in(M_insn_LDR_B), .out( W_insn_LDR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(1, 1'b0) W_STR_Reg_B(.in(M_insn_STR_B), .out( W_insn_STR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));

   Nbit_reg #(1, 1'b0) W_CTRL_W_R7_Reg_B(.in(M_Ctrl_W_R7_B), .out( W_Ctrl_W_R7_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(1, 1'b0) W_CTRL_RF_WE_Reg_B(.in(M_Ctrl_RF_WE_B), .out( W_Ctrl_RF_WE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));

   Nbit_reg #(3, 3'b000) W_Ctrl_NZP_Reg_B(.in(M_Ctrl_NZP_B), .out( W_Ctrl_NZP_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   Nbit_reg #(3, 3'b000) W_Rd_Reg_B(.in(M_Rd_B), .out( W_Rd_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
   wire W_Ctrl_Update_NZP_B;
   Nbit_reg #(1, 1'b0) W_CTRL_Update_NZP_Reg_B(.in(M_Ctrl_Update_NZP_B), .out( W_Ctrl_Update_NZP_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));



   assign W_RF_IN_data_B = (W_insn_LDR_B) ? W_Mem_B : W_ALU_B;

   // NZP register

   // A
   // Ctrl_NZP are the new nzp bits
   wire [2:0] Ctrl_NZP_A;
   wire [2:0] M_Ctrl_NZP_A;
   wire [2:0] W_Ctrl_NZP_A;   
   wire [2:0] NZP_A;
   wire X_NZP_WE_A; 
   assign X_NZP_WE_A = X_Ctrl_Update_NZP_A |  M_Stall_A;
   Nbit_reg #(3, 3'b000) nzp_reg_A (.in(Ctrl_NZP_A), .out(NZP_A), .clk(clk), .we(X_NZP_WE_A), .gwe(gwe), .rst(rst));

   wire signed [15:0] NZP_Data_A;
   assign NZP_Data_A = M_Stall_A ? O_Mem : 
                  X_Ctrl_W_R7_A ? X_PC_ADD_ONE_A : O_ALU_A;
   assign Ctrl_NZP_A[2] = (NZP_Data_A[15] == 1'b1)? 1'b1 : 1'b0; // N
   assign Ctrl_NZP_A[1] = (NZP_Data_A == 16'h0000)? 1'b1 : 1'b0; // Z
   assign Ctrl_NZP_A[0] = (NZP_Data_A > $signed(16'h0000))? 1'b1 : 1'b0;   // P

   // B
   // Ctrl_NZP are the new nzp bits
   wire [2:0] Ctrl_NZP_B;
   wire [2:0] M_Ctrl_NZP_B;
   wire [2:0] W_Ctrl_NZP_B;   
   wire [2:0] NZP_B;
   wire X_NZP_WE_B; 
   assign X_NZP_WE_B = X_Ctrl_Update_NZP_B |  M_Stall_B;
   Nbit_reg #(3, 3'b000) nzp_reg_B (.in(Ctrl_NZP_B), .out(NZP_B), .clk(clk), .we(X_NZP_WE_B), .gwe(gwe), .rst(rst));

   wire signed [15:0] NZP_Data_B;
   assign NZP_Data_B = M_Stall_B ? O_Mem : 
                  X_Ctrl_W_R7_B ? X_PC_ADD_ONE_B : O_ALU_B;
   assign Ctrl_NZP_B[2] = (NZP_Data_B[15] == 1'b1)? 1'b1 : 1'b0; // N
   assign Ctrl_NZP_B[1] = (NZP_Data_B == 16'h0000)? 1'b1 : 1'b0; // Z
   assign Ctrl_NZP_B[0] = (NZP_Data_B > $signed(16'h0000))? 1'b1 : 1'b0;   // P

   Nbit_reg #(3, 3'b000) nzp_used_reg (.in(NZP_Used), .out(Old_NZP_Used), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [2:0] Old_NZP_Used;
   wire [2:0] NZP_Used;
   assign NZP_Used = (M_Ctrl_Update_NZP_B) ? NZP_B:
                     (M_Ctrl_Update_NZP_A) ? NZP_A:
                     Old_NZP_Used;

   // Used to update M_Ctrl_NZP based on Mem output

   wire signed [15:0] mem_NZP_Data;
   assign mem_NZP_Data = O_Mem;
   assign Mem_NZP_Update[2] = (mem_NZP_Data[15] == 1'b1)? 1'b1 : 1'b0; // N
   assign Mem_NZP_Update[1] = (mem_NZP_Data == 16'h0000)? 1'b1 : 1'b0; // Z
   assign Mem_NZP_Update[0] = (mem_NZP_Data > $signed(16'h0000))? 1'b1 : 1'b0;   // P   

   // sub op for branch
   wire[2:0] sub_op_A;
   assign sub_op_A = X_INSN_A[11:9];
   wire sub_op_NOP_A = (sub_op_A == 3'b000);
   wire sub_op_BRp_A = (sub_op_A == 3'b001);
   wire sub_op_BRz_A = (sub_op_A == 3'b010);
   wire sub_op_BRzp_A = (sub_op_A == 3'b011);
   wire sub_op_BRn_A = (sub_op_A == 3'b100);
   wire sub_op_BRnp_A = (sub_op_A == 3'b101);
   wire sub_op_BRnz_A = (sub_op_A == 3'b110);
   wire sub_op_BRnzp_A = (sub_op_A == 3'b111);  

   // A should use the NZP of the latest insn which comes from B
   assign X_Ctrl_BR_JMP_A = (NZP_Used[0] & sub_op_BRp_A) | (NZP_Used[1] & sub_op_BRz_A) | (NZP_Used[2] & sub_op_BRn_A) | 
                        ((NZP_Used[0]|NZP_Used[1]) & sub_op_BRzp_A) | ((NZP_Used[0]|NZP_Used[2]) & sub_op_BRnp_A) | ((NZP_Used[1]|NZP_Used[2]) & sub_op_BRnz_A) | ((NZP_Used[1]|NZP_Used[0]|NZP_Used[2]) & sub_op_BRnzp_A);

   assign X_Ctrl_PC_JMP_A = (X_insn_BR_A & X_Ctrl_BR_JMP_A) | X_Ctrl_Control_insn_A;

   wire[2:0] sub_op_B;
   assign sub_op_B = X_INSN_B[11:9];
   wire sub_op_NOP_B = (sub_op_B == 3'b000);
   wire sub_op_BRp_B = (sub_op_B == 3'b001);
   wire sub_op_BRz_B = (sub_op_B == 3'b010);
   wire sub_op_BRzp_B = (sub_op_B == 3'b011);
   wire sub_op_BRn_B = (sub_op_B == 3'b100);
   wire sub_op_BRnp_B = (sub_op_B == 3'b101);
   wire sub_op_BRnz_B = (sub_op_B == 3'b110);
   wire sub_op_BRnzp_B = (sub_op_B == 3'b111);  
   // b should use the current NZP of A
   assign X_Ctrl_BR_JMP_B =    (NZP_Used[0] & sub_op_BRp_B) | (NZP_Used[1] & sub_op_BRz_B) | (NZP_Used[2] & sub_op_BRn_B) | 
                        ((NZP_Used[0]|NZP_Used[1]) & sub_op_BRzp_B) | ((NZP_Used[0]|NZP_Used[2]) & sub_op_BRnp_B) | ((NZP_Used[1]|NZP_Used[2]) & sub_op_BRnz_B) | ((NZP_Used[1]|NZP_Used[0]|NZP_Used[2]) & sub_op_BRnzp_B);
   assign X_Ctrl_PC_JMP_B = (X_insn_BR_B & X_Ctrl_BR_JMP_B) | X_Ctrl_Control_insn_B;

   // // stall logic 
   // // TO DO
   // // stall happens when 1) load to use 2) load to BR
   // wire Stall_Load_to_Branch;
   // assign Stall_Load_to_Branch = D_insn_BR & X_insn_LDR;
   // wire Stall_load_to_Use;
   // assign Stall_load_to_Use = X_insn_LDR & (((D_Rs == X_Rd) &R1RE) | ((D_Rt == X_Rd) & !D_insn_STR &R2RE));
   // wire Stall;
   // assign Stall = Stall_Load_to_Branch | Stall_load_to_Use;
   // assign D_Flush = X_Ctrl_PC_JMP;

   // New stall
   // 1. A LTU DX dependence; DEST = D.A
   wire A_LTU_dependence;
   assign A_LTU_dependence = ((X_insn_LDR_A & (((D_Rs_A == X_Rd_A) & R1RE_A) | ((D_Rt_A == X_Rd_A) & !D_insn_STR_A &R2RE_A)) ) 
                           & ~((( (X_Rd_B == D_Rs_A) & R1RE_A) | ((X_Rd_B == D_Rt_A) & R2RE_A)) & X_Ctrl_RF_WE_B & (X_Rd_A == X_Rd_B)) )                          // Nullified
                           | (X_insn_LDR_B & (((D_Rs_A == X_Rd_B) & R1RE_A) | ((D_Rt_A == X_Rd_B) & !D_insn_STR_A &R2RE_A)) ) 
                           ;
                           //& (X_Rd_A != X_Rd_B) & (X_Rd_A != D_Rd_A) )          // Nullified
                           
   // 2. B LTU DX dependence; DEST = D.B
   wire B_LTU_dependence;
   assign B_LTU_dependence = ( (X_insn_LDR_B & (((D_Rs_B == X_Rd_B) & R1RE_B) | ((D_Rt_B == X_Rd_B) & !D_insn_STR_B &R2RE_B)) )
                           & ~(( ((D_Rd_A == D_Rs_B) & R1RE_B ) | ((D_Rd_A == D_Rt_B) & R2RE_B ) ) & D_Ctrl_RF_WE_A & (D_Rd_A == X_Rd_B)) )   // nullified
                           | ( (X_insn_LDR_A & (((D_Rs_B == X_Rd_A) & R1RE_B) | ((D_Rt_B == X_Rd_A) & !D_insn_STR_B &R2RE_B)) ) 
                           & ~(( ((D_Rd_A == D_Rs_B)  & R1RE_B )| ((D_Rd_A == D_Rt_B) & R2RE_B)) & D_Ctrl_RF_WE_A & (D_Rd_A == X_Rd_A) )      // Nullified;  
                           & ~(( ((X_Rd_B == D_Rs_B)  & R1RE_B )| ((X_Rd_B == D_Rt_B) & R2RE_B)) & X_Ctrl_RF_WE_B & (X_Rd_B == X_Rd_A) ) )  
                           ;               
   // 3. A,B Decode dependence (B is the insn following A, and requires data from A)
   wire AB_dependence;
   assign AB_dependence = ((D_Rs_B == D_Rd_A) & R1RE_B & D_Ctrl_RF_WE_A) | ((D_Rt_B == D_Rd_A) & R2RE_B & D_Ctrl_RF_WE_A & ~D_insn_STR_B)
                              | (D_insn_BR_B & D_Ctrl_Update_NZP_A); // b IS A BR , and A updates NZP
   // 4. Structural Hazard 
   wire AB_Structural_hazard;
   assign AB_Structural_hazard = (D_insn_LDR_A | D_insn_STR_A) & (D_insn_LDR_B | D_insn_STR_B);                 
   
   // Pipe X.A /B IS A LDR, which is used by a following BR insns D.A
   wire A_Load_to_Branch;
   assign A_Load_to_Branch = D_insn_BR_A & ((X_insn_LDR_A & ~X_Ctrl_Update_NZP_B ) | X_insn_LDR_B);
   wire B_Load_to_Branch;
   assign B_Load_to_Branch = D_insn_BR_B & ((X_insn_LDR_A & ~X_Ctrl_Update_NZP_B ) | X_insn_LDR_B);   
   // STALL LOGIC
   wire [2:0] Stall_bits_A;
   wire [2:0] Stall_bits_B;

   assign Stall_bits_A = ( X_Ctrl_PC_JMP_A | X_Ctrl_PC_JMP_B) ? 2'b10:
                           (A_LTU_dependence | A_Load_to_Branch) ? 2'b11:
                           2'b00 ;
   assign Stall_bits_B = ( X_Ctrl_PC_JMP_A | X_Ctrl_PC_JMP_B ) ? 2'b10:
                           (A_LTU_dependence | A_Load_to_Branch) ? 2'b01:
                           (AB_dependence | AB_Structural_hazard ) ? 2'b01:
                           (B_LTU_dependence | B_Load_to_Branch) ? 2'b11:
                           2'b00 ;
   wire Stall_A;
   wire Stall_B;
   assign Stall_A = (Stall_bits_A == 2'b11) | (Stall_bits_A == 2'b01) | A_Load_to_Branch;
   assign Stall_B =    (Stall_bits_B == 2'b11) | (Stall_bits_B == 2'b01) | A_Load_to_Branch | B_Load_to_Branch;


   // pipeline switching
   wire Pipe_Switch;
   assign Pipe_Switch = ~X_Flush_A & ((AB_dependence | AB_Structural_hazard) | (B_LTU_dependence & ~AB_dependence & ~AB_Structural_hazard) | B_Load_to_Branch);



   // test_stall
   wire [1:0] D_Stall_out_bits_A;
   wire [1:0] D_Stall_in_bits_A;
   wire [1:0] X_Stall_in_bits_A;
   wire [1:0] X_Stall_out_bits_A;
   wire [1:0] M_Stall_in_bits_A;
   wire [1:0] M_Stall_out_bits_A;   
   wire [1:0] W_Stall_in_bits_A;
   wire [1:0] W_Stall_out_bits_A;

   assign D_Stall_in_bits_A =  Stall_bits_A;

   Nbit_reg #(2, 2'b10) D_Stall_Reg_A(.in(D_Stall_in_bits_A), .out( D_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst | X_Ctrl_PC_JMP_A ));
   Nbit_reg #(2, 2'b10) X_Stall_Reg_A(.in(X_Stall_in_bits_A), .out( X_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst | X_Ctrl_PC_JMP_A));
   // assign X_Stall_in_bits_A = (X_Ctrl_PC_JMP_A) ? 2'b10 :
   //                       (Stall_load_to_Use_A | Stall_Load_to_Branch_A) ? 2'b11:
   //                      D_Stall_out_bits_A;
   assign X_Stall_in_bits_A = ((D_PC_A == 16'h0000) & (D_INSN_A == 16'h0000)) ?  2'b10 : Stall_bits_A;
   Nbit_reg #(2, 2'b10) M_Stall_Reg_A(.in(M_Stall_in_bits_A), .out( M_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   assign M_Stall_in_bits_A =  X_Stall_out_bits_A;   
   Nbit_reg #(2, 2'b10) W_Stall_Reg_A(.in(W_Stall_in_bits_A), .out( W_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   assign W_Stall_in_bits_A = M_Stall_out_bits_A;   
   assign test_stall_A = W_Stall_out_bits_A; 

   wire [1:0] D_Stall_out_bits_B;
   wire [1:0] D_Stall_in_bits_B;
   wire [1:0] X_Stall_in_bits_B;
   wire [1:0] X_Stall_out_bits_B;
   wire [1:0] M_Stall_in_bits_B;
   wire [1:0] M_Stall_out_bits_B;   
   wire [1:0] W_Stall_in_bits_B;
   wire [1:0] W_Stall_out_bits_B;

   assign D_Stall_in_bits_B =  Stall_bits_B;

   Nbit_reg #(2, 2'b10) D_Stall_Reg_B(.in(D_Stall_in_bits_B), .out( D_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst| X_Ctrl_PC_JMP_B));
   Nbit_reg #(2, 2'b10) X_Stall_Reg_B(.in(X_Stall_in_bits_B), .out( X_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst | X_Ctrl_PC_JMP_B));
   // assign X_Stall_in_bits_B = (X_Ctrl_PC_JMP_B) ? 2'b10 :
   //                       (Stall_load_to_Use_B | Stall_Load_to_Branch_B) ? 2'b11:
   //                      D_Stall_out_bits_B;
   assign X_Stall_in_bits_B = ((D_PC_B == 16'h0000) & (D_INSN_B == 16'h0000)) ?  2'b10 : Stall_bits_B;
   Nbit_reg #(2, 2'b10) M_Stall_Reg_B(.in(M_Stall_in_bits_B), .out( M_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   // if A pc jumps, M_in stall bits should be 2
   assign M_Stall_in_bits_B =  (X_Ctrl_PC_JMP_A) ? 2'b10 : X_Stall_out_bits_B;   
   Nbit_reg #(2, 2'b10) W_Stall_Reg_B(.in(W_Stall_in_bits_B), .out( W_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   assign W_Stall_in_bits_B = M_Stall_out_bits_B;   
   assign test_stall_B = W_Stall_out_bits_B; 

   // Flush logic
   // D,X flush happens when Branch mis prediction OR pipe switch

   wire D_Flush_A;
   assign D_Flush_A = X_Ctrl_PC_JMP_A | X_Ctrl_PC_JMP_B;
   wire D_Flush_B;
   assign D_Flush_B = X_Ctrl_PC_JMP_B | X_Ctrl_PC_JMP_A;

   wire X_Flush_A;
   wire M_Flush_A;
   wire W_Flush_A;
   assign X_Flush_A = Stall_A | X_Ctrl_PC_JMP_A | X_Ctrl_PC_JMP_B;

   wire X_Flush_B;
   wire M_Flush_B;
   wire W_Flush_B;
   assign X_Flush_B = Stall_B | X_Ctrl_PC_JMP_B | Pipe_Switch | X_Ctrl_PC_JMP_A;
   assign M_Flush_B = X_Ctrl_PC_JMP_A;



   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */





   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
   always @(posedge gwe) begin
      // $display("%d test_regfile_data: %h W_ALU: %h", $time, test_regfile_data, W_ALU);
      // $display(" W_RF_IN_data: %h", W_RF_IN_data);
      // $display(" W_insn_LDR: %h", W_insn_LDR);
      // $display(" Stall_Load_to_Branch: %h ; Stall_load_to_Use: %h", Stall_Load_to_Branch, Stall_load_to_Use);
      // $display(" D_Rs: %h ; D_Rt: %h;  X_Rd: %h", D_Rs, D_Rt, X_Rd);            
      // $display(" o_dmem_addr: %h; o_dmem_towrite: %h ", o_dmem_addr, o_dmem_towrite);
      // $display(" ALU_in_1: %h ALU_in2: %h", ALU_in1, ALU_in2);
      // $display(" O_ALU: %h; O_Mem: %h", O_ALU, O_Mem);
      // $display(" WM_Bypass: %h", WM_Bypass);
      // $display(" WD_Bypass_1: %h WD_Bypass_2: %h", WD_Bypass_1, WD_Bypass_2);
      // $display(" WMX_Bypass_1: %h WMX_Bypass_2: %h", WMX_Bypass_1, WMX_Bypass_2);
      // $display(" X_Flush: %h D_Flush: %h", X_Flush, D_Flush);
      // $display(" Ctrl_NZP: %h; W_Ctrl_NZP: %h ;M_Ctrl_NZP: %h ", Ctrl_NZP, W_Ctrl_NZP, M_Ctrl_NZP);

      // $display("~~~~~~~~NEW CIRCLE~~~~~~~~~~");
      // $display("i_cur_insn_A: %h  i_cur_insn_B: %h", i_cur_insn_A, i_cur_insn_B);
      // $display("PC A    : %h %h %h %h %h", pc, D_PC_A, X_PC_A, M_PC_A, test_cur_pc_A);
      // $display("INSN_A  : %h %h %h %h %h", F_INSN_A, D_INSN_A, X_INSN_A, M_INSN_A, W_INSN_A);
      // $display("STALL_A : %h %h %h %h %h %h %h %h", D_Stall_in_bits_A,D_Stall_out_bits_A,X_Stall_in_bits_A,
      //               X_Stall_out_bits_A, M_Stall_in_bits_A, M_Stall_out_bits_A, 
      //               W_Stall_in_bits_A, W_Stall_out_bits_A);
      // $display(" ALU_in_1_A: %h ALU_in_2_A: %h O_ALU_A: %h", ALU_in1_A, ALU_in2_A, O_ALU_A);
      // $display(" WMX_Bypass_1_A: %h WMX_Bypass_2_A: %h", WMX_Bypass_1_A, WMX_Bypass_2_A);

      // $display("PC B    : %h %h %h %h %h", PC_ADD_ONE_A, D_PC_B, X_PC_B, M_PC_B, test_cur_pc_B);  
      // $display("INSN_B  : %h %h %h %h %h", F_INSN_B, D_INSN_B, X_INSN_B, M_INSN_B, W_INSN_B);
      // $display("STALL_B : %h %h %h %h %h %h %h %h", D_Stall_in_bits_B,D_Stall_out_bits_B,X_Stall_in_bits_B,
      //          X_Stall_out_bits_B, M_Stall_in_bits_B, M_Stall_out_bits_B, 
      //          W_Stall_in_bits_B, W_Stall_out_bits_B);
      // $display(" ALU_in_1_B: %h ALU_in_2_B: %h O_ALU_B: %h", ALU_in1_B, ALU_in2_B, O_ALU_B );
      // $display(" WMX_Bypass_1_B: %h WMX_Bypass_2_B: %h", WMX_Bypass_1_B, WMX_Bypass_2_B);

      // // $display("%h %h %h %h %h", INSN, D_INSN, X_INSN, M_INSN, W_INSN);
      // $display("X_Ctrl_PC_JMP_A: %h next_pc: %h", X_Ctrl_PC_JMP_A, next_pc);
      // $display("X_Ctrl_PC_JMP_B: %h next_pc: %h", X_Ctrl_PC_JMP_B, next_pc);

      // $display(" A_LTU_dependence: %h B_LTU_dependence: %h", A_LTU_dependence, B_LTU_dependence);
      // $display(" AB_dependence: %h AB_Structural_hazard: %h", AB_dependence, AB_Structural_hazard);
      // $display(" A_Load_to_Branch: %h B_Load_to_Branch: %h", A_Load_to_Branch, B_Load_to_Branch);
      // $display(" WM_Bypass_A: %h WM_Bypass_B: %h", WM_Bypass_A, WM_Bypass_B);
      // // $display(" M_Rt_A: %h W_Rd_B: %h W_Ctrl_RF_WE_B: %h M_insn_STR_A: %h", M_Rt_A, W_Rd_B, W_Ctrl_RF_WE_B, M_insn_STR_A);
      // //$display(" M_insn_STR_B: %h  (M_Rt_B == M_Rd_A): %h",M_insn_STR_B ,(M_Rt_B == M_Rd_A));         
      // // $display(" (M_insn_STR_A  & W_Ctrl_RF_WE_B & (M_Rt_A == W_Rd_B)): %h", (M_insn_STR_A  & W_Ctrl_RF_WE_B & (M_Rt_A == W_Rd_B)) )
      //                   ;     
      // $display(" MM_Bypass: %h", MM_Bypass);

   // (M_insn_STR_A & (M_Rt_A == W_Rd_B) & W_Ctrl_RF_WE_B) ? 2'b10 :

      // PC + 1
      // $display("W_Ctrl_W_R7_A: %h W_PC_ADD_ONE_A: %h", W_Ctrl_W_R7_A, W_PC_ADD_ONE_A);
      // $display("PC_ADD_ONE_A: %h D_PC_ADD_ONE_A: %h X_PC_ADD_ONE_A: %h M_PC_ADD_ONE_A: %h", PC_ADD_ONE_A, D_PC_ADD_ONE_A, X_PC_ADD_ONE_A, M_PC_ADD_ONE_A);
      // $display("Next PC: %h ; Stall: %h ; Ctrl_PC_JMP: %h", next_pc, Stall, X_Ctrl_PC_JMP);

      //$display("X_insn_BR: %h ; X_Ctrl_BR_JMP: %h ; X_Ctrl_Control_insn: %h", X_insn_BR, X_Ctrl_BR_JMP, X_Ctrl_Control_insn);


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




// `timescale 1ns / 1ps
// // Prevent implicit wire declaration
// // `default_nettype none
// module lc4_processor(input wire         clk,             // main clock
//                      input wire         rst,             // global reset
//                      input wire         gwe,             // global we for single-step clock
//                      output wire [15:0] o_cur_pc,        // address to read from instruction memory
//                      input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
//                      input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)
//                      output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
//                      input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
//                      output wire        o_dmem_we,       // data memory write enable
//                      output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set
//                      // testbench signals (always emitted from the WB stage)
//                      output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
//                      output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)
//                      output wire [15:0] test_cur_pc_A,       // program counter
//                      output wire [15:0] test_cur_pc_B,
//                      output wire [15:0] test_cur_insn_A,     // instruction bits
//                      output wire [15:0] test_cur_insn_B,
//                      output wire        test_regfile_we_A,   // register file write-enable
//                      output wire        test_regfile_we_B,
//                      output wire [ 2:0] test_regfile_wsel_A, // which register to write
//                      output wire [ 2:0] test_regfile_wsel_B,
//                      output wire [15:0] test_regfile_data_A, // data to write to register file
//                      output wire [15:0] test_regfile_data_B,
//                      output wire        test_nzp_we_A,       // nzp register write enable
//                      output wire        test_nzp_we_B,
//                      output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
//                      output wire [ 2:0] test_nzp_new_bits_B,
//                      output wire        test_dmem_we_A,      // data memory write enable
//                      output wire        test_dmem_we_B,
//                      output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
//                      output wire [15:0] test_dmem_addr_B,
//                      output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
//                      output wire [15:0] test_dmem_data_B,
//                      // zedboard switches/display/leds (ignore if you don't want to control these)
//                      input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
//                      output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
//                      );
//    /***  YOUR CODE HERE ***/
//    // Instruction Registers
//     assign led_data = switch_data; 
//     wire [15:0] d_i_bus_A, d2x_bus_tmp_A, d_i_bus_B, d2x_bus_tmp_B;
//     wire [33:0] d2x_bus_A, d2x_bus_final_A, x2m_bus_A, m2w_bus_A, w_o_bus_A;
//     wire [33:0] d2x_bus_B, d2x_bus_final_B, x2m_bus_B, m2w_bus_B, w_o_bus_B;
//     wire LTU_A, LTU_B, LTU_within_A, LTU_within_B, LTU_between_XA_DB, LTU_between_XB_DA, LTU_between_DA_DB;
//     wire mem_hazard, B_need_A;
//     wire x_br_taken_or_ctrl_A, branch_taken_A, x_br_taken_or_ctrl_B, branch_taken_B; 
//     wire pipe_switch;
//     Nbit_reg #(16, 16'b0) d_insn_reg_A (.in(d_i_bus_A), .out(d2x_bus_tmp_A), .clk(clk), .we(~LTU_A), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) x_insn_reg_A (.in(d2x_bus_final_A), .out(x2m_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) m_insn_reg_A (.in(x2m_bus_A), .out(m2w_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) w_insn_reg_A (.in(m2w_bus_A), .out(w_o_bus_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     Nbit_reg #(16, 16'b0) d_insn_reg_B (.in(d_i_bus_B), .out(d2x_bus_tmp_B), .clk(clk), .we(~LTU_B), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) x_insn_reg_B (.in(d2x_bus_final_B), .out(x2m_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) m_insn_reg_B (.in(x2m_bus_B), .out(m2w_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) w_insn_reg_B (.in(m2w_bus_B), .out(w_o_bus_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     assign pipe_switch = (d_stall_i_B != 0 && d_stall_i_A == 0) ? 1'b1 : 1'b0;
//     assign d_i_bus_A = (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? {16{1'b0}} : 
//                        pipe_switch ? d2x_bus_B[15:0] : 
//                        i_cur_insn_A;
//     assign d_i_bus_B = (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? {16{1'b0}} : 
//                        (d_stall_i_B != 0 && d_stall_i_A == 0) ? i_cur_insn_A : 
//                        i_cur_insn_B;
    
//     assign LTU_between_XB_DA = (x2m_bus_B[19]) && 
//                                (((d2x_bus_A[24]) && (d2x_bus_A[33:31] == x2m_bus_B[27:25])) || 
//                                ((d2x_bus_A[23]) && (d2x_bus_A[30:28] == x2m_bus_B[27:25]) && (~d2x_bus_A[18])) || (d2x_bus_A[15:12]==4'b0));
    
//     assign LTU_within_A = (x2m_bus_A[19]) && 
//                           (((d2x_bus_A[24]) && (d2x_bus_A[33:31] == x2m_bus_A[27:25])) || 
//                           ((d2x_bus_A[23]) && (d2x_bus_A[30:28] == x2m_bus_A[27:25]) && (~d2x_bus_A[18])) || (d2x_bus_A[15:12]==4'b0)) &&
//                           (~LTU_between_XB_DA);
//     assign LTU_within_B = (x2m_bus_B[19]) && 
//                           (((d2x_bus_B[24]) && (d2x_bus_B[33:31] == x2m_bus_B[27:25])) || 
//                           ((d2x_bus_B[23]) && (d2x_bus_B[30:28] == x2m_bus_B[27:25]) && (~d2x_bus_B[18])) || (d2x_bus_B[15:12]==4'b0)) 
//                           && (~B_need_A);
//     assign LTU_between_XA_DB = (x2m_bus_A[19]) && 
//                                (((d2x_bus_B[24]) && (d2x_bus_B[33:31] == x2m_bus_A[27:25])) || 
//                                ((d2x_bus_B[23]) && (d2x_bus_B[30:28] == x2m_bus_A[27:25]) && (~d2x_bus_B[18])) || (d2x_bus_B[15:12]==4'b0)) &&
//                                (~LTU_within_B) && 
//                                (~B_need_A);
//      assign B_need_A = ((d2x_bus_A[27:25] == d2x_bus_B[33:31] && d2x_bus_B[24]) || 
//                        (d2x_bus_A[27:25] == d2x_bus_B[30:28] && d2x_bus_B[23] && ~d2x_bus_B[18]) && d2x_bus_A[22]) || 
//                        (d2x_bus_A[17] && d2x_bus_A[21]);
    
//     assign LTU_A = LTU_within_A || LTU_between_XB_DA;
//     assign LTU_B = LTU_within_B || LTU_between_XA_DB;
//     assign mem_hazard = (d2x_bus_A[19] || d2x_bus_A[18]) && (d2x_bus_B[19] || d2x_bus_B[18]);

//     // Pipe X.A /B IS A LDR, which is used by a following BR insns D.A
//     wire LTBr_A, LTBr_B;
//     assign LTBr_A = d2x_bus_A[17] && ((x2m_bus_A[19] && ~x2m_bus_B[21]) | x2m_bus_B[19]);
//     assign LTBr_B = d2x_bus_B[17] && ((x2m_bus_A[19] && ~x2m_bus_B[21]) | x2m_bus_B[19]);  
   

//     // Stall Registers
//     wire [1:0] d_stall_i_A, d_stall_o_A, x_stall_i_A, x_stall_i_A_final, x_stall_o_A, m_stall_o_A;
//     wire [1:0] d_stall_i_B, d_stall_o_B, x_stall_i_B, x_stall_i_B_final, x_stall_o_B, m_stall_o_B;
//     Nbit_reg #(2, 2'b10) d_stall_reg_A (.in(d_stall_i_A), .out(d_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) x_stall_reg_A (.in(x_stall_i_A_final), .out(x_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) m_stall_reg_A (.in(x_stall_o_A), .out(m_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) w_stall_reg_A (.in(m_stall_o_A), .out(test_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     Nbit_reg #(2, 2'b10) d_stall_reg_B (.in(d_stall_i_B), .out(d_stall_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) x_stall_reg_B (.in(x_stall_i_B_final), .out(x_stall_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) m_stall_reg_B (.in(x_stall_o_B), .out(m_stall_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) w_stall_reg_B (.in(m_stall_o_B), .out(test_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     assign d_stall_i_A = (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? 2'd2 :
//                          (LTU_A || LTBr_A) ? 2'd3 :
//                          2'd0;
//     assign d_stall_i_B = (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? 2'd2 :
//                          (LTU_A || LTBr_A || B_need_A || mem_hazard) ? 2'd1 :
//                          (LTU_B || LTBr_B) ? 2'd3 :
//                          2'd0;

//     // assign d_stall_i_A =  (x_br_taken_or_ctrl_A == 1 || x_br_taken_or_ctrl_B == 1) ? 2'd2 : 2'd0;
//     // assign d_stall_i_B =  (x_br_taken_or_ctrl_B == 1 || x_br_taken_or_ctrl_B == 1) ? 2'd2 : 2'd0;

//     // assign x_stall_i_A = (LTU_A == 1) ? 2'd3 : 
//     //                       d_stall_o_A;
//     assign x_stall_i_A_final = ((d2x_pc_A == 16'h0000) || (d2x_bus_A[15:0] != 16'h0000)) ? 2'b10 : d_stall_i_A;

//     // assign x_stall_i_B = (LTU_A == 1 || B_need_A || mem_hazard) ? 2'd1 :
//     //                      (LTU_B == 1) ? 2'd3 :
//     //                      d_stall_o_B;
//     assign x_stall_i_B_final = ((d2x_pc_B == 16'h0000) || (d2x_bus_B[15:0] != 16'h0000)) ? 2'b10 : d_stall_i_B;
    
//     // PC Registers
//     wire [15:0] next_pc_A, f2d_pc_A, d_i_pc_A, d2x_pc_A, x2m_pc_A, m2w_pc_A, w_o_pc_A; 
//     wire [15:0] d_i_pc_B, d2x_pc_B, x2m_pc_B, m2w_pc_B, w_o_pc_B;
//     wire [15:0] f2d_pc_plus_one_A, f2d_pc_plus_two_A;
//     Nbit_reg #(16, 16'h8200) f_pc_reg_A (.in(next_pc_A), .out(f2d_pc_A), .clk(clk), .we(~LTU_A), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    d_pc_reg_A (.in(d_i_pc_A), .out(d2x_pc_A), .clk(clk), .we(~LTU_A), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    x_pc_reg_A (.in(d2x_pc_A), .out(x2m_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    m_pc_reg_A (.in(x2m_pc_A), .out(m2w_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    w_pc_reg_A (.in(m2w_pc_A), .out(w_o_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     Nbit_reg #(16, 16'b0)    d_pc_reg_B (.in(d_i_pc_B), .out(d2x_pc_B), .clk(clk), .we(~LTU_B), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    x_pc_reg_B (.in(d2x_pc_B), .out(x2m_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    m_pc_reg_B (.in(x2m_pc_B), .out(m2w_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    w_pc_reg_B (.in(m2w_pc_B), .out(w_o_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     cla16 Pipeline_A_PC_Inc_One(.a(f2d_pc_A), .b(16'b0), .cin(1'b1), .sum(f2d_pc_plus_one_A));
//     cla16 Pipeline_A_PC_Inc_Two(.a(f2d_pc_plus_one_A), .b(16'b0), .cin(1'b1), .sum(f2d_pc_plus_two_A));

//     wire [2:0] is_all_zero_A, is_all_zero_B;
//     wire [2:0] o_nzp_reg_val_A, o_nzp_reg_val_B;

//     assign is_all_zero_A = o_nzp_reg_val_A & x2m_bus_A[11:9];
//     assign branch_taken_A = ((is_all_zero_A != 3'b0) && (x2m_bus_A[17] == 1)) ? 1'b1 : 1'b0;
//     assign x_br_taken_or_ctrl_A = branch_taken_A || x2m_bus_A[16];

//     assign next_pc_A = (d_stall_i_A != 0) ? f2d_pc_A : 
//                         pipe_switch ? f2d_pc_plus_one_A :
//                         x_br_taken_or_ctrl_A ? o_alu_result_A :
//                         x_br_taken_or_ctrl_B ? o_alu_result_B : 
//                         f2d_pc_plus_two_A;
    
//     assign d_i_pc_A = (pipe_switch) ? d2x_pc_B :  
//                       (d_stall_i_A != 0) ? d2x_pc_A :
//                       f2d_pc_A;
//     assign d_i_pc_B = (pipe_switch) ? f2d_pc_A :  
//                       (d_stall_i_B != 0) ? d2x_pc_B :
//                       f2d_pc_plus_one_A;

//     assign is_all_zero_B = o_nzp_reg_val_B & x2m_bus_B[11:9];
//     assign branch_taken_B = ((is_all_zero_B != 3'b0) && (x2m_bus_B[17] == 1)) ? 1'b1 : 1'b0;
//     assign x_br_taken_or_ctrl_B = branch_taken_B || x2m_bus_B[16];
    
//     assign d2x_bus_A[15:0] = d2x_bus_tmp_A;

//     // Pipe Switch
//     assign d2x_bus_final_A = ((LTU_A | x_br_taken_or_ctrl_A | x_br_taken_or_ctrl_B) == 1) ? {34{1'b0}} : 
//                              d2x_bus_A;

//     assign d2x_bus_B[15:0] = d2x_bus_tmp_B;
//     assign d2x_bus_final_B = ((LTU_A | LTU_B | x_br_taken_or_ctrl_A | x_br_taken_or_ctrl_B) == 1) ? {34{1'b0}} : d2x_bus_B;

//     // Regiters for A, B, O, D //
//     wire [15:0] x_A_i_A, x_A_o_A, x_B_i_A, x_B_o_A,
//                 m_B_o_A, m_O_i_A, m_O_o_A, 
//                 w_O_o_A, w_D_i_A, w_D_o_A;
//     wire [15:0] x_A_i_B, x_A_o_B, x_B_i_B, x_B_o_B,
//                 m_B_o_B, m_O_i_B, m_O_o_B, 
//                 w_O_o_B, w_D_i_B, w_D_o_B;
//     wire [15:0] write_back_A, write_back_B;                  // Determine the value that writes back to the Regfiles //
                    
//     Nbit_reg #(16, 16'b0) x_A_reg_A (.in(x_A_i_A), .out(x_A_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) x_B_reg_A (.in(x_B_i_A), .out(x_B_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) m_B_reg_A (.in(rt_bypass_res_A), .out(m_B_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) m_O_reg_A (.in(m_O_i_A), .out(m_O_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) w_O_reg_A (.in(m_O_o_A), .out(w_O_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) w_D_reg_A (.in(i_cur_dmem_data_A), .out(w_D_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) x_A_reg_B (.in(x_A_i_B), .out(x_A_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) x_B_reg_B (.in(x_B_i_B), .out(x_B_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) m_B_reg_B (.in(rt_bypass_res_B), .out(m_B_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) m_O_reg_B (.in(m_O_i_B), .out(m_O_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) w_O_reg_B (.in(m_O_o_B), .out(w_O_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) w_D_reg_B (.in(i_cur_dmem_data_B), .out(w_D_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
//     assign  x_A_i_A = ((w_o_bus_A[27:25] == d2x_bus_A[33:31]) && w_o_bus_A[22]) ? write_back_A : o_regfile_rs_A; 
//     assign  x_B_i_A = ((w_o_bus_A[27:25] == d2x_bus_A[30:28]) && w_o_bus_A[22]) ? write_back_A : o_regfile_rt_A;
//     assign  x_A_i_B = ((w_o_bus_B[27:25] == d2x_bus_B[33:31]) && w_o_bus_B[22]) ? write_back_B : o_regfile_rs_B; 
//     assign  x_B_i_B = ((w_o_bus_B[27:25] == d2x_bus_B[30:28]) && w_o_bus_B[22]) ? write_back_B : o_regfile_rt_B;
//     assign  m_O_i_A = (d2x_bus_A[16] == 1) ? d2x_pc_A : o_alu_result_A; 
//     assign  m_O_i_B = (d2x_bus_B[16] == 1) ? d2x_pc_B : o_alu_result_B;
//     assign  write_back_A = (w_o_bus_A[19] == 1) ? w_D_o_A: w_O_o_A;
//     assign  write_back_B = (w_o_bus_B[19] == 1) ? w_D_o_B: w_O_o_B;

//     lc4_decoder Decoder_Pipe_A(
//         .r1sel(d2x_bus_A[33:31]), 
//         .r2sel(d2x_bus_A[30:28]),
//         .wsel(d2x_bus_A[27:25]),
//         .r1re(d2x_bus_A[24]),
//         .r2re(d2x_bus_A[23]),
//         .regfile_we(d2x_bus_A[22]),
//         .nzp_we(d2x_bus_A[21]), 
//         .select_pc_plus_one(d2x_bus_A[20]),
//         .is_load(d2x_bus_A[19]), 
//         .is_store(d2x_bus_A[18]),
//         .is_branch(d2x_bus_A[17]), 
//         .is_control_insn(d2x_bus_A[16]),
//         .insn(d2x_bus_A[15:0]));
    
//     lc4_decoder Decoder_Pipe_B(
//         .r1sel(d2x_bus_B[33:31]), 
//         .r2sel(d2x_bus_B[30:28]),
//         .wsel(d2x_bus_B[27:25]),
//         .r1re(d2x_bus_B[24]),
//         .r2re(d2x_bus_B[23]),
//         .regfile_we(d2x_bus_B[22]),
//         .nzp_we(d2x_bus_B[21]), 
//         .select_pc_plus_one(d2x_bus_B[20]),
//         .is_load(d2x_bus_B[19]), 
//         .is_store(d2x_bus_B[18]),
//         .is_branch(d2x_bus_B[17]), 
//         .is_control_insn(d2x_bus_B[16]),
//         .insn(d2x_bus_B[15:0]));
    
//     wire [15:0] o_regfile_rs_A, o_regfile_rs_B, o_regfile_rt_A, o_regfile_rt_B;             //output of ALU
//     wire [15:0] rs_bypass_res_A, rs_bypass_res_B, 
//                 rt_bypass_res_A, rt_bypass_res_B,
//                 wm_bypass_res_A, wm_or_mm_bypass_res_B;                
           
//     lc4_regfile_ss Superscaler_Regfile(
//         .clk(clk),
//         .gwe(gwe),
//         .rst(rst),
//         .i_rs_A(d2x_bus_A[33:31]),
//         .i_rt_A(d2x_bus_A[30:28]),
//         .o_rs_data_A(o_regfile_rs_A),
//         .o_rt_data_A(o_regfile_rt_A),
//         .i_rs_B(d2x_bus_B[33:31]),
//         .i_rt_B(d2x_bus_B[30:28]),
//         .o_rs_data_B(o_regfile_rs_B),
//         .o_rt_data_B(o_regfile_rt_B),
//         .i_rd_A(w_o_bus_A[27:25]),
//         .i_wdata_A(write_back_A),
//         .i_rd_we_A(w_o_bus_A[22]),
//         .i_rd_B(w_o_bus_B[27:25]),
//         .i_wdata_B(write_back_B),
//         .i_rd_we_B(w_o_bus_B[22]));
//     wire [15:0] o_alu_result_A, o_alu_result_B;
//     lc4_alu ALU_Pipe_A( 
//         .i_insn(x2m_bus_A[15:0]),
//         .i_pc(x2m_pc_A),
//         .i_r1data(rs_bypass_res_A),
//         .i_r2data(rt_bypass_res_A),
//         .o_result(o_alu_result_A));
    
//     lc4_alu ALU_Pipe_B( 
//         .i_insn(x2m_bus_B[15:0]),
//         .i_pc(x2m_pc_B),
//         .i_r1data(rs_bypass_res_B),
//         .i_r2data(rt_bypass_res_B),
//         .o_result(o_alu_result_B));
    
//     //  Register for dmem parameter's
//     wire [15:0] i_cur_dmem_data_A, i_cur_dmem_data_B;
//     assign test_dmem_we_A = m2w_bus_A[18];
//     assign test_dmem_we_B = m2w_bus_B[18];
//     assign o_dmem_we = test_dmem_we_A || test_dmem_we_B;
//     assign test_dmem_addr_A = ((m2w_bus_A[19] == 1) || (m2w_bus_A[18] == 1)) ? m_O_o_A : 16'b0;
//     assign test_dmem_addr_B = ((m2w_bus_B[19] == 1) || (m2w_bus_B[18] == 1)) ? m_O_o_B : 16'b0;
//     assign o_dmem_addr = test_dmem_addr_A | test_dmem_addr_B; 
//     assign i_cur_dmem_data_A = test_dmem_addr_A ? i_cur_dmem_data : 16'b0; 
//     assign i_cur_dmem_data_B = test_dmem_addr_B ? i_cur_dmem_data : 16'b0;    
//     assign test_dmem_data_A = (m2w_bus_A[19] == 1) ? i_cur_dmem_data_A :
//                               (m2w_bus_A[18] == 1) ? wm_bypass_res_A : 16'b0; 
//     assign test_dmem_data_B = (m2w_bus_B[19] == 1) ? i_cur_dmem_data_B :
//                               (m2w_bus_B[18] == 1) ? wm_or_mm_bypass_res_B : 16'b0;    
    
//     // NZP Registers //
//     Nbit_reg Superscalar_NZP_Reg_A(
//         .in(i_regfile_wdata_sign_A), 
//         .out(o_nzp_reg_val_A),
//         .clk(clk),
//         .we(x2m_bus_A[21]),
//         .gwe(gwe),
//         .rst(rst));
//     defparam Superscalar_NZP_Reg_A.n = 3;
//     Nbit_reg Superscalar_NZP_Reg_B(
//         .in(i_regfile_wdata_sign_B), 
//         .out(o_nzp_reg_val_B),
//         .clk(clk),
//         .we(x2m_bus_B[21]),
//         .gwe(gwe),
//         .rst(rst));
//     defparam Superscalar_NZP_Reg_B.n = 3;
//     // Registers for NZP
//     wire [2:0] i_regfile_wdata_sign_A, m_nzp_o_A, w_nzp_i_A,
//                i_regfile_wdata_sign_B, m_nzp_o_B, w_nzp_i_B;
//     wire [2:0] nzp_alu_A, nzp_ld_A, nzp_trap_A,
//                nzp_alu_B, nzp_ld_B, nzp_trap_B;
//     Nbit_reg #(3, 3'b0) m_nzp_reg_A (.in(i_regfile_wdata_sign_A), .out(m_nzp_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(3, 3'b0) w_nzp_reg_A (.in(w_nzp_i_A), .out(test_nzp_new_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(3, 3'b0) m_nzp_reg_B (.in(i_regfile_wdata_sign_B), .out(m_nzp_o_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(3, 3'b0) w_nzp_reg_B (.in(w_nzp_i_B), .out(test_nzp_new_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   
   
//     assign w_nzp_i_A = ((m2w_bus_A[19]==1)) ? nzp_ld_A : m_nzp_o_A;
//     assign nzp_alu_A = ($signed(o_alu_result_A) > 0) ? 3'b001 : 
//                        (o_alu_result_A == 0) ? 3'b010 : 
//                        3'b100;
//     assign nzp_ld_A = ($signed(i_cur_dmem_data_A) > 0) ? 3'b001 :
//                       (i_cur_dmem_data_A == 0) ? 3'b010 : 
//                       3'b100;  
//     assign nzp_trap_A = ($signed(x2m_pc_A) > 0) ? 3'b001:
//                         (x2m_pc_A == 0) ? 3'b010: 
//                         3'b100;  
//     assign i_regfile_wdata_sign_A = (x2m_bus_A[15:12] == 4'b1111) ? nzp_trap_A :  
//                                     ((m2w_bus_A[19] == 1) && (x_stall_o_A == 2'd3)) ? nzp_ld_A : 
//                                     nzp_alu_A;
    
//     assign w_nzp_i_B = ((m2w_bus_B[19]==1)) ? nzp_ld_B : m_nzp_o_B;
//     assign nzp_alu_B = ($signed(o_alu_result_B) > 0) ? 3'b001 : 
//                        (o_alu_result_B == 0) ? 3'b010 : 
//                        3'b100;
//     assign nzp_ld_B = ($signed(i_cur_dmem_data_B) > 0) ? 3'b001 :
//                       (i_cur_dmem_data_B == 0) ? 3'b010 : 
//                       3'b100;  
//     assign nzp_trap_B = ($signed(x2m_pc_B) > 0) ? 3'b001:
//                         (x2m_pc_B == 0) ? 3'b010: 
//                         3'b100;  
//     assign i_regfile_wdata_sign_B = (x2m_bus_B[15:12] == 4'b1111) ? nzp_trap_B :  
//                                     ((m2w_bus_B[19]==1) && (x_stall_o_B == 2'd3)) ? nzp_ld_B : 
//                                     nzp_alu_B;
    
//     // MX, WX bypass
//     wire rs_MB_XA_bypass, rs_MA_XA_bypass, rs_WB_XA_bypass, rs_WA_XA_bypass, 
//          rt_MB_XA_bypass, rt_MA_XA_bypass, rt_WB_XA_bypass, rt_WA_XA_bypass,
//          rs_MB_XB_bypass, rs_MA_XB_bypass, rs_WB_XB_bypass, rs_WA_XB_bypass,
//          rt_MB_XB_bypass, rt_MA_XB_bypass, rt_WB_XB_bypass, rt_WA_XB_bypass;
    
//     assign rs_MB_XA_bypass = (x2m_bus_A[33:31] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1);
//     assign rs_MA_XA_bypass = (x2m_bus_A[33:31] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1);
//     assign rs_WB_XA_bypass = (x2m_bus_A[33:31] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1);
//     assign rs_WA_XA_bypass = (x2m_bus_A[33:31] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1);

//     assign rt_MB_XA_bypass = (x2m_bus_A[30:28] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1);
//     assign rt_MA_XA_bypass = (x2m_bus_A[30:28] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1);
//     assign rt_WB_XA_bypass = (x2m_bus_A[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1);
//     assign rt_WA_XA_bypass = (x2m_bus_A[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1);

//     assign rs_MB_XB_bypass = (x2m_bus_B[33:31] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1);
//     assign rs_MA_XB_bypass = (x2m_bus_B[33:31] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1);
//     assign rs_WB_XB_bypass = (x2m_bus_B[33:31] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1);
//     assign rs_WA_XB_bypass = (x2m_bus_B[33:31] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1);

//     assign rt_MB_XB_bypass = (x2m_bus_B[30:28] == m2w_bus_B[27:25]) && (m2w_bus_B[22] == 1);
//     assign rt_MA_XB_bypass = (x2m_bus_B[30:28] == m2w_bus_A[27:25]) && (m2w_bus_A[22] == 1);
//     assign rt_WB_XB_bypass = (x2m_bus_B[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22] == 1);
//     assign rt_WA_XB_bypass = (x2m_bus_B[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22] == 1);
    
//     assign rs_bypass_res_A = rs_MB_XA_bypass ? m_O_o_B :
//                              rs_MA_XA_bypass ? m_O_o_A :
//                              rs_WB_XA_bypass ? write_back_B :
//                              rs_WA_XA_bypass ? write_back_A :
//                              x_A_o_A;
//     assign rt_bypass_res_A = rt_MB_XA_bypass ? m_O_o_B :
//                              rt_MA_XA_bypass ? m_O_o_A :
//                              rt_WB_XA_bypass ? write_back_B :
//                              rt_WA_XA_bypass ? write_back_A :
//                              x_B_o_A;
//     assign rs_bypass_res_B = rs_MB_XB_bypass ? m_O_o_B :
//                              rs_MA_XB_bypass ? m_O_o_A :
//                              rs_WB_XB_bypass ? write_back_B :
//                              rs_WA_XB_bypass ? write_back_A :
//                              x_A_o_B;
//     assign rt_bypass_res_B = rt_MB_XB_bypass ? m_O_o_B :
//                              rt_MA_XB_bypass ? m_O_o_A :
//                              rt_WB_XB_bypass ? write_back_B :
//                              rt_WA_XB_bypass ? write_back_A :
//                              x_B_o_B;
    
//     // WM and MM bypass
//     wire WB_MA_bypass, WA_MA_bypass, WB_MB_bypass, WA_MB_bypass, MA_MB_bypass;
//     assign WB_MA_bypass = (m2w_bus_A[18]) && (m2w_bus_A[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22]);
//     assign WA_MA_bypass = (m2w_bus_A[18]) && (m2w_bus_A[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22]);
//     assign WB_MB_bypass = (m2w_bus_B[18]) && (m2w_bus_B[30:28] == w_o_bus_B[27:25]) && (w_o_bus_B[22]);
//     assign WA_MB_bypass = (m2w_bus_B[18]) && (m2w_bus_B[30:28] == w_o_bus_A[27:25]) && (w_o_bus_A[22]);
//     assign MA_MB_bypass = (m2w_bus_B[18]) && (m2w_bus_B[30:28] == m2w_bus_A[27:25]) && (m2w_bus_A[22]);
//     assign wm_bypass_res_A = WB_MA_bypass ? write_back_B :
//                              WA_MA_bypass ? write_back_A :
//                              m_B_o_A;
//     assign wm_or_mm_bypass_res_B = WB_MB_bypass ? write_back_B :
//                              WA_MB_bypass ? write_back_A :
//                              MA_MB_bypass ? m_B_o_A :
//                              m_B_o_B;
    
//     assign o_cur_pc = f2d_pc_A;
//     assign o_dmem_towrite = test_dmem_addr_A ? wm_bypass_res_A : wm_or_mm_bypass_res_B;
//     assign test_cur_pc_A = w_o_pc_A;
//     assign test_cur_pc_B = w_o_pc_B;
//     assign test_cur_insn_A = w_o_bus_A[15:0];
//     assign test_cur_insn_B = w_o_bus_B[15:0];
//     assign test_regfile_we_A = w_o_bus_A[22];
//     assign test_regfile_we_B = w_o_bus_B[22];
//     assign test_regfile_wsel_A = w_o_bus_A[27:25];
//     assign test_regfile_wsel_B = w_o_bus_B[27:25];
//     assign test_regfile_data_A =  write_back_A;
//     assign test_regfile_data_B =  write_back_B;
//     assign test_nzp_we_A = w_o_bus_A[21];
//     assign test_nzp_we_B = w_o_bus_B[21];
//    /* Add $display(...) calls in the always block below to
//     * print out debug information at the end of every cycle.
//     *
//     * You may also use if statements inside the always block
//     * to conditionally print out information.
//     */
//    always @(posedge gwe) begin
//        if ($time >= 1 && $time <=500) begin
//        $display("=============================================");
//        $display("Time = %d, stall_A = %h, stall_B = %h, o_cur_pc = %h, next_pc_A %h, d_i_pc_A %h, d_i_pc_B %h, i_cur_insn_A = %h, i_cur_insn_B = %h, test_cur_insn_A = %h, test_cur_insn_B = %h \n \n ", 
//                 $time, test_stall_A, test_stall_B, o_cur_pc, next_pc_A, d_i_pc_A, d_i_pc_B, i_cur_insn_A, i_cur_insn_B, test_cur_insn_A, test_cur_insn_B);
//        $display("x_stall_i_A %d, x_stall_i_B %d, x_br_taken_or_ctrl_A %b, x_br_taken_or_ctrl_B %b, LTU_A %b, LTU_B %b, B_need_A %b, d2x_bus_A[16] %b, d2x_bus_A[17] %b, d2x_bus_A %b, mem_hazard %b \n \n", 
//                 x_stall_i_A, x_stall_i_B, x_br_taken_or_ctrl_A, x_br_taken_or_ctrl_B, LTU_A, LTU_B, B_need_A, d2x_bus_A[16], d2x_bus_A[17], (d2x_bus_A[15:0] != 16'h0000), mem_hazard);
//        end
//       // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
//       // if (o_dmem_we)
//       //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);
//       // Start each $display() format string with a %d argument for time
//       // it will make the output easier to read.  Use %b, %h, and %d
//       // for binary, hex, and decimal output of additional variables.
//       // You do not need to add a \n at the end of your format string.
//       // $display("%d ...", $time);
//       // Try adding a $display() call that prints out the PCs of
//       // each pipeline stage in hex.  Then you can easily look up the
//       // instructions in the .asm files in test_data.
//       // basic if syntax:
//       // if (cond) begin
//       //    ...;
//       //    ...;
//       // end
//       // Set a breakpoint on the empty $display() below
//       // to step through your pipeline cycle-by-cycle.
//       // You'll need to rewind the simulation to start
//       // stepping from the beginning.
//       // You can also simulate for XXX ns, then set the
//       // breakpoint to start stepping midway through the
//       // testbench.  Use the $time printouts you added above (!)
//       // to figure out when your problem instruction first
//       // enters the fetch stage.  Rewind your simulation,
//       // run it for that many nanoseconds, then set
//       // the breakpoint.
//       // In the objects view, you can change the values to
//       // hexadecimal by selecting all signals (Ctrl-A),
//       // then right-click, and select Radix->Hexadecimal.
//       // To see the values of wires within a module, select
//       // the module in the hierarchy in the "Scopes" pane.
//       // The Objects pane will update to display the wires
//       // in that module.
//       //$display();
//    end
// endmodule