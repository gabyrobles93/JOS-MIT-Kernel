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
  // Recuperamos la PTE en cuestión
  pte_t pte = uvpt[PGNUM(addr)];
  
  // Verificamos que la página esté mapeada
  if ((err & FEC_PR) == 0) panic("[pgfault] pgfault por página no mapeada");

  // Verificamos que el page fault no haya sido por una lectura
  if ((err & FEC_WR) == 0) panic("[pgfault] pgfault por lectura");

  // Verificamos que la página tenga copy-on-write
  if ((pte & PTE_COW) == 0) panic("[pgfault] pgfault COW no configurado");

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.

  // Alocamos una nueva página en PFTEMP
  r = sys_page_alloc(0, PFTEMP, PTE_W | PTE_U | PTE_P);
  if (r) panic("[pgfault] sys_page_alloc failed: %e", r);

  // Alineamos y copiamos el contenido de la página
  addr = (void *)ROUNDDOWN(addr, PGSIZE);
  memmove(PFTEMP, addr, PGSIZE);

  // Re-mapeamos correctamente
  r = sys_page_map(0, PFTEMP, 0, addr, PTE_W | PTE_U | PTE_P);
  if (r) panic("[pgfault] sys_page_map failed: %e", r);
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

  // Recuperamos la PTE asociada
  pte_t pte = uvpt[pn];

  // Reconstruimos la dirección de memoria virtual
  void * va = (void *)(pn << PTXSHIFT);

	if (pte & PTE_SHARE) {
		// Si es una pagina que debe ser compartida con
		// los mismos permisos que en el padre (por cuestiones
		// del filesystem, asi persisten cambios de archivos abiertos)
    r = sys_page_map(0, va, envid, va, pte & PTE_SYSCALL);
    if (r) panic("[duppage] sys_page_map: %e", r);
	} else if ((pte & PTE_W) || (pte & PTE_COW)) {
		// Si la página era de escritura o tenía copy on write
		
    // Mapeamos la página en el hijo sin PTE_W
    r = sys_page_map(0, va, envid, va, PTE_COW | PTE_U | PTE_P);
    if (r) panic("[duppage] sys_page_map: %e", r);

    // Re-mapeamos la página en el padre sin PTE_W
    r = sys_page_map(0, va, 0, va, PTE_COW | PTE_U | PTE_P);
    if (r) panic("[duppage] sys_page_map: %e", r);
	} else {
    // Si es una pagina de solo lectura simplemente la compartimos
    r = sys_page_map(0, va, envid, va, PTE_U | PTE_P);
    if (r) panic("[duppage] sys_page_map: %e", r);
  }

	return 0;
}

static void
dup_or_share(envid_t dstenv, void *va, int perm) {
	int r;

	// Si la pagina es de escritura
	// debemos crear una copia, de igual
	// manera que en duppage de dumbfork
	if (perm & PTE_W) {
		// Aloca una pagina para el proceso hijo (dstenv)
		// y la mapea en addr, con permisos de escritura
		if ((r = sys_page_alloc(dstenv, va, perm)) < 0)
			panic("[dup_or_share] sys_page_alloc: %e", r);

		// Mapea la pagina del hijo previamente alocada (addr de dstenv)
		// en el proceso padre (0 = currenv = proceso padre) en la direccion UTEMP
		if ((r = sys_page_map(dstenv, va, 0, UTEMP, perm)) < 0)
			panic("[dup_or_share] sys_page_map: %e", r);
		
		// Copia el contenido de la pagina addr (del padre)
		// en UTEMP (del padre) que esta mapeada con addr (del hijo)
		// Es decir esta copiando el contenido padre de addr en 
		// la pagina del hijo (copia del A.S.)
		memmove(UTEMP, va, PGSIZE);

		// Desmapea el mapeo previo (fue temporal) ya que
		// solo tenia como objetivo poder copiar el contenido
		// de la pagina padre a una mapeada con el hijo
		// (es el modo de copiar el AS al padre al hijo)
		// por ello el mapeo ya no es necesario
		// 0 = currenv = padre
		if ((r = sys_page_unmap(0, UTEMP)) < 0)
			panic("[dup_or_share] sys_page_unmap: %e", r);
	} else {
		// Si la pagina es de solo lectura la compartimos
		if ((r = sys_page_map(0, va, dstenv, va, perm)) < 0)
			panic("[dup_or_share] sys_page_map: %e", r);
	}
}

/*
Es muy parecido a dumbfork() ambos realizan las siguientes operaciones:
 + Una llamada a sys_exofork (syscall para crear proceso hijo)
 + En el padre devuelve el id del proceso creado, y 0 en el hijo
 + Ante errores se invoca a panic()
 + Poner al hijo como RUNNEABLE

Pero hacen cosas ligeramente diferentes:
 + dumbfork() llama a la función duppage, que copia de manera "boba" las paginas del padre al hijo
 + fork_v0() llama a dup_or_share()

*/

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

			// Checkeamos que la page table entry este mapeada
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
  int error;

  // Configuramos pgfault como el handler del padre
  // Esto tambien reserva memoria para su pila de excepciones
	set_pgfault_handler(pgfault);

  // Creamos el proceso hijo y validamos correctamente
  envid_t envid = sys_exofork();
  if (envid < 0) panic("[fork] sys_exofork failed: %e", envid);

  if (envid == 0) {
		// Si envid es 0 entonces el proceso
		// es el hijo, corregimos la variable 
		// thisenv y retornamos
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	} else {
    // Es el proceso padre
    // Usamos indices para poder iterar
    // sobre la cantidad minima de paginas posibles
    size_t pdx;
    size_t ptx;

    // Procesamos las paginas de memoria de 0 a UTOP
    // Si la pagina esta mapeada invocamos a dup_or_share()
    for (pdx = 0 ; pdx < PDX(UTOP) ; pdx++) {
      // Recuperamos el page directory entry
      pde_t pde = uvpd[pdx];

      // Verificamos que la Page Table este alocada
      // caso contrario la ignoramos y continuamos con la siguiente
      if ((pde & PTE_P) == 0) continue;

      // Si está alocada recorremos las 1024 PTE,
      // copiando las páginas alocadas.
      for (ptx = 0 ; ptx < NPTENTRIES ; ptx++) {
        // Construimos la direccion virtual
        // Usamos 0 para el offset
        uintptr_t addr = (uintptr_t)PGADDR(pdx, ptx, 0);

        // Usamos el PGNUM para acceder a uvpt con la VA construida
        pte_t pte = uvpt[PGNUM(addr)];

        // Si la dirección es el Stack de excepciones
        // no lo duplicamos sino que alocamos una nueva página
        // para el proceso hijo
        if (addr == (UXSTACKTOP - PGSIZE)) {
          error = sys_page_alloc(envid, (void *)addr, PTE_W | PTE_U | PTE_P);
          if (error) panic("[fork] sys_page_alloc failed: %e", error);
          continue;
        }

        // Si la página no está alocada la salteamos
        if ((pte & PTE_P) == 0) continue;

        // Si la página está alocada llamamos a duppage()
        duppage(envid, PGNUM(addr));
      }
    }

    // Configuramos pgfault como el handler del hijo
    error = sys_env_set_pgfault_upcall(envid, thisenv->env_pgfault_upcall);
    if (error) panic("[fork] sys_env_set_pgfault_upcall failed: %e", error);

    // Seteamos al proceso hijo como RUNNABLE
    error = sys_env_set_status(envid, ENV_RUNNABLE);
    if (error) panic("[fork] sys_env_set_status failed: %e", error);

    return envid;
  }
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
