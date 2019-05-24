`timescale 1ns / 1ps
`include "alu_common.vh"
module alu_alpha(
           input               clk,
           input               rst,
           input               stall_i,
           input               flush_i,
           input               hilo_accessed,

           input   [5:0]       alu_op,
           input   [31:0]      src_a,
           input   [31:0]      src_b,

           // For MFC0/MTC0
           input   [4:0]       rd,
           input   [2:0]       sel,
           output  [7:0]       cop0_addr, // rd || sel
           input   [31:0]      cop0_data,

           output logic[31:0]  result,
           output logic        cop0_wen,
           output logic        priv_inst,
           output logic        exp_overflow,
           output logic        exp_eret,
           output logic        exp_syscal,
           output logic        exp_break,
           output logic        stall_o
       );

reg [63:0] hilo;
wire hi = hilo[63:32];
wire lo = hilo[31:0];
wire [31:0] add_result = src_a + src_b;
wire [31:0] sub_result = src_a - src_b;

// COP0
assign cop0_addr = {rd, sel};
assign exp_eret = alu_op == `ALU_ERET;
assign exp_syscal = alu_op == `ALU_SYSC;
assign exp_break = alu_op == `ALU_BREK;

always_comb begin
                unique case(alu_op)
                           `ALU_MFC0, `ALU_MTC0, `ALU_SYSC, `ALU_BREK, `ALU_ERET:
                               priv_inst = 1'b1;
                           default:
                               priv_inst = 1'b0;
                       endcase
                   end

                   always_comb begin
                                   if(alu_op == `ALU_MTC0)
                                       cop0_wen = 1'b1;
                                   else
                                       cop0_wen = 1'b0;
                               end


                               // For mult/div
                               reg mult_done_prev, div_done_prev;
logic mult_done, div_done;
logic [63:0] _hilo_mult, _hilo_div;
// logic [63:0] hilo_mult, hilo_div;
logic [1:0] mult_op, div_op;
logic mult_commit, div_commit;

// Pipeline control.
wire mdu_running = ~(mult_done & div_done);
assign stall_o = mdu_running & hilo_accessed;
assign mult_commit = mult_done && (mult_done_prev != mult_done);
assign div_commit = div_done && (div_done_prev != div_done);

always_ff @(posedge clk) begin
              if(rst) begin
                  mult_done_prev <= 1'b0;
                  div_done_prev <= 1'b0;
              end
              else begin
                  mult_done_prev <= mult_done;
                  div_done_prev <= div_done;
              end
          end

          // The mult/div unit.
          always_comb begin
                          div_op = 2'd0;
                          mult_op = 2'd0;
                          if(!stall_i && !flush_i) begin
                              unique case(alu_op)
                                         `ALU_DIV:
                                             div_op = 2'b10;
                                         `ALU_DIVU:
                                             div_op = 2'b01;
                                         `ALU_MULT:
                                             mult_op = 2'b10;
                                         `ALU_MULTU:
                                             mult_op = 2'b01;
                                         default: begin
                                         end
                                     endcase
                                 end
                                 else begin
                                 end
                             end

                             divider div_alpha(
                                         .clk        (clk),
                                         .rst        (rst),
                                         .div_op     (div_op),
                                         .divisor    (src_b),
                                         .dividend   (src_a),
                                         .result     (_hilo_div),
                                         .done       (div_done)
                                     );

multplier mult_alpha(
              .clk        (clk),
              .rst        (rst),
              .op         (mult_op),
              .a          (src_a),
              .b          (src_b),
              .c          (_hilo_mult),
              .done       (mult_done)
          );

// Regular operation.
always_comb begin
                unique case(alu_op)
                           `ALU_ADD, `ALU_ADDU:
                               result = add_result;
                           `ALU_SUB, `ALU_SUBU:
                               result = sub_result;
                           `ALU_SLT:
                               result = $signed(src_a) < $signed(src_b) ? 32'd1 : 32'd0;
                           `ALU_SLTU:
                               result = src_a < src_b? 32'd1 : 32'd0;
                           `ALU_AND:
                               result = src_a & src_b;
                           `ALU_LUI:
                               result = { src_b[15:0], 16'h0000 };
                           `ALU_NOR:
                               result = ~(src_a | src_b);
                           `ALU_OR:
                               result = src_a | src_b;
                           `ALU_XOR:
                               result = src_a ^ src_b;
                           `ALU_SLL:
                               result = src_a << src_b[4:0];
                           `ALU_SRA:
                               result = src_a >>> src_b[4:0];
                           `ALU_SRL:
                               result = src_a >> src_b[4:0];
                           `ALU_MFHI:
                               result = hi;
                           `ALU_MFLO:
                               result = lo;
                           `ALU_OUTA:
                               result = src_a;
                           `ALU_OUTB:
                               result = src_b;
                           `ALU_MFC0:
                               result = cop0_data;
                           `ALU_MTC0:
                               result = cop0_addr;
                           default:
                               result = 32'hxxxx_xxxx;
                       endcase
                   end

                   always_comb begin
                                   unique case (alu_op)
                                              `ALU_ADD:
                                                  exp_overflow = ((src_a[31] ~^ src_b[31]) & (src_a[31] ^ src_b[31]));
                                              `ALU_SUB:
                                                  exp_overflow = ((src_a[31]  ^ src_b[31]) & (src_a[31] ^ src_b[31]));
                                              default:
                                                  exp_overflow = 1'b0;
                                          endcase
                                      end

                                      // HiLo read/write
                                      always_ff @(posedge clk) begin
                                                    if(rst) begin
                                                        hilo <= 64'h0000_0000_0000_0000;
                                                    end
                                                    else begin
                                                        if(div_commit)
                                                            hilo <= _hilo_div;
                                                        else if(mult_commit)
                                                            hilo <= _hilo_mult;
                                                        else begin
                                                            unique case(alu_op)
                                                                       `ALU_MFHI:
                                                                           hilo <= { src_a, lo };
                                                                       `ALU_MFLO:
                                                                           hilo <= { hi, src_a };
                                                                       default:
                                                                           hilo <= hilo;
                                                                   endcase
                                                               end
                                                           end
                                                       end

                                                       endmodule
