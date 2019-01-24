#include "ns.h"

extern union Nsipc nsipcbuf;


void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.

	int32_t value;

	while(1) {
		value = sys_receive_packet(nsipcbuf.pkt.jp_data);

		if (value < 0) {
			sys_yield();
			continue;
		}

		nsipcbuf.pkt.jp_len = value;
	
		ipc_send(ns_envid, NSREQ_INPUT, &nsipcbuf, PTE_U | PTE_P | PTE_W);

		while ((value = sys_ipc_try_send(ns_envid, NSREQ_INPUT, &nsipcbuf, PTE_P | PTE_W | PTE_U)) < 0) {
			if (value == -E_IPC_NOT_RECV) sys_yield();
		}
	}
}
