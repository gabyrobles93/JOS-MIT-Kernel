#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>

#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/env.h>
#include <kern/syscall.h>
#include <kern/sched.h>
#include <kern/kclock.h>
#include <kern/picirq.h>
#include <kern/cpu.h>
#include <kern/spinlock.h>

static struct Taskstate ts;

/* For debugging, so print_trapframe can distinguish between printing
 * a saved trapframe and printing the current trapframe and print some
 * additional information in the latter case.
 */
static struct Trapframe *last_tf;

/* Interrupt descriptor table.  (Must be built at run time because
 * shifted function addresses can't be represented in relocation records.)
 */
struct Gatedesc idt[256] = { { 0 } };
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };

// Declaración de los prototipos de trap

extern void trap_0();
extern void trap_1();

extern void trap_3();
extern void trap_4();
extern void trap_5();
extern void trap_6();
extern void trap_7();
extern void trap_8();

extern void trap_10();
extern void trap_11();
extern void trap_12();
extern void trap_13();
extern void trap_14();

extern void trap_16();
extern void trap_17();
extern void trap_18();
extern void trap_19();
extern void trap_20();

extern void trap_32();

extern void trap_48();

static const char *
trapname(int trapno)
{
	static const char *const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
		return "Hardware Interrupt";
	return "(unknown trap)";
}


void
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Se debe configurar las interrupciones del vector IDT
	// (Interruption Descriptor Table)
	// Para eso utilizamos la macro SETGATE
	// 1er parámetro: Gate. Ejemplo: idt[1]
	// 2do parámetro: istrap?: En JOS va siempre 0 (para deshabilitar interrupciones
	//                         dentro de la misma interrupción).
	// 3er parámetro: selector de code segment para buscar el handler de la interrupción
	//                En este caso será el text segment del kernel (macro GD_KT)
	// 4to parámetro: offset dentro del code segment para buscar el handler
	// 5to parámetro: Descriptor privilege level. En todo caso sera 0 (ring 0 para kernel)

	// DIVIDE ERROR #DE
	SETGATE(idt[T_DIVIDE], 0, GD_KT, trap_0, 0);
	// DEBUG EXCEPTION
	SETGATE(idt[T_DEBUG], 0, GD_KT, trap_1, 0);

	// Breakpoint (En la tarea kern_interrupts se indica que debe
	//				poder ser disparada por usuario RING 3)
	SETGATE(idt[T_BRKPT], 0, GD_KT, trap_3, 3);
	// Overflow
	SETGATE(idt[T_OFLOW], 0, GD_KT, trap_4, 0);
	// Bound Range Exceded
	SETGATE(idt[T_BOUND], 0, GD_KT, trap_5, 0);
	// Invalid Opcode
	SETGATE(idt[T_ILLOP], 0, GD_KT, trap_6, 0);
	// Device Not Available
	SETGATE(idt[T_DEVICE], 0, GD_KT, trap_7, 0);
	// Double Fault
	SETGATE(idt[T_DBLFLT], 0, GD_KT, trap_8, 0);
	// Invalid TSS
	SETGATE(idt[T_TSS], 0, GD_KT, trap_10, 0);
	// Segment Not Present
	SETGATE(idt[T_SEGNP], 0, GD_KT, trap_11, 0);
	// Stack-Segment Fault
	SETGATE(idt[T_STACK], 0, GD_KT, trap_12, 0);
	// General Protection
	SETGATE(idt[T_GPFLT], 0, GD_KT, trap_13, 0);
	// Page Fault
	SETGATE(idt[T_PGFLT], 0, GD_KT, trap_14, 0);
	// x87 FPU Floating-Point Error (Math Fault)
	SETGATE(idt[T_FPERR], 0, GD_KT, trap_16, 0);
	// Alignment Check
	SETGATE(idt[T_ALIGN], 0, GD_KT, trap_17, 0);
	// Machine ChecK
	SETGATE(idt[T_MCHK], 0, GD_KT, trap_18, 0);
	// SIMD Floating-Point Exception
	SETGATE(idt[T_SIMDERR], 0, GD_KT, trap_19, 0);
	// Virtualization Exception
	SETGATE(idt[20], 0, GD_KT, trap_20, 0);

	// Timer interruption
	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, trap_32, 0);

	// SYSCALL interrupt
	SETGATE(idt[48], 0, GD_KT, trap_48, 3);

	// Per-CPU setup
	trap_init_percpu();
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
	// The example code here sets up the Task State Segment (TSS) and
	// the TSS descriptor for CPU 0. But it is incorrect if we are
	// running on other CPUs because each CPU has its own kernel stack.
	// Fix the code so that it works for all CPUs.
	//
	// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct CpuInfo;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
	//   - You mapped the per-CPU kernel stacks in mem_init_mp()
	//
	// ltr sets a 'busy' flag in the TSS selector, so if you
	// accidentally load the same TSS on more than one CPU, you'll
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	// Obtenemos el cpunum (0 para cpu 1, 1 para cpu 2, etc...)
	int cpuid = cpunum();
	// Obtenenemos el struct cpuinfo del cpu en cuestión
	struct CpuInfo * curcpu = &(cpus[cpuid]);
	// De dicho cpu obtenemos la estructura Taskstate (que representa la TSS)
	struct Taskstate * curts = &(curcpu->cpu_ts);

	// Calculamos el indice del task segment del core en cuestión
	uint16_t idx = (GD_TSS0 >> 3) + cpuid;
	// Caklculamos el segmento del core en cuestión
	uint16_t seg = idx << 3;

	// El campo ts->ts_ss0 seguirá apuntando a GD_KD
	curts->ts_ss0 = GD_KD;

	// Al igual que en mem_init_mp() calculamos la dirección virtual del stack del cpu en cuestión
	uintptr_t kstacktop_i = KSTACKTOP - cpuid * (KSTKSIZE + KSTKGAP);

	// ts->ts_esp0 deberá inicializarse de manera dinámica según el valor de cpunum()
	curts->ts_esp0 = kstacktop_i;

	// Adecuación al nuevo esquema:

	curts->ts_iomb = sizeof(struct Taskstate);

	gdt[idx] = SEG16(STS_T32A, (uint32_t)(curts), sizeof(struct Taskstate) - 1, 0);

	gdt[idx].sd_s = 0;


	ltr(seg);

	lidt(&idt_pd);

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	// ts.ts_esp0 = KSTACKTOP;
	// ts.ts_ss0 = GD_KD;
	// ts.ts_iomb = sizeof(struct Taskstate);

	// Initialize the TSS slot of the gdt.
	// gdt[GD_TSS0 >> 3] =
	//        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	// gdt[GD_TSS0 >> 3].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	//ltr(GD_TSS0);

	// Load the IDT
	//lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
		cprintf("  cr2  0x%08x\n", rcr2());
	cprintf("  err  0x%08x", tf->tf_err);
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
	cprintf("  eip  0x%08x\n", tf->tf_eip);
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
	if ((tf->tf_cs & 3) != 0) {
		cprintf("  esp  0x%08x\n", tf->tf_esp);
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
	}
}

void
print_regs(struct PushRegs *regs)
{
	cprintf("  edi  0x%08x\n", regs->reg_edi);
	cprintf("  esi  0x%08x\n", regs->reg_esi);
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
	cprintf("  edx  0x%08x\n", regs->reg_edx);
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}


/*
trap_dispatch() va a tener un switch para cada excepcion posible:
        switch (tf->tf_trapno) {
                case t_syscall....
        }

En este switch vamos a tener manejadores para el T_BRKPT y para T_PGFLT
(breakpoint y page fault), para el resto nose hará nada y se volverá al
proceso original.

Además, la excepción de breakpoint se debe poder lanzar desde programas de usuario.
En general, esta excepción se usa para implementar el depurado de código.
-> Para esto se debe modificar este gate en trap init.
*/
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	switch (tf->tf_trapno) {
	case T_BRKPT: {
		monitor(tf);
		return;
	}
	case T_PGFLT: {
		page_fault_handler(tf);
		return;
	}
	case IRQ_OFFSET + IRQ_TIMER: {
		lapic_eoi(); 		// Avisamos al hardware que atrapamos la interrupcion
		sched_yield(); 	// Actuamos en consecuencia de la interrupcion (round-robin)
		return;
	}
	case T_SYSCALL: {
		uint32_t ret = syscall(tf->tf_regs.reg_eax,  // Syscall number
		                       tf->tf_regs.reg_edx,  // 1st argument
		                       tf->tf_regs.reg_ecx,  // 2nd argument
		                       tf->tf_regs.reg_ebx,  // 3rd argument
		                       tf->tf_regs.reg_edi,  // 4th argument
		                       tf->tf_regs.reg_esi   // 5th argument
		);
		tf->tf_regs.reg_eax = ret;  // Return value should be put in %eax
		return;
	}
	default:
		break;
	}
	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
		cprintf("Spurious interrupt on irq 7\n");
		print_trapframe(tf);
		return;
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}

void
trap(struct Trapframe *tf)
{
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
		asm volatile("hlt");

	// Re-acquire the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));

	if ((tf->tf_cs & 3) == 3) {
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
			env_free(curenv);
			curenv = NULL;
			sched_yield();
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
		env_run(curenv);
	else
		sched_yield();
}


void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if (tf->tf_cs == GD_KT) {
		panic("[%08x] kernel fault va %08x ip %08x\n",
		      curenv->env_id,
		      fault_va,
		      tf->tf_eip);
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Call the environment's page fault upcall, if one exists.  Set up a
	// page fault stack frame on the user exception stack (below
	// UXSTACKTOP), then branch to curenv->env_pgfault_upcall.
	//
	// The page fault upcall might cause another page fault, in which case
	// we branch to the page fault upcall recursively, pushing another
	// page fault stack frame on top of the user exception stack.
	//
	// The trap handler needs one word of scratch space at the top of the
	// trap-time stack in order to return.  In the non-recursive case, we
	// don't have to worry about this because the top of the regular user
	// stack is free.  In the recursive case, this means we have to leave
	// an extra word between the current top of the exception stack and
	// the new stack frame because the exception stack _is_ the trap-time
	// stack.
	//
	// If there's no page fault upcall, the environment didn't allocate a
	// page for its exception stack or can't write to it, or the exception
	// stack overflows, then destroy the environment that caused the fault.
	// Note that the grade script assumes you will first check for the page
	// fault upcall and print the "user fault va" message below if there is
	// none.  The remaining three checks can be combined into a single test.
	//
	// Hints:
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}
