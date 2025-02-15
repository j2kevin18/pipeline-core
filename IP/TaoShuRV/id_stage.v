`include "defines.v"
`include "cpu.vh"

module id_stage (
    input clk,
    input rst,

    // pipeline control
    output id_allow_in,
    input  if_to_id_valid,
    input  exe_allow_in,
    output id_to_exe_valid,

    // hazard detection && bypass
    input exe_valid,
    input exe_is_load,
    input [`BYPASS_BUS_WIDTH-1:0] exe_to_id_bypass_bus,
    input mem_valid,
    input [`BYPASS_BUS_WIDTH-1:0] mem_to_id_bypass_bus,
    input wb_valid,

    // bus from if
    input [`IF_TO_ID_BUS_WIDTH-1:0] if_to_id_bus,

    // bus to exe
    output [`ID_TO_EXE_BUS_WIDTH-1:0] id_to_exe_bus,

    // bus to if (for branch)
    output [`ID_TO_IF_BUS_WIDTH-1:0] id_to_if_bus,

    // bus from wb (for regfile)
    input [`WB_TO_ID_BUS_WIDTH-1:0] wb_to_id_bus
);

// pipeline registers
reg [`IF_TO_ID_BUS_WIDTH-1:0] id_reg;
wire [`PC_WIDTH-1:0] id_pc;
wire [`INSTR_WIDTH-1:0] id_inst;
assign {id_pc, id_inst} = id_reg;

// input bus from WB (for regfile)
wire wb_rf_wr_en;
wire [ 4:0] wb_rf_waddr;
wire [`XLEN-1:0] wb_rf_wdata;
assign {wb_rf_wr_en, wb_rf_waddr, wb_rf_wdata} = wb_to_id_bus;

// output bus to IF (for branch)
wire        branch_taken;
wire [`PC_WIDTH-1:0] branch_target;
wire        branch_taken_cancel;
assign id_to_if_bus = {branch_taken, branch_target, branch_taken_cancel};

 // output bus to EXE
 //decode阶段中的控制信号
  wire        src1_is_pc;   // 第一个操作数是否是PC
  wire        src2_is_imm;  // 第二个操作数是否是立即数
  wire        rf_wr_en;  // 是否写寄存器
  wire [`XLEN-1:0] rs1_value;
  wire [`XLEN-1:0] rs2_value;  // rs1或rs2的值
  reg branch_en; //满不满足分支条件
  reg [ 1:0]  rf_wr_sel;  // 判断结果是来自内存、PC，还是alu
  wire [`XLEN-1:0] id_imm;    //立即数
  reg [ 3:0] alu_ctrl; //alu的控制信号
  reg [ 2:0] dm_rd_ctrl; //dmem读控制
  reg [ 1:0] dm_wr_ctrl;  //dmem写控制
  wire [4:0] reg_waddr;
  assign id_to_exe_bus = {
    id_pc,
    src1_is_pc,
    src2_is_imm,
    rf_wr_en,
    id_imm,
    rs1_value,
    rs2_value,
    rf_wr_sel,
    alu_ctrl,
    dm_wr_ctrl,
    dm_rd_ctrl,
    reg_waddr,
    inst_ebreak
  };

// pipeline control
reg  id_valid; //id段是否为有效，有效则id_valid=0, 处于指令处理状态则id_valid=1
wire id_ready_go; //id段处理完毕

assign id_allow_in = !id_valid || (id_ready_go && exe_allow_in);
assign id_to_exe_valid = id_valid && id_ready_go;

always @(posedge clk) begin
  if (rst) begin
    id_valid <= 1'b0;
  end else if (branch_taken_cancel) begin
    id_valid <= 1'b0;
  end else if (id_allow_in) begin
    id_valid <= if_to_id_valid;
  end
end

always @(posedge clk) begin
  if (id_allow_in && if_to_id_valid) begin
    id_reg <= if_to_id_bus;
  end
end

// bypass
wire exe_rf_wr_en;
wire [4:0] exe_rf_waddr;
wire [`XLEN-1:0] exe_rf_wdata;
assign {exe_rf_wr_en, exe_rf_waddr, exe_rf_wdata} = exe_to_id_bypass_bus;
wire mem_rf_wr_en;
wire [4:0] mem_rf_waddr;
wire [`XLEN-1:0] mem_rf_wdata;
assign {mem_rf_wr_en, mem_rf_waddr, mem_rf_wdata} = mem_to_id_bypass_bus;

//内部信号
wire [ 6:0] funct7;
wire [ 2:0] funct3;
wire [ 6:0] opcode;
wire [ 4:0] rd;
wire [ 4:0] rs1;
wire [ 4:0] rs2;

wire rv32_lui;
wire rv32_auipc;
wire rv32_branch;
wire rv32_jal;
wire rv32_jalr;
wire rv32_load;
wire rv32_store;
wire rv32_alu_imm;
wire rv32_alu;
wire rv32_system;

wire    inst_lui;
wire    inst_auipc;
wire    inst_jal;
wire    inst_jalr;
wire    inst_beq;
wire    inst_bne;
wire    inst_blt;
wire    inst_bge;
wire    inst_bltu;
wire    inst_bgeu;
wire    inst_lb;
wire    inst_lh;
wire    inst_lw;
wire    inst_lbu;
wire    inst_lhu;
wire    inst_sb;
wire    inst_sh;
wire    inst_sw;
wire    inst_addi;
wire    inst_slti;
wire    inst_sltiu;
wire    inst_xori;
wire    inst_ori;
wire    inst_andi;
wire    inst_slli;
wire    inst_srli;
wire    inst_srai;
wire    inst_add;
wire    inst_sub;
wire    inst_sll;
wire    inst_slt;
wire    inst_sltu;
wire    inst_xor;
wire    inst_srl;
wire    inst_sra;
wire    inst_or;
wire    inst_and;
wire    inst_ecall;
wire    inst_ebreak;
wire    inst_mret;
wire    inst_csrrw;
wire    inst_csrrs;
wire    inst_csrrc;
wire    inst_csrrwi;
wire    inst_csrrsi;
wire    inst_csrrci;

wire    inst_add_type;
wire    inst_u_type;
wire    inst_jump_type;
wire    inst_b_type;
wire    inst_r_type;
wire    inst_i_type;
wire    inst_s_type;
wire    inst_csr;

reg [`XLEN-1:0] imm;    //立即数

wire signed [`XLEN-1:0] signed_rs1_value;
wire signed [`XLEN-1:0] signed_rs2_value;  // rs1或rs2的有符号值
wire [`XLEN-1:0] unsigned_rs1_value;
wire [`XLEN-1:0] unsigned_rs2_value;  // rs1或rs2的无符号值

wire [ 4:0] rf_raddr1;
wire [`XLEN-1:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [`XLEN-1:0] rf_rdata2;
wire        id_rf_wr_en;
wire [ 4:0] rf_waddr;
wire [`XLEN-1:0] rf_wdata;

//decode
assign  opcode  = id_inst[6:0];
assign  funct7  = id_inst[31:25];
assign  funct3  = id_inst[14:12];
assign  rd      = id_inst[11:7];
assign  rs1     = id_inst[19:15];
assign  rs2     = id_inst[24:20];

//opcode 
assign rv32_lui       = (opcode == 7'b01_101_11);
assign rv32_auipc     = (opcode == 7'b00_101_11);
assign rv32_branch    = (opcode == 7'b11_000_11);
assign rv32_jal       = (opcode == 7'b11_011_11);
assign rv32_jalr      = (opcode == 7'b11_001_11);
assign rv32_load      = (opcode == 7'b00_000_11);
assign rv32_store     = (opcode == 7'b01_000_11);
assign rv32_alu_imm   = (opcode == 7'b00_100_11);
assign rv32_alu       = (opcode == 7'b01_100_11);
assign rv32_system    = (opcode == 7'b11_100_11);

//判断指令类型
// INDEPENDENT INSTRUCTIONS
assign  inst_lui  = rv32_lui ;
assign  inst_auipc= rv32_auipc ;
assign  inst_jal  = rv32_jal ;
assign  inst_jalr = rv32_jalr    && (funct3 ==3'b000) ;

// BRANCH INSTRUCTIONS
assign  inst_beq  = rv32_branch  && (funct3 ==3'b000) ;
assign  inst_bne  = rv32_branch  && (funct3 ==3'b001) ;
assign  inst_blt  = rv32_branch  && (funct3 ==3'b100) ;
assign  inst_bge  = rv32_branch  && (funct3 ==3'b101) ;
assign  inst_bltu = rv32_branch  && (funct3 ==3'b110) ;
assign  inst_bgeu = rv32_branch  && (funct3 ==3'b111) ;

// LOAD INSTRUCTIONS
assign  inst_lb   = rv32_load    && (funct3 ==3'b000) ;
assign  inst_lh   = rv32_load    && (funct3 ==3'b001) ;
assign  inst_lw   = rv32_load    && (funct3 ==3'b010) ;
assign  inst_lbu  = rv32_load    && (funct3 ==3'b100) ;
assign  inst_lhu  = rv32_load    && (funct3 ==3'b101) ;

// STORE INSTRUCTIONS
assign  inst_sb   = rv32_store   && (funct3 ==3'b000) ;
assign  inst_sh   = rv32_store   && (funct3 ==3'b001) ;
assign  inst_sw   = rv32_store   && (funct3 ==3'b010) ;

// ALU OP
// 1. reg-imm
assign  inst_addi = rv32_alu_imm && (funct3 ==3'b000) ;
assign  inst_slti = rv32_alu_imm && (funct3 ==3'b010) ;
assign  inst_sltiu= rv32_alu_imm && (funct3 ==3'b011) ;
assign  inst_xori = rv32_alu_imm && (funct3 ==3'b100) ;
assign  inst_ori  = rv32_alu_imm && (funct3 ==3'b110) ;
assign  inst_andi = rv32_alu_imm && (funct3 ==3'b111) ;
assign  inst_slli = rv32_alu_imm && (funct3 ==3'b001) && (funct7 == 7'b00_000_00);
assign  inst_srli = rv32_alu_imm && (funct3 ==3'b101) && (funct7 == 7'b00_000_00);
assign  inst_srai = rv32_alu_imm && (funct3 ==3'b101) && (funct7 == 7'b01_000_00);

// 2. reg-reg
assign  inst_add  = rv32_alu && (funct3 ==3'b000) && (funct7 == 7'b00_000_00);
assign  inst_sub  = rv32_alu && (funct3 ==3'b000) && (funct7 == 7'b01_000_00);
assign  inst_sll  = rv32_alu && (funct3 ==3'b001) && (funct7 == 7'b00_000_00);
assign  inst_slt  = rv32_alu && (funct3 ==3'b010) && (funct7 == 7'b00_000_00);
assign  inst_sltu = rv32_alu && (funct3 ==3'b011) && (funct7 == 7'b00_000_00);
assign  inst_xor  = rv32_alu && (funct3 ==3'b100) && (funct7 == 7'b00_000_00);
assign  inst_srl  = rv32_alu && (funct3 ==3'b101) && (funct7 == 7'b00_000_00);
assign  inst_sra  = rv32_alu && (funct3 ==3'b101) && (funct7 == 7'b01_000_00);
assign  inst_or   = rv32_alu && (funct3 ==3'b110) && (funct7 == 7'b00_000_00);
assign  inst_and  = rv32_alu && (funct3 ==3'b111) && (funct7 == 7'b00_000_00);

// SYSTEM INSTRUCTIONS
assign inst_ecall  = rv32_system & (funct3 == 3'b000) & (id_inst[31:20] == 12'b0000_0000_0000);
assign inst_ebreak = rv32_system & (funct3 == 3'b000) & (id_inst[31:20] == 12'b0000_0000_0001);
assign inst_mret   = rv32_system & (funct3 == 3'b000) & (id_inst[31:20] == 12'b0011_0000_0010);

// CSR INSTRUCTIONS
assign inst_csrrw  = rv32_system & (funct3 == 3'b001);
assign inst_csrrs  = rv32_system & (funct3 == 3'b010);
assign inst_csrrc  = rv32_system & (funct3 == 3'b011);
assign inst_csrrwi = rv32_system & (funct3 == 3'b101);
assign inst_csrrsi = rv32_system & (funct3 == 3'b110);
assign inst_csrrci = rv32_system & (funct3 == 3'b111);

assign  inst_add_type = inst_auipc | inst_jal | inst_jalr | inst_b_type | inst_s_type 
                    | inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu | inst_add | inst_addi ;
assign  inst_u_type   = inst_lui | inst_auipc ;
assign  inst_jump_type= inst_jal ;
assign  inst_b_type   = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu ;   
assign  inst_r_type   = inst_add | inst_sub | inst_sll | inst_slt | inst_sltu | inst_xor 
                    | inst_srl | inst_sra | inst_or | inst_and ;
assign  inst_i_type   = inst_jalr | inst_lb | inst_lh | inst_lw | inst_lbu | inst_lhu 
                    | inst_addi | inst_slti | inst_sltiu | inst_xori | inst_ori | inst_andi
                    | inst_slli | inst_srli | inst_srai ;
assign  inst_s_type   = inst_sb | inst_sh | inst_sw ;
assign  inst_csr      = inst_csrrw | inst_csrrs | inst_csrrc | 
                        inst_csrrwi| inst_csrrsi| inst_csrrci;

//将指令转化成信号
assign reg_waddr    = rd;
assign src1_is_pc   = ~(inst_r_type | inst_i_type | inst_s_type);
assign src2_is_imm  = ~inst_r_type;  
assign rf_wr_en     =  (inst_u_type | inst_r_type | inst_i_type | inst_jump_type) && |(reg_waddr) && id_valid;

//从指令取出imm
always@(*)
begin
    if(inst_u_type) imm = {id_inst[31:12], {12{1'b0}}};
    else if(inst_b_type) imm = {{20{id_inst[31]}}, id_inst[7], id_inst[30:25], id_inst[11:8], 1'b0}; // 分支偏移
    else if(inst_jump_type) imm = {{12{id_inst[31]}}, id_inst[19:12], id_inst[20], id_inst[30:21], 1'b0}; // jal偏移
    else if(inst_i_type) imm = {{20{id_inst[31]}}, id_inst[31:20]};
    else if(inst_s_type) imm = {{20{id_inst[31]}}, id_inst[31:25], id_inst[11:7]};
    else imm = 0;
end 

assign id_imm = ({`XLEN{inst_i_type}} & imm)
                              | ({`XLEN{inst_s_type}} & imm)
                              | ({`XLEN{inst_b_type}} & imm)
                              | ({`XLEN{inst_jump_type}} & imm)
                              | ({`XLEN{inst_u_type}} & imm);

//读取寄存器的值
assign rf_raddr1 = rs1;
assign rf_raddr2 = rs2;
regfile u_regfile (
      .clk   (clk),
      .rst   (rst),
      .raddr1(rf_raddr1),
      .rdata1(rf_rdata1),
      .raddr2(rf_raddr2),
      .rdata2(rf_rdata2),
      .we    (id_rf_wr_en),
      .waddr (rf_waddr),
      .wdata (rf_wdata)
  );  

//生成rf_wr_sel信号
always@(*)
begin
    if(inst_jal |inst_jalr) 
        rf_wr_sel = 2'b01;
    else if(inst_addi |inst_slti |inst_sltiu |inst_xori |inst_ori |inst_andi
                    |inst_slli |inst_srli |inst_srai |inst_jalr |inst_r_type |inst_u_type) 
        rf_wr_sel = 2'b10;
    else if(inst_lb |inst_lh |inst_lw |inst_lbu |inst_lhu) 
        rf_wr_sel = 2'b11;
    else 
        rf_wr_sel = 2'b00;
end  

//生成alu_ctrl信号
always@(*)
begin
    if(inst_add_type) alu_ctrl = `ALU_OP_ADD;
    else if(inst_sub) alu_ctrl = `ALU_OP_SUB;
    else if(inst_sll | inst_slli) alu_ctrl = `ALU_OP_SLL;
    else if(inst_srl | inst_srli) alu_ctrl = `ALU_OP_SRL;
    else if(inst_sra | inst_srai) alu_ctrl = `ALU_OP_SRA;
    else if(inst_slt | inst_slti) alu_ctrl = `ALU_OP_SLT;
    else if(inst_sltu | inst_sltiu) alu_ctrl = `ALU_OP_SLTU;
    else if(inst_xor | inst_xori) alu_ctrl = `ALU_OP_XOR;
    else if(inst_or | inst_ori) alu_ctrl = `ALU_OP_OR;
    else if(inst_and | inst_andi) alu_ctrl = `ALU_OP_AND;
    else if(inst_lui) alu_ctrl = `ALU_OP_LUI;
    else alu_ctrl = `ALU_OP_XXX;
end

//生成[2:0]dm_rd_ctrl信号
always@(*)
begin
    if(inst_lb) dm_rd_ctrl = 3'b001;
    else if(inst_lbu) dm_rd_ctrl = 3'b010;
    else if(inst_lh) dm_rd_ctrl = 3'b011;
    else if(inst_lhu) dm_rd_ctrl = 3'b100;
    else if(inst_lw) dm_rd_ctrl = 3'b101;
    else dm_rd_ctrl = 3'b000;
end

//生成[1:0]data_sram_wr_ctrl信号
always@(*)
begin
    if(inst_sb) dm_wr_ctrl = 2'b01;
    else if(inst_sh) dm_wr_ctrl = 2'b10;
    else if(inst_sw) dm_wr_ctrl = 2'b11;
    else  dm_wr_ctrl = 2'b00;
end  

//分支判断
assign signed_rs1_value  = rs1_value;
assign signed_rs2_value  = rs2_value;
assign unsigned_rs1_value  = rs1_value;
assign unsigned_rs2_value  = rs2_value;

always@(*)
begin
    if(inst_beq) branch_en = unsigned_rs1_value == unsigned_rs2_value ? 1: 0;
    else if(inst_bne) branch_en = unsigned_rs1_value != unsigned_rs2_value ? 1: 0;
    else if(inst_blt) branch_en = signed_rs1_value < signed_rs2_value ? 1: 0;
    else if(inst_bge) branch_en = signed_rs1_value >= signed_rs2_value ? 1: 0;
    else if(inst_bltu) branch_en = unsigned_rs1_value < unsigned_rs2_value ? 1: 0;
    else if(inst_bgeu) branch_en = unsigned_rs1_value >= unsigned_rs2_value ? 1: 0;
    else branch_en = 0;
end

assign branch_taken = (branch_en || inst_jalr || inst_jal) && id_valid;
assign branch_target = (inst_b_type | inst_jump_type) ? (id_pc + imm) : 
                                            inst_jalr ? (unsigned_rs1_value + imm) : 0;

//对写回阶段的处理
assign id_rf_wr_en       = wb_rf_wr_en;
assign rf_waddr          = wb_rf_waddr;
assign rf_wdata          = wb_rf_wdata;

// hazard detection
// read rs1?
// RV32I不需要rs1的有:
    // 1. lui/auipc (u_type)
    // 2. jal 
    // 3. csrrwi/csrrsi/csrrci
    // 4. ecall/ebreak/mret
wire use_rf_rdata1 = id_valid && (!inst_u_type && !inst_jump_type && 
                                  !inst_csrrwi && !inst_csrrsi && !inst_csrrci &&
                                  !inst_ecall  && !inst_ebreak && !inst_mret);
// read rs2?
// RV32I需要rs2的有
    // 1. rv32_alu
    // 2. branch
    // 3. store
wire use_rf_rdata2 = id_valid && (inst_b_type || inst_s_type || inst_r_type);

// read csr?
// csrrw  csrrs  csrrc
// csrrwi csrrsi csrrci
wire use_csr = id_valid && inst_csr;

// case waddr is 0 has already been handled in line 250
// which means that if waddr is 0, rf_wr_en is 0
wire rf_rdata1_hazard = use_rf_rdata1 && (
  (exe_valid && exe_is_load && exe_rf_wr_en && (rf_raddr1 == exe_rf_waddr)) 
  // ||
  // (mem_valid && mem_rf_wr_en && (rf_raddr1 == mem_rf_waddr)) ||
  // (wb_valid && wb_rf_wr_en && (rf_raddr1 == wb_rf_waddr))
);
wire rf_rdata2_hazard = use_rf_rdata2 && (
  (exe_valid && exe_is_load && exe_rf_wr_en && (rf_raddr2 == exe_rf_waddr)) 
  // ||
  // (mem_valid && mem_rf_wr_en && (rf_raddr2 == mem_rf_waddr)) ||
  // (wb_valid && wb_rf_wr_en && (rf_raddr2 == wb_rf_waddr))
);

assign id_ready_go = !rf_rdata1_hazard && !rf_rdata2_hazard;
//预测总失败
assign branch_taken_cancel = id_valid && id_ready_go && branch_taken && exe_allow_in;

// bypass
assign rs1_value =
    (exe_valid && exe_rf_wr_en && (rf_raddr1 == exe_rf_waddr)) ? exe_rf_wdata :
    (mem_valid && mem_rf_wr_en && (rf_raddr1 == mem_rf_waddr)) ? mem_rf_wdata :
    (wb_valid && wb_rf_wr_en && (rf_raddr1 == wb_rf_waddr)) ? wb_rf_wdata :
    rf_rdata1;

assign rs2_value =
    (exe_valid && exe_rf_wr_en && (rf_raddr2 == exe_rf_waddr)) ? exe_rf_wdata :
    (mem_valid && mem_rf_wr_en && (rf_raddr2 == mem_rf_waddr)) ? mem_rf_wdata :
    (wb_valid && wb_rf_wr_en && (rf_raddr2 == wb_rf_waddr)) ? wb_rf_wdata :
    rf_rdata2;


endmodule
