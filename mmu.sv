`timescale 1ns / 1ps

module mmu(
          input                       clk,
          input                       rst,
          
		  // From/To CPU
		  input                       ien,
		  input [31:0]                iaddr_i,
		  output logic [31:0]         idata_i,
		  output logic                inst_ok,

		  // To data
		  input                       den,
		  input [3:0]                 dwen, // Which byte is write enabled?
		  input [31:0]                daddr_i,
		  input [31:0]                dwdata_i,
		  output logic [31:0]         drdata_i,
		  output logic                data_ok,
		  
		  //axi
		  //ar
		  output logic[3 :0]   arid,
		  output logic[31:0]   araddr,
		  output logic[7 :0]   arlen,
		  output logic[2 :0]   arsize,
		  output logic[1 :0]   arburst,
		  output logic[1 :0]   arlock,
		  output logic[3 :0]   arcache,
		  output logic[2 :0]   arprot,
		  output logic         arvalid,
		  input 	           arready,
		  //r           
		  input [3 :0]        rid,
		  input [31:0]        rdata,
		  input [1 :0]        rresp,
		  input               rlast,
		  input 	          rvalid,
		  output logic        rready,
		  //aw          
		  output logic[3 :0]   awid,
		  output logic[31:0]   awaddr,
		  output logic[7 :0]   awlen,
		  output logic[2 :0]   awsize,
		  output logic[1 :0]   awburst,
		  output logic[1 :0]   awlock,
		  output logic[3 :0]   awcache,
		  output logic[2 :0]   awprot,
		  output logic         awvalid,
		  input                awready,
		  //w          
		  output logic[3 :0]   wid,
		  output logic[31:0]   wdata,
		  output logic[3 :0]   wstrb,
		  output logic         wlast,
		  output logic         wvalid,
		  input 	           wready,
		  //b           
		  input [3 :0]         bid,
		  input [1 :0]         bresp,
		  input 	           bvalid,
		  output logic         bready
    );
   
    logic [31:0]   inst_addr_psy, data_addr_psy;
    logic          inst_uncacheable, data_uncacheable;
    
    always_comb begin : get_addr_psy
        inst_addr_psy = { 3'b0, iaddr_i[28:0] };
        data_addr_psy = { 3'b0, daddr_i[28:0] };
        inst_uncacheable = 1'd1;
        data_uncacheable = 1'd1;
    end

	// Sram like interface
    wire        inst_req, inst_wr;
    wire [31:0] inst_addr, inst_wdata;
    wire [ 1:0] inst_size;
    wire [31:0] inst_rdata;
    wire        inst_addr_ok, inst_data_ok;

    wire        data_req, data_wr;
    wire [31:0] data_addr, data_wdata;
    wire [ 1:0] data_size;
    wire [31:0] data_rdata;
    wire        data_addr_ok, data_data_ok;

	sram_like sram_interface(
		.clk				(clk),
		.rstn				(~rst),
		.inst_req           (inst_req),
        .inst_wr            (inst_wr),
        .inst_size          (inst_size),
        .inst_addr          (inst_addr),
        .inst_wdata         (inst_wdata),
        .inst_rdata         (inst_rdata),
        .inst_addr_ok       (inst_addr_ok),
        .inst_data_ok       (inst_data_ok),
		.data_req           (data_req),
        .data_wr            (data_wr),
        .data_size          (data_size),
        .data_addr          (data_addr),
        .data_wdata         (data_wdata),
        .data_rdata         (data_rdata),
        .data_addr_ok       (data_addr_ok),
        .data_data_ok       (data_data_ok),
        .ien                (ien),
        .iaddr_i            (inst_addr_psy),
        .idata_i            (idata_i),
        .inst_ok            (inst_ok),
        .den                (den),
        .dwen               (dwen),
        .daddr_i            (data_addr_psy),
        .drdata_i           (drdata_i),
        .dwdata_i           (dwdata_i),
        .data_ok            (data_ok)
	);
    
    cpu_axi_interface axi_uncached(
        .clk                (clk),
        .resetn             (~rst),
		.inst_req           (inst_req),
        .inst_wr            (inst_wr),
        .inst_size          (inst_size),
        .inst_addr          (inst_addr),
        .inst_wdata         (inst_wdata),
        .inst_rdata         (inst_rdata),
        .inst_addr_ok       (inst_addr_ok),
        .inst_data_ok       (inst_data_ok),
		.data_req           (data_req),
        .data_wr            (data_wr),
        .data_size          (data_size),
        .data_addr          (data_addr),
        .data_wdata         (data_wdata),
        .data_rdata         (data_rdata),
        .data_addr_ok       (data_addr_ok),
        .data_data_ok       (data_data_ok),
        .arid               (arid),
        .araddr             (araddr),
        .arlen              (arlen),
        .arsize             (arsize),
        .arburst            (arburst),
        .arlock             (arlock),
        .arcache            (arcache),
        .arprot             (arprot),
        .arvalid            (arvalid),
        .arready            (arready),
        .rid                (rid),
        .rdata              (rdata),
        .rresp              (rresp),
        .rlast              (rlast),
        .rvalid             (rvalid),
        .rready             (rready),
        .awid               (awid),
        .awaddr             (awaddr),
        .awlen              (awlen),
        .awsize             (awsize),
        .awburst            (awburst),
        .awlock             (awlock),
        .awcache            (awcache),
        .awprot             (awprot),
        .awvalid            (awvalid),
        .awready            (awready),
        .wid                (wid),
        .wdata              (wdata),
        .wstrb              (wstrb),
        .wlast              (wlast),
        .wvalid             (wvalid),
        .wready             (wready),
        .bid                (bid),
        .bresp              (bresp),
        .bvalid             (bvalid),
        .bready             (bready)
    );
endmodule
