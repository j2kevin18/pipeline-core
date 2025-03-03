`include "cpu.vh"
`include "defines.v"
`default_nettype wire

module wb_stage (
    input clk,
    input rst,

    // pipeline control
    output wb_allow_in,
    input  mem_to_wb_valid,

    //csr detection
    output [`PC_WIDTH-1:0] clint_csr_pc,
    output wb_inst_csr,
    output system_flush,

    //bypass
    output reg wb_valid,

    // bus from mem
    input [`MEM_TO_WB_BUS_WIDTH-1:0] mem_to_wb_bus,

    // bus to id (for regfile)
    output [`WB_TO_ID_BUS_WIDTH-1:0] wb_to_id_bus,

    output wire                   commit,
    output wire [`XLEN-1:0]       commit_pc,
    output reg [`XLEN-1:0]        commit_pre_pc
);

  // pipeline registers
  reg [`MEM_TO_WB_BUS_WIDTH-1:0] wb_reg;
  wire [`PC_WIDTH-1:0] wb_pc;
  wire [`XLEN-1:0] wb_result;
  wire wb_rf_wr_en;
  wire [4:0] wb_reg_waddr;
  wire [`XLEN-1:0] wb_csr_idx;
  wire [3:0] wb_csr_data_ctrl;
  wire [`XLEN-1:0] wb_csr_data;
  wire [1:0] wb_system_inst_ctrl;
  assign {wb_pc, wb_result, wb_rf_wr_en, wb_reg_waddr, 
          wb_csr_idx, wb_csr_data_ctrl, wb_csr_data, wb_system_inst_ctrl} = wb_reg;

  // output bus to ID
  wire [`XLEN-1:0] wb_final_result;

  assign wb_final_result = csr_valid ? clint_csr_out : wb_result;
  assign wb_to_id_bus = {wb_rf_wr_en, wb_reg_waddr, wb_final_result};

  // pipeline control
//   reg  wb_valid;
  wire wb_ready_go;

  assign wb_ready_go = 1;
  assign wb_allow_in = !wb_valid || wb_ready_go;

  always @(posedge clk) begin
    if (rst) begin
      wb_valid <= 1'b0;
    end else if (system_flush) begin
      wb_valid <= 1'b0;
    end else if (wb_allow_in) begin
      wb_valid <= mem_to_wb_valid;
    end
  end

  always @(posedge clk) begin
    if (wb_allow_in && mem_to_wb_valid) begin
      wb_reg <= mem_to_wb_bus;
    end
  end

  // always @(*) begin
  //   // $display("try to detect ebreak, wb_valid: %b, commit_pc: %h, pre_pc: %h", wb_valid, commit_pc, commit_pre_pc);
  //    $display("try to detect ebreak, wb_valid: %b, wb_reg_waddr: %h", wb_valid, wb_reg_waddr);
  // end

  //csr detection
  wire csr_valid;
  wire [`XLEN-1:0]     clint_csr_out;
  wire [`PC_WIDTH-1:0] clint_next_pc;

  assign csr_valid     = wb_csr_data_ctrl[3];
  assign wb_inst_csr   = csr_valid & wb_valid;
  assign clint_next_pc = wb_pc + 'd4;

  clint u_clint(
    .clk(clk), 
    .rst(rst),

    .clint_csr_data_ctrl   (wb_csr_data_ctrl)            ,
    .clint_next_pc         (clint_next_pc)               ,
    .clint_csr_idx         (wb_csr_idx)                  ,
    .clint_system_inst_ctrl(wb_system_inst_ctrl)         ,
    .clint_csr_data        (wb_csr_data)                 ,
    .clint_csr_pc          (clint_csr_pc)                ,
    .clint_csr_out         (clint_csr_out)               ,
    .system_flush          (system_flush)                   
  );



  // commit 
  assign commit_pre_pc = wb_pc;
  assign commit = wb_valid || system_flush;
  always @(posedge clk) begin
      commit_pc <= wb_pc;
  end

endmodule