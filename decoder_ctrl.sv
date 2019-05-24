`timescale 1ns / 1ps
`include "common.vh"
`include "alu_common.vh"

module decoder_ctrl(
           input           clk,
           input           rst,
           
           input [5:0]     opcode,
           input [4:0]     rt,
           input [4:0]     rd,
           input [5:0]     funct,
           input           is_branch,
           input           is_branch_al,

           output logic             in_delay_slot, // In delay slot?
           output logic             undefined_inst, // 1 as received a unknown operation.
           output logic[5:0]        alu_op,         // ALU operation
           output logic[1:0]        alu_src,        // ALU oprand 2 source(0 as rt, 1 as immed)
           output logic             alu_imm_src,    // ALU immediate src - 1 as unsigned, 0 as signed.
           output logic[1:0]        mem_type,       // Memory operation type -- load or store
           output logic[2:0]        mem_size,       // Memory operation size -- B,H,W,WL,WR
           output logic[4:0]        wb_reg_dest,    // Writeback register address
           output logic[4:0]        wb_reg_en,      // Writeback is enabled
           output logic             unsigned_flag   // Is this a unsigned operation in MEM stage.
);

reg _in_delay_slot;
assign in_delay_slot = _in_delay_slot;
always_ff @(posedge clk) begin
    if(rst)
        _in_delay_slot <= 1'b0;
    else if(is_branch && is_branch_al)
        _in_delay_slot <= 1'b1;
   else
        _in_delay_slot <= 1'b0;
end

// Control logic.
always_comb begin : decoder
    if(opcode == 6'b001000) begin
        alu_op      = `ALU_ADD;
        alu_src     = `SRC_IMM;
        alu_imm_src = `SIGN_EXTENDED;
        mem_type    = `MEM_NOOP;
        mem_size    = `SZ_FULL;
        wb_reg_dest = rt;
        wb_reg_en   = 1'b1;
        unsigned_flag = 1'b0;
        undefined_inst = 1'b0;
    end
end
endmodule
