`include "cpu.vh"
`include "defines.v"
`default_nettype wire

module wb_stage (
    input clk,
    input rst,

    // pipeline control
    output wb_allow_in,
    input  mem_to_wb_valid,

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
  wire [`XLEN-1:0] wb_final_result;
  wire wb_rf_wr_en;
  wire [4:0] wb_reg_waddr;
  wire wb_inst_ebreak;
  assign {wb_pc, wb_final_result, wb_rf_wr_en, wb_reg_waddr, wb_inst_ebreak} = wb_reg;

  // output bus to ID
  assign wb_to_id_bus = {wb_rf_wr_en, wb_reg_waddr, wb_final_result};

  // pipeline control
//   reg  wb_valid;
  wire wb_ready_go;

  assign wb_ready_go = 1;
  assign wb_allow_in = !wb_valid || wb_ready_go;

  always @(posedge clk) begin
    if (rst) begin
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
  import "DPI-C" function void dpi_ebreak		(input int pc);
  always @(posedge clk) begin
    if(wb_inst_ebreak) begin
      dpi_ebreak(0);
    end
  end

  assign commit_pre_pc = wb_pc;
  assign commit = wb_valid;
  always @(posedge clk) begin
      commit_pc <= wb_pc;
  end

endmodule