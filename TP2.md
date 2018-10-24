TP2: Procesos de usuario
========================

env_alloc
---------
Inicializa un nuevo Environment (proceso) que se encuentre libre. Entre otras cosas, le asigna un identificador único. El algoritmo para generar un nuevo identificador es el siguiente:

1. ¿Qué identificadores se asignan a los primeros 5 procesos creados? (Usar base hexadecimal.)

```
	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
	if (generation <= 0)  // Don't create a negative env_id.
		generation = 1 << ENVGENSHIFT;
	e->env_id = generation | (e - envs);
```

Como todos los structs Env se inicializaron en 0 (con meminit), inicialmente tendrán env_id = 0. En la última línea puede observarse una operación `or` en donde el término derecho es una resta entre dos punteros (aritmética de punteros), donde `e` es la dirección de memoria del enviroment libre siendo incializado y `envs` es la base del arreglo de enviroments. Por lo tanto, esta resta no es mas que el offset de la dirección del enviroment libre siendo inicializado.

Los primeros cinco procesos creados tendrán los siguientes identificadores:

```
Identificador número 1: 0x1000 = 4096
Identificador número 2: 0x1001 = 4097
Identificador número 3: 0x1002 = 4098
Identificador número 4: 0x1003 = 4099
Identificador número 5: 0x1004 = 4100
```

2. Supongamos que al arrancar el kernel se lanzan NENV proceso a ejecución. A continuación se destruye el proceso asociado a envs[630] y se lanza un proceso que cada segundo muere y se vuelve a lanzar. ¿Qué identificadores tendrá este proceso en sus sus primeras cinco ejecuciones?

En la primer ejecución, en el momento que se lanzan NENV procesos, el proceso asociado a envs[630] tendrá el identificador 0x1276. Al morir, dicho identificador seguirá asociado al struct de ese proceso. En su próxima ejecución, en el algoritmo de asignación de id, `e->env_id` tendrá el valor antiguo, por lo que la primera línea donde se hace el cálculo para `generation`, dará un valor distinto que para la primera ejecución. En particular, tendrá un aumento de 4096 unidades (decimal) en cada ejecución. Puesto que el `environment index` es siempre el mismo lo que se va modificando es el `Uniqueifier` que distingue procesos con el mismo índice que fueron creados en distintos tiempos.

Por lo que las primeras 5 ejecuciones de ese proceso tienen los siguientes ids:

```
1er env_id: 0x1276 = 4726
2do env_id: 0x2276 = 8822
3er env_id: 0x3276 = 12918
4to env_id: 0x4276 = 17014
5to env_id: 0x5276 = 21110
```

env_init_percpu
---------------

La instrucción `lgdt` ("Load Global Descriptor Table Register") recibe como operando la dirección de un struct del tipo `Pseudodesc`, que no es más que un uint16_t para LÍMITE y un uint32_t para BASE (en total 6 bytes). Donde BASE es la dirección virtual de la gdt (Global Descriptor Table) y LÍMITE es sizeof(gdt) - 1.

Dicha instrucción guarda estos valores (BASE y LÍMITE) en un registro especial de CPU denominado GDTR. Dicho registro, en x86, tiene 48 bits de longitud. Los 16 bits mas bajos indican el tamaño de la GDT y los 32 bits mas altos indican su ubicación en memoria.

```
GDTR:
|LIMIT|----BASE----|
```

Referencia: https://c9x.me/x86/html/file_module_x86_id_156.html


env_pop_tf
----------

Esta función restaura el TrapFrame de un Environment. Un TrapFrame no es mas una estructura que guarda una "foto" del estado de los registros en el momento que se realizó un context switch. Cuando el kernel decide que ese Environment debe volver a ejecución realiza una serie de pasos, y el último de ellos es la función env_pop_tf(). El switch siempre se hace desde kernel a user space (nunca de user a user space).

1. ¿Qué hay en `(%esp)` tras el primer `movl` de la función?

El primer `movl` de la función es:
```
movl %0,%%esp
```
Que no hace otra cosa más que hacer que apuntar %esp a el TrapFrame del environment (nuevo tope de stack).
Luego, con `popal` se hace una serie de pops (quitando cosas del nuevo stack, es decir, del TrapFrame) que se van asignando a los registros del CPU.

2. ¿Qué hay en `(%esp)` justo antes de la instrucción `iret`? ¿Y en `8(%esp)`?

Justo antes de la instrucción `iret`, `(%esp)` tiene la dirección del code segment (uint16_t tf_cs).

3. ¿Cómo puede determinar la CPU si hay un cambio de ring (nivel de privilegio)?

En la función env_alloc (que inicializa un proceso de usuario), se ejecutan las siguientes líneas:

```
	e->env_tf.tf_ds = GD_UD | 3;
	e->env_tf.tf_es = GD_UD | 3;
	e->env_tf.tf_ss = GD_UD | 3;
	e->env_tf.tf_esp = USTACKTOP;
	e->env_tf.tf_cs = GD_UT | 3;
```
Que setean los 2 bits mas bajos del registro de cada segmento en 3, que equivale al 3er ring. Además, se marcan con GD_UD (global descriptor user data) y GD_UT (global descriptor user text).
De esta manera el CPU sabe si el code segment a ejecutar pertenece al usuario o al kernel. Si pertenece al usuario, entonces `iret` restaura los registros SS (stack segment) y ESP (stack pointer). El stack pointer caerá dentro de [USTACKTOP-PGSIZE, USTACKTOP].

gdb_hello
---------
1. Poner un breakpoint en env_pop_tf() y continuar la ejecución hasta allí.
2. En QEMU, entrar en modo monitor (Ctrl-a c), y mostrar las cinco primeras líneas del comando info registers.

```
EAX=003bc000 EBX=f01c0000 ECX=f03bc000 EDX=0000023c
ESI=00010094 EDI=00000000 EBP=f0118fd8 ESP=f0118fbc
EIP=f0102ea6 EFL=00000092 [--S-A--] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
CS =0008 00000000 ffffffff 00cf9a00 DPL=0 CS32 [-R-]
```

3. De vuelta a GDB, imprimir el valor del argumento tf

```
(gdb) p tf
$1 = (struct Trapframe *) 0xf01c0000
```

4. Imprimir, con `x/Nx tf` tantos enteros como haya en el struct Trapframe donde N = sizeof(Trapframe) / sizeof(int).

```
(gdb) print sizeof(struct Trapframe) / sizeof(int)
$2 = 17
(gdb) x/17x tf
0xf01c0000:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01c0010:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01c0020:	0x00000023	0x00000023	0x00000000	0x00000000
0xf01c0030:	0x00800020	0x0000001b	0x00000000	0xeebfe000
0xf01c0040:	0x00000023
```

5. Avanzar hasta justo después del movl ...,%esp, usando `si M` para ejecutar tantas instrucciones como sea necesario en un solo paso.


6. Comprobar, con `x/Nx $sp` que los contenidos son los mismos que tf (donde N es el tamaño de tf).

```
(gdb) x/17x $sp
0xf01c0000:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01c0010:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01c0020:	0x00000023	0x00000023	0x00000000	0x00000000
0xf01c0030:	0x00800020	0x0000001b	0x00000000	0xeebfe000
0xf01c0040:	0x00000023
```

7. Explicar con el mayor detalle posible cada uno de los valores. Para los valores no nulos, se debe indicar dónde se configuró inicialmente el valor, y qué representa.

Para explicar cada uno de los valores, se debe entender que a este punto el "stack" tiene la estructura de un Trapframe, que se vió que tiene un tamaño de 17 bytes. La estructura de un Trapframe es la siguiente:

```
struct Trapframe {
	struct PushRegs tf_regs;
	uint16_t tf_es;
	uint16_t tf_padding1;
	uint16_t tf_ds;
	uint16_t tf_padding2;
	uint32_t tf_trapno;
	/* below here defined by x86 hardware */
	uint32_t tf_err;
	uintptr_t tf_eip;
	uint16_t tf_cs;
	uint16_t tf_padding3;
	uint32_t tf_eflags;
	/* below here only when crossing rings, such as from user to kernel */
	uintptr_t tf_esp;
	uint16_t tf_ss;
	uint16_t tf_padding4;
} __attribute__((packed));
```

Donde la estructura PushRegs se conforma como:

```
struct PushRegs {
	/* registers as pushed by pusha */
	uint32_t reg_edi;
	uint32_t reg_esi;
	uint32_t reg_ebp;
	uint32_t reg_oesp;	
	uint32_t reg_ebx;
	uint32_t reg_edx;
	uint32_t reg_ecx;
	uint32_t reg_eax;
} __attribute__((packed));
```
Las primeras dos líneas de valores de $sp:

```
0xf01c0000:	0x00000000	0x00000000	0x00000000	0x00000000
                  reg_edi         reg_esi         reg_ebp        reg_oesp
0xf01c0010:	0x00000000	0x00000000	0x00000000	0x00000000
                  reg_ebx         reg:edx         reg_ecx        reg_eax 
```

Son 8 bytes y se corresponde con la estructura de PushRegs, que son todos nulos (lógico si es la primera vez que entra en contexto este environment).

Luego , en la tercer línea de valores:

```
0xf01c0020:	0x00000023	0x00000023	0x00000000	0x00000000
		 pad - es        pad - ds         trapno          tf_err 
 ```
Los primeros 2 bytes corresponden a tf_es + tf_padding1 y tf_ds + padding2 respectivamente.
Los valores de es y ds (0x0023) se deben a que en `env_alloc()` se inicializaron con el valor `GD_UD | 3` (Global descriptor number = User Data y 3er ring).

En la cuarta línea de valores tenemos:

```
0xf01c0030:	0x00800020	0x0000001b	0x00000000	0xeebfe000
                  tf_eip         pad - cs        tf_eflags        tf_esp
```
El valor de tf_eip (instruction pointer) es la dirección a la primera línea del código ejecutable del environment. Si investigamos el elf con `readelf -S obj/user/hello` se observa lo siguiente:

```
There are 11 section headers, starting at offset 0x7690:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
->[ 1] .text             PROGBITS        00800020 006020 000d19 00  AX  0   0 16 <- (*)
¡

9. Ejecutar la instrucción iret. En ese momento se ha realizado el cambio de contexto y los símbolos del kernel ya no son válidos.

Imprimir el valor del contador de programa con `p $pc` o `p $eip`

```
(gdb) p $pc
$1 = (void (*)()) 0x800020
```

Cargar los símbolos de hello con `symbol-file obj/user/hello`. Volver a imprimir el valor del contador de programa




