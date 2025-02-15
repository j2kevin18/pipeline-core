`include "defines.v"

module regfile(
    input  wire        clk,
    input  wire        rst, 
    // READ PORT 1
    input  wire [ 4:0] raddr1,
    output wire [`XLEN-1:0] rdata1,
    // READ PORT 2
    input  wire [ 4:0] raddr2,
    output wire [`XLEN-1:0] rdata2,
    // WRITE PORT
    input  wire        we,       //write enable, HIGH valid
    input  wire [ 4:0] waddr,
    input  wire [`XLEN-1:0] wdata
);
reg [31:0] rf[`XLEN-1:0];

import "DPI-C" function void dpi_read_regfile(input logic [31 : 0] a []);
initial begin
	dpi_read_regfile(rf);
end

initial begin
    integer i;
    for (i = 0; i < 32; i = i + 1) begin
        rf[i] = i;
    end
    rf[20] = 32'h80000000;
end


//WRITE
always @(posedge clk) begin
    if(rst) begin
        rf[0]  <= 32'd0;
    end
    else if (we) rf[waddr]<= wdata;
end

//READ OUT 1
assign rdata1 = (raddr1==5'b0) ? `XLEN'b0 : rf[raddr1];

//READ OUT 2
assign rdata2 = (raddr2==5'b0) ? `XLEN'b0 : rf[raddr2];


endmodule
