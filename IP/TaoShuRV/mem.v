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

reg     [3:0]   byte_en;
// reg     [`XLEN-1:0]  mem[0:4095];
reg     [`XLEN-1:0]  mem_out;
integer i;

// initial
// begin
//     for(i=0;i<4095;i=i+1) mem[i] = 0;
// end

// initial
// begin
//   $readmemh("../test/riscvtest.txt",mem);
// //   $readmemh("../test/riscvtest_simple.txt",mem);
// end

// assign inst_sram_rdata = mem[inst_sram_addr >> 2];
//由于不能跨单位读取数据，地址最低两位的数值决定了当前单位能读取到的数据，即mem_out
// always@(*)
// begin
//     case(data_sram_addr[1:0])
//         2'b00:  mem_out <= mem[data_sram_addr[13:2]][31:0];
//         2'b01:  mem_out <= {8'h0,mem[data_sram_addr[13:2]][31:8]};
//         2'b10:  mem_out <= {16'h0,mem[data_sram_addr[13:2]][31:16]};
//         2'b11:  mem_out <= {24'h0,mem[data_sram_addr[13:2]][31:24]};
//     endcase
// end

assign mem_out = dpi_mem_read(data_sram_addr, 4);

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
        // byte_en = 4'b1111;
        dpi_mem_write(data_sram_addr, data_sram_wdata, 4);
    else if(data_sram_wr_ctrl == 2'b10)
    begin
        // if(data_sram_addr[1] == 1'b1) 
        //     byte_en = 4'b1100;
        // else
        //     byte_en = 4'b0011;
        dpi_mem_write(data_sram_addr, data_sram_wdata, 2);
    end
    else if(data_sram_wr_ctrl == 2'b01)
    begin
        // case(data_sram_addr[1:0])
        //     2'b00:  byte_en = 4'b0001;
        //     2'b01:  byte_en = 4'b0010;
        //     2'b10:  byte_en = 4'b0100;
        //     2'b11:  byte_en = 4'b1000;
        // endcase
        dpi_mem_write(data_sram_addr, data_sram_wdata, 1);
    end
    else begin
        // byte_en = 4'b0000;
    end
end

// always@(posedge clk)
// begin
//     if((byte_en != 1'b0) && (data_sram_addr[30:12]==19'b0))
//     begin
//         case(byte_en)
//             4'b0001: mem[data_sram_addr[13:2]][7:0] <= data_sram_wdata[7:0];
//             4'b0010: mem[data_sram_addr[13:2]][15:8] <= data_sram_wdata[7:0];
//             4'b0100: mem[data_sram_addr[13:2]][23:16] <= data_sram_wdata[7:0];
//             4'b1000: mem[data_sram_addr[13:2]][31:24] <= data_sram_wdata[7:0];
//             4'b0011: mem[data_sram_addr[13:2]][15:0] <= data_sram_wdata[15:0];
//             4'b1100: mem[data_sram_addr[13:2]][31:16] <= data_sram_wdata[15:0];
//             4'b1111: mem[data_sram_addr[13:2]][31:0] <= data_sram_wdata[31:0];
//         endcase
//     end
// end
endmodule