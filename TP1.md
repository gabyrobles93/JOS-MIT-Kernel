TP1: Memoria virtual en JOS
===========================

page2pa
-------
La función `page2pa` se enecuentra definida en el archivo `pmap.h`:

```
static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
}
```
Para entender su comportamiento es necesario comprender que representa cada tipo de dato:
* `typedef uint32_t physaddr_t:` el tipo de dato `physaddr_t` es un entero sin signo de 32 bits, utilizado para representar el valor de una dirección de memoria física.
* `struct PageInfo:` como se indica en el enunciado son estructuras con información asociada a las páginas de memoria física.
* `struct PageInfo *pages:` es el arreglo de páginas de memoria física, es decir es un puntero al primer `struct PageInfo` que está asociado a la primer página de memoria física

Entonces `(pp - pages)` es una cuenta que realiza aritmética de punteros en la que da el resultado del índice de la página de memoria física a la que corresponde la variable `pp`. Finalmente a este índice se le realiza un shift a izquierda de 12 posiciones (el valor de `PGSHIFT`), que es equivalente a multiplicar por la potencia 12 de 2, es decir `4096`, que es precisamiente el tamaño en bytes de cada página.


boot_alloc_pos
--------------

a) Partiendo desde KERNBASE, ubicado en `0xf0000000` (memoria virtual), el `kernel` es mapeado a partir del próximo `MB` desde esta posición, es decir en:

`KERNBASE + 0x00100000 = 0xf0000000 + 0x00100000 = 0xf0100000`

A partir de esta posición de memoria irá el `kernel`. Para determinar que posición de memoria devolverá el `boot_alloc(0)` antes de alocar memoria, es decir el valor con que se inicializá la variable `nextfree`, podemos averiguarlo de dos modos:

1) Corriendo el comando `size` sobre el binario, determinamos el tamaño del `kernel`:
```
➜  TP1-SisOp git:(master) ✗ size obj/kern/kernel 
   text	   data	    bss	    dec	    hex	filename
  34506	  41728	   1616	  77850	  1301a	obj/kern/kernel
```
Como vemos ocupa `77850` bytes (`0x0001301a` en hexadecimal). Por lo tanto sumamos este valor a la posición memoria donde empieza el `kernel`: 

`0xf0100000 + 0x0001301a = 0xf011301a`

Con lo cuál sabiendo que `nextfree` se inicializa en la dirección de memoria virtual de la página siguiente a la última página del `kernel`, deducimos que se inicializará en `0xf0114000`.

2) Otro modo es ejecutar el comando `nm` sobre el binario, con la opción `-n` para obtener los símbolos del mismo ordenados según su posición en memoria:
```
➜  TP1-SisOp git:(master) ✗ nm -n obj/kern/kernel
0010000c T _start
f010000c T entry
...
...
...
f0113948 B kern_pgdir
f011394c B pages
f0113950 B end
```
Podemos ver que el último símbolo `end` (que de hecho es el que se utiliza para inicializar `nextfree`) se ubica en `0xf0113950`, con lo cual volvemos a deducir que `nextfree` estará en `0xf0114000`.

Para comprobar esto se agregó el siguiente código tras implementar la función `boot_alloc()`:
```
void
mem_init(void)
{
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	cprintf("Nextfree, la pagina inmediata luego de que termina el kernel en el AS: %p \n", boot_alloc(0));
	.
	.
	.
```
Ejecutando el `kernel` se obtiene lo siguiente:

![alt text](https://github.com/gabyrobles93/TP1-SisOp/blob/master/nextfree.png)

b) A continuación se puede ver una sesión de `gdb` con lo que pide el enunciado y además comprueba lo formulado en el inciso anterior
```
➜  TP1-SisOp git:(master) ✗ make gdb
gdb -q -s obj/kern/kernel -ex 'target remote 127.0.0.1:26000' -n -x .gdbinit
Leyendo símbolos desde obj/kern/kernel...hecho.
Remote debugging using 127.0.0.1:26000
aviso: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.
0x0000fff0 in ?? ()
.gdbinit: No existe el archivo o el directorio.
(gdb) b boot_alloc 
Punto de interrupción 1 at 0xf0100995: file kern/pmap.c, line 98.
(gdb) c
Continuando.

Breakpoint 1, boot_alloc (n=0) at kern/pmap.c:98
98		if (!nextfree) {
(gdb) p nextfree 
$1 = 0x0
(gdb) n
100			nextfree = ROUNDUP((char *) end, PGSIZE);
(gdb) p (char*)&end
$2 = 0xf0113950 "\020"
(gdb) n
112		if ((uintptr_t)ROUNDUP(nextfree + n, PGSIZE) > (KERNBASE + (4 << 20))) {
(gdb) p nextfree 
$3 = 0xf0114000 ""
(gdb) n
116		if (n > 0) {
(gdb) n
123	}
(gdb) p nextfree 
$4 = 0xf0114000 ""
(gdb) n
mem_init () at kern/pmap.c:145
```


page_alloc
----------

...


