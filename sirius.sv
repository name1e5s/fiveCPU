`timescale 1ns / 1ps
module sirius(
        input               clk,
        input               rst,
        
        // To inst
        output  logic[31:0] inst_addr,
        input        [31:0] inst_data,
        
        // To data
        input        [3:0]  data_wen, // Which byte is write enabled?
        input               data_addr,
        input               data_wdata,
        input               data_rdata
    );
// TODO: <>
endmodule
