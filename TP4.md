TP4: Sistema de archivos e intérprete de comandos
=================================================

static_assert
-------------

**Se recomienda leer la función `diskaddr()` en el archivo `fs/bc.c`. ¿Qué es `super->s_nblocks`?**
La variable `super` es un `struct` que representa el super bloque del filesystem. En particular el campo `s_nblocks` almacena la cantidad de bloques que tiene nuestro filesystem, en esta función validamos que el número de bloque pasado por parámetro no sea mayor a la cantidad de bloques que tiene nuestro disco.