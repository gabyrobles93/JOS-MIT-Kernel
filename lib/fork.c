// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW 0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.

	panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	panic("duppage not implemented");
	return 0;
}

static void
dup_or_share(envid_t dstenv, void *va, int perm) {

}

envid_t
fork_v0(void)
{
	envid_t envid;
	uintptr_t addr;
	int r;

	// Creamos un proceso nuevo
	// El kernel copia los registros y 
	// continua desde aqui tanto para padre 
	// (envid > 0 (envid del hijo)) 
	// como para el hijo (envid = 0).
	envid = sys_exofork();
	if (envid < 0)
		panic("[fork_v0] sys_exofork failed: %e", envid);
	if (envid == 0) {
		// Si envid es 0 entonces el proceso
		// es el hijo, corregimos la variable 
		// thisenv y retornamos
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}

	// Si envid > 0, somos el padre y envid tenemos el id del hijo
	// Procesamos las paginas de memoria de 0 a UTOP
	// Si la pagina esta mapeada invocamos a dup_or_share()
	for (addr = 0; addr < UTOP; addr += PGSIZE) {
		// Recuperamos el page directory entry
		pde_t pde = uvpd[PDX(addr)];

		// Checkeamos que el Page directory este mapeado
		if (pde & PTE_P) {
			pte_t pte = uvpt[PGNUM(addr)];

			// Checkeamos que la page table este mapeada
			if (pte & PTE_P) {
				// Como la pagina esta mapeada, llamamos a dup_or_share
				dup_or_share(envid, (void*)addr, pte & PTE_SYSCALL);
			} 
		}
	}

	// Seteamos el proceso hijo como runneable
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("[fork_v0] sys_env_set_status: %e", r);

	return envid;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	return fork_v0();
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
