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

    // LTU Dependency Detection//
    wire LTU_within_A, LTU_within_B, LTU_A, LTU_between_XB_DA, LTU_between_XA_DB, LTU_B;
    wire mem_hazard;                // Case 4: Both A and B are memory instructions.
    wire B_need_A;                  // Case 3: The computation of PipeB need the result from Pipe A.

    assign LTU_within_A =     (x2m_bus_A[19]) && 
                            (((d2x_bus_A[24]) && (d2x_bus_A[33:31] == x2m_bus_A[27:25])) || 
                            ((d2x_bus_A[23]) && (d2x_bus_A[30:28] == x2m_bus_A[27:25]) && (~d2x_bus_A[18])) || (d2x_bus_A[15:12]==4'b0));
    assign LTU_between_XB_DA    =     (x2m_bus_B[19]) && 
                            (((d2x_bus_A[24]) && (d2x_bus_A[33:31] == x2m_bus_B[27:25])) || 
                            ((d2x_bus_A[23]) && (d2x_bus_A[30:28] == x2m_bus_B[27:25]) && (~d2x_bus_A[18])) || (d2x_bus_A[15:12]==4'b0));
    assign LTU_A = LTU_within_A || LTU_between_XB_DA ;              //For Case 1 of .md file

    assign LTU_within_B         =     (x2m_bus_B[19]) && 
                            (((d2x_bus_B[24]) && (d2x_bus_B[33:31] == x2m_bus_B[27:25])) || 
                            ((d2x_bus_B[23]) && (d2x_bus_B[30:28] == x2m_bus_B[27:25]) && (~d2x_bus_B[18])) || (d2x_bus_B[15:12]==4'b0));

    assign LTU_between_XA_DB    =     (x2m_bus_A[19]) && 
                            (((d2x_bus_B[24]) && (d2x_bus_B[33:31] == x2m_bus_A[27:25])) || 
                            ((d2x_bus_B[23]) && (d2x_bus_B[30:28] == x2m_bus_A[27:25]) && (~d2x_bus_B[18])) || (d2x_bus_B[15:12]==4'b0));
    assign LTU_B = LTU_within_B || LTU_between_XA_DB ;              //For Case 2 of .md file

    assign mem_hazard = (d2x_bus_A[19] || d2x_bus_A[18]) && (d2x_bus_B[19] || d2x_bus_B[18]);                   //For Case 4 of .md file

    assign B_need_A = (d2x_bus_A[27:25] == d2x_bus_B[33:31]) || (d2x_bus_A[27:25] == d2x_bus_B[30:28]);         //For Case 3 of .md file


    //Instructions registers//
    assign  d_i_bus_A = (x_br_taken_or_ctrl == 1) ? {16{1'b0}} : i_cur_insn_A; 
    assign  d_i_bus_A = (x_br_taken_or_ctrl == 1) ? {16{1'b0}} : i_cur_insn_B;

    //Instructions registers// 
    Nbit_reg #(16, 16'b0) d_insn_reg_A (.in(d_i_bus_A), .out(d2x_bus_tmp_A), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) d_insn_reg_B (.in(d_i_bus_B), .out(d2x_bus_tmp_B), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) d_insn_reg_A (.in(d_i_bus_A), .out(d2x_bus_tmp_A), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'b0) d_insn_reg_B (.in(d_i_bus_B), .out(d2x_bus_tmp_B), .clk(clk), .we(~load2use), .gwe(gwe), .rst(rst));

    // Stall registers //
    Nbit_reg #(2, 2'b10) d_stall_reg_A (.in(d_stall_i_A), .out(d_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) d_stall_reg_A (.in(d_stall_i_A), .out(d_stall_o_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) x_stall_reg_B (.in(x_stall_i_B), .out(test_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(2, 2'b10) x_stall_reg_B (.in(x_stall_i_B), .out(test_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    assign d_stall_i_A =  (x_br_taken_or_ctrl_A == 1) ? 2'd2 : 2'd0;
    assign d_stall_i_B =  (x_br_taken_or_ctrl_B == 1) ? 2'd2 : 2'd0;

    assign x_stall_i_A =  (LTU_A == 1) ? 2'd3 : 
                          d_stall_o_A;
    assign x_stall_i_B = (LTU_A == 1) ? 2'd1 :
                         (B_need_A || mem_hazard) ? 2'd1 :
                         (LTU_B == 1) ? 2'd3 :
                         d_stall_o_B;

    /***** Pipeline Stage2: Decoder *****/
    wire[33:0] d2x_bus_A, d2x_bus_B;
    lc4_decoder Decoder_Pipe_A (
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
            .insn(d2x_bus_A[15:0])
    );

    lc4_decoder Pipeline_Pipe_B (
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
    
    //**** Test Wire Assignment ****//
    assign o_cur_pc =           f2d_pc;
    assign o_dmem_addr =        ((m2w_bus[19] == 1) || (m2w_bus[18] == 1)) ? m_O_o : 16'b0;                   
    assign o_dmem_we =          m2w_bus[18];
    assign o_dmem_towrite =     wm_bypass_res;

    assign test_cur_pc_A =        w_o_pc_A;
    assign test_cur_pc_B =        w_o_pc_B;
    assign test_cur_insn_A =      w_o_bus_A[15:0];
    assign test_cur_insn_B =      w_o_bus_B[15:0];
    assign test_regfile_we_A =    w_o_bus_A[22];
    assign test_regfile_we_B =    w_o_bus_B[22];
    assign test_regfile_wsel_A =  w_o_bus_A[27:25];
    assign test_regfile_wsel_B =  w_o_bus_B[27:25];
    assign test_regfile_data_A =  write_back_A;
    assign test_regfile_data_A =  write_back_B;
    assign test_nzp_we_A =        w_o_bu_A[21];
    assign test_nzp_we_B =        w_o_bu_B[21];
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
