TP2: Procesos de usuario
========================

env_alloc
---------
Inicializa un nuevo enviroment (proceso) que se encuentre libre. Entre otras cosas, le asigna un identificador único. El algoritmo para generar un nuevo identificador es el siguiente:

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

En la primer ejecución, en el momento que se lanzan NENV procesos, el proceso asociado a envs[630] tendrá el identificador 0x1276. Al morir, dicho identificador seguirá asociado al struct de ese proceso. En su próxima ejecución, en el algoritmo de asignación de id, `e->env_id` tendrá el valor antiguo, por lo que la primera línea donde se hace el cálculo para `generation`, dará un valor distinto que para la primera ejecución. En particular, tendrá un aumento de 4096 unidades (decimal) en cada ejecución.

Por lo que las primeras 5 ejecuciones de ese proceso tienen los siguientes ids:

```
1er env_id: 0x1276 = 4726
2do env_id: 0x2276 = 8822
3er env_id: 0x3276 = 12918
4to env_id: 0x4276 = 17014
5to env_id: 0x5276 = 21110
```
...


env_init_percpu
---------------

...


env_pop_tf
----------

...


gdb_hello
---------

...
