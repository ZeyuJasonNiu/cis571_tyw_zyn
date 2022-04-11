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


    // X register wires
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


    // M register Wires
    // A
    wire [15:0] M_PC_A;
    wire [15:0] M_ALU_A;
    wire [15:0] M_R2_A;

    wire [2:0] M_Rs_A;
    wire [2:0] M_Rt_A;
    wire [2:0] M_Rd_A;

    wire [15:0] M_INSN_A;
    wire M_R1RE_A;
    wire M_R2RE_A;
    wire M_Stall_A;

    wire M_Ctrl_Update_NZP_A;
    wire [2:0] Mem_NZP_Update;
    wire [2:0]  M_Ctrl_NZP_out_A;

    // B
    wire [15:0] M_PC_B;
    wire [15:0] M_ALU_B;
    wire [15:0] M_R2_B;

    wire [2:0] M_Rs_B;
    wire [2:0] M_Rt_B;
    wire [2:0] M_Rd_B;

    wire [15:0] M_INSN_B;
    wire M_R1RE_B;
    wire M_R2RE_B;
    wire M_Stall_B;
    wire M_Ctrl_Update_NZP_B;
    wire [2:0]  M_Ctrl_NZP_out_B;


    // PC
    // pc wires attached to the PC register's ports
    wire [15:0]   pc;      // Current program counter (read out from pc_reg)
    wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

    // WHATS NEXT PC
    assign next_pc = Stall_A ? pc :
                    Pipe_Switch ? PC_ADD_ONE_A :
                    X_Ctrl_PC_JMP_A ? O_ALU_A :
                    X_Ctrl_PC_JMP_B ? O_ALU_B : 
                    PC_ADD_ONE_B ;

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


    // ************ PC registers ************ //
    // Program counter register, starts at 8200h at bootup
    Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'h0000) D_PC_Reg_A(.in(D_I_PC_A), .out( D_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_A | rst ));
    Nbit_reg #(16, 16'h0000) X_PC_Reg_A(.in(D_PC_A), .out( X_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
    Nbit_reg #(16, 16'h0000) M_PC_Reg_A(.in(X_PC_A), .out( M_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( M_Flush_A | rst ));
    Nbit_reg #(16, 16'h0000) W_PC_Reg_A(.in(M_PC_A), .out( W_PC_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));

    Nbit_reg #(16, 16'h0000) D_PC_Reg_B(.in(D_I_PC_B), .out( D_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_B | rst ));
    Nbit_reg #(16, 16'h0000) X_PC_Reg_B(.in(D_PC_B), .out( X_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
    Nbit_reg #(16, 16'h0000) M_PC_Reg_B(.in(X_PC_B), .out( M_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( M_Flush_B | rst ));
    Nbit_reg #(16, 16'h0000) W_PC_Reg_B(.in(M_PC_B), .out( W_PC_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
        
    assign D_I_PC_A = (Pipe_Switch) ? D_PC_B : (Stall_A) ? D_PC_A : pc;
    assign D_I_PC_B = (Pipe_Switch) ? pc :(Stall_B) ? D_PC_B : PC_ADD_ONE_A;



    // ************ Instruction registers ************ //                    
    Nbit_reg #(16, 16'h0000) D_insn_Reg_A(.in(F_INSN_A), .out( D_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_A | rst  ));
    Nbit_reg #(16, 16'h0000) X_insn_Reg_A(.in(D_INSN_A), .out( X_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_A | rst ));
    Nbit_reg #(16, 16'h0000) M_insn_Reg_A(.in(X_INSN_A), .out( M_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(16, 16'h0000) W_insn_Reg_A(.in(M_INSN_A), .out( W_INSN_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));

    Nbit_reg #(16, 16'h0000) D_insn_Reg_B(.in(F_INSN_B), .out( D_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_B | rst  ));
    Nbit_reg #(16, 16'h0000) X_insn_Reg_B(.in(D_INSN_B), .out( X_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush_B | rst ));
    Nbit_reg #(16, 16'h0000) M_insn_Reg_B(.in(X_INSN_B), .out( M_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(16, 16'h0000) W_insn_Reg_B(.in(M_INSN_B), .out( W_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));



    // ************ PC+1 registers ************ //
    Nbit_reg #(16, 16'h0000) D_PC_ADD_ONE_Reg_A(.in(PC_ADD_ONE_A), .out( D_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_A | rst  ));        
    Nbit_reg #(16, 16'h0000) D_PC_ADD_ONE_Reg_B(.in(PC_ADD_ONE_B), .out( D_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush_B | rst  ));

      
   
    //************ Decoders ************//
    wire [2:0] Rd_A, Rd_B; // raw rd output from decoder; 
    wire [2:0] D_Rd_A, D_Rd_B; // valid only when RF_WE is enabled; to avoid false WX by pass
    wire [2:0] D_Rs_A, D_Rt_A, D_Rs_B, D_Rt_B;
    wire R1RE_A, R2RE_A, R1RE_B, R2RE_B;

    lc4_decoder decode_A(.insn(D_INSN_A),               // instruction
                    .r1sel(D_Rs_A),              // rs
                    .r1re(R1RE_A),               // does this instruction read from rs?
                    .r2sel(D_Rt_A),              // rt
                    .r2re(R2RE_A),               // does this instruction read from rt?
                    .wsel(Rd_A),                 // rd
                    .regfile_we(D_Ctrl_RF_WE_A),         // does this instruction write to rd?
                    .nzp_we(D_Ctrl_Update_NZP_A),             // does this instruction write the NZP bits?
                    .select_pc_plus_one(D_Ctrl_W_R7_A), // write PC+1 to the regfile?
                    .is_load(D_insn_LDR_A),            // is this a load instruction?
                    .is_store(D_insn_STR_A),           // is this a store instruction?
                    .is_branch(D_insn_BR_A),          // is this a branch instruction?
                    .is_control_insn(D_Ctrl_Control_insn_A)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                    );

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

    assign D_Rd_A = (D_Ctrl_RF_WE_A)? Rd_A:3'b000;
    assign D_Rd_B = (D_Ctrl_RF_WE_B)? Rd_B:3'b000;



    //************ Superscaler Regfiles ************//
    wire [15:0] I_RF_data_A, X_RF_data_A, M_RF_data_A, W_RF_data_A;
    wire [15:0] I_RF_data_B, X_RF_data_B, M_RF_data_B, W_RF_data_B;

    wire [15:0] D_O_RF_R1_A, D_O_RF_R2_A;
    wire [15:0] D_O_RF_R1_B, D_O_RF_R2_B;

    wire [2:0] In_Rd_A;
    wire [2:0] In_Rd_B;

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

    assign In_Rd_A = (W_Ctrl_W_R7_A) ? 3'h7 : W_Rd_A;
    assign In_Rd_B = (W_Ctrl_W_R7_B) ? 3'h7 : W_Rd_B;
    assign I_RF_data_A = W_Ctrl_W_R7_A ? W_PC_ADD_ONE_A : W_RF_IN_data_A;
    assign I_RF_data_B = W_Ctrl_W_R7_B ? W_PC_ADD_ONE_B : W_RF_IN_data_B;



    // X registers

    
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



    //************ Bypass Classifiers (WMX) ************//
    // No passing: 0b000
    // MX from A: 0b001
    // WX from A: 0b010
    // MX from B: 0b101
    // WX from B: 0b110

    // Wires for ALUs
    wire [2:0] WMX_Bypass_1_A, WMX_Bypass_2_A;
    wire [15:0] ALU_in1_A, ALU_in2_A;
    wire [15:0] O_ALU_A;

    wire [2:0] WMX_Bypass_1_B, WMX_Bypass_2_B;
    wire [15:0] ALU_in1_B, ALU_in2_B;
    wire [15:0] O_ALU_B;

    // Pipe A
    // input 1 of ALU for A:
    assign WMX_Bypass_1_A = ((X_Rs_A == M_Rd_B) & M_Ctrl_RF_WE_B & X_R1RE_A) ? 3'b101 :
                            ((X_Rs_A == M_Rd_A) & M_Ctrl_RF_WE_A & X_R1RE_A) ? 3'b001 :
                            ((X_Rs_A == W_Rd_B) & W_Ctrl_RF_WE_B & X_R1RE_A) ? 3'b110 :
                            ((X_Rs_A == W_Rd_A) & W_Ctrl_RF_WE_A & X_R1RE_A) ? 3'b010 :
                            3'b000;
    assign WMX_Bypass_2_A = 
                            ((X_Rt_A == M_Rd_B) & M_Ctrl_RF_WE_B & X_R1RE_A) ? 3'b101 :
                            ((X_Rt_A == M_Rd_A) & M_Ctrl_RF_WE_A & X_R1RE_A) ? 3'b001 :
                            ((X_Rt_A == W_Rd_B) & W_Ctrl_RF_WE_B & X_R1RE_A) ? 3'b110 :
                            ((X_Rt_A == W_Rd_A) & W_Ctrl_RF_WE_A & X_R1RE_A) ? 3'b010 :
                            3'b000;

    assign ALU_in1_A =  (WMX_Bypass_1_A == 3'b000)? X_R1_A:
                        (WMX_Bypass_1_A == 3'b001)? M_ALU_A:
                        (WMX_Bypass_1_A == 3'b010)? I_RF_data_A:
                        (WMX_Bypass_1_A == 3'b101)? M_ALU_B:
                        (WMX_Bypass_1_A == 3'b110)? I_RF_data_B:
                        16'h0000 ;

    assign ALU_in2_A =  (WMX_Bypass_2_A == 3'b000)? X_R2_A:
                        (WMX_Bypass_2_A == 3'b001)? M_ALU_A:
                        (WMX_Bypass_2_A == 3'b010)? I_RF_data_A:
                        (WMX_Bypass_2_A == 3'b101)? M_ALU_B:
                        (WMX_Bypass_2_A == 3'b110)? I_RF_data_B:
                        16'h0000 ;

    // Pipe B (Applying Same logic from A)
    assign WMX_Bypass_1_B = ((X_Rs_B == M_Rd_B) & M_Ctrl_RF_WE_B & X_R1RE_B) ? 3'b101 :
                            ((X_Rs_B == M_Rd_A) & M_Ctrl_RF_WE_A & X_R1RE_B) ? 3'b001 :
                            ((X_Rs_B == W_Rd_B) & W_Ctrl_RF_WE_B & X_R1RE_B) ? 3'b110 :
                            ((X_Rs_B == W_Rd_A) & W_Ctrl_RF_WE_A & X_R1RE_B) ? 3'b010 :
                            3'b000;
    assign WMX_Bypass_2_B =  ((X_Rt_B == M_Rd_B) & M_Ctrl_RF_WE_B & X_R1RE_B) ? 3'b101 :
                            ((X_Rt_B == M_Rd_A) & M_Ctrl_RF_WE_A & X_R1RE_B) ? 3'b001 :
                            ((X_Rt_B == W_Rd_B) & W_Ctrl_RF_WE_B & X_R1RE_B) ? 3'b110 :
                            ((X_Rt_B == W_Rd_A) & W_Ctrl_RF_WE_A & X_R1RE_B) ? 3'b010 :
                            3'b000;

    assign ALU_in1_B =  (WMX_Bypass_1_B == 3'b000)? X_R1_B:
                        (WMX_Bypass_1_B == 3'b001)? M_ALU_A:
                        (WMX_Bypass_1_B == 3'b010)? I_RF_data_A:
                        (WMX_Bypass_1_B == 3'b101)? M_ALU_B:
                        (WMX_Bypass_1_B == 3'b110)? I_RF_data_B:
                        16'h0000 ;

    assign ALU_in2_B =  (WMX_Bypass_2_B == 3'b000)? X_R2_B:
                        (WMX_Bypass_2_B == 3'b001)? M_ALU_A:
                        (WMX_Bypass_2_B == 3'b010)? I_RF_data_A:
                        (WMX_Bypass_2_B == 3'b101)? M_ALU_B:
                        (WMX_Bypass_2_B == 3'b110)? I_RF_data_B:
                        16'h0000 ;

    wire [15:0] W_RF_IN_data_A;
    wire [15:0] M_PC_ADD_ONE_A;
    wire [15:0] W_RF_IN_data_B;
    wire [15:0] M_PC_ADD_ONE_B;



    //************ ALU for Pipe-A and Piep-B ************//
    lc4_alu myALU_A(.i_insn(X_INSN_A),
                .i_pc(X_PC_A),
                .i_r1data(ALU_in1_A),
                .i_r2data(ALU_in2_A),
                .o_result(O_ALU_A));

    lc4_alu myALU_B(.i_insn(X_INSN_B),
                .i_pc(X_PC_B),
                .i_r1data(ALU_in1_B),
                .i_r2data(ALU_in2_B),
                .o_result(O_ALU_B));




    // M register
    // A

    assign M_Flush_A = 1'b0;
    Nbit_reg #(16, 16'h0000) M_ALU_Reg_A(.in(O_ALU_A), .out( M_ALU_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(16, 16'h0000) M_R2_Reg_A(.in(ALU_in2_A), .out( M_R2_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(16, 16'h0000) M_PC_ADD_One_Reg_A(.in(X_PC_ADD_ONE_A), .out( M_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(16, 16'h0000) M_RF_Data_Reg_A(.in(X_RF_data_A), .out( M_RF_data_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));


    Nbit_reg #(1, 1'b0) M_STR_Reg_A(.in(X_insn_STR_A), .out( M_insn_STR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(1, 1'b0) M_LDR_Reg_A(.in(X_insn_LDR_A), .out( M_insn_LDR_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));


    Nbit_reg #(1, 1'b0) M_R1RE_Reg_A(.in(X_R1RE_A), .out( M_R1RE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(1, 1'b0) M_R2RE_Reg_A(.in(X_R2RE_A), .out( M_R2RE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));


    Nbit_reg #(1, 1'b0) M_Stall_Sig_Reg_A(.in(Stall_A), .out( M_Stall_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));


    Nbit_reg #(1, 1'b0) M_CTRL_W_R7_Reg_A(.in(X_Ctrl_W_R7_A), .out( M_Ctrl_W_R7_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(1, 1'b0) M_CTRL_RF_WE_Reg_A(.in(X_Ctrl_RF_WE_A), .out( M_Ctrl_RF_WE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    

    Nbit_reg #(1, 1'b0) M_CTRL_Update_NZP_Reg_A(.in(X_Ctrl_Update_NZP_A), .out( M_Ctrl_Update_NZP_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    
    assign M_Ctrl_NZP_A = (M_insn_LDR_A)? Mem_NZP_Update : M_Ctrl_NZP_out_A;
    Nbit_reg #(3, 3'b000) M_Ctrl_NZP_Reg_A(.in(Ctrl_NZP_A), .out( M_Ctrl_NZP_out_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(3, 3'b000) M_Rs_Reg_A(.in(X_Rs_A), .out( M_Rs_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(3, 3'b000) M_Rt_Reg_A(.in(X_Rt_A), .out( M_Rt_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));
    Nbit_reg #(3, 3'b000) M_Rd_Reg_A(.in(X_Rd_A), .out( M_Rd_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_A | rst  ));

    

    assign M_Flush_B = 1'b0;
    Nbit_reg #(16, 16'h0000) M_ALU_Reg_B(.in(O_ALU_B), .out( M_ALU_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(16, 16'h0000) M_R2_Reg_B(.in(ALU_in2_B), .out( M_R2_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(16, 16'h0000) M_PC_ADD_One_Reg_B(.in(X_PC_ADD_ONE_B), .out( M_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(16, 16'h0000) M_INSN_Reg_B(.in(X_INSN_B), .out( M_INSN_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(16, 16'h0000) M_RF_Data_Reg_B(.in(X_RF_data_B), .out( M_RF_data_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


    Nbit_reg #(1, 1'b0) M_STR_Reg_B(.in(X_insn_STR_B), .out( M_insn_STR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(1, 1'b0) M_LDR_Reg_B(.in(X_insn_LDR_B), .out( M_insn_LDR_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


    Nbit_reg #(1, 1'b0) M_R1RE_Reg_B(.in(X_R1RE_B), .out( M_R1RE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(1, 1'b0) M_R2RE_Reg_B(.in(X_R2RE_B), .out( M_R2RE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));

    
    Nbit_reg #(1, 1'b0) M_Stall_Sig_Reg_B(.in(Stall_B), .out( M_Stall_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


    Nbit_reg #(1, 1'b0) M_CTRL_W_R7_Reg_B(.in(X_Ctrl_W_R7_B), .out( M_Ctrl_W_R7_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(1, 1'b0) M_CTRL_RF_WE_Reg_B(.in(X_Ctrl_RF_WE_B), .out( M_Ctrl_RF_WE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
        

    Nbit_reg #(1, 1'b0) M_CTRL_Update_NZP_Reg_B(.in(X_Ctrl_Update_NZP_B), .out( M_Ctrl_Update_NZP_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    
    assign M_Ctrl_NZP_B = (M_insn_LDR_B)? Mem_NZP_Update : M_Ctrl_NZP_out_B;
    Nbit_reg #(3, 3'b000) M_Ctrl_NZP_Reg_B(.in(Ctrl_NZP_B), .out( M_Ctrl_NZP_out_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(3, 3'b000) M_Rs_Reg_B(.in(X_Rs_B), .out( M_Rs_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(3, 3'b000) M_Rt_Reg_B(.in(X_Rt_B), .out( M_Rt_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));
    Nbit_reg #(3, 3'b000) M_Rd_Reg_B(.in(X_Rd_B), .out( M_Rd_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush_B | rst  ));


    // memory

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
    assign MM_Bypass = M_insn_STR_B & (M_Rd_B == M_Rd_A);
    // WM bypass
    // no bypassing 2'b00
    // A bypassing 2'b01
    // B bypassing 2'b10
    wire [15:0] o_dmem_towrite_A;
    wire [15:0] o_dmem_towrite_B;   
    wire WM_Bypass_A;
    assign WM_Bypass_A = (M_insn_STR_A & W_insn_LDR_A & (M_Rt_A == W_Rd_A))? 2'b01 :
                            (M_insn_STR_A & W_insn_LDR_B & (M_Rt_A == W_Rd_B))? 2'b10 : 2'b00;

    assign o_dmem_towrite_A = (WM_Bypass_A == 2'b01)? W_RF_IN_data_A: 
                            (WM_Bypass_A == 2'b10)? W_RF_IN_data_B: 
                            (M_insn_STR_A) ? M_R2_A:
                            16'h0000;

    wire WM_Bypass_B;
    assign WM_Bypass_B = (M_insn_STR_B & W_insn_LDR_A & (M_Rt_B == W_Rd_A))? 2'b01 :
                            (M_insn_STR_B & W_insn_LDR_B & (M_Rt_B == W_Rd_B))? 2'b10 : 2'b00;
    assign o_dmem_towrite_B = (WM_Bypass_B == 2'b01)? W_RF_IN_data_A:
                            (WM_Bypass_B == 2'b10)? W_RF_IN_data_B:
                                (MM_Bypass) ? M_ALU_A :
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
    Nbit_reg #(16, 16'h0000) W_ALU_Reg_A(.in(M_ALU_A), .out( W_ALU_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
    Nbit_reg #(16, 16'h0000) W_MEM_Reg_A(.in(O_Mem), .out( W_Mem_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
    Nbit_reg #(16, 16'h0000) W_PC_ADD_One_Reg_A(.in(M_PC_ADD_ONE_A), .out( W_PC_ADD_ONE_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_A ));
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
    Nbit_reg #(16, 16'h0000) W_BLU_Reg_B(.in(M_ALU_B), .out( W_ALU_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
    Nbit_reg #(16, 16'h0000) W_MEM_Reg_B(.in(O_Mem), .out( W_Mem_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
    Nbit_reg #(16, 16'h0000) W_PC_ADD_One_Reg_B(.in(M_PC_ADD_ONE_B), .out( W_PC_ADD_ONE_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush_B ));
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



    //************ NZP Register and NZP update ************//
    // Ctrl_NZP are the new nzp bits
    wire [2:0] Ctrl_NZP_A, M_Ctrl_NZP_A, W_Ctrl_NZP_A, NZP_A;    
    wire [2:0] Ctrl_NZP_B, M_Ctrl_NZP_B, W_Ctrl_NZP_B, NZP_B;

    wire X_NZP_WE_A;
    wire X_NZP_WE_B; 

    wire signed [15:0] NZP_Data_A;
    wire signed [15:0] NZP_Data_B;

    Nbit_reg #(3, 3'b000) nzp_reg_A (.in(Ctrl_NZP_A), .out(NZP_A), .clk(clk), .we(X_NZP_WE_A), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'b000) nzp_reg_B (.in(Ctrl_NZP_B), .out(NZP_B), .clk(clk), .we(X_NZP_WE_B), .gwe(gwe), .rst(rst));

    assign X_NZP_WE_A = X_Ctrl_Update_NZP_A |  M_Stall_A;
    assign Ctrl_NZP_A[2] = (NZP_Data_A[15] == 1'b1)? 1'b1 : 1'b0; // N
    assign Ctrl_NZP_A[1] = (NZP_Data_A == 16'h0000)? 1'b1 : 1'b0; // Z
    assign Ctrl_NZP_A[0] = (NZP_Data_A > $signed(16'h0000))? 1'b1 : 1'b0;   // P
    assign NZP_Data_A = M_Stall_A ? O_Mem : 
                    X_Ctrl_W_R7_A ? X_PC_ADD_ONE_A : O_ALU_A;

    assign X_NZP_WE_B = X_Ctrl_Update_NZP_B |  M_Stall_B;
    assign Ctrl_NZP_B[2] = (NZP_Data_B[15] == 1'b1)? 1'b1 : 1'b0; // N
    assign Ctrl_NZP_B[1] = (NZP_Data_B == 16'h0000)? 1'b1 : 1'b0; // Z
    assign Ctrl_NZP_B[0] = (NZP_Data_B > $signed(16'h0000))? 1'b1 : 1'b0;   // P
    assign NZP_Data_B = M_Stall_B ? O_Mem : 
                    X_Ctrl_W_R7_B ? X_PC_ADD_ONE_B : O_ALU_B;

    // updating M_Ctrl_NZP based on Mem output
    wire signed [15:0] mem_NZP_Data;
    assign mem_NZP_Data = O_Mem;
    assign Mem_NZP_Update[2] = (mem_NZP_Data[15] == 1'b1)? 1'b1 : 1'b0; // N
    assign Mem_NZP_Update[1] = (mem_NZP_Data == 16'h0000)? 1'b1 : 1'b0; // Z
    assign Mem_NZP_Update[0] = (mem_NZP_Data > $signed(16'h0000))? 1'b1 : 1'b0;   // P   



    //************ Branch Operation Classifier ************//
    wire[2:0] sub_op_A, sub_op_B;

    assign sub_op_A = X_INSN_A[11:9];
    assign sub_op_B = X_INSN_B[11:9];

    wire sub_op_NOP_A = (sub_op_A == 3'b000);
    wire sub_op_BRp_A = (sub_op_A == 3'b001);
    wire sub_op_BRz_A = (sub_op_A == 3'b010);
    wire sub_op_BRzp_A = (sub_op_A == 3'b011);
    wire sub_op_BRn_A = (sub_op_A == 3'b100);
    wire sub_op_BRnp_A = (sub_op_A == 3'b101);
    wire sub_op_BRnz_A = (sub_op_A == 3'b110);
    wire sub_op_BRnzp_A = (sub_op_A == 3'b111);

    wire sub_op_NOP_B = (sub_op_B == 3'b000);
    wire sub_op_BRp_B = (sub_op_B == 3'b001);
    wire sub_op_BRz_B = (sub_op_B == 3'b010);
    wire sub_op_BRzp_B = (sub_op_B == 3'b011);
    wire sub_op_BRn_B = (sub_op_B == 3'b100);
    wire sub_op_BRnp_B = (sub_op_B == 3'b101);
    wire sub_op_BRnz_B = (sub_op_B == 3'b110);
    wire sub_op_BRnzp_B = (sub_op_B == 3'b111); 

    assign X_Ctrl_BR_JMP_A = (NZP_A[0] & sub_op_BRp_A) | (NZP_A[1] & sub_op_BRz_A) | (NZP_A[2] & sub_op_BRn_A) | 
                            ((NZP_A[0]|NZP_A[1]) & sub_op_BRzp_A) | ((NZP_A[0]|NZP_A[2]) & sub_op_BRnp_A) | ((NZP_A[1]|NZP_A[2]) & sub_op_BRnz_A) | ((NZP_A[1]|NZP_A[0]|NZP_A[2]) & sub_op_BRnzp_A);
    assign X_Ctrl_PC_JMP_A = (X_insn_BR_A & X_Ctrl_BR_JMP_A) | X_Ctrl_Control_insn_A;

    assign X_Ctrl_BR_JMP_B = (NZP_B[0] & sub_op_BRp_B) | (NZP_B[1] & sub_op_BRz_B) | (NZP_B[2] & sub_op_BRn_B) | 
                            ((NZP_B[0]|NZP_B[1]) & sub_op_BRzp_B) | ((NZP_B[0]|NZP_B[2]) & sub_op_BRnp_B) | ((NZP_B[1]|NZP_B[2]) & sub_op_BRnz_B) | ((NZP_B[1]|NZP_B[0]|NZP_B[2]) & sub_op_BRnzp_B);
    assign X_Ctrl_PC_JMP_B = (X_insn_BR_B & X_Ctrl_BR_JMP_B) | X_Ctrl_Control_insn_B;



    //  ************  LTU Dependence Classifier  ************ //
    wire A_LTU_dependence, B_LTU_dependence, AB_LTU_dependence, AB_Structural_hazard;
    wire A_Load_to_Branch, B_Load_to_Branch;

    // 1. A LTU DX dependence; from A or B
    assign A_LTU_dependence = ((X_insn_LDR_A & (((D_Rs_A == X_Rd_A) & R1RE_A) | ((D_Rt_A == X_Rd_A) & !D_insn_STR_A &R2RE_A)) ) 
                            & (X_Rd_A != X_Rd_B))                          // Nullified
                            | ((X_insn_LDR_A & (((D_Rs_B == X_Rd_A) & R1RE_B) | ((D_Rt_B == X_Rd_A) & !D_insn_STR_B &R2RE_B)) ) 
                            & (X_Rd_A != X_Rd_B) & (X_Rd_A != D_Rd_A) );          // Nullified                            ; 
    // 2. B LTU DX dependence; from A or B
    assign B_LTU_dependence = (X_insn_LDR_B & (((D_Rs_A == X_Rd_B) & R1RE_A) | ((D_Rt_A == X_Rd_B) & !D_insn_STR_A &R2RE_A)) )
                            | ((X_insn_LDR_B & (((D_Rs_B == X_Rd_B) & R1RE_B) | ((D_Rt_B == X_Rd_B) & !D_insn_STR_B &R2RE_B)) ) 
                            & (X_Rd_B != D_Rd_B))// Nullified;  
                            & (D_Rd_A != D_Rt_A) & (X_Rd_A != D_Rs_A);
    // 3. A,B Decode LTU dependence (B is the insn following A, and requires data from A)
    assign AB_LTU_dependence = ((D_Rs_B == D_Rd_A) & R1RE_B & D_Ctrl_RF_WE_A) | ((D_Rt_B == D_Rd_A) & R2RE_B & D_Ctrl_RF_WE_A);
    // 4. Structural Hazard   
    assign AB_Structural_hazard = (D_insn_LDR_A | D_insn_STR_A) & (D_insn_LDR_B | D_insn_STR_B);                 
    
    // Load-to-branch cases //
    assign A_Load_to_Branch = D_insn_BR_A & X_insn_LDR_A;
    assign B_Load_to_Branch = D_insn_BR_B & X_insn_LDR_B; 



    // ************ pipeline switching ************ //
    wire Pipe_Switch;
    assign Pipe_Switch = ~Stall_A & ((AB_LTU_dependence | AB_Structural_hazard) | (B_LTU_dependence & ~AB_LTU_dependence & ~AB_Structural_hazard) | B_Load_to_Branch);


 
    // ************ Stall Registers ************ //
    wire [1:0]  D_Stall_out_bits_A, D_Stall_in_bits_A, X_Stall_in_bits_A, X_Stall_out_bits_A,
                M_Stall_in_bits_A, M_Stall_out_bits_A, W_Stall_in_bits_A, W_Stall_out_bits_A;
    wire [1:0]  D_Stall_in_bits_B, D_Stall_out_bits_B, X_Stall_in_bits_B, X_Stall_out_bits_B,   
                M_Stall_in_bits_B, M_Stall_out_bits_B, W_Stall_in_bits_B, W_Stall_out_bits_B;
    wire [2:0] Stall_bits_A, Stall_bits_B;
    wire Stall_A, Stall_B;

    Nbit_reg #(2, 2'b10) D_Stall_Reg_A(.in(D_Stall_in_bits_A), .out( D_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
    Nbit_reg #(2, 2'b10) X_Stall_Reg_A(.in(X_Stall_in_bits_A), .out( X_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
    Nbit_reg #(2, 2'b10) M_Stall_Reg_A(.in(M_Stall_in_bits_A), .out( M_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
    Nbit_reg #(2, 2'b10) W_Stall_Reg_A(.in(W_Stall_in_bits_A), .out( W_Stall_out_bits_A ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
 
    Nbit_reg #(2, 2'b10) D_Stall_Reg_B(.in(D_Stall_in_bits_B), .out( D_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
    Nbit_reg #(2, 2'b10) X_Stall_Reg_B(.in(X_Stall_in_bits_B), .out( X_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
    Nbit_reg #(2, 2'b10) M_Stall_Reg_B(.in(M_Stall_in_bits_B), .out( M_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
    Nbit_reg #(2, 2'b10) W_Stall_Reg_B(.in(W_Stall_in_bits_B), .out( W_Stall_out_bits_B ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));

    // Stall logic classifier //
    assign Stall_bits_A =   (A_LTU_dependence) ? 2'b11:
                            (A_Load_to_Branch) ? 2'b10:
                            2'b00 ;
    assign Stall_bits_B =   (A_LTU_dependence) ? 2'b01:
                            (AB_LTU_dependence | AB_Structural_hazard) ? 2'b01:
                            (B_Load_to_Branch) ? 2'b10:
                            2'b00 ;
    
    assign Stall_A =    (Stall_bits_A == 2'b11) | (Stall_bits_A == 2'b01) | A_Load_to_Branch;
    assign Stall_B =    (Stall_bits_B == 2'b11) | (Stall_bits_B == 2'b01) | A_Load_to_Branch | B_Load_to_Branch;


    assign X_Stall_in_bits_A = (D_INSN_A != 16'h0000) ? Stall_bits_A : 2'b10;
    assign M_Stall_in_bits_A =  X_Stall_out_bits_A;   
    assign W_Stall_in_bits_A = M_Stall_out_bits_A;   
    assign test_stall_A = W_Stall_out_bits_A;
    assign D_Stall_in_bits_A =  Stall_bits_A; 

    assign D_Stall_in_bits_B =  Stall_bits_B;
    assign X_Stall_in_bits_B = (D_INSN_B != 16'h0000) ? Stall_bits_B : 2'b10;
    assign M_Stall_in_bits_B =  X_Stall_out_bits_B;   
    assign W_Stall_in_bits_B = M_Stall_out_bits_B;   
    assign test_stall_B = W_Stall_out_bits_B; 


    // ************ Flush Logics ************ //
    // Flush in D/X happens when mis-prediction/pipe switch occurs
    wire D_Flush_A, X_Flush_A, M_Flush_A, W_Flush_A;
    wire D_Flush_B, X_Flush_B, M_Flush_B, W_Flush_B;

    assign D_Flush_A = X_Ctrl_PC_JMP_A;
    assign D_Flush_B = X_Ctrl_PC_JMP_B;
    assign X_Flush_A = Stall_A | X_Ctrl_PC_JMP_A;
    assign X_Flush_B = Stall_B | X_Ctrl_PC_JMP_B | Pipe_Switch;



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
        if ($time >= 600 && $time <=1200) begin
        $display("=============================================");
        $display("Time = %d, o_cur_pc = %h, next_pc %h, i_cur_insn_A = %h, i_cur_insn_B = %h, test_cur_insn_A = %h, test_cur_insn_B = %h \n \n ", 
                $time, o_cur_pc, next_pc, i_cur_insn_A, i_cur_insn_B, test_cur_insn_A, test_cur_insn_B);
        $display("test_regfile_data_A %h, test_regfile_data_B %h, i_cur_dmem_data %h, o_alu_result_A %h, o_alu_result_B %h \n \n", 
                test_regfile_data_A, test_regfile_data_B, i_cur_dmem_data, O_ALU_A, O_ALU_B);
       end
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
      // $display("X_Ctrl_PC_JMP_B: %h next_pc: %h", X_Ctrl_PC_JMP_A, next_pc);
      // // $display("Next PC: %h ; Stall: %h ; Ctrl_PC_JMP: %h", next_pc, Stall, X_Ctrl_PC_JMP);

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
