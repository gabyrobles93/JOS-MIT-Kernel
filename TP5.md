**1. How did you structure your transmit implementation? In particular, what do you do if the transmit ring is full?

En primer lugar implementé la inicialización de la transmisión (e1000_tx_init), siguiendo los pasos de la hoja de datos de la placa de red. Aquí tome algunas decisiones de diseño, como por ejemplo:

- Definir en forma estática el arreglo de descriptores de transmisión (global y estático, en el archivo e1000.c)
- Definir en forma estática el arreglo de paquetes de transmisión, o buffers de datos a transmitir (global y estático, en el archivo e1000.c), donde la capacidad de cada buffer es el máximo permitido por Ethernet 1518 bytes.
- Ambos arreglos cuentan con una capacidad de 64 elementos (cota impuesta por el enunciado).
     
En la inicialización, se asocian los arreglos entre sí en un loop de 64 vueltas. El valor address de las estructuras de descriptor de transmisión se asocian uno a uno a las direcciones FISICAS de los paquetes de datos del segundo arreglo.

Luego, implementé la función de transmisión (e1000_send_packet), que valida que el tamaño del paquete a enviar sea menor al máximo impuesto por Ethernet (1518 bytes). Luego, obtiene el TAIL de la cola circular de descriptores mediante el valor del registro TDT. Luego chequea el valor del bit DD (Descriptor Done) del campo status del descriptor de transmisión: si es 1 significa que dicho descriptor está disponible para utilizarse. Si este valor DD es 0, significa que la cola está llena y se debe reintentar hasta que se libere algún descriptor.

En en caso de que se encuentre un descriptor libre, se copia la información del buffer en la dirección asociada al descriptor (y previamente alocada estáticamente en el arreglo de paquetes). Se setean mas parámetros del descriptor necesarios y por último se actualiza el valor de TAIL del arreglo circular como (i + 1) % N.

Para todas estas tareas implementé dos funciones auxiliares: setreg y getreg que reciben como parámetro un offset (desde la dirección base de registros de la placa) y el valor que se desea setear para getreg.

**2. How did you structure your receive implementation? In particular, what do you do if the receive queue is empty and a user environment requests the next incoming packet? 

En la inicialización de la recepción se setearon los registros de la placa siguiendo los pasos del manual y las recomendaciones del enunciado del trabajo. Aquí se tomaron algunas decisiones de diseño como:

- Hardcodear el valor de la MAC address de la placa (sugerido por el enunciado).
- Definir en forma estática el arreglo de descriptores de recepción (global y estático, en el archivo e1000.c)
- Definir en forma estática el arreglo de paquetes de recepción (global y estático, en el archivo e1000.c), donde el tamaño de cada buffer es de 2048 bytes (una de los posibles tamaños que ofrecía el manual de Intel).
- Ambos arreglos cuentan con una capacidad de 128 elementos (cota inferior impuesta por el enunciado).

En forma análoga a la transmisión, en la inicialización se asocian los arreglos entre si. El valor buffer address de las estructuras de descriptor de recepción se asocian uno a uno a las direcciones FISICAS de los paquetes de datos del segundo arreglo.

Luego implementé la función de recepción, que en primer lugar obtiene el indice del Tail en el anillo de descriptores. Se chequea si el anillo esta vacío viendo si el bit DD (Descriptor Done) esta encendido. En caso que el anillo no esté vacío, significa que hay algo para recibir, por lo tanto se mueve la información del buffer del descriptor al buffer que se recibe como parámetro. Luego se apagan los bits DD y EOP y por último se setea el registro RDT en la siguiente posición. Esta función retorna el largo del buffer recibido.

**3. What does the web page served by JOS's web server say?

This file came from JOS.
Cheesy web page! 

**4. How long approximately did it take you to do this lab? 
