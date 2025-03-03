`include "defines.v"

module regs_csr (
    input wire clk,
    input wire rst,

    input wire csr_wen,
    input wire [`XLEN-1:0] csr_read_addr,
    input wire [`XLEN-1:0] csr_write_addr,
    input wire [`XLEN-1:0] csr_write_data,
    output reg [`XLEN-1:0] csr_read_data,

    input wire ecall_valid
);

    reg [`XLEN-1:0] mstatus; // 12'h300
    reg [`XLEN-1:0] misa; // 12'h301
    reg [`XLEN-1:0] mie; // 12'h304
    reg [`XLEN-1:0] mtvec; // 12'h305
    reg [`XLEN-1:0] mscratch; // 12'h340
    reg [`XLEN-1:0] mepc; // 12'h341
    reg [`XLEN-1:0] mcause; // 12'h342
    reg [`XLEN-1:0] mtval; // 12'h343
    reg [`XLEN-1:0] mip; // 12'h344
    reg [`XLEN-1:0] mvendorid; // 12'hF11
    reg [`XLEN-1:0] marchid; // 12'hF12
    reg [`XLEN-1:0] mimpid; // 12'hF13
    reg [`XLEN-1:0] mhartid; // 12'hF14

    always @(*) begin
        case (csr_read_addr)
            `XLEN'h300: csr_read_data = mstatus;
            `XLEN'h301: csr_read_data = misa;
            `XLEN'h304: csr_read_data = mie;
            `XLEN'h305: csr_read_data = mtvec;
            `XLEN'h340: csr_read_data = mscratch;
            `XLEN'h341: csr_read_data = mepc;
            `XLEN'h342: csr_read_data = mcause;
            `XLEN'h343: csr_read_data = mtval;
            `XLEN'h344: csr_read_data = mip;
            `XLEN'hF11: csr_read_data = mvendorid;
            `XLEN'hF12: csr_read_data = marchid;
            `XLEN'hF13: csr_read_data = mimpid;
            `XLEN'hF14: csr_read_data = mhartid;
            default: csr_read_data = `XLEN'd0;
        endcase
    end

    always @(posedge clk) begin
        if(rst) begin
            mstatus <= `XLEN'h1800;
            misa <= `XLEN'b11000000000000000000000010000000;
            mie <= `XLEN'd0;
            mtvec <= `XLEN'd0;
            mscratch <= `XLEN'd0;
            mvendorid <= `XLEN'd0;
            marchid <= `XLEN'd0;
            mimpid <= `XLEN'd0;
            mhartid <= `XLEN'd0;
        end else begin
            if (csr_wen) begin
                case (csr_write_addr)
                    `XLEN'h300: mstatus <= csr_write_data;
                    `XLEN'h301: misa <= csr_write_data;
                    `XLEN'h304: mie <= csr_write_data;
                    `XLEN'h305: mtvec <= csr_write_data;
                    `XLEN'h340: mscratch <= csr_write_data;
                    `XLEN'h341: mepc <= csr_write_data;
                    `XLEN'h342: mcause <= csr_write_data;
                    `XLEN'h343: mtval <= csr_write_data;
                    default: ;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (ecall_valid) begin
            mcause <= `XLEN'd1;
        end
    end
    
endmodule