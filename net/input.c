#include "ns.h"

extern union Nsipc nsipcbuf;


void
input(envid_t ns_envid)
{
    binaryname = "ns_input";

    // LAB 6: Your code here:
    //  - read a packet from the device driver
    //  - send it to the network server
    // Hint: When you IPC a page to the network server, it will be
    // reading from it for a while, so don't immediately receive
    // another packet in to the same physical page.

    int32_t r;
    int32_t len;

    struct jif_pkt * pkt = (struct jif_pkt *) REQVA;
    sys_page_alloc(0, pkt, PTE_P | PTE_W | PTE_U);

    while(1) {
        while ( (len = sys_receive_packet(pkt->jp_data, 2048)) < 0) {
            sys_yield();
        }

        pkt->jp_len = len;

        while ((r = sys_ipc_try_send(ns_envid, NSREQ_INPUT, pkt, PTE_P | PTE_W | PTE_U)) < 0) {
            if (r == -E_IPC_NOT_RECV) sys_yield();
        }

        sys_page_unmap(0, pkt);
        pkt = (struct jif_pkt *) REQVA;
        sys_page_alloc(0, pkt, PTE_P | PTE_W | PTE_U);
    }
}