#include <kern/e1000.h>
#include <kern/pmap.h>

// LAB 6: Your driver code here

volatile uint32_t * bar_0;

// Inicializa la placa de red, es invocada por el código de PCI (kern/pci.c) que detecta el la placa de red
// en el puerto PCI del motherboard y luego recorre el arreglo de dispositivos PCI
// y matchea Vendor y Device ID para invocar a esta función de inicialización.
int e1000_init(struct pci_func *pcif) {
    //pci_func_enable negotiates an MMIO region with the E1000 and stores its base and size in BAR 0 
    // (that is, reg_base[0] and reg_size[0]). This is a range of physical memory addresses assigned to the device
    pci_func_enable(pcif);

    // Mapeamos la memoria física destinada a la placa E1000 para I/O en direcciones virtuales de MMIO
    bar_0 = (uint32_t *) mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);

    // Imprimimos el estado de la placa E1000, en hexadecimal, que es un registro de 4 bytes que está en a partir del byte 8 en
    // el espacio de registros.
    cprintf("E1000 Status: %x\n", getreg(E1000_STATUS));

    return 0;
}

uint32_t getreg(uint32_t offset) {
    return (volatile uint32_t) bar_0[offset/4];
}
