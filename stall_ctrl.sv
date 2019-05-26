`timescale 1ns / 1ps
`include "common.vh"
module stall_ctrl(
		  input [4:0]  de_rs,
		  input [4:0]  de_rt,
		  input        ex_stall_i,
          input [1:0]  id_ex_mem_type,
		  input [1:0]  ex_mem_type,
		  input [4:0]  ex_rt,

		  output logic if_stall_o,
		  output logic id_stall_o,
		  output logic ex_stall_o
		  );
   logic 		       load_use;
   logic               store_load;

   always_comb begin
      if_stall_o = ex_stall_i | load_use | store_load;
      id_stall_o = ex_stall_i;
      ex_stall_o = 1'b0;
   end

   always_comb begin
      if(ex_mem_type == `MEM_STOR && id_ex_mem_type == `MEM_LOAD)
         store_load = 1'b1;
      else
         store_load = 1'b0;
   end
   always_comb begin : detect_load_use
      if(ex_mem_type == `MEM_LOAD && 
         ex_rt != 5'd0 && (ex_rt == de_rs || ex_rt == de_rt))
        load_use = 1'b1;
      else
        load_use = 1'b0;
   end
endmodule
