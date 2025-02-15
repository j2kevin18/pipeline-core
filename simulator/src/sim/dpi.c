#include <common.h>
#include <cstdio>
#include <defs.h>
#include "verilated_dpi.h" // For VerilatedDpiOpenVar and other DPI related definitions




void difftest_skip_ref();

extern "C" void dpi_ebreak(int pc){
	// printf("下一个要执行的指令是ebreak\n");
	SIMTRAP(pc, 0);
}

extern "C" int dpi_mem_read(int addr, int len){
	if(addr == 0) return 0;
	if(addr >=  CONFIG_RTC_MMIO && addr < CONFIG_RTC_MMIO + 4){
		int time = get_time();
		IFDEF(CONFIG_DIFFTEST, difftest_skip_ref());
		return time;
	}else{
		unsigned int data = pmem_read(addr, len);
		// printf("read addr: 0x%x, data: 0x%x\n", addr, data);
		return data;
	}
}
extern "C" void dpi_mem_write(int addr, int data, int len){
	if(addr == CONFIG_SERIAL_MMIO){
		char ch = data;
		printf("%c", ch);
		fflush(stdout);
		IFDEF(CONFIG_DIFFTEST, difftest_skip_ref());
	}else{
		// printf("write addr: 0x%x, data: 0x%x\n", addr, data);
		pmem_write(addr, len, data);
	}
}


extern uint32_t  *reg_ptr;
extern "C" void dpi_read_regfile(const svOpenArrayHandle r) {
  reg_ptr = (uint32_t *)(((VerilatedDpiOpenVar*)r)->datap());
}