`timescale 1ns / 1ps

module mmu(
          input                       clk,
          input                       rst,
          
		  // From/To CPU
		  input                       ien,
		  input                       pc_changed,
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
		  output [3 :0]   arid,
		  output [31:0]   araddr,
		  output [7 :0]   arlen,
		  output [2 :0]   arsize,
		  output [1 :0]   arburst,
		  output [1 :0]   arlock,
		  output [3 :0]   arcache,
		  output [2 :0]   arprot,
		  output          arvalid,
		  input 	      arready,
		  //r           
		  input [3 :0]    rid,
		  input [31:0]    rdata,
		  input [1 :0]    rresp,
		  input           rlast,
		  input 	      rvalid,
		  output          rready,
		  //aw          
		  output [3 :0]   awid,
		  output [31:0]   awaddr,
		  output [7 :0]   awlen,
		  output [2 :0]   awsize,
		  output [1 :0]   awburst,
		  output [1 :0]   awlock,
		  output [3 :0]   awcache,
		  output [2 :0]   awprot,
		  output          awvalid,
		  input           awready,
		  //w          
		  output [3 :0]   wid,
		  output [31:0]   wdata,
		  output [3 :0]   wstrb,
		  output          wlast,
		  output          wvalid,
		  input 	      wready,
		  //b           
		  input [3 :0]    bid,
		  input [1 :0]    bresp,
		  input 	      bvalid,
		  output          bready
    );
   
    logic [31:0]   inst_addr_psy, data_addr_psy;
    logic          inst_uncacheable, data_uncacheable;
    
    always_comb begin : get_addr_psy
        inst_addr_psy = { 3'b0, iaddr_i[29:0] };
        data_addr_psy = { 3'b0, daddr_i[29:0] };
        inst_uncacheable = iaddr_i[30];
        data_uncacheable = daddr_i[30];
    end
    
    wire cached_pc_changed = pc_changed && ~inst_uncacheable;
    wire uncached_pc_changed =  pc_changed && inst_uncacheable;
    
    
    // I$
    wire  [31:0]        _inst_addr_mmu;
    wire                _inst_read_req;
    wire                _inst_addr_ok;
    wire  [31:0]        _inst_read_data;
    wire                _inst_mmu_valid;
    wire  [31:0]        _inst_mmu_last;
    wire  [31:0]        _cached_inst_data;
    wire  [31:0]        _cached_inst_ok;

    instruction_cache icache_0(
        .clk            (clk),
        .rst            (rst),
        .inst_en        (ien & ~inst_uncacheable),
        .inst_addr      (inst_addr_psy),
        .pc_changed     (cached_pc_changed),
        .inst_data      (_cached_inst_data),
        .inst_ok        (_cached_inst_ok),
        .inst_addr_mmu  (_inst_addr_mmu),
        .inst_read_req  (_inst_read_req),
        .inst_addr_ok   (_inst_addr_ok),
        .inst_read_data (_inst_read_data),
        .mmu_valid      (_inst_mmu_valid),
        .mmu_last       (_inst_mmu_last)
    );
    
    // Cache read interface
    //ar
	wire [3 :0]               r_arid;
	wire [31:0]               r_araddr;
	wire [7 :0]               r_arlen;
	wire [2 :0]               r_arsize;
	wire [1 :0]               r_arburst;
	wire [1 :0]               r_arlock;
	wire [3 :0]               r_arcache;
	wire [2 :0]               r_arprot;
	wire                      r_arvalid;
	wire                      r_arready;
	//r           
	wire[3 :0]                r_rid;
	wire[31:0]                r_rdata;
	wire[1 :0]                r_rresp;
	wire                      r_rlast;
	wire                      r_rvalid;
	wire                      r_rready;
	
	cache_axi_rinterface r_interface(
	   .clk                (clk),
	   .rst                (rst),
	   .inst_addr_mmu      (_inst_addr_mmu),
	   .inst_read_req      (_inst_read_req),
	   .inst_addr_ok       (_inst_addr_ok),
	   .inst_read_data     (_inst_read_data),
	   .inst_mmu_valid     (_inst_mmu_valid),
	   .inst_mmu_last      (_inst_mmu_last),
	   .arid               (r_arid),
	   .araddr             (r_araddr),
	   .arlen              (r_arlen),
	   .arsize             (r_arsize),
	   .arburst            (r_arburst),
	   .arlock             (r_arlock),
	   .arcache            (r_arcache),
	   .arprot             (r_arprot),
	   .arvalid            (r_arvalid),
	   .rid                (rid),
	   .rdata              (rdata),
	   .rresp              (rresp),
	   .rlast              (rlast),
	   .rvalid             (rvalid),
	   .rready             (r_rready)
	);
    
    
    // Uncached load/store
    wire [31:0]  _inst_addr, _inst_data, _data_addr, _data_wdata, _data_rdata;
    wire [3:0]   _data_wen;
    wire         iok, dok;
    wire         inst_req, inst_wr, inst_addr_ok, inst_data_ok,data_req, data_wr, data_addr_ok, data_data_ok;
    wire [31:0]  inst_addr, inst_wdata, inst_rdata, data_addr, data_wdata, data_rdata;
    wire [1:0]   data_size, inst_size;
   
    logic [3 :0]   _arid;
    logic [31:0]   _araddr;
    logic [7 :0]   _arlen;
    logic [2 :0]   _arsize;
    logic [1 :0]   _arburst;
    logic [1 :0]   _arlock;
    logic [3 :0]   _arcache;
    logic [2 :0]   _arprot;
    logic          _arvalid;
    logic 	       _arready;
       
    logic [3 :0]   _rid;
    logic [31:0]   _rdata;
    logic [1 :0]   _rresp;
    logic          _rlast;
    logic 	       _rvalid;
    logic          _rready;
         
    logic [3 :0]   _awid;
    logic [31:0]   _awaddr;
    logic [7 :0]   _awlen;
    logic [2 :0]   _awsize;
    logic [1 :0]   _awburst;
    logic [1 :0]   _awlock;
    logic [3 :0]   _awcache;
    logic [2 :0]   _awprot;
    logic          _awvalid;
    logic          _awready;
       
    logic [3 :0]   _wid;
    logic [31:0]   _wdata;
    logic [3 :0]   _wstrb;
    logic          _wlast;
    logic          _wvalid;
    logic 	       _wready;
           
    logic [3 :0]   _bid;
    logic [1 :0]   _bresp;
    logic 	       _bvalid;
    logic          _bready;

   cpu_axi_interface axi(
			 .clk                (clk),
			 .resetn             (~rst),
			 .inst_req           (inst_req & inst_uncacheable),
			 .inst_wr            (inst_wr & inst_uncacheable),
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
			 .arid               (_arid),
			 .araddr             (_araddr),
			 .arlen              (_arlen),
			 .arsize             (_arsize),
			 .arburst            (_arburst),
			 .arlock             (_arlock),
			 .arcache            (_arcache),
			 .arprot             (_arprot),
			 .arvalid            (_arvalid),
			 .arready            (_arready),
			 .rid                (_rid),
			 .rdata              (_rdata),
			 .rresp              (_rresp),
			 .rlast              (_rlast),
			 .rvalid             (_rvalid),
			 .rready             (_rready),
			 .awid               (_awid),
			 .awaddr             (_awaddr),
			 .awlen              (_awlen),
			 .awsize             (_awsize),
			 .awburst            (_awburst),
			 .awlock             (_awlock),
			 .awcache            (_awcache),
			 .awprot             (_awprot),
			 .awvalid            (_awvalid),
			 .awready            (_awready),
			 .wid                (_wid),
			 .wdata              (_wdata),
			 .wstrb              (_wstrb),
			 .wlast              (_wlast),
			 .wvalid             (_wvalid),
			 .wready             (_wready),
			 .bid                (_bid),
			 .bresp              (_bresp),
			 .bvalid             (_bvalid),
			 .bready             (_bready)
    );

   sram_like sram_interface(
			    .clk                (clk),
			    .rstn               (~rst),
			    .pc_changed         (pc_changed),
			    .ien                (ien),
			    .iaddr_i            ({3'b0, _inst_addr[28:0]}),
			    .idata_i            (_inst_data),
			    .inst_ok            (iok),
			    .den                (den),
			    .dwen               (_data_wen),
			    .daddr_i            ({3'b0, _data_addr[28:0]}),
			    .dwdata_i           (_data_wdata),
			    .drdata_i           (_data_rdata),
			    .data_ok            (dok),
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
			    .data_data_ok       (data_data_ok)
    );
endmodule
