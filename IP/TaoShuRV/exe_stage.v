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
  wire exe_inst_use_mem;
  wire [3:0] exe_mul_div_ctrl;
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
    exe_inst_ebreak,
    exe_inst_use_mem,
    exe_mul_div_ctrl
  } = exe_reg;

  // output bus to MEM
  reg [`XLEN-1:0] exe_result;
  // assign exe_to_mem_bus = {exe_pc, exe_result, exe_rf_wr_sel, exe_rf_wr_en, exe_reg_waddr}; //同步RAM
  assign exe_to_mem_bus = {exe_pc, exe_result, exe_rf_wr_sel, exe_rf_wr_en, 
                          exe_reg_waddr, data_sram_rdata, exe_inst_ebreak};

  // pipeline control
  // reg  ex_valid;
  wire exe_ready_go;

  assign exe_ready_go = ~mul_div_valid | ~is_div_or_mul | div_ready;
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
  wire [`XLEN-1:0] alu_result;


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

  wire mul_div_valid;
  wire is_signed;
  wire is_mul_div_high;
  wire is_div_or_mul;
  wire [2*`XLEN-1:0] mul_result;

  assign mul_div_valid = exe_mul_div_ctrl[3];
  assign is_div_or_mul = exe_mul_div_ctrl[2];
  assign is_signed = exe_mul_div_ctrl[1];
  assign is_mul_div_high = exe_mul_div_ctrl[0];

  /* verilator lint_off UNOPTFLAT */
  wallace_mul u_wallace_mul (
      .mul1(alu_src1),
      .mul2(alu_src2),
      .is_signed(is_signed),
      .result(mul_result)
  );
  /* verilator lint_on UNOPTFLAT */

  wire div_ready;
  reg div_valid;
  reg div_used;
  // wire div_error;
  wire [2*`XLEN-1:0] div_result;

  div_pipeline#(
    .DATA_LEN(`XLEN)
  )
  u_div (
    .clk 			      (clk)                                 , 
    .rst 			      (rst)                                 ,
    .valid 			    (div_valid)                           , 
    .dividend		    (alu_src1)                            , 
    .divisor			  (alu_src2)                            , 
    .is_signed 		  (is_signed)                           ,

    .remainder		  (div_result[2*`XLEN-1:`XLEN])         ,
    .quotient 		  (div_result[`XLEN-1:0])               ,
    .ready			    (div_ready)       
  );

  always @(posedge clk) begin
    if(rst) begin 
      div_valid <= 1'b0;
      div_used <= 1'b0;
    end
    else if(is_div_or_mul) begin
      div_valid <= 1'b1;
      div_used <= 1'b1;
    end

    if(div_used) div_valid <= 1'b0;
    if(div_ready) div_used <= 1'b0;

  end

  always @(*) begin
    if(~mul_div_valid) begin
      assign exe_result = alu_result;
    end 
    else begin
      case ({is_div_or_mul, is_mul_div_high})
        2'b00: assign exe_result = mul_result[`XLEN-1:0];
        2'b01: assign exe_result = mul_result[2*`XLEN-1:`XLEN];
        2'b10: assign exe_result = div_result[`XLEN-1:0];
        2'b11: assign exe_result = div_result[2*`XLEN-1:`XLEN];
      endcase
    end
  end

  assign data_sram_wr_ctrl = exe_dm_wr_ctrl & {2{exe_valid}};
  assign data_sram_rd_ctrl = exe_dm_rd_ctrl;
  assign data_sram_addr  = exe_inst_use_mem ? exe_result : `MEM_BASE;
  assign data_sram_wdata = exe_rs2_value;

  // hazard detection
  assign exe_to_id_bypass_bus = {exe_rf_wr_en, exe_reg_waddr, exe_result};
  assign exe_is_load = |exe_dm_rd_ctrl;

endmodule