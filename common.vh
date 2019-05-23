// JUMP instruction type
`define B_EQNE 3'b000
`define B_LTGE 3'b001
`define B_JUMP 3'b010
`define B_JREG 3'b011
`define B_INVA 3'b111


`define MEM_LOAD    2'b10
`define MEM_STOR    2'b01
`define MEM_NOOP    2'b00

`define SZ_FULL     3'b111
`define SZ_HALF     3'b010
`define SZ_BYTE     3'b000