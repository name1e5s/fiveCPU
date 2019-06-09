`timescale 1ns / 1ps

module cache_axi_rinterface(
    input                       clk,
    input                       rst,
    
    // From/to i$
    input  [31:0]               inst_addr_mmu,
    input                       inst_read_req,
    output logic                inst_addr_ok,
    output logic  [31:0]        inst_read_data,
    output logic                inst_mmu_valid,
    output logic                inst_mmu_last,
    
    //ar
	output [3 :0]               arid,
	output [31:0]               araddr,
	output [7 :0]               arlen,
	output [2 :0]               arsize,
	output [1 :0]               arburst,
	output [1 :0]               arlock,
	output [3 :0]               arcache,
	output [2 :0]               arprot,
	output                      arvalid,
	input                       arready,
	//r           
	input [3 :0]                rid,
	input [31:0]                rdata,
	input [1 :0]                rresp,
	input                       rlast,
	input                       rvalid,
	output                      rready
);

   assign arid    = 4'd0;
   assign araddr  = inst_addr_mmu;
   assign arlen   = 8'd15;
   assign arsize  = 3'd3;
   assign arburst = 2'd1;
   assign arlock  = 2'd0;
   assign arcache = 4'd0;
   assign arprot  = 3'd0;
   assign arvalid = inst_read_req;
   assign inst_addr_ok = arready;
   assign rready = 1'd1;
   assign inst_read_data = rdata;
   assign inst_mmu_valid = rvalid;
   assign inst_mmu_last = rlast;
   
endmodule
