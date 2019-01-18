#include <kern/e1000.h>

// LAB 6: Your driver code here

// Inicializa la placa de red, es invocada por el código de PCI (kern/pci.c) que detecta el la placa de red
// en el puerto PCI del motherboard y luego recorre el arreglo de dispositivos PCI
// y matchea Vendor y Device ID para invocar a esta función de inicialización.
int e1000_init(struct pci_func *pcif) {
    pci_func_enable(pcif);

    return 0;
}