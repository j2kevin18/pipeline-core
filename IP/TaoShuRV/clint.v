`include "defines.v"

module clint (
    input wire clk,
    input wire rst,

    //csr instruction
    input wire [3:0]              clint_csr_data_ctrl,
    input wire [`PC_WIDTH-1:0]    clint_next_pc,
    input wire [`XLEN-1:0]        clint_csr_idx,

    input wire  [`XLEN-1:0]       clint_csr_data,
    output reg  [`XLEN-1:0]       clint_csr_pc,
    output wire [`XLEN-1:0]       clint_csr_out,

    //system instruction
    input wire [1:0]              clint_system_inst_ctrl,

    output wire                   system_flush
);

    wire [`XLEN-1:0] csr_read_addr;
    wire [`XLEN-1:0] csr_write_addr;
    wire [`XLEN-1:0] csr_write_data;
    reg [`XLEN-1:0] csr_read_data;
    wire csr_wen;

    //csr control
    wire csr_valid;
    reg [`XLEN-1:0] inst_csr_write_data;

    assign csr_valid = clint_csr_data_ctrl[3];
    assign clint_csr_out = csr_read_data;
    
    regs_csr u_regs_csr(
        .clk            	(clk             ),
        .rst            	(rst             ),

        .csr_wen      	    (csr_wen       ),
        .csr_read_addr  	(csr_read_addr   ),
        .csr_write_addr 	(csr_write_addr  ),
        .csr_write_data 	(csr_write_data  ),
        .csr_read_data  	(csr_read_data   ),

        .ecall_valid     	(ecall_valid   )
    );

    always @(*) begin
        case(clint_csr_data_ctrl[1:0]) 
            2'b01: inst_csr_write_data = clint_csr_data; 
            2'b10: inst_csr_write_data = clint_csr_data | csr_read_data;
            2'b11: inst_csr_write_data = (~clint_csr_data) & csr_read_data;
            default: begin end
        endcase
    end

    //system instruction control
    import "DPI-C" function void dpi_ebreak		(input int pc);
    reg ebreak_valid;
    reg ebreak_used;
    wire ecall_valid;
    reg [`XLEN-1:0] system_csr_read_addr;
    reg [`XLEN-1:0] system_csr_write_addr;
    reg [`XLEN-1:0] system_csr_write_data;

    always @(posedge clk) begin
        // ebreak
        if (clint_system_inst_ctrl == 2'b01) begin
            dpi_ebreak(0);
        end
    end

    always @(*) begin
        case(clint_system_inst_ctrl) 
            // ebreak
            // 2'b01: begin
            //     dpi_ebreak(0);
            // end 
            // ecall
            2'b10: begin
                system_csr_read_addr = `XLEN'h305; // mtvec
                clint_csr_pc = csr_read_data;

                system_csr_write_addr = `XLEN'h341; //mepc
                system_csr_write_data = clint_next_pc;
            end
            // mret
            2'b11:begin
                system_csr_read_addr = `XLEN'h341; // mepc
                clint_csr_pc = csr_read_data;

                system_csr_write_addr = 'd0;
                system_csr_write_data = 'd0;
            end
            default: begin end
        endcase
    end

    assign ecall_valid      = (clint_system_inst_ctrl == 2'b10);
    assign system_flush     = (clint_system_inst_ctrl == 2'b11) || (clint_system_inst_ctrl == 2'b10);
    assign csr_read_addr    = csr_valid ? clint_csr_idx : ((|clint_system_inst_ctrl) ? system_csr_read_addr : 'd0);
    assign csr_write_addr   = csr_valid ? clint_csr_idx : ((|clint_system_inst_ctrl) ? system_csr_write_addr : 'd0);
    assign csr_write_data   = csr_valid ? inst_csr_write_data : ((|clint_system_inst_ctrl) ? system_csr_write_data : 'd0);
    assign csr_wen          = csr_valid || ecall_valid;

endmodule