`include "cpu.vh"

module exe_stage (
    input clk,
    input rst,

    // pipeline control
    output exe_allow_in,
    input  id_to_exe_valid,
    input  mem_allow_in,
    output exe_to_mem_valid,

    // hazard detection && bypass
    output [`BYPASS_BUS_WIDTH-1:0] exe_to_id_bypass_bus,
    output exe_is_load,
    output reg exe_valid,


    // bus from id
    input [`ID_TO_EXE_BUS_WIDTH-1:0] id_to_exe_bus,

    // bus to mem
    output [`EXE_TO_MEM_BUS_WIDTH-1:0] exe_to_mem_bus,

    // cpu interface
    output wire [2:0]  data_sram_rd_ctrl,
    output wire [1:0]  data_sram_wr_ctrl,
    output [`XLEN-1:0] data_sram_addr,
    output [`XLEN-1:0] data_sram_wdata,
    input [`XLEN-1:0] data_sram_rdata
);

  // pipeline registers
  reg [`ID_TO_EXE_BUS_WIDTH-1:0] exe_reg;

  wire [`PC_WIDTH-1:0] exe_pc;
  wire exe_src1_is_pc;
  wire exe_src2_is_imm;
  wire exe_rf_wr_en;
  wire [`XLEN-1:0] exe_imm;
  wire [`XLEN-1:0] exe_rs1_value;
  wire [`XLEN-1:0] exe_rs2_value;
  wire [1:0] exe_rf_wr_sel;
  wire [3:0] exe_alu_ctrl;
  wire [1:0] exe_dm_wr_ctrl;
  wire [2:0] exe_dm_rd_ctrl;
  wire [4:0] exe_reg_waddr;
  wire exe_inst_ebreak;
  assign {
    exe_pc,
    exe_src1_is_pc,
    exe_src2_is_imm,
    exe_rf_wr_en,
    exe_imm,
    exe_rs1_value,
    exe_rs2_value,
    exe_rf_wr_sel,
    exe_alu_ctrl,
    exe_dm_wr_ctrl,
    exe_dm_rd_ctrl,
    exe_reg_waddr,
    exe_inst_ebreak
  } = exe_reg;

  // output bus to MEM
  wire [`XLEN-1:0] alu_result;
  // assign exe_to_mem_bus = {exe_pc, alu_result, exe_rf_wr_sel, exe_rf_wr_en, exe_reg_waddr}; //同步RAM
  assign exe_to_mem_bus = {exe_pc, alu_result, exe_rf_wr_sel, exe_rf_wr_en, 
                          exe_reg_waddr, data_sram_rdata, exe_inst_ebreak};

  // pipeline control
  // reg  ex_valid;
  wire exe_ready_go;

  assign exe_ready_go = 1;
  assign exe_allow_in = !exe_valid || (exe_ready_go && mem_allow_in);
  assign exe_to_mem_valid = exe_valid && exe_ready_go;

  always @(posedge clk) begin
    if (rst) begin
      exe_valid <= 1'b0;
    end else if (exe_allow_in) begin
      exe_valid <= id_to_exe_valid;
    end
  end

  always @(posedge clk) begin
    if (exe_allow_in && id_to_exe_valid) begin
      exe_reg <= id_to_exe_bus;
    end
  end

  // internal signals
  wire [3:0] alu_ctrl;
  wire [`XLEN-1:0] alu_src1;
  wire [`XLEN-1:0] alu_src2;
  // wire [`XLEN-1:0] alu_result;

  // EXE stage
  assign alu_ctrl   = exe_alu_ctrl;
  assign alu_src1 = exe_src1_is_pc ? exe_pc : exe_rs1_value;
  assign alu_src2 = exe_src2_is_imm ? exe_imm : exe_rs2_value;

  alu u_alu (
      .alu_ctrl  (alu_ctrl),
      .alu_src1  (alu_src1),
      .alu_src2  (alu_src2),
      .alu_result(alu_result)
  );

  assign data_sram_wr_ctrl = exe_dm_wr_ctrl & {2{exe_valid}};
  assign data_sram_rd_ctrl = exe_dm_rd_ctrl;
  assign data_sram_addr  = alu_result;
  assign data_sram_wdata = exe_rs2_value;

  // hazard detection
  assign exe_to_id_bypass_bus = {exe_rf_wr_en, exe_reg_waddr, alu_result};
  assign exe_is_load = |exe_dm_rd_ctrl;

endmodule