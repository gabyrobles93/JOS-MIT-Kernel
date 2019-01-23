1. ¿How did you structure your transmit implementation? In particular, what do you do if the transmit ring is full?

En primer lugar implementé la inicialización de la transmisión (e1000_tx_init), siguiendo los pasos de la hoja de datos de la placa de red. Aquí tome algunas decisiones de diseño, como por ejemplo:

- Definir en forma estática el arreglo de descriptores de transmisión (global y estático, en el archivo e1000.c)
- Definir en forma estática el arreglo de paquetes de transmisión, o buffers de datos a transmitir (global y estático, en el archivo e1000.c)
     - Ambos arreglos cuentan con una capacidad de 64 elementos (cota impuesta por el enunciado).
     
En la inicialización, se asocian los arreglos entre sí en un loop de 64 vueltas. El valor address de las estructuras de descriptor de transmisión se asocian uno a uno a las direcciones FISICAS de los paquetes de datos del segundo arreglo.

Luego, implementé la función de transmisión (e1000_send_packet), que valida que el tamaño del paquete a enviar sea menor al máximo impuesto por Ethernet (1518 bytes). Luego, obtiene el TAIL de la cola circular de descriptores mediante el valor del registro TDT. Luego chequea el valor del bit DD (Descriptor Done) del campo status del descriptor de transmisión: si es 1 significa que dicho descriptor está disponible para utilizarse. Si este valor DD es 0, significa que la cola está llena y se debe reintentar hasta que se libere algún descriptor.

En en caso de que se encuentre un descriptor libre, se copia la información del buffer en la dirección asociada al descriptor (y previamente alocada estáticamente en el arreglo de paquetes). Se setean mas parámetros del descriptor necesarios y por último se actualiza el valor de TAIL del arreglo circular como (i + 1) % N.

Para todas estas tareas implementé dos funciones auxiliares: setreg y getreg que reciben como parámetro un offset (desde la dirección base de registros de la placa) y el valor que se desea setear para getreg.
