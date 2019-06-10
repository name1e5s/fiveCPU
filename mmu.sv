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
    // SRAM output signal
    wire [31:0] uncached_idata_i;
    wire        uncached_inst_ok;
    wire [31:0] uncached_drdata_i;
    wire        uncached_data_ok;
    wire [ 3:0] uncached_arid;
    wire [31:0] uncached_araddr;
    wire [7 :0] uncached_arlen;
    wire [2 :0] uncached_arsize;
    wire [1 :0] uncached_arburst;
    wire [1 :0] uncached_arlock;
    wire [3 :0] uncached_arcache;
    wire [2 :0] uncached_arprot;
    wire        uncached_arvalid;
    wire        uncached_rready;
    wire [3 :0] uncached_awid;
    wire [31:0] uncached_awaddr;
    wire [7 :0] uncached_awlen;
    wire [2 :0] uncached_awsize;
    wire [1 :0] uncached_awburst;
    wire [1 :0] uncached_awlock;
    wire [3 :0] uncached_awcache;
    wire [2 :0] uncached_awprot;
    wire        uncached_awvalid;
    wire [3 :0] uncached_wid;
    wire [31:0] uncached_wdata;
    wire [3 :0] uncached_wstrb;
    wire        uncached_wlast;
    wire        uncached_wvalid;
    wire        uncached_bready;

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
        .ien                (ien & inst_uncacheable),
        .iaddr_i            (inst_addr_psy),
        .idata_i            (uncached_idata_i),
        .inst_ok            (uncached_inst_ok),
        .den                (den & data_uncacheable),
        .dwen               (dwen & {4{data_uncacheable}}),
        .daddr_i            (data_addr_psy),
        .drdata_i           (uncached_drdata_i),
        .dwdata_i           (dwdata_i),
        .data_ok            (uncached_data_ok)
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
        .arid               (uncached_arid),
        .araddr             (uncached_araddr),
        .arlen              (uncached_arlen),
        .arsize             (uncached_arsize),
        .arburst            (uncached_arburst),
        .arlock             (uncached_arlock),
        .arcache            (uncached_arcache),
        .arprot             (uncached_arprot),
        .arvalid            (uncached_arvalid),
        .arready            (arready),
        .rid                (rid),
        .rdata              (rdata),
        .rresp              (rresp),
        .rlast              (rlast),
        .rvalid             (rvalid),
        .rready             (uncached_rready),
        .awid               (uncached_awid),
        .awaddr             (uncached_awaddr),
        .awlen              (uncached_awlen),
        .awsize             (uncached_awsize),
        .awburst            (uncached_awburst),
        .awlock             (uncached_awlock),
        .awcache            (uncached_awcache),
        .awprot             (uncached_awprot),
        .awvalid            (uncached_awvalid),
        .awready            (awready),
        .wid                (uncached_wid),
        .wdata              (uncached_wdata),
        .wstrb              (uncached_wstrb),
        .wlast              (uncached_wlast),
        .wvalid             (uncached_wvalid),
        .wready             (wready),
        .bid                (bid),
        .bresp              (bresp),
        .bvalid             (bvalid),
        .bready             (uncached_bready)
    );

    // Cached signal
    wire [31:0] cached_idata_i;
    wire        cached_inst_ok;
    wire [31:0] cached_drdata_i;
    wire        cached_data_ok;
    wire [ 3:0] cached_arid;
    wire [31:0] cached_araddr;
    wire [7 :0] cached_arlen;
    wire [2 :0] cached_arsize;
    wire [1 :0] cached_arburst;
    wire [1 :0] cached_arlock;
    wire [3 :0] cached_arcache;
    wire [2 :0] cached_arprot;
    wire        cached_arvalid;
    wire        cached_rready;
    wire [3 :0] cached_awid;
    wire [31:0] cached_awaddr;
    wire [7 :0] cached_awlen;
    wire [2 :0] cached_awsize;
    wire [1 :0] cached_awburst;
    wire [1 :0] cached_awlock;
    wire [3 :0] cached_awcache;
    wire [2 :0] cached_awprot;
    wire        cached_awvalid;
    wire [3 :0] cached_wid;
    wire [31:0] cached_wdata;
    wire [3 :0] cached_wstrb;
    wire        cached_wlast;
    wire        cached_wvalid;
    wire        cached_bready;

    // internal signal
    wire [31:0] _inst_addr_mmu;
    wire        _inst_read_req;
    wire        _inst_addr_ok;
    wire        _inst_read_data;
    wire        _mmu_valid;
    wire        _mmu_last;

    instruction_cache icache_0(
        .clk                (clk),
        .rst                (rst),
        .inst_en            (ien & (~inst_uncacheable)),
        .inst_addr          (inst_addr_psy),
        .inst_data          (cached_idata_i),
        .inst_ok            (cached_inst_ok),
        .inst_addr_mmu      (_inst_addr_mmu),
        .inst_read_req      (_inst_read_req),
        .inst_addr_ok       (_inst_addr_ok),
        .inst_read_data     (_inst_read_data),
        .mmu_valid          (_mmu_valid),
        .mmu_last           (_mmu_last)
    );

    cache_axi_rinterface cache_rinterface(
        .clk                (clk),
        .rst                (rst),
        .inst_addr_mmu      (_inst_addr_mmu),
        .inst_read_req      (_inst_read_req),
        .inst_addr_ok       (_inst_addr_ok),
        .inst_read_data     (_inst_read_data),
        .inst_mmu_valid     (_inst_mmu_valid),
        .inst_mmu_last      (inst_mmu_last),
        .arid               (cached_arid),
        .araddr             (cached_araddr),
        .arlen              (cached_arlen),
        .arsize             (cached_arsize),
        .arburst            (cached_arburst),
        .arlock             (cached_arlock),
        .arcache            (cached_arcache),
        .arprot             (cached_arprot),
        .arvalid            (cached_arvalid),
        .rready             (rcached_ready)
    );

    // Signal select
    always_comb begin : select_output
        if( (den && data_uncacheable) || 
                (ien && inst_uncacheable)) begin
        // Uncacheable load/store
            idata_i     = uncached_idata_i;
            inst_ok     = uncached_inst_ok;
            drdata_i    = uncached_drdata_i;
            data_ok     = uncached_data_ok;
            arid        = uncached_arid;
            araddr      = uncached_araddr;
            arlen       = uncached_arlen;
            arsize      = uncached_arsize;
            arburst     = uncached_arburst;
            arlock      = uncached_arlock;
            arcache     = uncached_arcache;
            arprot      = uncached_arprot;
            arvalid     = uncached_arvalid;
            rready      = uncached_rready;
            awid        = uncached_awid;
            awaddr      = uncached_awaddr;
            awlen       = uncached_awlen;
            awsize      = uncached_awsize;
            awburst     = uncached_awburst;
            awlock      = uncached_awlock;
            awcache     = uncached_awcache;
            awprot      = uncached_awprot;
            awvalid     = uncached_awvalid;
            wid         = uncached_wid;
            wdata       = uncached_wdata;
            wstrb       = uncached_wstrb;
            wlast       = uncached_wlast;
            wvalid      = uncached_wvalid;
            bready      = uncached_bready;
        end
        else begin
        // Cacheable load/store
            idata_i     = cached_idata_i;
            inst_ok     = cached_inst_ok;
            drdata_i    = cached_drdata_i;
            data_ok     = cached_data_ok;
            arid        = cached_arid;
            araddr      = cached_araddr;
            arlen       = cached_arlen;
            arsize      = cached_arsize;
            arburst     = cached_arburst;
            arlock      = cached_arlock;
            arcache     = cached_arcache;
            arprot      = cached_arprot;
            arvalid     = cached_arvalid;
            rready      = cached_rready;
            awid        = cached_awid;
            awaddr      = cached_awaddr;
            awlen       = cached_awlen;
            awsize      = cached_awsize;
            awburst     = cached_awburst;
            awlock      = cached_awlock;
            awcache     = cached_awcache;
            awprot      = cached_awprot;
            awvalid     = cached_awvalid;
            wid         = cached_wid;
            wdata       = cached_wdata;
            wstrb       = cached_wstrb;
            wlast       = cached_wlast;
            wvalid      = cached_wvalid;
            bready      = cached_bready;
        end
    end
endmodule
