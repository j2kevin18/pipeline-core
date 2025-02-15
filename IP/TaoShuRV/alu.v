`include "defines.v"

module alu (
    input  wire [3:0] alu_ctrl,
    input  wire [`XLEN-1:0] alu_src1,
    input  wire [`XLEN-1:0] alu_src2,
    output wire [`XLEN-1:0] alu_result
);

  wire op_add;  //add operation
  wire op_sub;  //sub operation
  wire op_slt;  //signed compared and set less than
  wire op_sltu;  //unsigned compared and set less than
  wire op_and;  //bitwise and
  wire op_or;  //bitwise or
  wire op_xor;  //bitwise xor
  wire op_sll;  //logic left shift
  wire op_srl;  //logic right shift
  wire op_sra;  //arithmetic right shift
  wire op_lui;  //Load Upper Immediate

  // control code decomposition
  assign op_add  = alu_ctrl == `ALU_OP_ADD;
  assign op_sub  = alu_ctrl == `ALU_OP_SUB;
  assign op_slt  = alu_ctrl == `ALU_OP_SLT;
  assign op_sltu = alu_ctrl == `ALU_OP_SLTU;
  assign op_and  = alu_ctrl == `ALU_OP_AND;
  assign op_or   = alu_ctrl == `ALU_OP_OR;
  assign op_xor  = alu_ctrl == `ALU_OP_XOR;
  assign op_sll  = alu_ctrl == `ALU_OP_SLL;
  assign op_srl  = alu_ctrl == `ALU_OP_SRL;
  assign op_sra  = alu_ctrl == `ALU_OP_SRA;
  assign op_lui  = alu_ctrl == `ALU_OP_LUI;

  wire [`XLEN-1:0] add_sub_result;
  wire [`XLEN-1:0] slt_result;
  wire [`XLEN-1:0] sltu_result;
  wire [`XLEN-1:0] and_result;
  wire [`XLEN-1:0] or_result;
  wire [`XLEN-1:0] xor_result;
  wire [`XLEN-1:0] sll_result;
  wire [2*`XLEN-1:0] sr_doubleword_result;
  wire [`XLEN-1:0] sr_result;
  wire [`XLEN-1:0] lui_result;


  // 32-bit adder
  wire [`XLEN-1:0] adder_a;
  wire [`XLEN-1:0] adder_b;
  wire [`XLEN-1:0] adder_cin;
  wire [`XLEN-1:0] adder_result;
  wire        adder_cout;

  assign adder_a = alu_src1;
  assign adder_b = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rs1-rs2
  assign adder_cin = (op_sub | op_slt | op_sltu) ? 32'h1 : 32'h0;
  assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

  // ADD, SUB result
  assign add_sub_result = adder_result;

  // SLT result
  assign slt_result[`XLEN-1:1] = {`XLEN-1{1'b0}};  //rs1 < rs2 1
  assign slt_result[0]    = (alu_src1[`XLEN-1] & ~alu_src2[`XLEN-1])
                        | ((alu_src1[`XLEN-1] ~^ alu_src2[`XLEN-1]) & adder_result[`XLEN-1]);
  // 有符号数比较，如果rs1的符号位为1，rs2的符号位为0（即rs1小于零，rs2大于等于零），那么slt为1
  // 或者如果rs1的符号位和rs2的符号位相同，且rs1-rs2的符号位为1，那么slt为1

  // SLTU result
  assign sltu_result[`XLEN-1:1] = {`XLEN-1{1'b0}};
  assign sltu_result[0] = ~adder_cout;
  // 无符号数比较，如果rs1-rs2的进位位为0，那么slt为1

  // bitwise operation
  assign and_result = alu_src1 & alu_src2;
  assign or_result = alu_src1 | alu_src2;  
  assign xor_result = alu_src1 ^ alu_src2;
  assign lui_result = alu_src2;

  // SLL result
  assign sll_result = alu_src1 << alu_src2[4:0];  //rs1 << shamt 

  // SRL, SRA result
  assign sr_doubleword_result = {{`XLEN{op_sra & alu_src1[`XLEN-1]}}, alu_src1[`XLEN-1:0]} >> alu_src2[4:0]; //rs1 >> shamt 

  assign sr_result = sr_doubleword_result[`XLEN-1:0];  

  // final result mux
  assign alu_result = ({`XLEN{op_add|op_sub}} & add_sub_result)
                  | ({`XLEN{op_slt       }} & slt_result)
                  | ({`XLEN{op_sltu      }} & sltu_result)
                  | ({`XLEN{op_and       }} & and_result)
                  | ({`XLEN{op_or        }} & or_result)
                  | ({`XLEN{op_xor       }} & xor_result)
                  | ({`XLEN{op_lui       }} & lui_result)
                  | ({`XLEN{op_sll       }} & sll_result)
                  | ({`XLEN{op_srl|op_sra}} & sr_result);

endmodule