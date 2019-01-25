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
#define E1000_TXD_CMD_EOP    0x00000001 /* End of Packet */

#define E1000_RCTL_LBM_NO         0x00000000    /* no loopback mode */
#define E1000_RCTL_RDMTS_HALF     0x00000000    /* rx desc min threshold size */
#define E1000_RCTL_MO_0           0x00000000    /* multicast offset 11:0 */
#define E1000_RCTL_SZ_2048        0x00000000    /* rx buffer size 2048 */
#define E1000_RCTL_LPE            0x00000020    /* long packet enable */
#define E1000_RCTL_BSEX           0x02000000    /* Buffer size extension */

#define E1000_RAH_AV  0x80000000        /* Receive descriptor valid */
#define E1000_RA       0x05400  /* Receive Address - RW Array */
#define E1000_MTA      0x05200  /* Multicast Table Array - RW Array */
#define E1000_IMS      0x000D0  /* Interrupt Mask Set - RW */
#define E1000_RDBAL    0x02800  /* RX Descriptor Base Address Low - RW */
#define E1000_RDBAH    0x02804  /* RX Descriptor Base Address High - RW */
#define E1000_RDLEN    0x02808  /* RX Descriptor Length - RW */
#define E1000_RDH      0x02810  /* RX Descriptor Head - RW */
#define E1000_RDT      0x02818  /* RX Descriptor Tail - RW */
#define E1000_RCTL     0x00100  /* RX Control - RW */
#define E1000_RCTL_EN             0x00000002    /* enable */
#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */
#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */
#define E1000_RXD_STAT_EOP      0x02    /* End of Packet */

#define E_AGAIN -1  /* Error, la cola está llena */
#define E_INVAL -2  /* Error, paquete inválido */

#define E1000_MAX_TX_DESCRIPTORS 64
#define E1000_MAX_RX_DESCRIPTORS 128
#define E1000_RCV_BUFFER_SIZE 2048



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

struct rx_desc {
    uint64_t buffer_addr; /* Address of the descriptor's data buffer */
    uint16_t length;     /* Length of data DMAed into data buffer */
    uint16_t csum;       /* Packet checksum */
    uint8_t status;      /* Descriptor status */
    uint8_t errors;      /* Descriptor Errors */
    uint16_t special;
}__attribute__((packed));;

struct tx_packet
{
    uint8_t buffer[ETHERNET_MAX_PACKET_LEN];
}__attribute__((packed));;

struct rx_packet
{
    uint8_t buffer[ETHERNET_MAX_PACKET_LEN];
}__attribute__((packed));;

int e1000_init(struct pci_func *pcif);
uint32_t getreg(uint32_t offset);
void setreg(uint32_t offset, uint32_t value);
int e1000_send_packet(char * buffer, size_t size);
int e1000_receive_packet(char * buffer, size_t size);

#endif  // JOS_KERN_E1000_H
