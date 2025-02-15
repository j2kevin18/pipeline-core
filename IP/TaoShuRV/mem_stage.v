`include "cpu.vh"

module mem_stage (
    input clk,
    input rst,

    // pipeline control
    output mem_allow_in,
    input  exe_to_mem_valid,
    input  wb_allow_in,
    output mem_to_wb_valid,

    // bypass
    output reg mem_valid,
    output [`BYPASS_BUS_WIDTH-1:0] mem_to_id_bypass_bus,

    // bus from exe
    input [`EXE_TO_MEM_BUS_WIDTH-1:0] exe_to_mem_bus,

    // bus to wb
    output [`MEM_TO_WB_BUS_WIDTH-1:0] mem_to_wb_bus

    // cpu interface
    // input [`XLEN-1:0] data_sram_rdata
);

    // pipeline registers
    reg [`EXE_TO_MEM_BUS_WIDTH-1:0] mem_reg;

    wire [`PC_WIDTH-1:0] mem_pc;
    wire [`XLEN-1:0] mem_alu_result;
    wire [1:0]  mem_rf_wr_sel;
    wire mem_rf_wr_en;
    wire [4:0] mem_reg_waddr;
    wire [`XLEN-1:0] mem_data_sram_rdata;
    wire mem_inst_ebreak;
    assign {mem_pc, mem_alu_result, mem_rf_wr_sel, mem_rf_wr_en, 
            mem_reg_waddr, mem_data_sram_rdata, mem_inst_ebreak} = mem_reg;

    // output bus to WB
    reg [`XLEN-1:0] final_result;
    assign mem_to_wb_bus = {mem_pc, final_result, mem_rf_wr_en, mem_reg_waddr, mem_inst_ebreak};

    // pipeline control
    // reg  mem_valid;
    wire mem_ready_go;

    assign mem_ready_go = 1;
    assign mem_allow_in = !mem_valid || (mem_ready_go && wb_allow_in);
    assign mem_to_wb_valid = mem_valid && mem_ready_go;

    always @(posedge clk) begin
        if (rst) begin
        mem_valid <= 1'b0;
        end else if (mem_allow_in) begin
        mem_valid <= exe_to_mem_valid;
        end
    end

    always @(posedge clk) begin
        if (mem_allow_in && exe_to_mem_valid) begin
        mem_reg <= exe_to_mem_bus;
        end
    end

    // internal signals
    wire [`XLEN-1:0] mem_result;

    // MEM stage
    // assign mem_result = data_sram_rdata; //同步RAM
    assign mem_result = mem_data_sram_rdata; //异步RAM

    always@(*)
    begin
        case(mem_rf_wr_sel)
        2'b00:  final_result = `XLEN'h0;
        2'b01:  final_result = mem_pc + 4;
        2'b10:  final_result = mem_alu_result;
        2'b11:  final_result = mem_result;
        default:final_result = `XLEN'h0;
        endcase
    end

   // bypass to ID
  assign mem_to_id_bypass_bus = {mem_rf_wr_en, mem_reg_waddr, final_result};

endmodule