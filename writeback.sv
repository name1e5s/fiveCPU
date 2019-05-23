`timescale 1ns / 1ps
`include "common.vh"
module writeback(
        input   [31:0]      result,
        input   [31:0]      pc_address,
        input   [4:0]       reg_dest,
        input               write_en,
        input               branch_link,
        
        output  logic       reg_write_en,
        output  logic[4:0]  reg_write_dest,
        output  logic[31:0] reg_write_data
);

always_comb begin
    if(branch_link) begin
        reg_write_dest = 5'h1f;
        reg_write_data = pc_address;
        reg_write_en = 1'b1;
    end
    else begin
        reg_write_en = write_en;
        reg_write_dest = reg_dest;
        reg_write_data = result;
    end
end
endmodule
