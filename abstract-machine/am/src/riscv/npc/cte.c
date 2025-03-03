#include <am.h>
#include "arch/riscv.h"
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      case EVENT_YIELD  : ev.event = EVENT_YIELD; break;
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context *cnt = (Context*)kstack.end - 1;
  for(int i = 0; i < NR_REGS; ++i){
    cnt->gpr[i] = 0;
  }
  cnt->gpr[10] = (uintptr_t)arg; 
  cnt->mcause  = EVENT_YIELD;
  cnt->mstatus = 0x1800;
  cnt->mepc    = (uintptr_t)entry;
  cnt->pdir    = NULL;
  return cnt;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
