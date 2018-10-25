/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER_NOEC(trap_0, T_DIVIDE)
TRAPHANDLER_NOEC(trap_1, T_DEBUG)

TRAPHANDLER_NOEC(trap_3, T_BRKPT)
TRAPHANDLER_NOEC(trap_4, T_OFLOW)
TRAPHANDLER_NOEC(trap_5, T_BOUND)
TRAPHANDLER_NOEC(trap_6, T_ILLOP)
TRAPHANDLER_NOEC(trap_7, T_DEVICE)
TRAPHANDLER(trap_8, T_DBLFLT)

TRAPHANDLER(trap_10, T_TSS)
TRAPHANDLER(trap_11, T_SEGNP)
TRAPHANDLER(trap_12, T_STACK)
TRAPHANDLER(trap_13, T_GPFLT)
TRAPHANDLER(trap_14, T_PGFLT)

TRAPHANDLER_NOEC(trap_16, T_PGFLT)
TRAPHANDLER(trap_17, T_ALIGN)
TRAPHANDLER_NOEC(trap_18, T_MCHK)
TRAPHANDLER_NOEC(trap_19, T_SIMDERR)
TRAPHANDLER_NOEC(trap_20, 20)
TRAPHANDLER_NOEC(trap_48, T_SYSCALL)


/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	/* push values to make the stack look like a struct Trapframe */
	/* Tener en cuenta que el CPU al recibir una interrupción con cambio de privilegios
	   automáticamente hace un push al stack de SS, ESP, EFLAGS, CS, EIP y Error Code 
	   En el TRAPHANDLER, antes de llamar a _alltraps, se hizo push de trapno
	   Por lo tanto hay que pushear en este orden: ds, es y los registros de proposito general */
	
	pushl	%ds
	pushl	%es
	pushal		/* Lo contrario al popal de env_pop_tf */

	/* load GD_KD into %ds and %es 
	Ayuda: cargar GD_KD en %ds y %es mediante un registro intermedio de 16 bits 
	(por ejemplo, %ax). Considerar, además, que GD_KD es una constante numérica, 
	no una dirección de memoria (‘mov $GD_KD’ vs ‘mov GD_KD’).	
	*/

	mov $GD_KT, %ax
	mov %ax, %ds
	mov %ax, %es

	/* pushl %esp to pass a pointer to the Trapframe as an argument to trap() */

	pushl %esp

	/* call trap */
	call trap
	

	

	

