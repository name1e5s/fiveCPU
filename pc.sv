`timescale 1ns / 1ps
// The program counter.

module pc(
        input               clk,
        input               rst,
        input               stall_i,
        
        input               is_branch_taken,
        input       [31:0]  branch_address,
        
        output logic        alignment_error,
        output logic[31:0]  pc_address
    );

reg [31:0] _pc;
assign pc_address = _pc;
assign alignment_error = |_pc[1:0];
logic [31:0] next_pc;
logic [31:0] seq_pc = _pc + 32'd4;

always_comb begin : get_next_pc
    if(stall)
        next_pc = _pc;
    else if(is_branch_taken)
        next_pc = branch_address;
    else
        next_pc = seq_pc;
end

always_ff @(posedge clk) begin
    if(rst)
        _pc <= 32'h0000_0000;
    else
        _pc <= next_pc;
end

endmodule
