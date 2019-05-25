`timescale 1ns / 1ps
// The register file.
module register(
		input 		    clk,
		input 		    rst,

		input [4:0] 	    raddr_a,
		output logic [31:0] rdata_a,

		input [4:0] 	    raddr_b,
		output logic [31:0] rdata_b,

		input 		    wenable_a,
		input [4:0] 	    waddr_a,
		input [31:0] 	    wdata_a
		);

   reg [31:0] 			    _register[0:31];

   always_comb begin : read_data_a
      if(raddr_a == 5'b00000)
        rdata_a = 32'h0000_0000;
      else if(wenable_a && waddr_a == raddr_a)
        rdata_a = wdata_a;
      else
        rdata_a = _register[raddr_a];
   end

   always_comb begin : read_data_b
      if(raddr_b == 5'b00000)
        rdata_b = 32'h0000_0000;
      else if(wenable_a && waddr_a == raddr_b)
        rdata_b = wdata_a;
      else
        rdata_b = _register[raddr_b];
   end

   always_ff @(posedge clk) begin : write_data
      if(rst) begin
         for(int i = 0; i < 31; i++)
           _register[i] <= 32'h0000_0000;
      end
      else if(wenable_a)
        _register[waddr_a] <= wdata_a;
      else begin
         // Nothing happend, make vivado happy.
      end
   end
endmodule
