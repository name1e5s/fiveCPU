`timescale 1ns / 1ps
module forwarding(
        input [4:0]                     de_reg,
        input                           ex_reg_en,
        input [4:0]                     ex_reg,
        input                           mem_reg_en,
        input [4:0]                     mem_reg,

        input [31:0]                    de_data,
        input [31:0]                    ex_data,
        input [31:0]                    mem_data,

        output logic [31:0]             reg_data
        );

    always_comb begin
        if(de_reg != 5'd0) begin
            if(de_reg == ex_reg && ex_reg_en)
                reg_data = ex_data;
            else if(de_reg == mem_reg && mem_reg_en)
                reg_data = mem_data;
            else
                reg_data = de_data;
        end
        else
            reg_data = 32'd0;
    end

endmodule
