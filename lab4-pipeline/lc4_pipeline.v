// Wuji Zhang: wujizh
// Min Wang: minyun

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // main clock
    input wire         rst, // global reset
    input wire         gwe, // global we for single-step clock
                                    
    output wire [15:0] o_cur_pc, // Address to read from instruction memory
    input wire [15:0]  i_cur_insn, // Output of instruction memory
    output wire [15:0] o_dmem_addr, // Address to read/write from/to data memory
    input wire [15:0]  i_cur_dmem_data, // Output of data memory
    output wire        o_dmem_we, // Data memory write enable
    output wire [15:0] o_dmem_towrite, // Value to write to data memory
   
    output wire [1:0]  test_stall, // Testbench: is this is stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc, // Testbench: program counter
    output wire [15:0] test_cur_insn, // Testbench: instruction bits
    output wire        test_regfile_we, // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel, // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data, // Testbench: value to write into the register file
    output wire        test_nzp_we, // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits, // Testbench: value to write to NZP bits
    output wire        test_dmem_we, // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr, // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data, // Testbench: value read/writen from/to memory

    input wire [7:0]   switch_data, // Current settings of the Zedboard switches
    output wire [7:0]  led_data // Which Zedboard LEDs should be turned on?
    );
   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)


   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   assign next_pc = Stall ? pc : 
                    X_Ctrl_PC_JMP ? O_ALU : PC_ADD_ONE ;

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*** YOUR CODE HERE ***/
   // TEST ASSIGNMENT
   assign test_cur_pc = W_PC;
   assign test_cur_insn = W_INSN;
   assign test_regfile_we = W_Ctrl_RF_WE;
   assign test_regfile_wsel = In_Rd;
   assign test_regfile_data = I_RF_data;
   assign test_nzp_we = W_Ctrl_Update_NZP;
   assign test_nzp_new_bits = W_Ctrl_NZP;
   assign test_dmem_we = W_insn_STR;   
   assign test_dmem_addr = W_dmem_addr;
   assign test_dmem_data = (W_insn_STR) ?  W_dmem_towrite: 
                           (W_insn_LDR) ? W_Mem:
                           16'h0000;     
   // Define Control Signals
   wire D_Ctrl_W_R7;
   wire X_Ctrl_W_R7;
   wire M_Ctrl_W_R7;
   wire W_Ctrl_W_R7;

   wire D_Ctrl_RF_WE;
   wire X_Ctrl_RF_WE;
   wire M_Ctrl_RF_WE;  
   wire W_Ctrl_RF_WE;

   wire D_Ctrl_Update_NZP;
   wire X_Ctrl_Update_NZP;

   wire D_Ctrl_Control_insn;
   wire X_Ctrl_PC_JMP;
   wire X_Ctrl_BR_JMP;
   wire D_insn_BR;
   wire X_insn_BR;
   wire D_insn_LDR;
   wire X_insn_LDR;
   wire M_insn_LDR;
   wire W_insn_LDR;
   wire D_insn_STR;
   wire X_insn_STR;
   wire M_insn_STR;
   wire W_insn_STR;
   
   wire Flush;



   // PC
   assign o_cur_pc = pc;
   wire [15:0] D_PC;
   wire [15:0] D_I_PC;

   // PC adder
   wire [15:0] PC_ADD_ONE;
   wire [15:0] D_PC_ADD_ONE;
   cla16 PCadder(.a(pc), .b(16'h0000), .cin(1'b1), .sum(PC_ADD_ONE));


   // D Register

   wire [15:0] INSN;
   assign INSN = i_cur_insn;
   wire [15:0] D_INSN;
   wire [15:0] D_I_INSN;

   assign D_I_PC = (Stall)   ? D_PC : pc;
   assign D_I_INSN = (Stall)   ? D_INSN : INSN;
   wire D_Flush;
   Nbit_reg #(16, 16'h0000) D_PC_Reg(.in(D_I_PC), .out( D_PC ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush | rst ));
   Nbit_reg #(16, 16'h0000) D_insn_Reg(.in(D_I_INSN), .out( D_INSN ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush | rst  ));
   Nbit_reg #(16, 16'h0000) D_PC_ADD_ONE_Reg(.in(PC_ADD_ONE), .out( D_PC_ADD_ONE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( D_Flush | rst  ));


   // decoder
   wire [2:0] Rd; // raw rd output from decoder; 
   wire [2:0] D_Rd; // valid only when RF_WE is enabled; to avoid false WX by pass
   assign D_Rd = (D_Ctrl_RF_WE)? Rd:3'b000;
   wire [2:0] D_Rs;
   wire [2:0] D_Rt;
   wire R1RE;
   wire R2RE;
   lc4_decoder decode(.insn(D_INSN),               // instruction
                   .r1sel(D_Rs),              // rs
                   .r1re(R1RE),               // does this instruction read from rs?
                   .r2sel(D_Rt),              // rt
                   .r2re(R2RE),               // does this instruction read from rt?
                   .wsel(Rd),               // rd
                   .regfile_we(D_Ctrl_RF_WE),         // does this instruction write to rd?
                   .nzp_we(D_Ctrl_Update_NZP),             // does this instruction write the NZP bits?
                   .select_pc_plus_one(D_Ctrl_W_R7), // write PC+1 to the regfile?
                   .is_load(D_insn_LDR),            // is this a load instruction?
                   .is_store(D_insn_STR),           // is this a store instruction?
                   .is_branch(D_insn_BR),          // is this a branch instruction?
                   .is_control_insn(D_Ctrl_Control_insn)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
                   );

   // Regfile

   wire [15:0] I_RF_data;
   wire [15:0] X_RF_data;
   wire [15:0] M_RF_data;
   wire [15:0] W_RF_data;
   wire [15:0] O_RF_R1;
   wire [15:0] O_RF_R2;
   wire [2:0] In_Rd;
   assign In_Rd = (W_Ctrl_W_R7) ? 3'h7 : W_Rd;
   lc4_regfile #(16) myregfile   (.clk(clk),
    .gwe(gwe),
    .rst(rst),
    .i_rs(D_Rs),      // rs selector
    .o_rs_data(O_RF_R1), // rs contents
    .i_rt(D_Rt),      // rt selector
    .o_rt_data(O_RF_R2), // rt contents
    .i_rd(In_Rd),      // rd selector
    .i_wdata(I_RF_data),   // data to write
    .i_rd_we(W_Ctrl_RF_WE)    // write enable
    );

   wire [15:0] D_O_RF_R1;
   wire [15:0] D_O_RF_R2;

   // WD Bypass Control
   wire WD_Bypass_1;
   wire WD_Bypass_2;

   assign WD_Bypass_1 = ((D_Rs == W_Rd) & W_Ctrl_RF_WE & R1RE);
   assign WD_Bypass_2 = ((D_Rt == W_Rd) & W_Ctrl_RF_WE & R2RE);  

   assign D_O_RF_R1 = (WD_Bypass_1) ? I_RF_data : O_RF_R1;
   assign D_O_RF_R2 = (WD_Bypass_2) ? I_RF_data : O_RF_R2;

   assign I_RF_data = W_Ctrl_W_R7 ? W_PC_ADD_ONE : W_RF_IN_data;

   // X registers
   wire [15:0] X_PC;
   wire [15:0] X_INSN;
   wire [15:0] X_PC_ADD_ONE;
   wire [15:0] X_R1;
   wire [15:0] X_R2;   
   wire [2:0] X_Rs;
   wire [2:0] X_Rt;
   wire [2:0] X_Rd;
   wire X_Ctrl_Control_insn;

   Nbit_reg #(16, 16'h0000) X_PC_Reg(.in(D_PC), .out( X_PC ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(16, 16'h0000) X_insn_Reg(.in(D_INSN), .out( X_INSN ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(16, 16'h0000) X_PC_ADD_One_Reg(.in(D_PC_ADD_ONE), .out( X_PC_ADD_ONE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   
   Nbit_reg #(16, 16'h0000) X_RF_Data_Reg(.in(I_RF_data), .out( X_RF_data ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));

   Nbit_reg #(16, 16'h0000) X_R1_Reg(.in(D_O_RF_R1), .out( X_R1 ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(16, 16'h0000) X_R2_Reg(.in(D_O_RF_R2), .out( X_R2 ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));

   wire X_R1RE;
   wire X_R2RE;
   Nbit_reg #(1, 1'b0) X_R1RE_Reg(.in(R1RE), .out( X_R1RE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(1, 1'b0) X_R2RE_Reg(.in(R2RE), .out( X_R2RE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));


   Nbit_reg #(1, 1'b0) X_STR_Reg(.in(D_insn_STR), .out( X_insn_STR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(1, 1'b0) X_LDR_Reg(.in(D_insn_LDR), .out( X_insn_LDR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   
   Nbit_reg #(1, 1'b0) X_insn_BR_Reg(.in(D_insn_BR), .out( X_insn_BR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_W_R7_Reg(.in(D_Ctrl_W_R7), .out( X_Ctrl_W_R7 ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_RF_WE_Reg(.in(D_Ctrl_RF_WE), .out( X_Ctrl_RF_WE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_Control_Reg(.in(D_Ctrl_Control_insn), .out( X_Ctrl_Control_insn ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(1, 1'b0) X_CTRL_Update_NZP_Reg(.in(D_Ctrl_Update_NZP), .out( X_Ctrl_Update_NZP ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));

   Nbit_reg #(3, 3'b000) X_Rs_Reg(.in(D_Rs), .out( X_Rs ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(3, 3'b000) X_Rt_Reg(.in(D_Rt), .out( X_Rt ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));
   Nbit_reg #(3, 3'b000) X_Rd_Reg(.in(D_Rd), .out( X_Rd ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( X_Flush | rst ));



    // ALU
   wire [1:0] WMX_Bypass_1;
   wire [1:0] WMX_Bypass_2;
   wire [15:0] O_ALU;
   wire [15:0] ALU_in1;
   wire [15:0] ALU_in2;  

   // WMX Bypass
   assign WMX_Bypass_1 = ((X_Rs == M_Rd) & M_Ctrl_RF_WE & X_R1RE) ? 2'b01 :
                        ((X_Rs == W_Rd) & W_Ctrl_RF_WE & X_R1RE) ? 2'b00: 2'b10;
   assign WMX_Bypass_2 = ((X_Rt == M_Rd) & M_Ctrl_RF_WE & X_R2RE) ? 2'b01 :
                        ((X_Rt == W_Rd) & W_Ctrl_RF_WE & X_R2RE) ? 2'b00: 2'b10;

   assign ALU_in1 = (WMX_Bypass_1 == 2'b00)? W_RF_IN_data:
                     (WMX_Bypass_1 == 2'b01)? M_ALU:
                     (WMX_Bypass_1 == 2'b10)? X_R1: 16'h0000 ;
   assign ALU_in2 = (WMX_Bypass_2 == 2'b00)? W_RF_IN_data:
                     (WMX_Bypass_2 == 2'b01)? M_ALU:
                     (WMX_Bypass_2 == 2'b10)? X_R2: 16'h0000 ;

   lc4_alu myALU(.i_insn(X_INSN),
               .i_pc(X_PC),
               .i_r1data(ALU_in1),
               .i_r2data(ALU_in2),
               .o_result(O_ALU));

   wire [15:0] W_RF_IN_data;
   wire [15:0] M_PC_ADD_ONE;

   // M register
   wire [15:0] M_PC;
   wire [15:0] M_ALU;
   wire [15:0] M_R2;

   wire [2:0] M_Rs;
   wire [2:0] M_Rt;
   wire [2:0] M_Rd;

   wire [15:0] M_INSN;
   assign M_Flush = 1'b0;
   Nbit_reg #(16, 16'h0000) M_PC_Reg(.in(X_PC), .out( M_PC ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( M_Flush | rst ));
   Nbit_reg #(16, 16'h0000) M_ALU_Reg(.in(O_ALU), .out( M_ALU ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(16, 16'h0000) M_R2_Reg(.in(ALU_in2), .out( M_R2 ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(16, 16'h0000) M_PC_ADD_One_Reg(.in(X_PC_ADD_ONE), .out( M_PC_ADD_ONE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(16, 16'h0000) M_INSN_Reg(.in(X_INSN), .out( M_INSN ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(    M_Flush | rst  ));
   Nbit_reg #(16, 16'h0000) M_RF_Data_Reg(.in(X_RF_data), .out( M_RF_data ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),.rst(  M_Flush | rst  ));


   Nbit_reg #(1, 1'b0) M_STR_Reg(.in(X_insn_STR), .out( M_insn_STR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(1, 1'b0) M_LDR_Reg(.in(X_insn_LDR), .out( M_insn_LDR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));

   wire M_R1RE;
   wire M_R2RE;
   Nbit_reg #(1, 1'b0) M_R1RE_Reg(.in(X_R1RE), .out( M_R1RE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(1, 1'b0) M_R2RE_Reg(.in(X_R2RE), .out( M_R2RE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));

   wire M_Stall;
   Nbit_reg #(1, 1'b0) M_Stall_Sig_Reg(.in(Stall), .out( M_Stall ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));


   Nbit_reg #(1, 1'b0) M_CTRL_W_R7_Reg(.in(X_Ctrl_W_R7), .out( M_Ctrl_W_R7 ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(1, 1'b0) M_CTRL_RF_WE_Reg(.in(X_Ctrl_RF_WE), .out( M_Ctrl_RF_WE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   
   wire M_Ctrl_Update_NZP;
   Nbit_reg #(1, 1'b0) M_CTRL_Update_NZP_Reg(.in(X_Ctrl_Update_NZP), .out( M_Ctrl_Update_NZP ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   
   wire [2:0] Mem_NZP_Update;
   wire [2:0]  M_Ctrl_NZP_out;
   assign M_Ctrl_NZP = (M_insn_LDR)? Mem_NZP_Update : M_Ctrl_NZP_out;
   Nbit_reg #(3, 3'b000) M_Ctrl_NZP_Reg(.in(Ctrl_NZP), .out( M_Ctrl_NZP_out ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(3, 3'b000) M_Rs_Reg(.in(X_Rs), .out( M_Rs ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(3, 3'b000) M_Rt_Reg(.in(X_Rt), .out( M_Rt ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));
   Nbit_reg #(3, 3'b000) M_Rd_Reg(.in(X_Rd), .out( M_Rd ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst(  M_Flush | rst  ));



   // memory
   assign o_dmem_addr = (M_insn_LDR | M_insn_STR) ? M_ALU : 16'h0000; 
   assign o_dmem_we = M_insn_STR;

   wire [15:0] W_dmem_addr;
   wire [15:0] W_dmem_towrite;   

   // WM by pass
   wire WM_Bypass;
   assign WM_Bypass = M_insn_STR & W_insn_LDR & (M_Rt == W_Rd);
   assign o_dmem_towrite = (WM_Bypass)? W_RF_IN_data: 
                           ((M_insn_STR) ? M_R2:16'h0000);


   // W registers
   wire [15:0] O_Mem;
   assign O_Mem = i_cur_dmem_data;
   wire [15:0] W_ALU;
   wire [15:0] W_Mem;
   wire [15:0] W_PC_ADD_ONE;
   wire [2:0] W_Rd;
   wire [15:0] W_INSN;
   wire [15:0] W_PC;
   assign W_Flush = 1'b0;
   Nbit_reg #(16, 16'h0000) W_PC_Reg(.in(M_PC), .out( W_PC ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(16, 16'h0000) W_ALU_Reg(.in(M_ALU), .out( W_ALU ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(16, 16'h0000) W_MEM_Reg(.in(O_Mem), .out( W_Mem ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(16, 16'h0000) W_PC_ADD_One_Reg(.in(M_PC_ADD_ONE), .out( W_PC_ADD_ONE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(16, 16'h0000) W_INSN_Reg(.in(M_INSN), .out( W_INSN ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(16, 16'h0000) W_RF_Data_Reg(.in(M_RF_data), .out( W_RF_data ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));

   Nbit_reg #(16, 16'h0000) W_mem_addr_Reg(.in(o_dmem_addr), .out( W_dmem_addr ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(16, 16'h0000) W_mem_towrite_Reg(.in(o_dmem_towrite), .out( W_dmem_towrite ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));


   Nbit_reg #(1, 1'b0) W_LDR_Reg(.in(M_insn_LDR), .out( W_insn_LDR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(1, 1'b0) W_STR_Reg(.in(M_insn_STR), .out( W_insn_STR ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));

   Nbit_reg #(1, 1'b0) W_CTRL_W_R7_Reg(.in(M_Ctrl_W_R7), .out( W_Ctrl_W_R7 ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(1, 1'b0) W_CTRL_RF_WE_Reg(.in(M_Ctrl_RF_WE), .out( W_Ctrl_RF_WE ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));

   Nbit_reg #(3, 3'b000) W_Ctrl_NZP_Reg(.in(M_Ctrl_NZP), .out( W_Ctrl_NZP ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   Nbit_reg #(3, 3'b000) W_Rd_Reg(.in(M_Rd), .out( W_Rd ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));
   wire W_Ctrl_Update_NZP;
   Nbit_reg #(1, 1'b0) W_CTRL_Update_NZP_Reg(.in(M_Ctrl_Update_NZP), .out( W_Ctrl_Update_NZP ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( W_Flush ));



   assign W_RF_IN_data = (W_insn_LDR) ? W_Mem : W_ALU;
   // NZP register
   wire [2:0] Ctrl_NZP;
   wire [2:0] M_Ctrl_NZP;
   wire [2:0] W_Ctrl_NZP;   
   wire [2:0] NZP;
   wire X_NZP_WE; 
   assign X_NZP_WE = X_Ctrl_Update_NZP |  M_Stall;
   Nbit_reg #(3, 3'b000) nzp_reg (.in(Ctrl_NZP), .out(NZP), .clk(clk), .we(X_NZP_WE), .gwe(gwe), .rst(rst));

   wire signed [15:0] NZP_Data;
   assign NZP_Data = M_Stall ? O_Mem : 
                  X_Ctrl_W_R7 ? X_PC_ADD_ONE : O_ALU;
   assign Ctrl_NZP[2] = (NZP_Data[15] == 1'b1)? 1'b1 : 1'b0; // N
   assign Ctrl_NZP[1] = (NZP_Data == 16'h0000)? 1'b1 : 1'b0; // Z
   assign Ctrl_NZP[0] = (NZP_Data > $signed(16'h0000))? 1'b1 : 1'b0;   // P

   // Used to update M_Ctrl_NZP based on Mem output
   wire signed [15:0] mem_NZP_Data;
   assign mem_NZP_Data = O_Mem;
   assign Mem_NZP_Update[2] = (mem_NZP_Data[15] == 1'b1)? 1'b1 : 1'b0; // N
   assign Mem_NZP_Update[1] = (mem_NZP_Data == 16'h0000)? 1'b1 : 1'b0; // Z
   assign Mem_NZP_Update[0] = (mem_NZP_Data > $signed(16'h0000))? 1'b1 : 1'b0;   // P   

   // sub op for branch
   wire[2:0] sub_op;
   assign sub_op = X_INSN[11:9];
   wire sub_op_NOP = (sub_op == 3'b000);
   wire sub_op_BRp = (sub_op == 3'b001);
   wire sub_op_BRz = (sub_op == 3'b010);
   wire sub_op_BRzp = (sub_op == 3'b011);
   wire sub_op_BRn = (sub_op == 3'b100);
   wire sub_op_BRnp = (sub_op == 3'b101);
   wire sub_op_BRnz = (sub_op == 3'b110);
   wire sub_op_BRnzp = (sub_op == 3'b111);  

   assign X_Ctrl_BR_JMP = (NZP[0] & sub_op_BRp) | (NZP[1] & sub_op_BRz) | (NZP[2] & sub_op_BRn) | 
                        ((NZP[0]|NZP[1]) & sub_op_BRzp) | ((NZP[0]|NZP[2]) & sub_op_BRnp) | ((NZP[1]|NZP[2]) & sub_op_BRnz) | ((NZP[1]|NZP[0]|NZP[2]) & sub_op_BRnzp);
   assign X_Ctrl_PC_JMP = (X_insn_BR & X_Ctrl_BR_JMP) | X_Ctrl_Control_insn;

   // stall logic
   // stall happens when 1) load to use 2) load to BR
   wire Stall_Load_to_Branch;
   assign Stall_Load_to_Branch = D_insn_BR & X_insn_LDR;
   wire Stall_load_to_Use;
   assign Stall_load_to_Use = X_insn_LDR & (((D_Rs == X_Rd) &R1RE) | ((D_Rt == X_Rd) & !D_insn_STR &R2RE));
   wire Stall;
   assign Stall = Stall_Load_to_Branch | Stall_load_to_Use;
   assign D_Flush = X_Ctrl_PC_JMP;
   // test_stall
   wire [1:0] D_Stall_out_bits;
   wire [1:0] D_Stall_in_bits;
   wire [1:0] X_Stall_in_bits;
   wire [1:0] X_Stall_out_bits;
   wire [1:0] M_Stall_in_bits;
   wire [1:0] M_Stall_out_bits;   
   wire [1:0] W_Stall_in_bits;
   wire [1:0] W_Stall_out_bits;

   assign D_Stall_in_bits =  X_Ctrl_PC_JMP ? 2'b10: 2'b00;

   Nbit_reg #(2, 2'b10) D_Stall_Reg(.in(D_Stall_in_bits), .out( D_Stall_out_bits ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   Nbit_reg #(2, 2'b10) X_Stall_Reg(.in(X_Stall_in_bits), .out( X_Stall_out_bits ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   assign X_Stall_in_bits = (X_Ctrl_PC_JMP) ? 2'b10 :
                         (Stall_load_to_Use | Stall_Load_to_Branch) ? 2'b11:
                        D_Stall_out_bits;
   Nbit_reg #(2, 2'b10) M_Stall_Reg(.in(M_Stall_in_bits), .out( M_Stall_out_bits ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   assign M_Stall_in_bits =  X_Stall_out_bits;   
   Nbit_reg #(2, 2'b10) W_Stall_Reg(.in(W_Stall_in_bits), .out( W_Stall_out_bits ), .clk( clk ), .we( 1'b1 ), .gwe(gwe),  .rst( rst ));
   assign W_Stall_in_bits = M_Stall_out_bits;   
   assign test_stall = W_Stall_out_bits; 
   // Flush logic
   // D,X flush happens when Branch mis prediction
   wire X_Flush;
   wire M_Flush;
   wire W_Flush;
   assign X_Flush = Stall | X_Ctrl_PC_JMP;
   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    * 
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    */
`ifndef NDEBUG
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
      //$display("%h %h %h %h %h %h %h %h", D_Stall_in_bits,D_Stall_out_bits,X_Stall_in_bits,
      //               X_Stall_out_bits, M_Stall_in_bits, M_Stall_out_bits, 
      //               W_Stall_in_bits, W_Stall_out_bits);

      // $display("%h %h %h %h %h", pc, D_PC, X_PC, M_PC, test_cur_pc);
      // $display("%h %h %h %h %h", INSN, D_INSN, X_INSN, M_INSN, W_INSN);
      // $display("X_Ctrl_PC_JMP: %h next_pc: %h", X_Ctrl_PC_JMP, next_pc);
      // $display("Next PC: %h ; Stall: %h ; Ctrl_PC_JMP: %h", next_pc, Stall, X_Ctrl_PC_JMP);

      //$display("X_insn_BR: %h ; X_Ctrl_BR_JMP: %h ; X_Ctrl_Control_insn: %h", X_insn_BR, X_Ctrl_BR_JMP, X_Ctrl_Control_insn);
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
      // run it for that many nano-seconds, then set
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
`endif
endmodule









// /* Group Member:    Zeyu Niu | Tianyi Wu
//  * Pennkey:         zyniu    |  wubill
//  */


// `timescale 1ns / 1ps
// // disable implicit wire declaration
// `default_nettype none

// //  Pipeline Module Begins  //
//     module lc4_processor(
//         input  wire        clk,                // Main clock
//         input  wire        rst,                // Global reset
//         input  wire        gwe,                // Global we for single-step clock
    
//         output wire [15:0] o_cur_pc,           // Address to read from instruction memory
//         input  wire [15:0] i_cur_insn,         // Output of instruction memory
//         output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
//         input  wire [15:0] i_cur_dmem_data,    // Output of data memory
//         output wire        o_dmem_we,          // Data memory write enable
//         output wire [15:0] o_dmem_towrite,     // Value to write to data memory

//         // Testbench signals are used by the testbench to verify the correctness of your datapath.
//         // Many of these signals simply export internal processor state for verification (such as the PC).
//         // Some signals are duplicate output signals for clarity of purpose.
//         //
//         // Don't forget to include these in your schematic!

//         output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
//         output wire [15:0] test_cur_pc,        // Testbench: program counter
//         output wire [15:0] test_cur_insn,      // Testbench: instruction bits
//         output wire        test_regfile_we,    // Testbench: register file write enable
//         output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
//         output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
//         output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
//         output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
//         output wire        test_dmem_we,       // Testbench: data memory write enable
//         output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
//         output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
    
//         input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
//         output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
//     );

//     // By default, assign LEDs to display switch inputs to avoid warnings about
//     // disconnected ports. Feel free to use this for debugging input/output if
//     // you desire.
//     // assign led_data = switch_data;

//     // PC fetch and plus one before D stage //
//     wire    [15:0] f2d_pc_plus_one;
//     cla16 Pipeline_PC_Inc(.a(f2d_pc), .b(16'b0), .cin(1'b1), .sum(f2d_pc_plus_one));

//     // Register file for Pipelned Datapath //
//     wire [15:0] o_regfile_rs, o_regfile_rt;              
//     lc4_regfile Pipeline_Regfile (
//             .clk(clk),
//             .gwe(gwe),
//             .rst(rst),
//             .i_rs(d2x_bus[33:31]), 
//             .o_rs_data(o_regfile_rs),
//             .i_rt(d2x_bus[30:28]), 
//             .o_rt_data(o_regfile_rt),
//             .i_rd(w_o_bus[27:25]), 
//             .i_wdata(write_back), 
//             .i_rd_we(w_o_bus[22])
//     );
        

//     /**** Registers for Intermediate States ****/

//     // Intermediate PC registers //
//     wire [15:0]     next_pc;
//     wire [15:0]     f2d_pc, d2x_pc, x2m_pc, m2w_pc, w_o_pc; 

//     Nbit_reg #(16, 16'h8200) f_pc_reg (.in(next_pc), .out(f2d_pc), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    d_pc_reg (.in(f2d_pc), .out(d2x_pc), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    x_pc_reg (.in(d2x_pc), .out(x2m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    m_pc_reg (.in(x2m_pc), .out(m2w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)    w_pc_reg (.in(m2w_pc), .out(w_o_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


//     // Instructions registers //
//     wire            x_br_taken_or_ctrl, branch_taken;                   // Taking branch or control instruction will flush the current cycle
//     wire            load2use;                                           // Judge whether there is a load-to-use stall
//     wire [15:0]     d_i_bus, d2x_bus_tmp;                               // PC bus at D and pre_X stage
//     wire [33:0]     d2x_bus, d2x_bus_final, x2m_bus, m2w_bus, w_o_bus;  // Intermediate buses 

//     Nbit_reg #(16, 16'b0) d_insn_reg (.in(d_i_bus), .out(d2x_bus_tmp), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) x_insn_reg (.in(d2x_bus_final), .out(x2m_bus), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) m_insn_reg (.in(x2m_bus), .out(m2w_bus), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(34, 34'b0) w_insn_reg (.in(m2w_bus), .out(w_o_bus), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     assign  d_i_bus = (x_br_taken_or_ctrl == 1) ? {16{1'b0}} : i_cur_insn;                  // misprediction and control signal causes flush
//     assign  d2x_bus[15:0] = d2x_bus_tmp;
//     assign  d2x_bus_final = ((load2use | x_br_taken_or_ctrl) == 1) ? {34{1'b0}} : d2x_bus;  // load2use also causes flush, but only judged after D stage//


//     // Wires to calculating br_predict and next PC //
//     wire [2:0]      is_all_zero;                                        
//     wire [2:0]      o_nzp_reg_val;

//     assign  is_all_zero = o_nzp_reg_val & x2m_bus[11:9];
//     assign  branch_taken = ((is_all_zero != 3'b0) && (x2m_bus[17] == 1)) ? 1'b1 : 1'b0;
//     assign  x_br_taken_or_ctrl = branch_taken || x2m_bus[16];
//     assign  next_pc = (x_br_taken_or_ctrl == 1) ? o_alu_result : f2d_pc_plus_one;


//     // Regiters for Intermediate A, B, O, D Input/Output //
//     wire [15:0]     x_A_i, x_A_o, x_B_i, x_B_o,
//                     m_B_o, m_O_i, m_O_o, 
//                     w_O_o, w_D_i, w_D_o;
//     wire [15:0]     write_back;                  // Determine the value that writes back to the Regfiles //
                    
//     Nbit_reg #(16, 16'b0) x_A_reg (.in(x_A_i), .out(x_A_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) x_B_reg (.in(x_B_i), .out(x_B_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) m_B_reg (.in(rt_bypass_res), .out(m_B_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) m_O_reg (.in(m_O_i), .out(m_O_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) w_O_reg (.in(m_O_o), .out(w_O_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0) w_D_reg (.in(i_cur_dmem_data), .out(w_D_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
//     assign  x_A_i = ((w_o_bus[27:25] == d2x_bus[33:31]) && w_o_bus[22]) ? write_back : o_regfile_rs; 
//     assign  x_B_i = ((w_o_bus[27:25] == d2x_bus[30:28]) && w_o_bus[22]) ? write_back : o_regfile_rt;
//     assign  m_O_i = (x2m_bus[16] == 1) ? d2x_pc : o_alu_result;                     
//     assign  write_back = (w_o_bus[19] == 1) ? w_D_o : w_O_o;        // Write back to register


//     // Registers for stall cycle //
//     wire[1:0]   d_stall_i, d_stall_o, x_stall_i, 
//                 x_stall_o, m_stall_o;

//     Nbit_reg #(2, 2'b10) d_stall_reg (.in(d_stall_i), .out(d_stall_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) x_stall_reg (.in(x_stall_i), .out(x_stall_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) m_stall_reg (.in(x_stall_o), .out(m_stall_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(2, 2'b10) w_stall_reg (.in(m_stall_o), .out(test_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     assign  d_stall_i = (x_br_taken_or_ctrl == 1) ? 2'd2 : 2'd0;
//     assign  x_stall_i = (load2use == 1) ? 2'd3 :                    // load2use only judged after the Decoder stage
//                         (x_br_taken_or_ctrl == 1) ? 2'd2 :          // (Initial predict all set Not-Taken) Wrong predic and control both cause flush
//                         d_stall_o;


//     // Registers for NZP values //
//     wire [2:0] i_regfile_wdata_sign, m_nzp_o, w_nzp_i;
//     wire [2:0] nzp_alu, nzp_ld, nzp_trap;

//     Nbit_reg #(3, 3'b0) m_nzp_reg (.in(i_regfile_wdata_sign), .out(m_nzp_o), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(3, 3'b0) w_nzp_reg (.in(w_nzp_i), .out(test_nzp_new_bits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     assign w_nzp_i =    ((m2w_bus[19]==1)) ? nzp_ld : m_nzp_o;          // For load insn, nzp_ld are independently calculated
//     assign nzp_alu =    ($signed(o_alu_result) > 0) ? 3'b001: 
//                         (o_alu_result == 0) ? 3'b010: 
//                         3'b100;
//     assign nzp_ld  =    ($signed(i_cur_dmem_data) > 0) ? 3'b001:
//                         (i_cur_dmem_data == 0) ? 3'b010: 
//                         3'b100;  
//     assign nzp_trap =   ($signed(x2m_pc) > 0) ? 3'b001:
//                         (x2m_pc == 0) ? 3'b010: 
//                         3'b100;  
//     // NZP has 3 different possible sources: output of ALU, Output of dataMemory, PC from X stage 
//     assign i_regfile_wdata_sign =   (x2m_bus[15:12] == 4'b1111) ? nzp_trap :  
//                                     ((m2w_bus[19]==1) && (x_stall_o==2'd3) ) ? nzp_ld : 
//                                     nzp_alu;


//     //  Register for memory operationss  //
//     wire [15:0] w_dmem_data;

//     Nbit_reg #(1, 1'b0)     w_dmem_we_reg (.in(o_dmem_we), .out(test_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)   w_dmem_addr_reg (.in(o_dmem_addr), .out(test_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
//     Nbit_reg #(16, 16'b0)   w_dmem_data_reg (.in(w_dmem_data), .out(test_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

//     assign w_dmem_data =    (m2w_bus[19] == 1) ? i_cur_dmem_data :
//                             (m2w_bus[18] == 1) ? wm_bypass_res : 16'b0;

//     //**** Intermediate State Registers END ****/


//     // NZP Register //
//     Nbit_reg Pipeline_NZP_Reg (
//             .in(i_regfile_wdata_sign), 
//             .out(o_nzp_reg_val),
//             .clk(clk),
//             .we(x2m_bus[21]),
//             .gwe(gwe),
//             .rst(rst)
//     );
//     defparam Pipeline_NZP_Reg.n = 3;


//     /***** Pipeline Stage2: Decoder *****/
//     lc4_decoder Pipeline_Decoder (
//             .r1sel(d2x_bus[33:31]), 
//             .r2sel(d2x_bus[30:28]),
//             .wsel(d2x_bus[27:25]),
//             .r1re(d2x_bus[24]),
//             .r2re(d2x_bus[23]),
//             .regfile_we(d2x_bus[22]),
//             .nzp_we(d2x_bus[21]), 
//             .select_pc_plus_one(d2x_bus[20]),
//             .is_load(d2x_bus[19]), 
//             .is_store(d2x_bus[18]),
//             .is_branch(d2x_bus[17]), 
//             .is_control_insn(d2x_bus[16]),
//             .insn(d2x_bus[15:0])
//     );

    
//     /***** Pipeline Stage3: Execute (ALU) *****/
//     wire    [15:0] o_alu_result, rs_bypass_res, rt_bypass_res, wm_bypass_res;

//     lc4_alu Pipeline_Alu ( 
//             .i_insn(x2m_bus[15:0]),
//             .i_pc(x2m_pc),
//             .i_r1data(rs_bypass_res),
//             .i_r2data(rt_bypass_res),
//             .o_result(o_alu_result)
//     );
    
//     // Bypass results assignment//
//     assign rs_bypass_res =  ((x2m_bus[33:31] == m2w_bus[27:25]) && (m2w_bus[22] == 1)) ? m_O_o:         // MX for ALU input rs_data
//                             ((x2m_bus[33:31] == w_o_bus[27:25]) && w_o_bus[22] == 1) ? write_back:      // WX for ALU input rs_data
//                             x_A_o;

//     assign rt_bypass_res =  ((x2m_bus[30:28] == m2w_bus[27:25]) && (m2w_bus[22] == 1)) ? m_O_o:          // MX for ALU input rt_data
//                             ((x2m_bus[30:28] == w_o_bus[27:25]) && w_o_bus[22] == 1) ? write_back:       // WX for ALU input rt_data
//                             x_B_o;

//     assign wm_bypass_res = ((m2w_bus[18]) && (m2w_bus[30:28] == w_o_bus[27:25]) && (w_o_bus[22])) ? write_back : m_B_o;     // WM Bypass

//     assign load2use   =     (x2m_bus[19]) && 
//                             (((d2x_bus[24]) && (d2x_bus[33:31] == x2m_bus[27:25])) || 
//                             ((d2x_bus[23]) && (d2x_bus[30:28] == x2m_bus[27:25]) && (~d2x_bus[18])) || (d2x_bus[15:12]==4'b0));

    
//     //**** Test Wire Assignment ****//
//     assign o_cur_pc =           f2d_pc;
//     assign o_dmem_addr =        ((m2w_bus[19] == 1) || (m2w_bus[18] == 1)) ? m_O_o : 16'b0;                   
//     assign o_dmem_we =          m2w_bus[18];
//     assign o_dmem_towrite =     wm_bypass_res;

//     assign test_cur_pc =        w_o_pc;
//     assign test_cur_insn =      w_o_bus[15:0];
//     assign test_regfile_we =    w_o_bus[22];
//     assign test_regfile_wsel =  w_o_bus[27:25];
//     assign test_regfile_data =  write_back;
//     assign test_nzp_we =        w_o_bus[21];
//     //**** Test Wire Assignment END ****//


//     /* STUDENT CODE ENDS */

//     /* Add $display(...) calls in the always block below to
//         * print out debug information at the end of every cycle.
//         *
//         * You may also use if statements inside the always block
//         * to conditionally print out information.
//         *
//         * You do not need to resynthesize and re-implement if this is all you change;
//         * just restart the simulation.
//         * 
//         * To disable the entire block add the statement
//         * `define NDEBUG
//         * to the top of your file.  We also define this symbol
//         * when we run the grading scripts.*/
//     `ifndef NDEBUG
//     always @(posedge gwe) begin

//         // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
//         // if (o_dmem_we)
//         //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

//         // Start each $display() format string with a %d argument for time
//         // it will make the output easier to read.  Use %b, %h, and %d
//         // for binary, hex, and decimal output of additional variables.
//         // You do not need to add a \n at the end of your format string.
//         // $display("%d ...", $time);

//         // Try adding a $display() call that prints out the PCs of
//         // each pipeline stage in hex.  Then you can easily look up the
//         // instructions in the .asm files in test_data.

//         // basic if syntax:
//         // if (cond) begin
//         //    ...;
//         //    ...;
//         // end

//         // Set a breakpoint on the empty $display() below
//         // to step through your pipeline cycle-by-cycle.
//         // You'll need to rewind the simulation to start
//         // stepping from the beginning.

//         // You can also simulate for XXX ns, then set the
//         // breakpoint to start stepping midway through the
//         // testbench.  Use the $time printouts you added above (!)
//         // to figure out when your problem instruction first
//         // enters the fetch stage.  Rewind your simulation,
//         // run it for that many nano-seconds, then set
//         // the breakpoint.

//         // In the objects view, you can change the values to
//         // hexadecimal by selecting all signals (Ctrl-A),
//         // then right-click, and select Radix->Hexadecial.

//         // To see the values of wires within a module, select
//         // the module in the hierarchy in the "Scopes" pane.
//         // The Objects pane will update to display the wires
//         // in that module.

//         // $display();

//     end
//     `endif
//     endmodule