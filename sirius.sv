`timescale 1ns / 1ps
module sirius(
        input               clk,
        input               rst_n,
        
        // To inst
        output  logic[31:0] inst_addr,
        input        [31:0] inst_data,
        
        // To data
        output              data_en,
        output       [3:0]  data_wen, // Which byte is write enabled?
        output logic[31:0]  data_addr,
        output              data_wdata,
        input               data_rdata
    );
// Global signal and stall control.
wire rst = ~rst_n;
wire cp0_exp_en;
wire flush = cp0_exp_en;
wire if_stall, id_stall, ex_stall;
wire ex_stall_i;
wire [31:0]     rs_data, rt_data;
reg [1:0] id_ex_mem_type;
reg [4:0] id_ex_rt_addr;

stall_ctrl stall_0(
    .de_rs          (rs_data),
    .de_rt          (rt_data),
    .ex_stall_i     (ex_stall_i),
    .ex_mem_type    (id_ex_mem_type),
    .ex_rt          (id_ex_rt_addr),
    .if_stall_o     (if_stall),
    .id_stall_o     (id_stall),
    .ex_stall_o     (ex_stall)
);

// IF
wire if_pc_alignment_error;
wire if_pc_address;
assign inst_addr = if_pc_address;

wire ex_branch_taken;
wire ex_branch_address;

pc pc_0(
    .clk                (clk),
    .rst                (rst),
    .stall_i            (if_stall),
    .is_branch_taken    (ex_branch_taken),
    .branch_address     (ex_branch_address),
    .alignment_error    (if_pc_alignment_error),
    .pc_address         (if_pc_address)
);

// IF-ID registers
reg if_id_pc_alignment_error;
reg [31:0] if_id_pc_address;
reg [31:0] if_id_instruction;

always_ff @(posedge clk) begin: update_if_id
    if(rst || flush) begin
        if_id_pc_alignment_error <= 1'b0;
        if_id_pc_address <= 32'd0;
        if_id_instruction <= 32'd0;
    end
    else if(!if_stall)begin
        if_id_pc_alignment_error <= if_pc_alignment_error;
        if_id_pc_address <= if_pc_address;
        if_id_instruction <= inst_data;
    end
    else begin
    end
end

// ID
wire [5:0]  id_decoder_opcode, id_decoder_funct;
wire [4:0]  id_decoder_rs, id_decoder_rt, id_decoder_rd, id_decoder_shamt;
wire [15:0] id_decoder_immediate;
wire [25:0] id_decoder_instr_index;
wire [2:0]  id_decoder_branch_type;
wire        is_branch_inst, is_branch_link, is_hilo_access;

decoder decoder_0(
    .clk            (clk),
    .rst            (rst),
    .instruction    (if_id_instruction),
    .opcode         (id_decoder_opcode),
    .rs             (id_decoder_rs),
    .rt             (id_decoder_rt),
    .rd             (id_decoder_rd),
    .shamt          (id_decoder_shamt),
    .funct          (id_decoder_funct),
    .immediate      (id_decoder_immediate),
    .instr_index    (id_decoder_instr_index),
    .branch_type    (id_decoder_branch_type),
    .is_branch_instr (is_branch_inst),
    .is_branch_link (is_branch_link),
    .is_hilo_accessed (is_hilo_access)
);

wire id_in_delay_slot;
wire id_undefined_inst;
wire [5:0] id_alu_op;
wire [1:0] id_alu_src;
wire id_alu_imm_src;
wire id_mem_type;
wire id_mem_size;
wire id_wb_reg_dest;
wire id_wb_reg_en;
wire id_unsigned_flag;

decoder_ctrl decoder_control_0(
    .clk            (clk),
    .rst            (rst),
    .opcode         (id_decoder_opcode),
    .rt             (id_decoder_rt),
    .rd             (id_decoder_rd),
    .funct          (id_decoder_funct),
    .is_branch      (is_branch_inst),
    .is_branch_al   (is_branch_link),
    .in_delay_slot  (id_in_delay_slot),
    .undefined_inst (id_undefined_inst),
    .alu_op         (id_alu_op),
    .alu_src        (id_alu_src),
    .alu_imm_src    (id_alu_imm_src),
    .mem_type       (id_mem_type),
    .mem_size       (id_mem_size),
    .wb_reg_dest    (id_wb_reg_dest),
    .wb_reg_en      (id_wb_reg_en),
    .unsigned_flag  (id_unsigned_flag)
);

// Reg file
wire [31:0] id_data_a, id_data_b;
wire wb_reg_write_en;
wire [4:0] wb_reg_write_dest;
wire [31:0] wb_reg_write_data;
register reg_0(
    .clk        (clk),
    .rst        (rst),
    .raddr_a    (id_decoder_rs),
    .rdata_a    (id_data_a),
    .raddr_b    (id_decoder_rt),
    .rdata_b    (id_data_b),
    .wenable_a  (wb_reg_write_en),
    .waddr_a    (wb_reg_write_dest),
    .wdata_a    (wb_reg_write_data)
);

reg id_ex_wb_reg_dest;
reg id_ex_wb_reg_en;
wire [31:0] ex_result;
wire [31:0] mem_result;
reg [31:0] ex_mem_wb_reg_dest;
reg ex_mem_wb_reg_en;

forwarding  forwarding_rs(
    .de_reg         (id_decoder_rs),
    .ex_reg_en      (id_ex_wb_reg_en),
    .ex_reg         (id_ex_wb_reg_dest),
    .mem_reg_en     (ex_mem_wb_reg_en),
    .mem_reg        (ex_mem_wb_reg_dest),
    .de_data        (id_data_a),
    .ex_data        (ex_result),
    .mem_data       (mem_result),
    .reg_data       (rs_data)
);

forwarding  forwarding_rt(
    .de_reg         (id_decoder_rt),
    .ex_reg_en      (id_ex_wb_reg_en),
    .ex_reg         (id_ex_wb_reg_dest),
    .mem_reg_en     (ex_mem_wb_reg_en),
    .mem_reg        (ex_mem_wb_reg_dest),
    .de_data        (id_data_a),
    .ex_data        (ex_result),
    .mem_data       (mem_result),
    .reg_data       (rt_data)
);

// Compute alu_src
wire [31:0] id_alu_src_a = rs_data;
logic [31:0] id_alu_src_b;

always_comb begin: compute_alu_source
    unique case(id_alu_src)
    `SRC_SFT:
        id_alu_src_b = { 26'd0 ,id_decoder_shamt };
    `SRC_IMM: begin
        if(id_alu_imm_src)
            id_alu_src_b = { 16'd0, id_decoder_immediate };
        else
            id_alu_src_b = { {16{id_decoder_immediate[15]}}, id_decoder_immediate};
    end
    default:
        id_alu_src_b = rt_data;
    endcase
end

// ID-EX registers
reg [31:0] id_ex_pc_address;
reg [31:0] id_ex_instruction;
reg id_ex_pc_alignment_error;
// For function unit
reg [5:0] id_ex_alu_op;
reg [31:0] id_ex_rs_data, id_ex_rt_data;
reg [31:0] id_ex_alu_src_a, id_ex_alu_src_b;
reg id_ex_is_branch_inst, id_ex_is_branch_link;
reg [2:0] id_ex_decoder_branch_type;
// For MEM stage
reg [2:0] id_ex_mem_size;
reg       id_ex_mem_unsigned_flag;
// For CP0
reg [4:0] id_ex_rd_addr;
reg [2:0] id_ex_sel;
reg id_ex_undefined_inst;
reg id_ex_in_delay_slot;
// For wb
reg id_ex_branch_link;

always_ff @(posedge clk) begin: update_id_ex
    if(rst || flush) begin
        id_ex_pc_address <= 32'd0;
        id_ex_instruction <= 32'd0;
        id_ex_pc_alignment_error <= 1'b0;
        id_ex_rs_data <= 32'd0;
        id_ex_rt_data <= 32'd0;
        id_ex_alu_src_a <= 32'd0;
        id_ex_alu_src_b <= 32'd0;
        id_ex_mem_type <= `MEM_NOOP;
        id_ex_mem_size <= `SZ_FULL;
        id_ex_mem_unsigned_flag <= 1'b0;
        id_ex_wb_reg_dest <= 5'b0;
        id_ex_wb_reg_en <= 1'b0;
        id_ex_rd_addr <= 5'd0;
        id_ex_sel <= 3'd0;
        id_ex_is_branch_inst <= 1'b0;
        id_ex_is_branch_link <= 1'b0;
        id_ex_decoder_branch_type <= 3'd0;
        id_ex_alu_op <= 6'd0;
        id_ex_rt_addr <= 5'd0;
        id_ex_undefined_inst <= 1'b0;
        id_ex_in_delay_slot <= 1'b0;
        id_ex_branch_link <= 1'b0;
    end
    else if(!id_stall) begin
        id_ex_pc_address <= if_id_pc_address;
        id_ex_instruction <= if_id_instruction;
        id_ex_pc_alignment_error <= if_id_pc_alignment_error;
        id_ex_rs_data <= rs_data;
        id_ex_rt_data <= rt_data;
        id_ex_alu_src_a <= id_alu_src_a;
        id_ex_alu_src_b <= id_alu_src_b;
        id_ex_mem_type <= id_mem_type;
        id_ex_mem_size <= id_mem_size;
        id_ex_mem_unsigned_flag <= id_unsigned_flag;
        id_ex_wb_reg_dest <= id_wb_reg_dest;
        id_ex_wb_reg_en <= id_wb_reg_en;
        id_ex_rd_addr <= id_decoder_rd;
        id_ex_sel <= if_id_instruction[2:0];
        id_ex_is_branch_inst <= is_branch_inst;
        id_ex_is_branch_link <= is_branch_link;
        id_ex_decoder_branch_type <= id_decoder_branch_type;
        id_ex_alu_op <= id_alu_op;
        id_ex_rt_addr <= id_decoder_rt;
        id_ex_undefined_inst <= id_undefined_inst;
        id_ex_in_delay_slot <= id_in_delay_slot;
        id_ex_branch_link <= is_branch_link;
    end
end

// EX
wire [7:0] ex_cop0_addr;
wire ex_cop0_wen, ex_priv_inst, ex_exp_overflow;
wire ex_exp_eret, ex_exp_syscal, ex_exp_break;
wire [31:0] cop0_rdata;
branch branch_0(
    .pc_address     (id_ex_pc_address),
    .instruction    (id_ex_instruction),
    .is_branch_instr(id_ex_is_branch_inst),
    .branch_type    (id_decoder_branch_type),
    .data_rs        (id_ex_rs_data),
    .data_rt        (id_ex_rt_data),
    .branch_taken   (ex_branch_taken),
    .branch_address (ex_branch_address)
);

alu_alpha alu_alpha_0(
    .clk            (clk),
    .rst            (rst),
    .stall_i        (ex_stall),
    .flush_i        (flush),
    .hilo_accessed  (is_hilo_access),
    .alu_op         (id_ex_alu_op),
    .src_a          (id_ex_alu_src_a),
    .src_b          (id_ex_alu_src_b),
    .rd             (id_ex_rd_addr),
    .sel            (id_ex_sel),
    .cop0_addr      (ex_cop0_addr),
    .cop0_data      (cop0_rdata),
    .result         (ex_result),
    .cop0_wen       (ex_cop0_wen),
    .priv_inst      (ex_priv_inst),
    .exp_overflow   (ex_exp_overflow),
    .exp_eret       (ex_exp_eret),
    .exp_syscal     (ex_exp_syscal),
    .exp_break      (ex_exp_break),
    .stall_o        (ex_stall_i)
);

// EX-MEM registers
// For cp0
reg ex_mem_cp0_wen;
reg [7:0] ex_mem_cp0_waddr;
reg [31:0] ex_mem_cp0_wdata;
// For memory conrtol
reg [31:0] ex_mem_result;
reg [31:0] ex_mem_rt_value;
reg [1:0] ex_mem_type;
reg [2:0] ex_mem_size;
reg ex_mem_signed;
// For exception
reg ex_mem_iaddr_align_error;
reg ex_mem_invalid_instruction;
reg ex_mem_syscall;
reg ex_mem_break_;
reg ex_mem_eret;
reg ex_mem_overflow;
reg ex_mem_wen;
reg ex_mem_in_delay_slot;
reg [31:0] ex_mem_pc_address;
reg [31:0] ex_mem_mem_address;
reg is_inst;
// For wb
reg ex_mem_branch_link;

always_ff @(posedge clk) begin
    if(rst || flush) begin
        ex_mem_cp0_wen <= 1'b0;
        ex_mem_cp0_waddr <= 8'b0;
        ex_mem_cp0_wdata <= 32'd0;
        ex_mem_result <= 32'd0;
        ex_mem_rt_value <= 32'd0;
        ex_mem_type <= 2'd0;
        ex_mem_size <= 3'd0;
        ex_mem_signed <= 1'b0;
        ex_mem_iaddr_align_error <= 1'd0;
        ex_mem_invalid_instruction <= 1'd0;
        ex_mem_syscall <= 1'd0;
        ex_mem_break_ <= 1'd0;
        ex_mem_eret <= 1'd0;
        ex_mem_overflow <= 1'd0;
        ex_mem_wen <= 1'd0;
        ex_mem_in_delay_slot <= 1'd0;
        ex_mem_pc_address <= 32'd0;
        ex_mem_mem_address <= 32'd0;
        is_inst <= 1'd0;
        ex_mem_wb_reg_dest <= 5'd0;
        ex_mem_wb_reg_en <= 1'b0;
        ex_mem_branch_link <= 1'd0;
    end
    else if(!ex_stall) begin
        ex_mem_cp0_wen <= ex_cop0_wen;
        ex_mem_cp0_waddr <= ex_cop0_addr;
        ex_mem_cp0_wdata <= id_ex_rt_data;
        ex_mem_rt_value <= id_ex_rt_data;
        ex_mem_type <= id_ex_mem_type;
        ex_mem_size <= id_ex_mem_size;
        ex_mem_signed <= id_ex_mem_unsigned_flag;
        ex_mem_iaddr_align_error <= id_ex_pc_alignment_error;
        ex_mem_invalid_instruction <= id_ex_undefined_inst;
        ex_mem_syscall <= ex_exp_syscal;
        ex_mem_break_ <=ex_exp_break;
        ex_mem_eret <= ex_exp_eret;
        ex_mem_overflow <= ex_exp_overflow;
        ex_mem_wen <= ex_mem_type == `MEM_STOR;
        ex_mem_in_delay_slot <= id_ex_in_delay_slot;
        ex_mem_pc_address <= id_ex_pc_address;
        ex_mem_mem_address <= ex_result;
        ex_mem_wb_reg_dest <= id_ex_wb_reg_dest;
        ex_mem_wb_reg_en <= id_ex_wb_reg_en;
        ex_mem_branch_link <= id_ex_branch_link;
    end
end

// MEM
wire mem_address_error;
memory memory_0(
    .clk            (clk),
    .rst            (rst),
    .address        (ex_mem_mem_address),
    .rt_value       (ex_mem_rt_value),
    .mem_type       (ex_mem_type),
    .mem_size       (ex_mem_size),
    .mem_signed     (ex_mem_signed),
    .mem_en         (data_en),
    .mem_wen        (data_wen),
    .mem_addr       (data_addr),
    .mem_wdata      (data_wdata),
    .mem_rdata      (data_rdata),
    .result         (mem_result),
    .address_error  (mem_address_error)
);

// Interrupt handler
reg is_inst_if_id ,is_inst_id_ex, is_inst_ex_mem;

always_ff @(posedge clk) begin
    if(rst || flush) begin
        is_inst_if_id <= 1'b0;
        is_inst_id_ex <= 1'b0;
        is_inst_ex_mem <= 1'b0;
    end
    else begin
        is_inst_if_id <= ~if_stall;
        is_inst_id_ex <= (~id_stall) & is_inst_if_id;
        is_inst_ex_mem <= (~ex_stall) & is_inst_id_ex;
    end
end
// CP0 -- Read at EX, write at MEM.
wire exp_detect;
wire cp0_exl_clean, cp0_exp_bad_vaddr_wen;
wire [31:0] cp0_exp_epc, cp0_exp_bad_vaddr, exp_pc_address;
wire [4:0] cp0_exp_code;
wire [31:0] epc_address;
wire allow_int;
wire [7:0] int_flag;
cp0 cp0(
    .clk            (clk),
    .rst            (rst),
    .raddr          (ex_cop0_addr),
    .rdata          (cop0_rdata),
    .wen            (ex_mem_cp0_wen),
    .waddr          (ex_mem_cp0_waddr),
    .wdata          (ex_mem_cp0_wdata),
    .exp_en         (exp_detect),
    .exp_badvaddr_en(cp0_exp_bad_vaddr_wen),
    .exp_badvaddr   (cp0_exp_bad_vaddr),
    .exp_bd         (ex_mem_in_delay_slot),
    .exp_code       (cp0_exp_code),
    .exp_epc        (cp0_exp_epc),
    .epc_address    (epc_address),
    .allow_interrupt(allow_int),
    .interrupt_flag (int_flag)
);

exception exp_0(
    .clk                    (clk),
    .rst                    (rst),
    .iaddr_alignment_error  (ex_mem_iaddr_align_error),
    .daddr_alignment_error  (mem_address_error),
    .invalid_instruction    (ex_mem_invalid_instruction),
    .priv_instruction       (1'b0), // kernel mode in perf_test
    .syscall                (ex_exp_syscal),
    .break_                 (ex_exp_break),
    .eret                   (ex_exp_eret),
    .overflow               (ex_mem_overflow),
    .mem_wen                (ex_mem_wen),
    .in_delay_slot          (ex_mem_in_delay_slot),
    .pc_address             (ex_mem_pc_address),
    .mem_address            (ex_mem_mem_address),
    .epc_address            (epc_address),
    .allow_interrupt        (allow_int),
    .interrupt_flag         (int_flag),
    .is_inst                (is_inst_ex_mem),
    .exp_detect             (exp_detect),
    .cp0_exp_en             (cp0_exp_en),
    .cp0_exl_clean          (cp0_exl_clean),
    .cp0_exp_epc            (cp0_exp_epc),
    .cp0_exp_code           (cp0_exp_code),
    .cp0_exp_bad_vaddr      (cp0_exp_bad_vaddr),
    .cp0_exp_bad_vaddr_wen  (cp0_exp_bad_vaddr_wen),
    .exp_pc_address         (exp_pc_address)
);

// MEM-WB registers
reg [31:0] mem_wb_result, mem_wb_pc_address;
reg [4:0] mem_wb_reg_dest;
reg mem_wb_reg_write_en;
reg mem_wb_branch_link;

always_ff @(posedge clk) begin
    if(rst) begin
        mem_wb_result <= 32'd0;
        mem_wb_pc_address <= 32'd0;
        mem_wb_reg_dest <= 5'd0;
        mem_wb_reg_write_en <= 1'd0;
        mem_wb_branch_link <= 1'd0;
    end
    else begin
        mem_wb_result <= mem_result;
        mem_wb_pc_address <= ex_mem_pc_address;
        mem_wb_reg_dest <= ex_mem_wb_reg_dest;
        mem_wb_reg_write_en <= ex_mem_wb_reg_en;
        mem_wb_branch_link <= ex_mem_branch_link;
    end
end

writeback(
    .result         (mem_wb_result),
    .pc_address     (mem_wb_pc_address),
    .reg_dest       (mem_wb_reg_dest),
    .write_en       (mem_wb_reg_write_en),
    .branch_link    (mem_wb_branch_link),
    .reg_write_en   (wb_reg_write_en),
    .reg_write_dest (wb_reg_write_dest),
    .reg_write_data (wb_reg_write_data)
);

endmodule
