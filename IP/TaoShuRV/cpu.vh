`include "defines.v"

`ifndef TAOSHU_RVCPU_H
    `define TAOSHU_RVCPU_H
    `define IF_TO_ID_BUS_WIDTH (`PC_WIDTH + `INSTR_WIDTH)
    `define ID_TO_EXE_BUS_WIDTH (`PC_WIDTH + `XLEN*3 + 19 + 1)
    `define EXE_TO_MEM_BUS_WIDTH (`PC_WIDTH + `XLEN*2 + 8 + 1)
    `define MEM_TO_WB_BUS_WIDTH (`PC_WIDTH + `XLEN + 6 + 1)
    `define WB_TO_ID_BUS_WIDTH (`XLEN + 6)
    `define ID_TO_IF_BUS_WIDTH (`PC_WIDTH + 2)
    `define BYPASS_BUS_WIDTH (`XLEN + 6)
`endif