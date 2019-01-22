#include <kern/e1000.h>
#include <kern/pmap.h>
#include <kern/env.h>
#include <inc/string.h>

// LAB 6: Your driver code here

volatile uint32_t * bar_0;
static void e1000_tx_init(void);

struct tx_desc tx_descriptors[E1000_MAX_DESCRIPTORS] __attribute__ ((aligned (16)));
struct tx_packet tx_packets[E1000_MAX_DESCRIPTORS];

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
    cprintf("e1000 Status: %x\n", getreg(E1000_STATUS));

    // Inicializacion de transmision (Exercise 5)
    e1000_tx_init();

    e1000_send_packet("Hola", 4);
    e1000_send_packet("Hello", 5);
    e1000_send_packet("World", 5);

    return 0;
}

uint32_t getreg(uint32_t offset) {
    return (volatile uint32_t) bar_0[offset/4];
}

void setreg(uint32_t offset, uint32_t value) {
    bar_0[offset/4] = value;
}

void e1000_tx_init(void) {
    // Escribo ceros en el arreglo de descriptores de tx para inicializar esta memoria
    memset(tx_descriptors, 0, E1000_MAX_DESCRIPTORS * sizeof(struct tx_desc));
    // Seteo el registro TDBAL (Transmit Descriptor Base Address Low)
    // Va la dirección física, pues la placa accede a memoria sin pasar por la MMU
    setreg(E1000_TDBAL, PADDR(tx_descriptors));
    // Seteo el registro TDLEN (Transmit Descriptor Lenght)
    setreg(E1000_TDLEN, sizeof(struct tx_desc) * E1000_MAX_DESCRIPTORS);
    // Seteo el registro TDH (Transmit Descriptor Head). Debe ir en 0 según documentación
    setreg(E1000_TDH, 0);
    // Seteo el registro TDT (Transmit Descriptor Tail). Debe ir en 0 según documentación
    setreg(E1000_TDT, 0);
    // Seteo el registro TCTL (Transmit Control REGISTER) según documentación
    setreg(E1000_TCTL, E1000_TCTL_EN | E1000_TCTL_PSP | E1000_TCTL_CT | E1000_TCTL_COLD);
    // Seteo el registro TIPG (TX Inter-packet gap) según documentación
    setreg(E1000_TIPG, (10 << 0) | (6 << 20) | (4 << 10));
    // Asocio los buffers de paquete con el address de los descriptors y enciendo bit DD (descriptor se puede utilizar)
    for (int i = 0; i < E1000_MAX_DESCRIPTORS; i++) {
        tx_descriptors[i].addr = PADDR(tx_packets[i].buffer);
        tx_descriptors[i].status |= E1000_TXD_STAT_DD;
    }
}

int e1000_send_packet(char * buffer, size_t size) {
    // Chequeamos si hay algún descriptor libre
    // Obtenemos el índice del Tail de la cola de descriptores de transmisión.
    uint32_t td_tail = getreg(E1000_TDT);

    // Si el tamaño a enviar es mas grande que el maximo permitido por Ethernet entonces error
    if (size > ETHERNET_MAX_PACKET_LEN) {
        return -E_INVAL;
    }

    struct tx_desc * current_tx_desc = tx_descriptors + td_tail;

    if (current_tx_desc->status & E1000_TXD_STAT_DD) { // El hardware procesó este descriptor y se puede reciclar
        memmove(tx_packets[td_tail].buffer, buffer, size);
        current_tx_desc->length = (uint16_t) size;
        current_tx_desc->status &= ~E1000_TXD_STAT_DD;
        current_tx_desc->cmd |= E1000_TXD_CMD_RS | E1000_TXD_CMD_RPS;
        setreg(E1000_TDT, (td_tail+1) % E1000_MAX_DESCRIPTORS);
    } else {
        return -E_AGAIN;    // Cola llena, se debe reintentar, quizá el hardware libere algun descriptor
    }
 
    return 0;
   
}