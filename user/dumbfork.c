// Ping-pong a counter between two processes.
// Only need to start one of these -- splits into two, crudely.

#include <inc/string.h>
#include <inc/lib.h>

envid_t dumbfork(void);

void
umain(int argc, char **argv)
{
	envid_t who;
	int i;

	// fork a child process
	who = dumbfork();

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
		sys_yield();
	}
}

void
duppage(envid_t dstenv, void *addr)
{
	int r;

	// This is NOT what you should do in your fork.

	// Aloca una pagina para el proceso destino (destenv)
	// y la mapea en addr, con permisos de escritura
	if ((r = sys_page_alloc(dstenv, addr, PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_alloc: %e", r);

	// Mapea la pagina del hijo previamente alocada (addr de dstenv)
	// en el proceso padre (0 = currenv = proceso padre) en la direccion UTEMP
	if ((r = sys_page_map(dstenv, addr, 0, UTEMP, PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_map: %e", r);
	
	// Copia el contenido de la pagina addr (del padre)
	// en UTEMP (del padre) que esta mapeada con addr (del hijo)
	// Es decir esta copiando el contenido padre de addr en 
	// la pagina del hijo (copia del A.S.)
	memmove(UTEMP, addr, PGSIZE);

	// Desmapea el mapeo previo (fue temporal) ya que
	// solo tenia como objetivo poder copiar el contenido
	// de la pagina padre a una mapeada con el hijo
	// (es el modo de copiar el AS al padre al hijo)
	// por ello el mapeo ya no es necesario
	// 0 = currenv = padre
	if ((r = sys_page_unmap(0, UTEMP)) < 0)
		panic("sys_page_unmap: %e", r);
}

/*
Implementación de fork() altamente ineficiente, 
pues copia físicamente (página a página) el espacio de memoria de padre a hijo. 
*/
envid_t
dumbfork(void)
{
	envid_t envid;
	uint8_t *addr;
	int r;
	extern unsigned char end[];

	// Allocate a new child environment.
	// The kernel will initialize it with a copy of our register state,
	// so that the child will appear to have called sys_exofork() too -
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.

	// Aloca un nuevo environment copiando el trapframe del padre
	envid = sys_exofork();
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.

	// Copiamos en el address space del hijo, el Program Data & Heap del padre
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
		duppage(envid, addr); // Llama a duppage con el envid del hijo

	// Also copy the stack we are currently running on.
	duppage(envid, ROUNDDOWN(&addr, PGSIZE));

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);

	return envid;
}

