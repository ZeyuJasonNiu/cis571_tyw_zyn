/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module Branch_And_PC_Unit(
        input wire clk, rst, gwe,
        input wire [15:0] pc_plus_one,
        input wire [15:0] i_regfile_wdata,
        input wire o_decoder_nzp_we,
        input wire o_decoder_is_branch,
        input wire o_decoder_is_control_insn,
        input wire [15:0] insn,
        output wire [15:0] o_next_pc,
        input wire [15:0] o_alu_result,
        output wire [2:0] test_nzp_new_bits);
        
        //wire nzp_if_branch7;
        wire bu_nzp_reduced, bu_branch_output_sel, bu_nzp_passed;
        wire [2:0] i_regfile_wdata_sign, o_nzp_reg_val, is_all_zero;
        // Select NZP bits according to the sign of Input data //
        assign i_regfile_wdata_sign = ($signed(i_regfile_wdata) > 0) ? 3'b001:
                                    (i_regfile_wdata == 0) ? 3'b010: 3'b100;

        // NZP Register //
        Nbit_reg NZP_Reg (
            .in(i_regfile_wdata_sign), 
            .out(o_nzp_reg_val),
            .clk(clk),
            .we(o_decoder_nzp_we),
            .gwe(gwe),
            .rst(rst)
            );
        defparam NZP_Reg.n = 3;

        // Calculate and select "next_pc" //
        assign is_all_zero = o_nzp_reg_val & insn[11:9];
        assign o_next_pc = (o_decoder_is_control_insn == 1 || (o_decoder_is_branch == 1 && (is_all_zero != 3'b000))) ? o_alu_result : pc_plus_one;
        assign test_nzp_new_bits = i_regfile_wdata_sign;
endmodule

//  Single_cycle Module Begins  //
    module lc4_processor(
        input  wire        clk,                // Main clock
        input  wire        rst,                // Global reset
        input  wire        gwe,                // Global we for single-step clock
    
        output wire [15:0] o_cur_pc,           // Address to read from instruction memory
        input  wire [15:0] i_cur_insn,         // Output of instruction memory
        output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
        input  wire [15:0] i_cur_dmem_data,    // Output of data memory
        output wire        o_dmem_we,          // Data memory write enable
        output wire [15:0] o_dmem_towrite,     // Value to write to data memory

        // Testbench signals are used by the testbench to verify the correctness of your datapath.
        // Many of these signals simply export internal processor state for verification (such as the PC).
        // Some signals are duplicate output signals for clarity of purpose.
        //
        // Don't forget to include these in your schematic!

        output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
        output wire [15:0] test_cur_pc,        // Testbench: program counter
        output wire [15:0] test_cur_insn,      // Testbench: instruction bits
        output wire        test_regfile_we,    // Testbench: register file write enable
        output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
        output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
        output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
        output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
        output wire        test_dmem_we,       // Testbench: data memory write enable
        output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
        output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
    
        input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
        output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
        );

    // By default, assign LEDs to display switch inputs to avoid warnings about
    // disconnected ports. Feel free to use this for debugging input/output if
    // you desire.
    assign led_data = switch_data;

    
    /* DO NOT MODIFY THIS CODE */
    // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
    assign test_stall = 2'b0; 

    // pc wires attached to the PC register's ports
    wire [15:0]   pc;      // Current program counter (read out from pc_reg)
    wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

    // Program counter register, starts at 8200h at bootup
    Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    /* END DO NOT MODIFY THIS CODE */

   /***** Pipeline Stage2: Decoder *****/
    wire [2:0] o_decoder_r1sel, o_decoder_r2sel, o_decoder_wsel;
    wire    o_decoder_r1re, o_decoder_r2re, o_decoder_regfile_we, 
            o_decoder_nzp_we, o_decoder_pc_plus_one, o_decoder_is_load, 
            o_decoder_is_store, o_decoder_is_branch, o_decoder_is_control_insn;
            
    lc4_decoder Single_Decoder (    
        .insn(i_cur_insn),
        .r1sel(o_decoder_r1sel), .r1re(o_decoder_r1re),
        .r2sel(o_decoder_r2sel), .r2re(o_decoder_r2re),
        .wsel(o_decoder_wsel), .regfile_we(o_decoder_regfile_we),
        .nzp_we(o_decoder_nzp_we), 
        .select_pc_plus_one(o_decoder_pc_plus_one),
        .is_load(o_decoder_is_load), .is_store(o_decoder_is_store),
        .is_branch(o_decoder_is_branch), 
        .is_control_insn(o_decoder_is_control_insn));
                                        
    wire [15:0] o_regfile_rs, o_regfile_rt;
    wire [15:0] i_regfile_wdata;
    
    lc4_regfile Single_Regfile (
        .clk(clk),
        .gwe(gwe),
        .rst(rst),
        .i_rs(o_decoder_r1sel), 
        .o_rs_data(o_regfile_rs),
        .i_rt(o_decoder_r2sel), 
        .o_rt_data(o_regfile_rt),
        .i_rd(o_decoder_wsel), 
        .i_wdata(i_regfile_wdata), 
        .i_rd_we(o_decoder_regfile_we));
    
    
    /***** Pipeline Stage3: Execute (ALU) *****/
    wire [15:0] o_alu_result;
    lc4_alu Single_Alu ( 
        .i_insn(i_cur_insn),
        .i_pc(pc),
        .i_r1data(o_regfile_rs),
        .i_r2data(o_regfile_rt),
        .o_result(o_alu_result));
    
    /***** ALU Unit to calculate *****/
    wire [15:0] pc_plus_one;
    cla16 Single_PC_Inc(.a(pc), .b(16'b0), .cin(1'b1), .sum(pc_plus_one));
    assign i_regfile_wdata = (o_decoder_pc_plus_one == 1) ? pc_plus_one :
                             (o_decoder_is_load == 1) ? i_cur_dmem_data : o_alu_result;
    
    /***** Pipeline Stage5: Writeback to next PC *****/
    Branch_And_PC_Unit Single_Branch_And_Next_PC( 
        .clk(clk), 
        .rst(rst), 
        .gwe(gwe),
        .pc_plus_one(pc_plus_one), 
        .i_regfile_wdata(i_regfile_wdata),
        .o_decoder_nzp_we(o_decoder_nzp_we),
        .o_decoder_is_branch(o_decoder_is_branch),
        .o_decoder_is_control_insn(o_decoder_is_control_insn),
        .insn(i_cur_insn),
        .o_next_pc(next_pc),
        .o_alu_result(o_alu_result),
        .test_nzp_new_bits(test_nzp_new_bits));

    // Output wire Assignment //
    assign o_cur_pc = pc;
    assign o_dmem_addr = ((o_decoder_is_load == 1) || (o_decoder_is_store == 1)) ? o_alu_result : 16'b0;                   
    assign o_dmem_we = o_decoder_is_store;
    assign o_dmem_towrite = o_regfile_rt;

    // Test wire Assignment //
    assign test_cur_pc = pc;
    assign test_cur_insn = i_cur_insn;
    assign test_regfile_we = o_decoder_regfile_we;
    assign test_regfile_wsel = o_decoder_wsel;
    assign test_regfile_data = i_regfile_wdata;
    assign test_nzp_we = o_decoder_nzp_we;
    assign test_dmem_we = o_dmem_we;
    assign test_dmem_addr = o_dmem_addr;
    assign test_dmem_data = (o_decoder_is_load == 1) ? i_cur_dmem_data :
                            (o_decoder_is_store == 1) ? o_dmem_towrite : 16'b0;
    

    /* STUDENT CODE ENDS */


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
    `ifndef NDEBUG
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
        // run it for that many nano-seconds, then set
        // the breakpoint.

        // In the objects view, you can change the values to
        // hexadecimal by selecting all signals (Ctrl-A),
        // then right-click, and select Radix->Hexadecial.

        // To see the values of wires within a module, select
        // the module in the hierarchy in the "Scopes" pane.
        // The Objects pane will update to display the wires
        // in that module.

        // $display();
    end
    `endif
    endmodule

