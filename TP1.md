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

...


page_alloc
----------

...


