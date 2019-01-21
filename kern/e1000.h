#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <inc/types.h>
#include <kern/pci.h>

#define E1000_STATUS   0x00008  /* Device Status - RO */

int e1000_init(struct pci_func *pcif);
uint32_t getreg(uint32_t offset);

#endif  // JOS_KERN_E1000_H
