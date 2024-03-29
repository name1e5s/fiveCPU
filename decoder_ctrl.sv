`timescale 1ns / 1ps
`include "common.vh"
`include "alu_common.vh"

module decoder_ctrl(
		input						clk,
		input						rst,
		input						flush,

		input [31:0]				instruction,
		input [5:0]					opcode,
		input [4:0]					rt,
		input [4:0]					rd,
		input [5:0]					funct,
		input						is_branch,
		input						is_branch_al,

		output logic				in_delay_slot, // In delay slot?
		output logic				undefined_inst, // 1 as received a unknown operation.
		output logic [5:0]	 		alu_op, // ALU operation
		output logic [1:0] 			alu_src, // ALU oprand 2 source(0 as rt, 1 as immed)
		output logic       			alu_imm_src, // ALU immediate src - 1 as unsigned, 0 as signed.
		output logic [1:0] 			mem_type, // Memory operation type -- load or store
		output logic [2:0] 			mem_size, // Memory operation size -- B,H,W,WL,WR
		output logic [4:0] 			wb_reg_dest, // Writeback register address
		output logic       			wb_reg_en, // Writeback is enabled
		output logic       			unsigned_flag   // Is this a unsigned operation in MEM stage.
);

	reg		_in_delay_slot;
	assign	in_delay_slot 	= _in_delay_slot;
	always_ff @(posedge clk) begin : update_in_delay_slot
		if(rst || flush)
			_in_delay_slot <= 1'b0;
		else if(is_branch || is_branch_al)
			_in_delay_slot <= 1'b1;
		else
			_in_delay_slot <= 1'b0;
	end

	// Control logic.
	always_comb begin : decoder
		undefined_inst = 1'b0;
		casex({opcode, funct})
			{6'b000000, 6'b100000}: // ADD
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADD, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001000, 6'bxxxxxx}: // ADDI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADD, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b100001}: // ADDU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001001, 6'bxxxxxx}: // ADDIU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b100010}: // SUB
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SUB, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b100011}: // SUBU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SUBU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b101010}: // SLT
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SLT, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001010, 6'bxxxxxx}: // SLTI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SLT, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b101011}: // SLTU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SLTU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001011, 6'bxxxxxx}: // SLTIU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SLTU, `SRC_IMM, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b011010}: // DIV
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_DIV, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b011011}: // DIVU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_DIVU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b011000}: // MULT
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_MULT, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b011001}: // MULTU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_MULTU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b100100}: // AND
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_AND, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001100, 6'bxxxxxx}: // ANDI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_AND, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b001111, 6'bxxxxxx}: // LUI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_LUI, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b100111}: // NOR
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_NOR, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b100101}: // OR
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_OR, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001101, 6'bxxxxxx}: // ORI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_OR, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b100110}: // XOR
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_XOR, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b001110, 6'bxxxxxx}: // XORI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_XOR, `SRC_IMM, `ZERO_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b000100}: // SLLV
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SLL, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b000000}: // SLL
 				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SLL, `SRC_SFT, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b000111}: // SRAV
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SRA, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b000011}: // SRA
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SRA, `SRC_SFT, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b000110}: // SRLV
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SRL, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b000010}: // SRL
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SRL, `SRC_SFT, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b010000}: // MFHI
          		{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_MFHI, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b010010}: // MFLO
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_MFLO, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b1, `ZERO_EXTENDED};
			{6'b000000, 6'b010001}: // MTHI
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_MTHI, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b010011}: // MTLO
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_MTLO, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rd, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b001101}: // BREAK
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_BREK, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
			{6'b000000, 6'b001100}: // SYSCALL
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_SYSC, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
			{6'b100000, 6'bxxxxxx}: // LB
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_BYTE, rt, 1'b1, `SIGN_EXTENDED};
			{6'b100100, 6'bxxxxxx}: // LBU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_BYTE, rt, 1'b1, `ZERO_EXTENDED};
			{6'b100001, 6'bxxxxxx}: // LH
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_HALF, rt, 1'b1, `SIGN_EXTENDED};
			{6'b100101, 6'bxxxxxx}: // LHU
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_HALF, rt, 1'b1, `ZERO_EXTENDED};
			{6'b100011, 6'bxxxxxx}: // LW
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_LOAD, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
			{6'b101000, 6'bxxxxxx}: // SB
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_STOR, `SZ_BYTE, rt, 1'b0, `SIGN_EXTENDED};
			{6'b101001, 6'bxxxxxx}: // SH
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_STOR, `SZ_HALF, rt, 1'b0, `SIGN_EXTENDED};
			{6'b101011, 6'bxxxxxx}: // SW
				{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
					{`ALU_ADDU, `SRC_IMM, `SIGN_EXTENDED, `MEM_STOR, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
			{6'b010000, 6'bxxxxxx}: begin // PRIV_INST
				if(instruction == 32'b01000010000000000000000000011000) // ERET
					{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
						{`ALU_ERET, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
				else if(instruction[25:21] == 5'b00000) // MFC0
					{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
						{`ALU_MFC0, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b1, `ZERO_EXTENDED};
				else if(instruction[25:21] == 5'b00100) // MTC0
					{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
						{`ALU_MTC0, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
			end
			default: begin
				if(is_branch && is_branch_al)
					{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
						{`ALU_OUTA, `SRC_PCA, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, 5'd31, 1'b1, `ZERO_EXTENDED};
				else begin
					undefined_inst = ~is_branch;
					{alu_op, alu_src, alu_imm_src, mem_type, mem_size, wb_reg_dest, wb_reg_en, unsigned_flag} = 
						{`ALU_ADDU, `SRC_REG, `SIGN_EXTENDED, `MEM_NOOP, `SZ_FULL, rt, 1'b0, `ZERO_EXTENDED};
				end
			end
		endcase
	end
endmodule
