#include "ns.h"
#include <inc/lib.h>

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
	envid_t from_env;
	int32_t value;

	while(1) {
		value = ipc_recv(&from_env, &nsipcbuf, NULL);

		if ((from_env != ns_envid) || (value != NSREQ_OUTPUT)) continue;

		do {
			value = sys_transmit_packet(nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len);
		} while(value < 0);
	}
}


