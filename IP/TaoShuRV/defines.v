`define INSTR_WIDTH 32
`define PC_WIDTH 32
`define XLEN 32


// ALU_OP {inst[30], func3}
`define ALU_OP_ADD      4'b0000
`define ALU_OP_SUB      4'b1000
`define ALU_OP_SLL      4'b0001
`define ALU_OP_SLT      4'b0010
`define ALU_OP_SLTU     4'b0011
`define ALU_OP_XOR      4'b0100
`define ALU_OP_SRL      4'b0101
`define ALU_OP_SRA      4'b1101
`define ALU_OP_OR       4'b0110
`define ALU_OP_AND      4'b0111
`define ALU_OP_LUI      4'b1110


`define ALU_OP_XXX      4'b1111

`define MEM_BASE        32'h80000000

