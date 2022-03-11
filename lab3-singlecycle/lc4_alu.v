/* TODO: name and PennKeys of all group members here */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);
        //signed immediate numbers
        wire [10:0] IMM11;
        assign IMM11 = i_insn[10:0];


        //*** SUB Modules Start ***//
        //*************************//
        //shift and mod module//
        wire [15:0] shiftnMOD_result;
        shift_and_mod_cal ShiftnMOD0(.shift_in1(i_r1data), .shift_in2(i_r2data),
        .insn(i_insn), .o_shift_and_mod(shiftnMOD_result));

        //logic as a module//
        wire[15:0] logic_result;
        logic_cal log0(.login1(i_r1data), .login2(i_r2data),
        .insn(i_insn[8:0]), .log_result(logic_result));

        //const and hiconst module//
        wire[15:0] const_result;
        const_cal const0(.constin(i_r1data), .insn(i_insn), .con_result(const_result));

        //compare as a module//
        wire[15:0] compare_result;
        cmp_calcu cmp0(.cmp_in1(i_r1data), .cmp_in2(i_r2data), .insn(i_insn), .cmp_result(compare_result));

        //All the ALU-related intructions and
        wire[15:0] CLA_related_result;
        CLA_calcu cla0(.cla_in1(i_r1data), .cla_in2(i_r2data), .pc_in(i_pc),
        .insn(i_insn[15:0]), .cla_result(CLA_related_result));
        //*** SUB Modules End ***//
        //***********************//


        //*******************************************//
        //******Single-Categorized Instructions******//
        //TRAP//
        wire [15:0] TRAP;
        assign TRAP = (i_pc & 16'h0000) | (16'h8000 | {8'b00000000, i_insn[7:0]});

        //DIV//
        wire [15:0] DIV_result;
        lc4_divider DIV_cal(.i_dividend(i_r1data), .i_divisor(i_r2data), .o_remainder(), .o_quotient(DIV_result));

        //MUL//
        wire [15:0] MUL_result;
        assign MUL_result = i_r1data * i_r2data;

        //JSR and JSRR
        wire [15:0] JSR_result, JSRR_result;
        assign JSRR_result = i_r1data;
        assign JSR_result = (i_pc & 16'h8000) | (IMM11 << 4);

        //RTI
        wire [15:0] RTI_result;
        assign RTI_result = i_r1data;
        //*******************************************//
        //*** Single Categorized Instructions End ***//


        //***********************//
        //Output the final result
        assign o_result =   (i_insn[15:12] == 4'b1010) ? shiftnMOD_result:
                            (i_insn[15:12] == 4'b0101) ? logic_result:
                            (i_insn[15:12] == 4'b1001) ? const_result:
                            (i_insn[15:12] == 4'b1101) ? const_result:
                            (i_insn[15:12] == 4'b0010) ? compare_result:
                            (i_insn[15:12] == 4'b1111) ? TRAP:
                            ({i_insn[15:12], i_insn[5:3]} == 7'b0001001) ? MUL_result:
                            ({i_insn[15:12], i_insn[5:3]} == 7'b0001011) ? DIV_result:
                            (i_insn[15:11] == 5'b01001) ? JSR_result:           //JSR
                            (i_insn[15:11] == 5'b01000) ? JSRR_result:          //JSRR
                            (i_insn[15:12] == 4'b1000) ? RTI_result:             //RTI
                            CLA_related_result;
endmodule


//**SHIFT and MOD instructions (i_insn[15:12] = 1010)**//
//**in1: Rs(i_r1data); in2: Rt(i_r2data)**//
module shift_and_mod_cal (
        input wire [15:0] shift_in1,shift_in2,
        input wire [15:0] insn,
        output wire [15:0] o_shift_and_mod
);

        wire [15: 0] MOD_result;
        lc4_divider mod(.i_dividend(shift_in1), .i_divisor(shift_in2), .o_remainder(MOD_result),.o_quotient());

        assign o_shift_and_mod =    (insn[5:4] == 2'b00) ? (shift_in1 << insn[3:0]):
                                    (insn[5:4] == 2'b01) ? $signed($signed(shift_in1) >>> insn[3:0]):
                                    (insn[5:4] == 2'b10) ? (shift_in1 >> insn[3:0]):
                                    MOD_result;

        
endmodule


//**Logic instructions (i_insn[15:12] = 1010)**//
//**in1: Rs(i_r1data); in2: Rt(i_r2data)**//
module logic_cal(
        input wire [15:0] login1,login2,
        input wire [8:0] insn,
        output wire [15:0] log_result
);
        wire [15:0] SIMM5;
        assign SIMM5 = {{11{insn[4]}}, insn[4:0]};

        assign log_result =     (insn[5] == 1'b1) ? (login1 & SIMM5):
                                (insn[4:3] == 2'b00) ? (login1 & login2):
                                (insn[4:3] == 2'b01) ? (~login1):
                                (insn[4:3] == 2'b10) ? (login1 | login2):
                                (insn[4:3] == 2'b11) ? (login1 ^ login2):
                                16'b0000;
endmodule

//**CONST and HICONST**//
//**constin: i_r1data; in2: Rt(i_r2data)**//
module const_cal(
        input wire [15:0] constin,
        input wire [15:0] insn,
        output wire [15:0] con_result
);
        wire [15:0] CONST, HICONST;
        wire [15:0] UIMM8 = {8'b00000000, insn[7:0]};
        assign CONST = {{7{insn[8]}}, insn[8:0]};
        assign HICONST = (constin & 16'h00ff) | (UIMM8 << 8);

        assign con_result = (insn[15:12] == 4'b1001) ? CONST : HICONST;
endmodule

//** Compare instructions(i_insn[15:12] = 1010) **//
//**** in1: Rs(i_r1data); in2: Rt(i_r2data) ****//
module cmp_calcu (
        input wire [15:0] cmp_in1, cmp_in2,
        input wire [15:0] insn,
        output wire [15:0] cmp_result
);
        wire [15:0] IMM7, UIMM7;
        wire [15:0] CMP, CMPU, CMPI, CMPIU;
        assign IMM7 = {{9{insn[6]}}, insn[6:0]};
        assign UIMM7 = {9'b000000000, insn[6:0]};

        assign CMP =    ($signed(cmp_in1) > $signed(cmp_in2)) ? 16'h0001:
                        ($signed(cmp_in1) == $signed(cmp_in2)) ? 16'h0000:
                        16'hffff;

        assign CMPU =   ($unsigned(cmp_in1) > $unsigned(cmp_in2)) ? 16'h0001:
                        ($unsigned(cmp_in1) == $unsigned(cmp_in2)) ? 16'h0000:
                        16'hffff;

        assign CMPI =   ($signed(cmp_in1) > $signed(IMM7)) ? 16'h0001:
                        ($signed(cmp_in1) == $signed(IMM7)) ? 16'h0000:
                        16'hffff;

        assign CMPIU =  ($unsigned(cmp_in1) > UIMM7) ? 16'h0001:
                        ($unsigned(cmp_in1) == UIMM7) ? 16'h0000:
                        16'hffff;

        assign cmp_result =     (insn[8:7] == 2'b00) ? CMP:
                                (insn[8:7] == 2'b01) ? CMPU:
                                (insn[8:7] == 2'b10) ? CMPI:
                                CMPIU;
endmodule

module CLA_calcu(
        input wire [15:0] cla_in1, cla_in2, pc_in, insn,
        output wire [15:0] cla_result);
      //** CLA Input Select **//
      wire signed [15:0] CLA_in1, CLA_in2;
      wire CLA_cin;

      assign CLA_in1 = (insn[15:12] == 4'b0000) ? pc_in:
                       (insn[15:11] == 5'b11001) ? pc_in:
                       cla_in1;

      assign CLA_in2 = (insn[15:12] == 4'b0000) ? {{7{insn[8]}}, insn[8:0]}: // BRANCH
                       ({insn[15:12], insn[5]} == 5'b00011) ? {{11{insn[4]}}, insn[4:0]}: // ADD IMM5
                       ({insn[15:12], insn[4]} == 5'b00011) ? (~cla_in2): //SUB
                       (insn[15:12] == 4'b0110) ? {{10{insn[5]}}, insn[5:0]}: //LDR
                       (insn[15:12] == 4'b0111) ? {{10{insn[5]}}, insn[5:0]}: // STR
                       (insn[15:11] == 5'b11000) ? 16'h0000: // JMPR
                       (insn[15:11] == 5'b11001) ? {{5{insn[10]}}, insn[10:0]}: //JMP
                       cla_in2;

      assign CLA_cin = (insn[15:12] == 4'b0000) ? 1'b1:                         //BRANCH, NOP
                       ({insn[15:12], insn[5:3]} == 8'b0001010) ? 1'b1:         //SUB
                       (insn[15:11] == 5'b11001) ? 1'b1:                        //JMP
                       1'b0;

      cla16 CLA_cal(.a(CLA_in1), .b(CLA_in2), .cin(CLA_cin), .sum(cla_result));

endmodule
