`timescale 1ns / 1ps
// The program counter.

module pc(
          input 	      clk,
          input 	      rst,
          input 	      stall_i,

          input 	      is_branch_taken,
          input [31:0] 	      branch_address,

          input 	      is_exception_taken,
          input [31:0] 	      exception_address,

          output logic 	      alignment_error,
          output logic [31:0] pc_address
	  );

   reg [31:0] 		      _pc;
   always_comb begin
      if(is_exception_taken)
        pc_address = exception_address;
      if(is_branch_taken)
        pc_address = branch_address;
      else
        pc_address = _pc;
   end

   assign alignment_error = |pc_address[1:0];
   logic [31:0] next_pc;
   wire [31:0] 	seq_pc = pc_address + 32'd4;

   always_comb begin : get_next_pc
      if(stall_i)
        next_pc = pc_address;
      else
        next_pc = seq_pc;
   end

   always_ff @(posedge clk) begin
      if(rst)
        _pc <= 32'hbfc0_0000;
      else
        _pc <= next_pc;
   end
endmodule
