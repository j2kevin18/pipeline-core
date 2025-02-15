`include "cpu.vh"

module cpu (
    input wire clk,
    input wire rst,

    // output wire [`PC_WIDTH-1:0] inst_sram_addr,
    // input wire [`INSTR_WIDTH-1:0] inst_sram_rdata,

    output wire [`XLEN-1:0]          cur_pc,
    output wire                       commit,
    output wire [`XLEN-1:0]          commit_pc,
    output wire [`XLEN-1:0]          commit_pre_pc


);

  reg [2:0]  data_sram_rd_ctrl;
  reg [1:0]  data_sram_wr_ctrl;
  reg [`XLEN-1:0] data_sram_addr;
  reg [`XLEN-1:0] data_sram_wdata;
  reg [`XLEN-1:0] data_sram_rdata;


  // IF
  wire if_to_id_valid;
  wire [`IF_TO_ID_BUS_WIDTH-1:0] if_to_id_bus;

  // ID
  wire id_allow_in;
  wire id_to_exe_valid;
  wire [`ID_TO_EXE_BUS_WIDTH-1:0] id_to_exe_bus;
  wire [`ID_TO_IF_BUS_WIDTH-1:0] id_to_if_bus;

  // EXE
  wire exe_allow_in;
  wire exe_to_mem_valid;
  wire [`EXE_TO_MEM_BUS_WIDTH-1:0] exe_to_mem_bus;
  wire exe_valid;
  wire exe_is_load;
  wire [`BYPASS_BUS_WIDTH-1:0] exe_to_id_bypass_bus;

  // MEM
  wire mem_allow_in;
  wire mem_to_wb_valid;
  wire mem_valid;
  wire [`BYPASS_BUS_WIDTH-1:0] mem_to_id_bypass_bus;
  wire [`MEM_TO_WB_BUS_WIDTH-1:0] mem_to_wb_bus;

  // WB
  wire wb_allow_in;
  wire wb_valid;
  wire [`WB_TO_ID_BUS_WIDTH-1:0] wb_to_id_bus;

  
  if_stage u_if_stage(
    .clk             	(clk              ),
    .rst           	  (rst              ),
    .id_allow_in     	(id_allow_in      ),
    .if_to_id_valid  	(if_to_id_valid   ),
    .if_to_id_bus    	(if_to_id_bus     ),
    .id_to_if_bus    	(id_to_if_bus     ),

    .cur_pc           (cur_pc       )
    // .inst_sram_en    	(inst_sram_en     ),
    // .inst_sram_addr  	(inst_sram_addr   ),
    // .inst_sram_rdata 	(inst_sram_rdata  )
  );


  id_stage u_id_stage(
    .clk                  	(clk                   ),
    .rst                	(rst                 ),
    .id_allow_in          	(id_allow_in           ),
    .if_to_id_valid       	(if_to_id_valid        ),
    .exe_allow_in         	(exe_allow_in          ),
    .id_to_exe_valid      	(id_to_exe_valid       ),
    .exe_valid            	(exe_valid             ),
    .exe_is_load          	(exe_is_load           ),
    .exe_to_id_bypass_bus 	(exe_to_id_bypass_bus  ),
    .mem_valid            	(mem_valid             ),
    .mem_to_id_bypass_bus 	(mem_to_id_bypass_bus  ),
    .wb_valid             	(wb_valid              ),
    .if_to_id_bus         	(if_to_id_bus          ),
    .id_to_exe_bus        	(id_to_exe_bus         ),
    .id_to_if_bus         	(id_to_if_bus          ),
    .wb_to_id_bus         	(wb_to_id_bus          )
  );
  
  exe_stage u_exe_stage(
    .clk                  	(clk                   ),
    .rst                	(rst                 ),
    .exe_allow_in         	(exe_allow_in          ),
    .id_to_exe_valid      	(id_to_exe_valid       ),
    .mem_allow_in         	(mem_allow_in          ),
    .exe_to_mem_valid     	(exe_to_mem_valid      ),
    .exe_to_id_bypass_bus 	(exe_to_id_bypass_bus  ),
    .exe_is_load          	(exe_is_load           ),
    .exe_valid            	(exe_valid             ),
    .id_to_exe_bus        	(id_to_exe_bus         ),
    .exe_to_mem_bus       	(exe_to_mem_bus        ),
    .data_sram_rd_ctrl    	(data_sram_rd_ctrl     ),
    .data_sram_wr_ctrl    	(data_sram_wr_ctrl     ),
    .data_sram_addr       	(data_sram_addr        ),
    .data_sram_wdata      	(data_sram_wdata       ),
    .data_sram_rdata      	(data_sram_rdata       ) 
  );

  
  mem_stage u_mem_stage(
    .clk                  	(clk                   ),
    .rst                	(rst                 ),
    .mem_allow_in         	(mem_allow_in          ),
    .exe_to_mem_valid     	(exe_to_mem_valid      ),
    .wb_allow_in          	(wb_allow_in           ),
    .mem_to_wb_valid      	(mem_to_wb_valid       ),
    .mem_valid            	(mem_valid             ),
    .mem_to_id_bypass_bus 	(mem_to_id_bypass_bus  ),
    .exe_to_mem_bus       	(exe_to_mem_bus        ),
    .mem_to_wb_bus        	(mem_to_wb_bus         )
    // .data_sram_rdata      	(data_sram_rdata       )
  );

  
  wb_stage u_wb_stage(
    .clk             	(clk              ),
    .rst           	(rst            ),
    .wb_allow_in     	(wb_allow_in      ),
    .mem_to_wb_valid 	(mem_to_wb_valid  ),
    .wb_valid        	(wb_valid         ),
    .mem_to_wb_bus   	(mem_to_wb_bus    ),
    .wb_to_id_bus    	(wb_to_id_bus     ),

    .commit           (commit       ),
    .commit_pc        (commit_pc    ),
    .commit_pre_pc    (commit_pre_pc)
  );

  mem u_mem(
        .clk               	(clk                ),
        // .inst_sram_addr    	(inst_sram_addr     ),
        // .inst_sram_rdata   	(inst_sram_rdata    ),
        .data_sram_rd_ctrl 	(data_sram_rd_ctrl  ),
        .data_sram_wr_ctrl 	(data_sram_wr_ctrl  ),
        .data_sram_addr    	(data_sram_addr     ),
        .data_sram_wdata   	(data_sram_wdata    ),
        .data_sram_rdata   	(data_sram_rdata    )
  );
  

endmodule
