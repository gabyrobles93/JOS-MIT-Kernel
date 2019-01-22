#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <inc/types.h>
#include <kern/pci.h>

#define ETHERNET_MAX_PACKET_LEN 1518

#define E1000_STATUS   0x00008  /* Device Status - RO */
#define E1000_TDBAL    0x03800  /* TX Descriptor Base Address Low - RW */
#define E1000_TDLEN    0x03808  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818  /* TX Descripotr Tail - RW */
#define E1000_TCTL     0x00400  /* TX Control - RW */
#define E1000_TCTL_EN     0x00000002    /* enable tx */
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */
#define E1000_TCTL_CT     0x00000100    /* collision threshold */
#define E1000_TCTL_COLD   0x00040000    /* collision distance */
#define E1000_TIPG     0x00410  /* TX Inter-packet gap -RW */

#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */

#define E1000_TXD_CMD_RS     0x00000008 /* Report Status */
#define E1000_TXD_CMD_RPS    0x00000010 /* Report Packet Sent */

#define E_AGAIN -1  /* Error, la cola está llena */
#define E_INVAL -2  /* Error, paquete inválido */

#define E1000_MAX_DESCRIPTORS 64

struct tx_desc
{
	uint64_t addr;
	uint16_t length;
	uint8_t cso;
	uint8_t cmd;
	uint8_t status;
	uint8_t css;
	uint16_t special;
}__attribute__((packed));;

struct tx_packet
{
    uint8_t buffer[ETHERNET_MAX_PACKET_LEN];
}__attribute__((packed));;

int e1000_init(struct pci_func *pcif);
uint32_t getreg(uint32_t offset);
void setreg(uint32_t offset, uint32_t value);
int e1000_send_packet(char * buffer, size_t size);

#endif  // JOS_KERN_E1000_H
