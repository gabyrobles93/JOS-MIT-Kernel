TP3: Multitarea con desalojo
============================

static_assert
-------------

¿cómo y por qué funciona la macro `static_assert` que define JOS?
La implementación de `static_assert` es la siguiente:
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

