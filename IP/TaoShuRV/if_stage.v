`include "cpu.vh"

module if_stage (
    input clk,
    input rst,

    // pipeline control
    input  id_allow_in,
    output if_to_id_valid,

    //csr detection
    input [`PC_WIDTH-1:0] clint_csr_pc,
    input system_flush,

    // bus to id
    output [`IF_TO_ID_BUS_WIDTH-1:0] if_to_id_bus,

    // bus from id
    input [`ID_TO_IF_BUS_WIDTH-1:0] id_to_if_bus,

    // cpu interface
    // output        inst_sram_en,
    // output [`PC_WIDTH-1:0] inst_sram_addr,
    // input  [`INSTR_WIDTH-1:0] inst_sram_rdata
    output wire [`XLEN-1:0]          cur_pc
);

// input bus from ID (for branch)
wire        branch_taken;  // 是否分支
wire [`PC_WIDTH-1:0] branch_target;  // 分支目标地址
wire        branch_taken_cancel; //分支取消
assign {branch_taken, branch_target, branch_taken_cancel} = id_to_if_bus;

// output bus to ID
reg  [`PC_WIDTH-1:0] if_pc;
wire [`INSTR_WIDTH-1:0] inst;
assign if_to_id_bus = {if_pc, inst};

//内部信号
wire [`PC_WIDTH-1:0] seq_pc;
wire [`PC_WIDTH-1:0] nextpc;  // 下一个pc值，pc+4或分支目标地址
wire [`PC_WIDTH-1:0] mret_pc; // mret指令的返回地址
wire [`PC_WIDTH-1:0] filtered_pc;

// pipeline control
reg if_valid; 
wire pre_if_valid;
wire if_allow_in;
wire if_ready_go;

always @(posedge clk) begin
  if (rst) begin
    if_valid <= 1'b0;
  end else if (if_allow_in) begin
    if_valid <= pre_if_valid;
  end else if (branch_taken_cancel) begin
    if_valid <= 1'b0;
  end else if (system_flush) begin
    if_valid <= 1'b0;
  end
end

//pre-fetch stage
assign seq_pc = if_pc + `PC_WIDTH'h4;
assign nextpc = branch_taken ? branch_target : seq_pc;
assign mret_pc  = system_flush ? clint_csr_pc : nextpc;
assign pre_if_valid = ~rst; 

//ifetch stage
assign if_ready_go = 1;
assign if_to_id_valid = if_valid && if_ready_go;
assign if_allow_in = !if_valid || (if_ready_go && id_allow_in);

always @(posedge clk) begin
    if (rst) begin
        if_pc <= `MEM_BASE -`PC_WIDTH'h4; 
    end else if (if_allow_in && pre_if_valid) begin
        if_pc <= mret_pc;
    end
end

import "DPI-C" function int  dpi_mem_read 	(input int addr  , input int len);
assign cur_pc              = seq_pc;
assign filtered_pc         = (if_pc >= `MEM_BASE && if_pc <= `MEM_TOP) ? if_pc : `MEM_BASE;
assign inst                = dpi_mem_read(filtered_pc, 4);

endmodule