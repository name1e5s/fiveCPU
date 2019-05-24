`timescale 1ns / 1ps
`include "common.vh"
module stall_ctrl(
        input   [4:0]   de_rs,
        input   [4:0]   de_rt,
        input           ex_stall_i,

        input           ex_mem_type,
        input           ex_rt,
        
        output  logic   if_stall_o,
        output  logic   id_stall_o,
        output  logic   ex_stall_o
    );
logic   load_use;

always_comb begin
    if_stall_o = ex_stall_i | load_use;
    id_stall_o = ex_stall_i | load_use;
    ex_stall_o = 1'b0;
end

always_comb begin : detect_load_use
    if(ex_mem_type == `MEM_LOAD &&
       ex_rt != 5'd0 && (ex_rt == de_rs || ex_rt == de_rt))
       load_use = 1'b1;
    load_use = 1'b0;
end
endmodule