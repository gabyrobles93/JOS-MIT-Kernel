TP3: Multitarea con desalojo
============================

static_assert
-------------

**¿cómo y por qué funciona la macro `static_assert` que define JOS?**
**La implementación de `static_assert` es la siguiente:**
```
// static_assert(x) will generate a compile-time error if 'x' is false.
#define static_assert(x)	switch (x) case 0: case (x):
```
Esto genera un error en tiempo de compilación, lo que no quiere decir que tenga el mismo comportamiento que `_Static_assert`. La implementación de `JOS` lo que hace es recibir una expresión `x` que en caso de ser falsa (`case 0`) generará el código `case (x)` con lo cual habrá una duplicación en el valor `case`. A continuación se puede ver una prueba:
```
In file included from kern/pmap.c:7:0:
kern/pmap.c: In function ‘page_init’:
./inc/assert.h:18:45: error: duplicate case value
 #define static_assert(x) switch (x) case 0: case (x):
                                             ^
kern/pmap.c:371:2: note: in expansion of macro ‘static_assert’
  static_assert(MPENTRY_PADDR % PGSIZE == 1);
  ^~~~~~~~~~~~~
./inc/assert.h:18:37: note: previously used here
 #define static_assert(x) switch (x) case 0: case (x):
                                     ^
kern/pmap.c:371:2: note: in expansion of macro ‘static_assert’
  static_assert(MPENTRY_PADDR % PGSIZE == 1);
  ^~~~~~~~~~~~~
```

env_return
----------

**Al terminar un proceso su función `umain()` ¿dónde retoma la ejecución el kernel? Describir la secuencia de llamadas desde que termina `umain()` hasta que el kernel dispone del proceso.**

En `lib/entry.S` (usuario) se llama a la función `libmain()`. Ésta última es quien configura la variable `thisenv` y el nombre del binario en caso de existir y finalmente llama a `umain()` por lo tanto, una vez que termina `umain()` la ejecución retorna aquí en `libmain()` quien es la encargada de llamar a `exit()` para que el kernel disponga del proceso.

**¿En qué cambia la función env_destroy() en este TP, respecto al TP anterior?**

En el TP anterior como no disponíamos de múltiples procesos no se hacía ningún tipo de validación y se liberaba el proceso. En la nueva implementación ya que el mismo proceso podría estar corriendo en otro CPU es necesario comprobarlo (el `if` comprueba si está corriendo y si además no es el proceso actual de este CPU), si esto es así se cambia el estado a `ENV_DYING`, con lo que se convierte en un "proceso zombie" y será liberado la próxima vez que se le ceda el control. En caso de no ser así se lo libera y se hace una última validación para comprobar que el proceso no era el que estaba corriendo en ese momento. En caso de ser así se actualiza `curenv` y se fuerza el cambio con otro proceso con `sched_yield`.

sys_yield
---------

**Leer y estudiar el código del programa `user/yield.c`. Cambiar la función `i386_init()` para lanzar tres instancias de dicho programa, y mostrar y explicar la salida de `make qemu-nox`**
La función de `yield.c` simplemente realiza un ciclo for en el que se desaloja y luego de retomar el control del CPU, imprime por salida estándar un mensaje para indicar que retomó la ejecución, su `PID` y el número de iteración en la que se encuentra. Al correr el comando indicado se obtuvo la siguiente salida:
```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Hello, I am environment 00001002.
Back in environment 00001000, iteration 0.
Back in environment 00001001, iteration 0.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 1.
Back in environment 00001000, iteration 2.
Back in environment 00001001, iteration 2.
Back in environment 00001002, iteration 2.
Back in environment 00001000, iteration 3.
Back in environment 00001001, iteration 3.
Back in environment 00001002, iteration 3.
Back in environment 00001000, iteration 4.
All done in environment 00001000.
[00001000] exiting gracefully
[00001000] free env 00001000
Back in environment 00001001, iteration 4.
All done in environment 00001001.
[00001001] exiting gracefully
[00001001] free env 00001001
Back in environment 00001002, iteration 4.
All done in environment 00001002.
[00001002] exiting gracefully
[00001002] free env 00001002
No runnable environments in the system!
```
Se puede observar como se crean los tres procesos y en cada iteración cada proceso se desaloja intencionalmente. Primero arranca `00001000`, se desaloja, luego por `round-robin` irá el proceso siguiente `00001001`, entra al ciclo y se desaloja, por último empieza el ciclo el proceso `00001002` que se desaloja y por la política de `round-robin` ahora le tocará al proceso `00001000` nuevamente e imprime el primer mensaje por pantalla `"Back in enviroment..."`. Así se repiten todos los ciclos hasta que el primer proceso llega al último y podemos observar como el kernel cede el CPU a otros procesos recién cuando el proceso actual muere (ya que no hay llamadas explícitas a `schied_yield()` y no están habilitadas las interrupciones del timer).

envid2env
---------

**Responder qué ocurre:**
**en `JOS`, si un proceso llama a `sys_env_destroy(0)`**
Cuando se hace el llamado `sys_env_destroy(0)`, lo primero que hace la syscall es pasar de `envid` a `struct Env *`, con lo que se hace llamado a `envid2env(0)`. Dicha función si se invoca con 0 devuelve el proceso actual, es decir `curenv`. Luego se llama a `env_destroy()`, con lo que está destruyendo el proceso actual (en dicha función se agrega la comprobación de: si se está destruyendo al proceso actual se hace llamado a `schied_yield` para correr otro programa `RUNNABLE`).

**en Linux, si un proceso llama a `kill(0, 9)`**

En Linux, mediante el comando `kill` se puede enviar una señal a un proceso o grupo de procesos. En particular, la señal número 9 significa KILL (terminar con el/los procesos). Si un proceso llama `kill(0, 9)` entonces terminará con todos los procesos cuyo ID de grupo sea el mismo que el suyo, incluido a si mismo.

**E ídem para:**
**JOS: `sys_env_destroy(-1)`**
La definición de `envid_t` en `env.h` indica que ID's negativos significan errores. En particular tendremos un comportamiento inesperado ya que el en la sentencia: 
`e = &envs[ENVX(envid)];`
Estaremos accediendo a `envs[NENV]` ya que -1 es equivalente a todos los bits en 1.
Con lo que seguramente falle en el siguiente `if`:
```
if (e->env_status == ENV_FREE || e->env_id != envid) {
  *env_store = 0;
  return -E_BAD_ENV;
}
```
y devuelva `-E_BAD_ENV` y la syscall devuelve el error al usuario.

**Linux: `kill(-1, 9)`**

Según el manual de kill de linux, el comando `kill -9 -1` termina con todos los procesos que se pueda terminar.

dumbfork
--------

**1. Si, antes de llamar a `dumbfork()`, el proceso se reserva a sí mismo una página con `sys_page_alloc()` ¿se propagará una copia al proceso hijo? ¿Por qué?**

Si un proceso se reserva una página a si mismo con `sys_page_alloc()`, dicha página va a mapearse en su address space en la dirección virutal `va` que le indique por parámetro. Para dicha dirección se valida que esté por debajo de UTOP. Si el mapeo se hace en el Pogram Data & Heap o en el Normal User Stack, entonces dicha página va a propagarse como copia al hijo. Esto se debe a que dumfork realiza copia al address space de hijo de las páginas asociadas al Program Data & Heap y Normal User Stack.

**2. ¿Se preserva el estado de solo-lectura en las páginas copiadas? Mostrar, con código en espacio de usuario, cómo saber si una dirección de memoria es modificable por el proceso, o no. (Ayuda: usar las variables globales `uvpd` y/o `uvpt`.)**

No, no se preserva el estado de solo lectura ya que todas las páginas necesarias que se van alocando se hace con los permisos `PTE_P|PTE_U|PTE_W`, independientemente de los permisos originales de la página que se está duplicando.
En el siguiente fragmento de código podemos saber si una dirección de memoria es modificable por el proceso o no:
```
pde_t pde = uvpd[PDX(addr)];

// Verificamos bit de presencia de la page table.
if (pde & PTE_P) {
  // Obtenemos el PTE
  pte_t pte = uvpt[PGNUM(addr)];

  // Verificamos bit de presencia de la página
  if (pte & PTE_P) {
    if (pte & PTE_W) {
      // Modificable por el usuario
    } else {
      // No modificable por el usuario
    }
  ...
```

**3. Describir el funcionamiento de la función `duppage()`.**

Se puede observar en el código original comentarios explicando la función paso por paso. Básicamente copia el contenido de una página de un proceso padre a un proceso hijo. Para ello realiza los siguientes pasos:
1. Aloca una página para el proceso destino mapeada en la dirrección parámetro `addr`.
2. Mapea la página recién alocada en la dirección `UTEMP` del proceso padre.
3. El proceso padre copia el contenido de su página en dirección `addr` en la dirección `UTEMP` (en consecuencia escribe en `addr` del proceso hijo).
4. Desmapea las direcciones del paso 2.

**4. Supongamos que se añade a `duppage()` un argumento booleano que indica si la página debe quedar como solo-lectura en el proceso hijo:**
  * **indicar qué llamada adicional se debería hacer si el booleano es `true`**
  * **describir un algoritmo alternativo que no aumente el número de llamadas al sistema, que debe quedar en 3 (1 × alloc, 1 × map, 1 × unmap).**

Un proceso puede cambiarse los permisos de una página re-mapeando la página en la nueva dirección con `sys_page_map` (pasando los nuevos permisos). Por lo tanto, si `duppage()` recibe `true` como parámetro, se debería añadir al final la siguiente llamada adicional:

```
	if ((r = sys_page_map(dstenv, addr, dstenv, addr, PTE_P|PTE_U)) < 0)
		panic("sys_page_map: %e", r);
```

Un algoritmo alternativo podría obtenerse cambiando el orden de las operaciones. Si las operaciones originales son:

```
. Alocar una página para el proceso destino y mapearla en la dirección addr
. Mapear la misma página en el proceso del padre, en la dirección UTEMP.
. Copiar el contenido de la página addr (del padre) en la página de la dirección UTEMP
. Desmapear el mapeo de UTEMP del padre.
```

El algoritmo alternativo presentaría el siguiente orden:

```
. Alocar una página para el proceso padre y mapearla en la dirección `UTEMP`
. Copiar el contenido de la página addr (del padre) en la página de la dirección UTEMP
. Mapear la misma página en el proceso hijo, en la dirección addr.
. Desmapear el mapeo de UTEMP del padre.
```

**5. ¿Por qué se usa `ROUNDDOWN(&addr)` para copiar el stack? ¿Qué es `addr` y por qué, si el stack crece hacia abajo, se usa `ROUNDDOWN` y no `ROUNDUP`?**

Se usa &addr por que es una variable local y por lo tanto vive en el stack, y ROUNDOWN por que queremos el principio de la página

multicore_init
--------------

**1. ¿Qué código copia, y a dónde, la siguiente línea de la función boot_aps()?**

```
memmove(code, mpentry_start, mpentry_end - mpentry_start);
```
En el sistema operativo, los CPUs se pueden clasificar en dos tipos: BSP (bootstrap procesors) responsables de bootear el sistema operativo, y APs (application procesors) activados por el BSP una vez que el S.O. esté up and running.

El CPU BSP, tras inicializar el sistema operativo, llama a la función boot_aps(), que inicializa los CPUs del tipo APs.
Los APs inician en modo real (sin virtualizaciones, page directories, etc.) al igual que lo hizo anteriormente BSP. La diferencia es que ahora tenemos un procesador ya virtualizado, que puede 'ayudar' al resto en este proceso.

La línea en cuestión, es ejecutada por BSP, y lo que hace es copiar código que servirá de entry-point para los APs. Dicho código, ubicado en `mpentry.S`, presenta los tags `mpentry_start` y `mpentry_end`, que sirve para ubicarlo y determinar su tamaño. El mismo es copiado en la dirección física `MPENTRY_PADDR`, que no estará previamente en uso.


**2. ¿Para qué se usa la variable global mpentry_kstack? ¿Qué ocurriría si el espacio para este stack se reservara en el archivo kern/mpentry.S, de manera similar a bootstack en el archivo kern/entry.S?**

Previo a que un AP se inicialice con la función `lapic_startap()`, el BSP setea una variable global que es un puntero al kernel stack del cpu próximo a inicializar.

El espacio para ese stack no puede reservarse en el archivo `mpentry.S`, ya que como arranca en modo real, no tiene ninguna referencia del page directory ya creado del kernel.


**3. Cuando QEMU corre con múltiples CPUs, éstas se muestran en GDB como hilos de ejecución separados. Mostrar una sesión de GDB en la que se muestre cómo va cambiando el valor de la variable global mpentry_kstack**

```
(gdb) watch mpentry_kstack 
	Hardware watchpoint 1: mpentry_kstack
(gdb) continue
	Continuing.
	The target architecture is assumed to be i386
	=> 0xf0100186 <boot_aps+127>:	mov    %esi,%ecx

	Thread 1 hit Hardware watchpoint 1: mpentry_kstack

	Old value = (void *) 0x0
	New value = (void *) 0xf024b000 <percpu_kstacks+65536>
	boot_aps () at kern/init.c:105
	105			lapic_startap(c->cpu_id, PADDR(code));
(gdb) bt
	#0  boot_aps () at kern/init.c:105
	#1  0xf010020f in i386_init () at kern/init.c:55
	#2  0xf0100047 in relocated () at kern/entry.S:89
(gdb) info threads
	  Id   Target Id         Frame 
	* 1    Thread 1 (CPU#0 [running]) boot_aps () at kern/init.c:105
	  2    Thread 2 (CPU#1 [halted ]) 0x000fd412 in ?? ()
	  3    Thread 3 (CPU#2 [halted ]) 0x000fd412 in ?? ()
	  4    Thread 4 (CPU#3 [halted ]) 0x000fd412 in ?? ()
(gdb) continue
	Continuing.
	=> 0xf0100186 <boot_aps+127>:	mov    %esi,%ecx

	Thread 1 hit Hardware watchpoint 1: mpentry_kstack

	Old value = (void *) 0xf024b000 <percpu_kstacks+65536>
	New value = (void *) 0xf0253000 <percpu_kstacks+98304>
	boot_aps () at kern/init.c:105
	105			lapic_startap(c->cpu_id, PADDR(code));
(gdb) info threads
	  Id   Target Id         Frame 
	* 1    Thread 1 (CPU#0 [running]) boot_aps () at kern/init.c:105
	  2    Thread 2 (CPU#1 [running]) 0xf010029d in mp_main () at kern/init.c:123
	  3    Thread 3 (CPU#2 [halted ]) 0x000fd412 in ?? ()
	  4    Thread 4 (CPU#3 [halted ]) 0x000fd412 in ?? ()
(gdb) thread 2
	[Switching to thread 2 (Thread 2)]
	#0  0xf010029d in mp_main () at kern/init.c:123
	123		xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
(gdb) bt
	#0  0xf010029d in mp_main () at kern/init.c:123
	#1  0x00007060 in ?? ()
(gdb) p cpunum()
	Could not fetch register "orig_eax"; remote failure reply 'E14'
(gdb) thread 1
	[Switching to thread 1 (Thread 1)]
	#0  boot_aps () at kern/init.c:105
	105			lapic_startap(c->cpu_id, PADDR(code));
(gdb) p cpunum()
	Could not fetch register "orig_eax"; remote failure reply 'E14'
(gdb) continue
	Continuing.
	=> 0xf0100186 <boot_aps+127>:	mov    %esi,%ecx

	Thread 1 hit Hardware watchpoint 1: mpentry_kstack

	Old value = (void *) 0xf0253000 <percpu_kstacks+98304>
	New value = (void *) 0xf025b000 <percpu_kstacks+131072>
	boot_aps () at kern/init.c:105
	105			lapic_startap(c->cpu_id, PADDR(code));

```

Las ejecuciones `p cpnum()` resultaron en el siguiente error:

```
Could not fetch register "orig_eax"; remote failure reply 'E14'
```
Lo cual fue validado con el docente. De todas formas, las impresiones deberían haber sido '1' y '0' en cada invocación. Siempre será N-1 donde N es el número de cpu thread.


**4. En el archivo kern/mpentry.S se puede leer:**

```
# We cannot use kern_pgdir yet because we are still
# running at a low EIP.
movl $(RELOC(entry_pgdir)), %eax
```
**a) ¿Qué valor tiene el registro %eip cuando se ejecuta esa línea? Responder con redondeo a 12 bits, justificando desde qué región de memoria se está ejecutando este código.**
**b) ¿Se detiene en algún momento la ejecución si se pone un breakpoint en mpentry_start? ¿Por qué?**

a) Esa línea pertenece al código entry point de un AP, dicho código fué mapeado a la dirección `MPENTRY_PADDR` con `memmove()` en `boot_aps()`. Esa dirección es `0x7000` (es una dirección física). Por lo tanto, el registro `%eip` cuando pasa por esa instrucción, redondeada a 12 bits, es `0x7000`.

b) No, la ejecución no se detiene si se pone un breakpoint en `mpentry_start`. GDB desconoce la dirección de esa instrucción, esto se debe a que ese cpu está en real-mode y no tiene virtualización de memoria (que es lo que necesita gdb para ubicarlo).


**4. Con GDB, mostrar el valor exacto de %eip y mpentry_kstack cuando se ejecuta la instrucción anterior en el último AP.**

Con los siguientes comandos se llega al breakpoint deseado `(0x7000)` en el thread 4 (último AP)

```
(gdb) b *0x7000 thread 4
	Breakpoint 1 at 0x7000
(gdb) continue
	Continuing.
	Thread 2 received signal SIGTRAP, Trace/breakpoint trap.
	[Switching to Thread 2]
	The target architecture is assumed to be i8086
	[ 700:   0]    0x7000:	cli    
	0x00000000 in ?? ()
(gdb) disable 1
(gdb) si 10
	The target architecture is assumed to be i386
	=> 0x7020:	mov    $0x10,%ax
	0x00007020 in ?? ()
(gdb) enable 1
(gdb) continue
	Continuing.
	Thread 3 received signal SIGTRAP, Trace/breakpoint trap.
	[Switching to Thread 3]
	The target architecture is assumed to be i8086
	[ 700:   0]    0x7000:	cli    
	0x00000000 in ?? ()
(gdb) disable 1
(gdb) si 10
	The target architecture is assumed to be i386
	=> 0x7020:	mov    $0x10,%ax
	0x00007020 in ?? ()
(gdb) enable 1
(gdb) continue
Continuing.
	Thread 4 received signal SIGTRAP, Trace/breakpoint trap.
	[Switching to Thread 4]
	The target architecture is assumed to be i8086
	[ 700:   0]    0x7000:	cli    
	0x00000000 in ?? ()
```

Con los siguientes comandos se visualizan las 10 próximas instrucciones:

```
(gdb) disable 1
(gdb) si 10
	The target architecture is assumed to be i386
	=> 0x7020:	mov    $0x10,%ax
	0x00007020 in ?? ()
(gdb) x/10i $eip
	=> 0x7020:	mov    $0x10,%ax
	   0x7024:	mov    %eax,%ds
	   0x7026:	mov    %eax,%es
	   0x7028:	mov    %eax,%ss
	   0x702a:	mov    $0x0,%ax
	   0x702e:	mov    %eax,%fs
	   0x7030:	mov    %eax,%gs
	   0x7032:	mov    $0x11f000,%eax
	   0x7037:	mov    %eax,%cr3
	   0x703a:	mov    %cr4,%eax
```

Como vemos, `eax` se seteará con el valor `$0x11f000` que corresponde con la dirección física del símbolo `entry_pgdir` que es la entrada al page directory del kernel. Podemos poner un breakpoint y visualizar el valor de `eip` en esta línea haciendo:

```
(gdb) watch $eax == 0x11f000
	Watchpoint 3: $eax == 0x11f000
(gdb) continue
	Continuing.
	=> 0x7037:	mov    %eax,%cr3
	Thread 4 hit Watchpoint 3: $eax == 0x11f000
	Old value = 0
	New value = 1
	0x00007037 in ?? ()
(gdb) p $eip
$1 = (void (*)()) 0x7037

```
Luego continuamos ejecutando líneas con `si` hasta la línea en que se se setea el stack en `mpentry_kstack` e imprimimos dicha dirección.

```
(gdb) si
...
(gdb) p mpentry_kstack
$4 = (void *) 0xf025b000 <percpu_kstacks+131072>
```

ipc_recv
---------

**1. Un proceso podría intentar enviar el valor númerico -E_INVAL vía ipc_send(). ¿Cómo es posible distinguir si es un error, o no? En estos casos:**

```
CASO A:
envid_t src = -1;
int r = ipc_recv(&src, 0, NULL);

if (r < 0)
  if (/* ??? */)
    puts("Hubo error.");
  else
    puts("Valor negativo correcto.")
```


```
CASO B
// Versión B
int r = ipc_recv(NULL, 0, NULL);

if (r < 0)
  if (/* ??? */)
    puts("Hubo error.");
  else
    puts("Valor negativo correcto.")
```

En el caso A, el wrapper `ipc_recv` fue llamado con un valor de `from_env_store` distinto de NULL, por lo que de fallar la syscall dicho valor será puesto a cero. Entonces el código para diferenciar un error de un valor negativo enviado podría ser:

```
CASO A:
envid_t src = -1;
int r = ipc_recv(&src, 0, NULL);

if (r < 0)
  if (!src)
    puts("Hubo error.");
  else
    puts("Valor negativo correcto.")
```

En el caso B, tanto `from_env_store` como `perm_store` pasados como parámetro son `NULL`, lo que significa que no servirán para distinguir un error de la syscall. En este caso puede utilizarse el registro `eax`, que si retorna con éxito, es puesto a 0. El código sería el siguiente:

```
CASO B
// Versión B
int r = ipc_recv(NULL, 0, NULL);

if (r < 0)
  if (!thisenv->env_tf.tf_regs.reg_eax)
    puts("Hubo error.");
  else
    puts("Valor negativo correcto.")
```

sys_ipc_try_send
----------------

**Implementar la llamada al sistema `sys_ipc_try_send()` siguiendo los comentarios en el código, y responder:**

**1. ¿Cómo se podría hacer bloqueante esta llamada? Esto es: qué estrategia de implementación se podría usar para que, si un proceso A intenta a enviar a B, pero B no está esperando un mensaje, el proceso A sea puesto en estado `ENV_NOT_RUNNABLE`, y sea despertado una vez B llame a `ipc_recv()`.**

Se podria usar un mecanismo similar al que utiliza `sys_ipc_recv` agregando un flag del tipo `bool env_ipc_sending;` en el `struct Env`. De esta manera ambas syscalls primero validarán errores y luego en caso del send si el proceso pasado por parámetro no está dormido en receiving, el sender se va a dormir. Así el proceso que recibe (ahora la syscall recibirá el id del proceso que espera recibir), comprobará si este está intentando enviar datos con el flag propuesto. Como este es el caso, mapeará y tomará el dato necesario y despertará al sender y retornará. El caso análogo en el que el receive llega primero y este se pone en NOT RUNNEABLE ya lo conocemos y es el implementado hasta ahora.

**2. Con esta nueva estrategia de implementación mejorada ¿podría ocurrir un deadlock? Poner un ejemplo de código de usuario que entre en deadlock.**

**3. ¿Podría el kernel detectar el deadlock, e impedirlo devolviendo un nuevo error, E_DEADLOCK? ¿Qué función o funciones tendrían que modificarse para ello?**

Ejecución de Tests
----

´´´
make[1]: Leaving directory '/home/grobles/FIUBA/Sistemas Operativos/TP1-SisOp'
helloinit: OK (2.4s) 
Part 0 score: 1/1

yield: OK (1.2s) 
spin0: Timeout! OK (1.2s) 
Part 1 score: 2/2

dumbfork: OK (0.8s) 
forktree: OK (2.0s) 
spin: OK (2.0s) 
Part 2 score: 3/3

yield2: OK (1.0s) 
stresssched: OK (2.1s) 
Part 3 score: 2/2

sendpage: OK (2.0s) 
pingpong: OK (1.9s) 
primes: OK (3.3s) 
Part 4 score: 3/3

faultread: OK (1.3s) 
faultwrite: OK (2.3s) 
faultdie: OK (1.9s) 
faultregs: OK (2.2s) 
faultalloc: OK (1.8s) 
faultallocbad: OK (2.1s) 
faultnostack: OK (1.8s) 
faultbadhandler: OK (2.2s) 
faultevilhandler: OK (1.8s) 
Part 5 score: 9/9

Score: 20/20
´´´

