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