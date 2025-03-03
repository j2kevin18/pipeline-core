`include "defines.v"

//异步ram
module mem(
input           clk,
// input wire [`PC_WIDTH-1:0] inst_sram_addr,
// output wire [`INSTR_WIDTH-1:0] inst_sram_rdata,

input   [2:0]   data_sram_rd_ctrl,
input   [1:0]   data_sram_wr_ctrl,
input wire [`XLEN-1:0] data_sram_addr,
input wire [`XLEN-1:0] data_sram_wdata,
output reg [`XLEN-1:0] data_sram_rdata
);

import "DPI-C" function void dpi_mem_write(input int addr, input int data, int len);
import "DPI-C" function int  dpi_mem_read (input int addr  , input int len);

reg     [`XLEN-1:0]  mem_out;
wire    [`XLEN-1:0]  filtered_data_sram_addr;

assign filtered_data_sram_addr = (data_sram_addr >= `MEM_BASE && data_sram_addr <= `MEM_TOP) ? data_sram_addr : `MEM_BASE;
assign mem_out = dpi_mem_read(filtered_data_sram_addr, 4);

always@(*)
begin
    case(data_sram_rd_ctrl)                                         
        3'b001: data_sram_rdata = {{24{mem_out[7]}}, mem_out[7:0]};
        3'b010: data_sram_rdata = {{24{1'b0}},mem_out[7:0]};
        3'b011: data_sram_rdata = {{16{mem_out[15]}},mem_out[15:0]};
        3'b100: data_sram_rdata = {{16{1'b0}},mem_out[15:0]};
        3'b101: data_sram_rdata = mem_out[31:0];
        default: data_sram_rdata = 32'h0;
    endcase
end

always@(posedge clk)
begin
    if(data_sram_wr_ctrl == 2'b11)
        dpi_mem_write(data_sram_addr, data_sram_wdata, 4);
    else if(data_sram_wr_ctrl == 2'b10) begin
        dpi_mem_write(data_sram_addr, data_sram_wdata, 2);
    end else if(data_sram_wr_ctrl == 2'b01) begin
        dpi_mem_write(data_sram_addr, data_sram_wdata, 1);
    end else begin end
end

endmodule