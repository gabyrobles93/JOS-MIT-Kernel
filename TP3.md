TP3: Multitarea con desalojo
============================

static_assert
-------------

**¿cómo y por qué funciona la macro `static_assert` que define JOS?
La implementación de `static_assert` es la siguiente:**
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

Al terminar un proceso su función `umain()` ¿dónde retoma la ejecución el kernel? Describir la secuencia de llamadas desde que termina `umain()` hasta que el kernel dispone del proceso.

En `lib/entry.S` (usuario) se llama a la función `libmain()`. Ésta última es quien configura la variable `thisenv` y el nombre del binario en caso de existir y finalmente llama a `umain()` por lo tanto, una vez que termina `umain()` la ejecución retorna aquí en `libmain()` quien es la encargada de llamar a `exit()` para que el kernel disponga del proceso.

**¿En qué cambia la función env_destroy() en este TP, respecto al TP anterior?**

En el TP anterior como no disponíamos de múltiples procesos no se hacía ningún tipo de validación y se liberaba el proceso. En la nueva implementación ya que el mismo proceso podría estar corriendo en otro CPU es necesario comprobarlo (el `if` comprueba si está corriendo y si además no es el proceso actual de este CPU), si esto es así se cambia el estado a `ENV_DYING`, con lo que se convierte en un "proceso zombie" y será liberado la próxima vez que se le ceda el control. En caso de no ser así se lo libera y se hace una última validación para comprobar que el proceso no era el que estaba corriendo en ese momento. En caso de ser así se actualiza `curenv` y se fuerza el cambio con otro proceso con `sched_yield`.

