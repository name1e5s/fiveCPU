`timescale 1ns / 1ps
// The program counter.

module pc(
        input                       clk,
        input                       rst,
        input                       stall_i,
        input                       is_branch_taken,
        input [31:0]                branch_address,

        input                       is_exception_taken,
        input [31:0]                exception_address,

        output logic                alignment_error,
        output logic                pc_valid,
        output logic [31:0]         pc_address
);

   reg [31:0] _pc;
    assign pc_valid = stall_i || ~(is_exception_taken || is_branch_taken);
    
    assign pc_address = _pc;
    assign alignment_error = |pc_address[1:0];
    logic [31:0] next_pc;
    wire  [31:0] seq_pc = _pc + 32'd4;

    always_comb begin : get_next_pc
        if(!stall_i) begin
            if(is_exception_taken)
                next_pc = exception_address;
            else if(is_branch_taken)
                next_pc = branch_address;
            else
                next_pc = seq_pc;
        end
    end

    always_ff @(posedge clk) begin : change_pc
            if(rst)
                 _pc <= 32'hbfc0_0000;
            else if(!stall_i)
                 _pc <= next_pc;
    end
endmodule
