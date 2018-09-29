
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
_start = RELOC(entry)

.globl entry
.func entry
entry:
	movw	$0x1234,0x472			# warm boot
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f0100046:	b8 50 69 11 f0       	mov    $0xf0116950,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 65 27 00 00       	call   f01027c2 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 94 06 00 00       	call   f01006f6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 2c 10 f0       	push   $0xf0102c00
f010006f:	e8 b0 1c 00 00       	call   f0101d24 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 72 1b 00 00       	call   f0101beb <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 c0 08 00 00       	call   f0100946 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 69 11 f0 00 	cmpl   $0x0,0xf0116940
f010009a:	74 0f                	je     f01000ab <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009c:	83 ec 0c             	sub    $0xc,%esp
f010009f:	6a 00                	push   $0x0
f01000a1:	e8 a0 08 00 00       	call   f0100946 <monitor>
f01000a6:	83 c4 10             	add    $0x10,%esp
f01000a9:	eb f1                	jmp    f010009c <_panic+0x11>
	panicstr = fmt;
f01000ab:	89 35 40 69 11 f0    	mov    %esi,0xf0116940
	asm volatile("cli; cld");
f01000b1:	fa                   	cli    
f01000b2:	fc                   	cld    
	va_start(ap, fmt);
f01000b3:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000b6:	83 ec 04             	sub    $0x4,%esp
f01000b9:	ff 75 0c             	pushl  0xc(%ebp)
f01000bc:	ff 75 08             	pushl  0x8(%ebp)
f01000bf:	68 3c 2c 10 f0       	push   $0xf0102c3c
f01000c4:	e8 5b 1c 00 00       	call   f0101d24 <cprintf>
	vcprintf(fmt, ap);
f01000c9:	83 c4 08             	add    $0x8,%esp
f01000cc:	53                   	push   %ebx
f01000cd:	56                   	push   %esi
f01000ce:	e8 2b 1c 00 00       	call   f0101cfe <vcprintf>
	cprintf("\n>>>\n");
f01000d3:	c7 04 24 1b 2c 10 f0 	movl   $0xf0102c1b,(%esp)
f01000da:	e8 45 1c 00 00       	call   f0101d24 <cprintf>
f01000df:	83 c4 10             	add    $0x10,%esp
f01000e2:	eb b8                	jmp    f010009c <_panic+0x11>

f01000e4 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000eb:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ee:	ff 75 0c             	pushl  0xc(%ebp)
f01000f1:	ff 75 08             	pushl  0x8(%ebp)
f01000f4:	68 21 2c 10 f0       	push   $0xf0102c21
f01000f9:	e8 26 1c 00 00       	call   f0101d24 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	53                   	push   %ebx
f0100102:	ff 75 10             	pushl  0x10(%ebp)
f0100105:	e8 f4 1b 00 00       	call   f0101cfe <vcprintf>
	cprintf("\n");
f010010a:	c7 04 24 66 2c 10 f0 	movl   $0xf0102c66,(%esp)
f0100111:	e8 0e 1c 00 00       	call   f0101d24 <cprintf>
	va_end(ap);
}
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011c:	c9                   	leave  
f010011d:	c3                   	ret    

f010011e <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010011e:	55                   	push   %ebp
f010011f:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100121:	89 c2                	mov    %eax,%edx
f0100123:	ec                   	in     (%dx),%al
	return data;
}
f0100124:	5d                   	pop    %ebp
f0100125:	c3                   	ret    

f0100126 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100126:	55                   	push   %ebp
f0100127:	89 e5                	mov    %esp,%ebp
f0100129:	89 c1                	mov    %eax,%ecx
f010012b:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010012d:	89 ca                	mov    %ecx,%edx
f010012f:	ee                   	out    %al,(%dx)
}
f0100130:	5d                   	pop    %ebp
f0100131:	c3                   	ret    

f0100132 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100132:	55                   	push   %ebp
f0100133:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100135:	b8 84 00 00 00       	mov    $0x84,%eax
f010013a:	e8 df ff ff ff       	call   f010011e <inb>
	inb(0x84);
f010013f:	b8 84 00 00 00       	mov    $0x84,%eax
f0100144:	e8 d5 ff ff ff       	call   f010011e <inb>
	inb(0x84);
f0100149:	b8 84 00 00 00       	mov    $0x84,%eax
f010014e:	e8 cb ff ff ff       	call   f010011e <inb>
	inb(0x84);
f0100153:	b8 84 00 00 00       	mov    $0x84,%eax
f0100158:	e8 c1 ff ff ff       	call   f010011e <inb>
}
f010015d:	5d                   	pop    %ebp
f010015e:	c3                   	ret    

f010015f <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010015f:	55                   	push   %ebp
f0100160:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100162:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100167:	e8 b2 ff ff ff       	call   f010011e <inb>
f010016c:	a8 01                	test   $0x1,%al
f010016e:	74 0f                	je     f010017f <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f0100170:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100175:	e8 a4 ff ff ff       	call   f010011e <inb>
f010017a:	0f b6 c0             	movzbl %al,%eax
}
f010017d:	5d                   	pop    %ebp
f010017e:	c3                   	ret    
		return -1;
f010017f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100184:	eb f7                	jmp    f010017d <serial_proc_data+0x1e>

f0100186 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f0100186:	55                   	push   %ebp
f0100187:	89 e5                	mov    %esp,%ebp
f0100189:	56                   	push   %esi
f010018a:	53                   	push   %ebx
f010018b:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f010018d:	bb 00 00 00 00       	mov    $0x0,%ebx
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100192:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100197:	e8 82 ff ff ff       	call   f010011e <inb>
f010019c:	a8 20                	test   $0x20,%al
f010019e:	75 12                	jne    f01001b2 <serial_putc+0x2c>
f01001a0:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001a6:	7f 0a                	jg     f01001b2 <serial_putc+0x2c>
	     i++)
		delay();
f01001a8:	e8 85 ff ff ff       	call   f0100132 <delay>
	     i++)
f01001ad:	83 c3 01             	add    $0x1,%ebx
f01001b0:	eb e0                	jmp    f0100192 <serial_putc+0xc>

	outb(COM1 + COM_TX, c);
f01001b2:	89 f0                	mov    %esi,%eax
f01001b4:	0f b6 d0             	movzbl %al,%edx
f01001b7:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001bc:	e8 65 ff ff ff       	call   f0100126 <outb>
}
f01001c1:	5b                   	pop    %ebx
f01001c2:	5e                   	pop    %esi
f01001c3:	5d                   	pop    %ebp
f01001c4:	c3                   	ret    

f01001c5 <serial_init>:

static void
serial_init(void)
{
f01001c5:	55                   	push   %ebp
f01001c6:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001c8:	ba 00 00 00 00       	mov    $0x0,%edx
f01001cd:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001d2:	e8 4f ff ff ff       	call   f0100126 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001d7:	ba 80 00 00 00       	mov    $0x80,%edx
f01001dc:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001e1:	e8 40 ff ff ff       	call   f0100126 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f01001e6:	ba 0c 00 00 00       	mov    $0xc,%edx
f01001eb:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001f0:	e8 31 ff ff ff       	call   f0100126 <outb>
	outb(COM1+COM_DLM, 0);
f01001f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01001fa:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f01001ff:	e8 22 ff ff ff       	call   f0100126 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100204:	ba 03 00 00 00       	mov    $0x3,%edx
f0100209:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010020e:	e8 13 ff ff ff       	call   f0100126 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f0100213:	ba 00 00 00 00       	mov    $0x0,%edx
f0100218:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f010021d:	e8 04 ff ff ff       	call   f0100126 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f0100222:	ba 01 00 00 00       	mov    $0x1,%edx
f0100227:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010022c:	e8 f5 fe ff ff       	call   f0100126 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100231:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100236:	e8 e3 fe ff ff       	call   f010011e <inb>
f010023b:	3c ff                	cmp    $0xff,%al
f010023d:	0f 95 05 34 65 11 f0 	setne  0xf0116534
	(void) inb(COM1+COM_IIR);
f0100244:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100249:	e8 d0 fe ff ff       	call   f010011e <inb>
	(void) inb(COM1+COM_RX);
f010024e:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100253:	e8 c6 fe ff ff       	call   f010011e <inb>

}
f0100258:	5d                   	pop    %ebp
f0100259:	c3                   	ret    

f010025a <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f010025a:	55                   	push   %ebp
f010025b:	89 e5                	mov    %esp,%ebp
f010025d:	56                   	push   %esi
f010025e:	53                   	push   %ebx
f010025f:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100261:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100266:	b8 79 03 00 00       	mov    $0x379,%eax
f010026b:	e8 ae fe ff ff       	call   f010011e <inb>
f0100270:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100276:	7f 0e                	jg     f0100286 <lpt_putc+0x2c>
f0100278:	84 c0                	test   %al,%al
f010027a:	78 0a                	js     f0100286 <lpt_putc+0x2c>
		delay();
f010027c:	e8 b1 fe ff ff       	call   f0100132 <delay>
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100281:	83 c3 01             	add    $0x1,%ebx
f0100284:	eb e0                	jmp    f0100266 <lpt_putc+0xc>
	outb(0x378+0, c);
f0100286:	89 f0                	mov    %esi,%eax
f0100288:	0f b6 d0             	movzbl %al,%edx
f010028b:	b8 78 03 00 00       	mov    $0x378,%eax
f0100290:	e8 91 fe ff ff       	call   f0100126 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f0100295:	ba 0d 00 00 00       	mov    $0xd,%edx
f010029a:	b8 7a 03 00 00       	mov    $0x37a,%eax
f010029f:	e8 82 fe ff ff       	call   f0100126 <outb>
	outb(0x378+2, 0x08);
f01002a4:	ba 08 00 00 00       	mov    $0x8,%edx
f01002a9:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002ae:	e8 73 fe ff ff       	call   f0100126 <outb>
}
f01002b3:	5b                   	pop    %ebx
f01002b4:	5e                   	pop    %esi
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002c0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002c7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002ce:	5a a5 
	if (*cp != 0xA55A) {
f01002d0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002d7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002db:	74 63                	je     f0100340 <cga_init+0x89>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002dd:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f01002e4:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002e7:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01002ee:	8b 35 30 65 11 f0    	mov    0xf0116530,%esi
f01002f4:	ba 0e 00 00 00       	mov    $0xe,%edx
f01002f9:	89 f0                	mov    %esi,%eax
f01002fb:	e8 26 fe ff ff       	call   f0100126 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100300:	8d 7e 01             	lea    0x1(%esi),%edi
f0100303:	89 f8                	mov    %edi,%eax
f0100305:	e8 14 fe ff ff       	call   f010011e <inb>
f010030a:	0f b6 d8             	movzbl %al,%ebx
f010030d:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100310:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100315:	89 f0                	mov    %esi,%eax
f0100317:	e8 0a fe ff ff       	call   f0100126 <outb>
	pos |= inb(addr_6845 + 1);
f010031c:	89 f8                	mov    %edi,%eax
f010031e:	e8 fb fd ff ff       	call   f010011e <inb>

	crt_buf = (uint16_t*) cp;
f0100323:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100326:	89 0d 2c 65 11 f0    	mov    %ecx,0xf011652c
	pos |= inb(addr_6845 + 1);
f010032c:	0f b6 c0             	movzbl %al,%eax
f010032f:	09 c3                	or     %eax,%ebx
	crt_pos = pos;
f0100331:	66 89 1d 28 65 11 f0 	mov    %bx,0xf0116528
}
f0100338:	83 c4 04             	add    $0x4,%esp
f010033b:	5b                   	pop    %ebx
f010033c:	5e                   	pop    %esi
f010033d:	5f                   	pop    %edi
f010033e:	5d                   	pop    %ebp
f010033f:	c3                   	ret    
		*cp = was;
f0100340:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100347:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f010034e:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100351:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
f0100358:	eb 94                	jmp    f01002ee <cga_init+0x37>

f010035a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010035a:	55                   	push   %ebp
f010035b:	89 e5                	mov    %esp,%ebp
f010035d:	53                   	push   %ebx
f010035e:	83 ec 04             	sub    $0x4,%esp
f0100361:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100363:	ff d3                	call   *%ebx
f0100365:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100368:	74 2d                	je     f0100397 <cons_intr+0x3d>
		if (c == 0)
f010036a:	85 c0                	test   %eax,%eax
f010036c:	74 f5                	je     f0100363 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f010036e:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100374:	8d 51 01             	lea    0x1(%ecx),%edx
f0100377:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f010037d:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100383:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100389:	75 d8                	jne    f0100363 <cons_intr+0x9>
			cons.wpos = 0;
f010038b:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f0100392:	00 00 00 
f0100395:	eb cc                	jmp    f0100363 <cons_intr+0x9>
	}
}
f0100397:	83 c4 04             	add    $0x4,%esp
f010039a:	5b                   	pop    %ebx
f010039b:	5d                   	pop    %ebp
f010039c:	c3                   	ret    

f010039d <kbd_proc_data>:
{
f010039d:	55                   	push   %ebp
f010039e:	89 e5                	mov    %esp,%ebp
f01003a0:	53                   	push   %ebx
f01003a1:	83 ec 04             	sub    $0x4,%esp
	stat = inb(KBSTATP);
f01003a4:	b8 64 00 00 00       	mov    $0x64,%eax
f01003a9:	e8 70 fd ff ff       	call   f010011e <inb>
	if ((stat & KBS_DIB) == 0)
f01003ae:	a8 01                	test   $0x1,%al
f01003b0:	0f 84 06 01 00 00    	je     f01004bc <kbd_proc_data+0x11f>
	if (stat & KBS_TERR)
f01003b6:	a8 20                	test   $0x20,%al
f01003b8:	0f 85 05 01 00 00    	jne    f01004c3 <kbd_proc_data+0x126>
	data = inb(KBDATAP);
f01003be:	b8 60 00 00 00       	mov    $0x60,%eax
f01003c3:	e8 56 fd ff ff       	call   f010011e <inb>
	if (data == 0xE0) {
f01003c8:	3c e0                	cmp    $0xe0,%al
f01003ca:	0f 84 93 00 00 00    	je     f0100463 <kbd_proc_data+0xc6>
	} else if (data & 0x80) {
f01003d0:	84 c0                	test   %al,%al
f01003d2:	0f 88 9e 00 00 00    	js     f0100476 <kbd_proc_data+0xd9>
	} else if (shift & E0ESC) {
f01003d8:	8b 15 00 63 11 f0    	mov    0xf0116300,%edx
f01003de:	f6 c2 40             	test   $0x40,%dl
f01003e1:	74 0c                	je     f01003ef <kbd_proc_data+0x52>
		data |= 0x80;
f01003e3:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f01003e6:	83 e2 bf             	and    $0xffffffbf,%edx
f01003e9:	89 15 00 63 11 f0    	mov    %edx,0xf0116300
	shift |= shiftcode[data];
f01003ef:	0f b6 c0             	movzbl %al,%eax
f01003f2:	0f b6 90 c0 2d 10 f0 	movzbl -0xfefd240(%eax),%edx
f01003f9:	0b 15 00 63 11 f0    	or     0xf0116300,%edx
	shift ^= togglecode[data];
f01003ff:	0f b6 88 c0 2c 10 f0 	movzbl -0xfefd340(%eax),%ecx
f0100406:	31 ca                	xor    %ecx,%edx
f0100408:	89 15 00 63 11 f0    	mov    %edx,0xf0116300
	c = charcode[shift & (CTL | SHIFT)][data];
f010040e:	89 d1                	mov    %edx,%ecx
f0100410:	83 e1 03             	and    $0x3,%ecx
f0100413:	8b 0c 8d a0 2c 10 f0 	mov    -0xfefd360(,%ecx,4),%ecx
f010041a:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010041e:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100421:	f6 c2 08             	test   $0x8,%dl
f0100424:	74 0d                	je     f0100433 <kbd_proc_data+0x96>
		if ('a' <= c && c <= 'z')
f0100426:	89 d8                	mov    %ebx,%eax
f0100428:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010042b:	83 f9 19             	cmp    $0x19,%ecx
f010042e:	77 7b                	ja     f01004ab <kbd_proc_data+0x10e>
			c += 'A' - 'a';
f0100430:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100433:	f7 d2                	not    %edx
f0100435:	f6 c2 06             	test   $0x6,%dl
f0100438:	75 35                	jne    f010046f <kbd_proc_data+0xd2>
f010043a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100440:	75 2d                	jne    f010046f <kbd_proc_data+0xd2>
		cprintf("Rebooting!\n");
f0100442:	83 ec 0c             	sub    $0xc,%esp
f0100445:	68 5c 2c 10 f0       	push   $0xf0102c5c
f010044a:	e8 d5 18 00 00       	call   f0101d24 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f010044f:	ba 03 00 00 00       	mov    $0x3,%edx
f0100454:	b8 92 00 00 00       	mov    $0x92,%eax
f0100459:	e8 c8 fc ff ff       	call   f0100126 <outb>
f010045e:	83 c4 10             	add    $0x10,%esp
f0100461:	eb 0c                	jmp    f010046f <kbd_proc_data+0xd2>
		shift |= E0ESC;
f0100463:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f010046a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010046f:	89 d8                	mov    %ebx,%eax
f0100471:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100474:	c9                   	leave  
f0100475:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100476:	8b 15 00 63 11 f0    	mov    0xf0116300,%edx
f010047c:	89 d3                	mov    %edx,%ebx
f010047e:	83 e3 40             	and    $0x40,%ebx
f0100481:	89 c1                	mov    %eax,%ecx
f0100483:	83 e1 7f             	and    $0x7f,%ecx
f0100486:	85 db                	test   %ebx,%ebx
f0100488:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f010048b:	0f b6 c0             	movzbl %al,%eax
f010048e:	0f b6 80 c0 2d 10 f0 	movzbl -0xfefd240(%eax),%eax
f0100495:	83 c8 40             	or     $0x40,%eax
f0100498:	0f b6 c0             	movzbl %al,%eax
f010049b:	f7 d0                	not    %eax
f010049d:	21 d0                	and    %edx,%eax
f010049f:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f01004a4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01004a9:	eb c4                	jmp    f010046f <kbd_proc_data+0xd2>
		else if ('A' <= c && c <= 'Z')
f01004ab:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01004ae:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004b1:	83 f8 1a             	cmp    $0x1a,%eax
f01004b4:	0f 42 d9             	cmovb  %ecx,%ebx
f01004b7:	e9 77 ff ff ff       	jmp    f0100433 <kbd_proc_data+0x96>
		return -1;
f01004bc:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004c1:	eb ac                	jmp    f010046f <kbd_proc_data+0xd2>
		return -1;
f01004c3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004c8:	eb a5                	jmp    f010046f <kbd_proc_data+0xd2>

f01004ca <cga_putc>:
{
f01004ca:	55                   	push   %ebp
f01004cb:	89 e5                	mov    %esp,%ebp
f01004cd:	57                   	push   %edi
f01004ce:	56                   	push   %esi
f01004cf:	53                   	push   %ebx
f01004d0:	83 ec 0c             	sub    $0xc,%esp
	if (!(c & ~0xFF))
f01004d3:	89 c1                	mov    %eax,%ecx
f01004d5:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004db:	89 c2                	mov    %eax,%edx
f01004dd:	80 ce 07             	or     $0x7,%dh
f01004e0:	85 c9                	test   %ecx,%ecx
f01004e2:	0f 44 c2             	cmove  %edx,%eax
	switch (c & 0xff) {
f01004e5:	0f b6 d0             	movzbl %al,%edx
f01004e8:	83 fa 09             	cmp    $0x9,%edx
f01004eb:	0f 84 c9 00 00 00    	je     f01005ba <cga_putc+0xf0>
f01004f1:	83 fa 09             	cmp    $0x9,%edx
f01004f4:	0f 8e 81 00 00 00    	jle    f010057b <cga_putc+0xb1>
f01004fa:	83 fa 0a             	cmp    $0xa,%edx
f01004fd:	0f 84 aa 00 00 00    	je     f01005ad <cga_putc+0xe3>
f0100503:	83 fa 0d             	cmp    $0xd,%edx
f0100506:	0f 85 e5 00 00 00    	jne    f01005f1 <cga_putc+0x127>
		crt_pos -= (crt_pos % CRT_COLS);
f010050c:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100513:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100519:	c1 e8 16             	shr    $0x16,%eax
f010051c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010051f:	c1 e0 04             	shl    $0x4,%eax
f0100522:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
	if (crt_pos >= CRT_SIZE) {
f0100528:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f010052f:	cf 07 
f0100531:	0f 87 dd 00 00 00    	ja     f0100614 <cga_putc+0x14a>
	outb(addr_6845, 14);
f0100537:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010053d:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100542:	89 f8                	mov    %edi,%eax
f0100544:	e8 dd fb ff ff       	call   f0100126 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100549:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f0100550:	8d 77 01             	lea    0x1(%edi),%esi
f0100553:	0f b6 d7             	movzbl %bh,%edx
f0100556:	89 f0                	mov    %esi,%eax
f0100558:	e8 c9 fb ff ff       	call   f0100126 <outb>
	outb(addr_6845, 15);
f010055d:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100562:	89 f8                	mov    %edi,%eax
f0100564:	e8 bd fb ff ff       	call   f0100126 <outb>
	outb(addr_6845 + 1, crt_pos);
f0100569:	0f b6 d3             	movzbl %bl,%edx
f010056c:	89 f0                	mov    %esi,%eax
f010056e:	e8 b3 fb ff ff       	call   f0100126 <outb>
}
f0100573:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100576:	5b                   	pop    %ebx
f0100577:	5e                   	pop    %esi
f0100578:	5f                   	pop    %edi
f0100579:	5d                   	pop    %ebp
f010057a:	c3                   	ret    
	switch (c & 0xff) {
f010057b:	83 fa 08             	cmp    $0x8,%edx
f010057e:	75 71                	jne    f01005f1 <cga_putc+0x127>
		if (crt_pos > 0) {
f0100580:	0f b7 15 28 65 11 f0 	movzwl 0xf0116528,%edx
f0100587:	66 85 d2             	test   %dx,%dx
f010058a:	74 ab                	je     f0100537 <cga_putc+0x6d>
			crt_pos--;
f010058c:	83 ea 01             	sub    $0x1,%edx
f010058f:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100596:	0f b7 d2             	movzwl %dx,%edx
f0100599:	b0 00                	mov    $0x0,%al
f010059b:	83 c8 20             	or     $0x20,%eax
f010059e:	8b 0d 2c 65 11 f0    	mov    0xf011652c,%ecx
f01005a4:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01005a8:	e9 7b ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		crt_pos += CRT_COLS;
f01005ad:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f01005b4:	50 
f01005b5:	e9 52 ff ff ff       	jmp    f010050c <cga_putc+0x42>
		cons_putc(' ');
f01005ba:	b8 20 00 00 00       	mov    $0x20,%eax
f01005bf:	e8 98 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005c4:	b8 20 00 00 00       	mov    $0x20,%eax
f01005c9:	e8 8e 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005ce:	b8 20 00 00 00       	mov    $0x20,%eax
f01005d3:	e8 84 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005d8:	b8 20 00 00 00       	mov    $0x20,%eax
f01005dd:	e8 7a 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01005e7:	e8 70 00 00 00       	call   f010065c <cons_putc>
		break;
f01005ec:	e9 37 ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		crt_buf[crt_pos++] = c;		/* write the character */
f01005f1:	0f b7 15 28 65 11 f0 	movzwl 0xf0116528,%edx
f01005f8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005fb:	66 89 0d 28 65 11 f0 	mov    %cx,0xf0116528
f0100602:	0f b7 d2             	movzwl %dx,%edx
f0100605:	8b 0d 2c 65 11 f0    	mov    0xf011652c,%ecx
f010060b:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
f010060f:	e9 14 ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100614:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f0100619:	83 ec 04             	sub    $0x4,%esp
f010061c:	68 00 0f 00 00       	push   $0xf00
f0100621:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100627:	52                   	push   %edx
f0100628:	50                   	push   %eax
f0100629:	e8 e0 21 00 00       	call   f010280e <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010062e:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f0100634:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010063a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100640:	83 c4 10             	add    $0x10,%esp
f0100643:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100648:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010064b:	39 d0                	cmp    %edx,%eax
f010064d:	75 f4                	jne    f0100643 <cga_putc+0x179>
		crt_pos -= CRT_COLS;
f010064f:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100656:	50 
f0100657:	e9 db fe ff ff       	jmp    f0100537 <cga_putc+0x6d>

f010065c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
f010065f:	53                   	push   %ebx
f0100660:	83 ec 04             	sub    $0x4,%esp
f0100663:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100665:	e8 1c fb ff ff       	call   f0100186 <serial_putc>
	lpt_putc(c);
f010066a:	89 d8                	mov    %ebx,%eax
f010066c:	e8 e9 fb ff ff       	call   f010025a <lpt_putc>
	cga_putc(c);
f0100671:	89 d8                	mov    %ebx,%eax
f0100673:	e8 52 fe ff ff       	call   f01004ca <cga_putc>
}
f0100678:	83 c4 04             	add    $0x4,%esp
f010067b:	5b                   	pop    %ebx
f010067c:	5d                   	pop    %ebp
f010067d:	c3                   	ret    

f010067e <serial_intr>:
	if (serial_exists)
f010067e:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100685:	75 02                	jne    f0100689 <serial_intr+0xb>
f0100687:	f3 c3                	repz ret 
{
f0100689:	55                   	push   %ebp
f010068a:	89 e5                	mov    %esp,%ebp
f010068c:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010068f:	b8 5f 01 10 f0       	mov    $0xf010015f,%eax
f0100694:	e8 c1 fc ff ff       	call   f010035a <cons_intr>
}
f0100699:	c9                   	leave  
f010069a:	c3                   	ret    

f010069b <kbd_intr>:
{
f010069b:	55                   	push   %ebp
f010069c:	89 e5                	mov    %esp,%ebp
f010069e:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006a1:	b8 9d 03 10 f0       	mov    $0xf010039d,%eax
f01006a6:	e8 af fc ff ff       	call   f010035a <cons_intr>
}
f01006ab:	c9                   	leave  
f01006ac:	c3                   	ret    

f01006ad <cons_getc>:
{
f01006ad:	55                   	push   %ebp
f01006ae:	89 e5                	mov    %esp,%ebp
f01006b0:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f01006b3:	e8 c6 ff ff ff       	call   f010067e <serial_intr>
	kbd_intr();
f01006b8:	e8 de ff ff ff       	call   f010069b <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01006bd:	8b 15 20 65 11 f0    	mov    0xf0116520,%edx
	return 0;
f01006c3:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01006c8:	3b 15 24 65 11 f0    	cmp    0xf0116524,%edx
f01006ce:	74 18                	je     f01006e8 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01006d0:	8d 4a 01             	lea    0x1(%edx),%ecx
f01006d3:	89 0d 20 65 11 f0    	mov    %ecx,0xf0116520
f01006d9:	0f b6 82 20 63 11 f0 	movzbl -0xfee9ce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01006e0:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01006e6:	74 02                	je     f01006ea <cons_getc+0x3d>
}
f01006e8:	c9                   	leave  
f01006e9:	c3                   	ret    
			cons.rpos = 0;
f01006ea:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01006f1:	00 00 00 
f01006f4:	eb f2                	jmp    f01006e8 <cons_getc+0x3b>

f01006f6 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01006f6:	55                   	push   %ebp
f01006f7:	89 e5                	mov    %esp,%ebp
f01006f9:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006fc:	e8 b6 fb ff ff       	call   f01002b7 <cga_init>
	kbd_init();
	serial_init();
f0100701:	e8 bf fa ff ff       	call   f01001c5 <serial_init>

	if (!serial_exists)
f0100706:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f010070d:	74 02                	je     f0100711 <cons_init+0x1b>
		cprintf("Serial port does not exist!\n");
}
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    
		cprintf("Serial port does not exist!\n");
f0100711:	83 ec 0c             	sub    $0xc,%esp
f0100714:	68 68 2c 10 f0       	push   $0xf0102c68
f0100719:	e8 06 16 00 00       	call   f0101d24 <cprintf>
f010071e:	83 c4 10             	add    $0x10,%esp
}
f0100721:	eb ec                	jmp    f010070f <cons_init+0x19>

f0100723 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100723:	55                   	push   %ebp
f0100724:	89 e5                	mov    %esp,%ebp
f0100726:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100729:	8b 45 08             	mov    0x8(%ebp),%eax
f010072c:	e8 2b ff ff ff       	call   f010065c <cons_putc>
}
f0100731:	c9                   	leave  
f0100732:	c3                   	ret    

f0100733 <getchar>:

int
getchar(void)
{
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100739:	e8 6f ff ff ff       	call   f01006ad <cons_getc>
f010073e:	85 c0                	test   %eax,%eax
f0100740:	74 f7                	je     f0100739 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100742:	c9                   	leave  
f0100743:	c3                   	ret    

f0100744 <iscons>:

int
iscons(int fdnum)
{
f0100744:	55                   	push   %ebp
f0100745:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100747:	b8 01 00 00 00       	mov    $0x1,%eax
f010074c:	5d                   	pop    %ebp
f010074d:	c3                   	ret    

f010074e <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074e:	55                   	push   %ebp
f010074f:	89 e5                	mov    %esp,%ebp
f0100751:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100754:	68 c0 2e 10 f0       	push   $0xf0102ec0
f0100759:	68 de 2e 10 f0       	push   $0xf0102ede
f010075e:	68 e3 2e 10 f0       	push   $0xf0102ee3
f0100763:	e8 bc 15 00 00       	call   f0101d24 <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	68 4c 2f 10 f0       	push   $0xf0102f4c
f0100770:	68 ec 2e 10 f0       	push   $0xf0102eec
f0100775:	68 e3 2e 10 f0       	push   $0xf0102ee3
f010077a:	e8 a5 15 00 00       	call   f0101d24 <cprintf>
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	c9                   	leave  
f0100785:	c3                   	ret    

f0100786 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
f0100789:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010078c:	68 f5 2e 10 f0       	push   $0xf0102ef5
f0100791:	e8 8e 15 00 00       	call   f0101d24 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100796:	83 c4 08             	add    $0x8,%esp
f0100799:	68 0c 00 10 00       	push   $0x10000c
f010079e:	68 74 2f 10 f0       	push   $0xf0102f74
f01007a3:	e8 7c 15 00 00       	call   f0101d24 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	68 0c 00 10 00       	push   $0x10000c
f01007b0:	68 0c 00 10 f0       	push   $0xf010000c
f01007b5:	68 9c 2f 10 f0       	push   $0xf0102f9c
f01007ba:	e8 65 15 00 00       	call   f0101d24 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 f9 2b 10 00       	push   $0x102bf9
f01007c7:	68 f9 2b 10 f0       	push   $0xf0102bf9
f01007cc:	68 c0 2f 10 f0       	push   $0xf0102fc0
f01007d1:	e8 4e 15 00 00       	call   f0101d24 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 00 63 11 00       	push   $0x116300
f01007de:	68 00 63 11 f0       	push   $0xf0116300
f01007e3:	68 e4 2f 10 f0       	push   $0xf0102fe4
f01007e8:	e8 37 15 00 00       	call   f0101d24 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ed:	83 c4 0c             	add    $0xc,%esp
f01007f0:	68 50 69 11 00       	push   $0x116950
f01007f5:	68 50 69 11 f0       	push   $0xf0116950
f01007fa:	68 08 30 10 f0       	push   $0xf0103008
f01007ff:	e8 20 15 00 00       	call   f0101d24 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100804:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100807:	b8 4f 6d 11 f0       	mov    $0xf0116d4f,%eax
f010080c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100811:	c1 f8 0a             	sar    $0xa,%eax
f0100814:	50                   	push   %eax
f0100815:	68 2c 30 10 f0       	push   $0xf010302c
f010081a:	e8 05 15 00 00       	call   f0101d24 <cprintf>
	return 0;
}
f010081f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100824:	c9                   	leave  
f0100825:	c3                   	ret    

f0100826 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100826:	55                   	push   %ebp
f0100827:	89 e5                	mov    %esp,%ebp
f0100829:	57                   	push   %edi
f010082a:	56                   	push   %esi
f010082b:	53                   	push   %ebx
f010082c:	83 ec 5c             	sub    $0x5c,%esp
f010082f:	89 c3                	mov    %eax,%ebx
f0100831:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100834:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010083b:	be 00 00 00 00       	mov    $0x0,%esi
f0100840:	eb 5d                	jmp    f010089f <runcmd+0x79>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100842:	83 ec 08             	sub    $0x8,%esp
f0100845:	0f be c0             	movsbl %al,%eax
f0100848:	50                   	push   %eax
f0100849:	68 0e 2f 10 f0       	push   $0xf0102f0e
f010084e:	e8 32 1f 00 00       	call   f0102785 <strchr>
f0100853:	83 c4 10             	add    $0x10,%esp
f0100856:	85 c0                	test   %eax,%eax
f0100858:	74 0a                	je     f0100864 <runcmd+0x3e>
			*buf++ = 0;
f010085a:	c6 03 00             	movb   $0x0,(%ebx)
f010085d:	89 f7                	mov    %esi,%edi
f010085f:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100862:	eb 39                	jmp    f010089d <runcmd+0x77>
		if (*buf == 0)
f0100864:	0f b6 03             	movzbl (%ebx),%eax
f0100867:	84 c0                	test   %al,%al
f0100869:	74 3b                	je     f01008a6 <runcmd+0x80>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010086b:	83 fe 0f             	cmp    $0xf,%esi
f010086e:	0f 84 86 00 00 00    	je     f01008fa <runcmd+0xd4>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
f0100874:	8d 7e 01             	lea    0x1(%esi),%edi
f0100877:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f010087b:	83 ec 08             	sub    $0x8,%esp
f010087e:	0f be c0             	movsbl %al,%eax
f0100881:	50                   	push   %eax
f0100882:	68 0e 2f 10 f0       	push   $0xf0102f0e
f0100887:	e8 f9 1e 00 00       	call   f0102785 <strchr>
f010088c:	83 c4 10             	add    $0x10,%esp
f010088f:	85 c0                	test   %eax,%eax
f0100891:	75 0a                	jne    f010089d <runcmd+0x77>
			buf++;
f0100893:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100896:	0f b6 03             	movzbl (%ebx),%eax
f0100899:	84 c0                	test   %al,%al
f010089b:	75 de                	jne    f010087b <runcmd+0x55>
			*buf++ = 0;
f010089d:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f010089f:	0f b6 03             	movzbl (%ebx),%eax
f01008a2:	84 c0                	test   %al,%al
f01008a4:	75 9c                	jne    f0100842 <runcmd+0x1c>
	}
	argv[argc] = 0;
f01008a6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008ad:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ae:	85 f6                	test   %esi,%esi
f01008b0:	74 5f                	je     f0100911 <runcmd+0xeb>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b2:	83 ec 08             	sub    $0x8,%esp
f01008b5:	68 de 2e 10 f0       	push   $0xf0102ede
f01008ba:	ff 75 a8             	pushl  -0x58(%ebp)
f01008bd:	e8 65 1e 00 00       	call   f0102727 <strcmp>
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 57                	je     f0100920 <runcmd+0xfa>
f01008c9:	83 ec 08             	sub    $0x8,%esp
f01008cc:	68 ec 2e 10 f0       	push   $0xf0102eec
f01008d1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d4:	e8 4e 1e 00 00       	call   f0102727 <strcmp>
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	74 3b                	je     f010091b <runcmd+0xf5>
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e0:	83 ec 08             	sub    $0x8,%esp
f01008e3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e6:	68 30 2f 10 f0       	push   $0xf0102f30
f01008eb:	e8 34 14 00 00       	call   f0101d24 <cprintf>
	return 0;
f01008f0:	83 c4 10             	add    $0x10,%esp
f01008f3:	be 00 00 00 00       	mov    $0x0,%esi
f01008f8:	eb 17                	jmp    f0100911 <runcmd+0xeb>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008fa:	83 ec 08             	sub    $0x8,%esp
f01008fd:	6a 10                	push   $0x10
f01008ff:	68 13 2f 10 f0       	push   $0xf0102f13
f0100904:	e8 1b 14 00 00       	call   f0101d24 <cprintf>
			return 0;
f0100909:	83 c4 10             	add    $0x10,%esp
f010090c:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100911:	89 f0                	mov    %esi,%eax
f0100913:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100916:	5b                   	pop    %ebx
f0100917:	5e                   	pop    %esi
f0100918:	5f                   	pop    %edi
f0100919:	5d                   	pop    %ebp
f010091a:	c3                   	ret    
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010091b:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100920:	83 ec 04             	sub    $0x4,%esp
f0100923:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100926:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100929:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010092c:	52                   	push   %edx
f010092d:	56                   	push   %esi
f010092e:	ff 14 85 ac 30 10 f0 	call   *-0xfefcf54(,%eax,4)
f0100935:	89 c6                	mov    %eax,%esi
f0100937:	83 c4 10             	add    $0x10,%esp
f010093a:	eb d5                	jmp    f0100911 <runcmd+0xeb>

f010093c <mon_backtrace>:
{
f010093c:	55                   	push   %ebp
f010093d:	89 e5                	mov    %esp,%ebp
}
f010093f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100944:	5d                   	pop    %ebp
f0100945:	c3                   	ret    

f0100946 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100946:	55                   	push   %ebp
f0100947:	89 e5                	mov    %esp,%ebp
f0100949:	53                   	push   %ebx
f010094a:	83 ec 10             	sub    $0x10,%esp
f010094d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100950:	68 58 30 10 f0       	push   $0xf0103058
f0100955:	e8 ca 13 00 00       	call   f0101d24 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010095a:	c7 04 24 7c 30 10 f0 	movl   $0xf010307c,(%esp)
f0100961:	e8 be 13 00 00       	call   f0101d24 <cprintf>
f0100966:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100969:	83 ec 0c             	sub    $0xc,%esp
f010096c:	68 46 2f 10 f0       	push   $0xf0102f46
f0100971:	e8 f2 1b 00 00       	call   f0102568 <readline>
		if (buf != NULL)
f0100976:	83 c4 10             	add    $0x10,%esp
f0100979:	85 c0                	test   %eax,%eax
f010097b:	74 ec                	je     f0100969 <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f010097d:	89 da                	mov    %ebx,%edx
f010097f:	e8 a2 fe ff ff       	call   f0100826 <runcmd>
f0100984:	85 c0                	test   %eax,%eax
f0100986:	79 e1                	jns    f0100969 <monitor+0x23>
				break;
	}
}
f0100988:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010098b:	c9                   	leave  
f010098c:	c3                   	ret    

f010098d <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f010098d:	55                   	push   %ebp
f010098e:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100990:	0f 01 38             	invlpg (%eax)
}
f0100993:	5d                   	pop    %ebp
f0100994:	c3                   	ret    

f0100995 <page2pa>:

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100995:	55                   	push   %ebp
f0100996:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100998:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
f010099e:	c1 f8 03             	sar    $0x3,%eax
f01009a1:	c1 e0 0c             	shl    $0xc,%eax
}
f01009a4:	5d                   	pop    %ebp
f01009a5:	c3                   	ret    

f01009a6 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009a6:	55                   	push   %ebp
f01009a7:	89 e5                	mov    %esp,%ebp
f01009a9:	56                   	push   %esi
f01009aa:	53                   	push   %ebx
f01009ab:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009ad:	83 ec 0c             	sub    $0xc,%esp
f01009b0:	50                   	push   %eax
f01009b1:	e8 ea 12 00 00       	call   f0101ca0 <mc146818_read>
f01009b6:	89 c3                	mov    %eax,%ebx
f01009b8:	83 c6 01             	add    $0x1,%esi
f01009bb:	89 34 24             	mov    %esi,(%esp)
f01009be:	e8 dd 12 00 00       	call   f0101ca0 <mc146818_read>
f01009c3:	c1 e0 08             	shl    $0x8,%eax
f01009c6:	09 d8                	or     %ebx,%eax
}
f01009c8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01009cb:	5b                   	pop    %ebx
f01009cc:	5e                   	pop    %esi
f01009cd:	5d                   	pop    %ebp
f01009ce:	c3                   	ret    

f01009cf <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f01009cf:	55                   	push   %ebp
f01009d0:	89 e5                	mov    %esp,%ebp
f01009d2:	56                   	push   %esi
f01009d3:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01009d4:	b8 15 00 00 00       	mov    $0x15,%eax
f01009d9:	e8 c8 ff ff ff       	call   f01009a6 <nvram_read>
f01009de:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01009e0:	b8 17 00 00 00       	mov    $0x17,%eax
f01009e5:	e8 bc ff ff ff       	call   f01009a6 <nvram_read>
f01009ea:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01009ec:	b8 34 00 00 00       	mov    $0x34,%eax
f01009f1:	e8 b0 ff ff ff       	call   f01009a6 <nvram_read>
f01009f6:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01009f9:	85 c0                	test   %eax,%eax
f01009fb:	75 0e                	jne    f0100a0b <i386_detect_memory+0x3c>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;
f01009fd:	89 d8                	mov    %ebx,%eax
	else if (extmem)
f01009ff:	85 f6                	test   %esi,%esi
f0100a01:	74 0d                	je     f0100a10 <i386_detect_memory+0x41>
		totalmem = 1 * 1024 + extmem;
f0100a03:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100a09:	eb 05                	jmp    f0100a10 <i386_detect_memory+0x41>
		totalmem = 16 * 1024 + ext16mem;
f0100a0b:	05 00 40 00 00       	add    $0x4000,%eax

	npages = totalmem / (PGSIZE / 1024);
f0100a10:	89 c2                	mov    %eax,%edx
f0100a12:	c1 ea 02             	shr    $0x2,%edx
f0100a15:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a1b:	89 c2                	mov    %eax,%edx
f0100a1d:	29 da                	sub    %ebx,%edx
f0100a1f:	52                   	push   %edx
f0100a20:	53                   	push   %ebx
f0100a21:	50                   	push   %eax
f0100a22:	68 bc 30 10 f0       	push   $0xf01030bc
f0100a27:	e8 f8 12 00 00       	call   f0101d24 <cprintf>
	        totalmem,
	        basemem,
	        totalmem - basemem);
}
f0100a2c:	83 c4 10             	add    $0x10,%esp
f0100a2f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a32:	5b                   	pop    %ebx
f0100a33:	5e                   	pop    %esi
f0100a34:	5d                   	pop    %ebp
f0100a35:	c3                   	ret    

f0100a36 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a36:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f0100a3d:	74 28                	je     f0100a67 <boot_alloc+0x31>
	// LAB 2: Your code here.

	// Están mapeados menos de 4 MB
	// por lo que no podemos pedir
	// más memoria que eso
	if ((uintptr_t)ROUNDUP(nextfree + n, PGSIZE) > (KERNBASE + (4 << 20))) {
f0100a3f:	8b 0d 38 65 11 f0    	mov    0xf0116538,%ecx
f0100a45:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a4c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a52:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f0100a58:	77 20                	ja     f0100a7a <boot_alloc+0x44>
		panic("boot_alloc: out of memory");
	}

	result = nextfree;

	if (n > 0) {
f0100a5a:	85 c0                	test   %eax,%eax
f0100a5c:	74 06                	je     f0100a64 <boot_alloc+0x2e>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);	
f0100a5e:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	}

	return result;
}
f0100a64:	89 c8                	mov    %ecx,%eax
f0100a66:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a67:	ba 4f 79 11 f0       	mov    $0xf011794f,%edx
f0100a6c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a72:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
f0100a78:	eb c5                	jmp    f0100a3f <boot_alloc+0x9>
{
f0100a7a:	55                   	push   %ebp
f0100a7b:	89 e5                	mov    %esp,%ebp
f0100a7d:	83 ec 0c             	sub    $0xc,%esp
		panic("boot_alloc: out of memory");
f0100a80:	68 00 37 10 f0       	push   $0xf0103700
f0100a85:	6a 71                	push   $0x71
f0100a87:	68 1a 37 10 f0       	push   $0xf010371a
f0100a8c:	e8 fa f5 ff ff       	call   f010008b <_panic>

f0100a91 <_kaddr>:
{
f0100a91:	55                   	push   %ebp
f0100a92:	89 e5                	mov    %esp,%ebp
f0100a94:	53                   	push   %ebx
f0100a95:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100a98:	89 cb                	mov    %ecx,%ebx
f0100a9a:	c1 eb 0c             	shr    $0xc,%ebx
f0100a9d:	3b 1d 44 69 11 f0    	cmp    0xf0116944,%ebx
f0100aa3:	73 0b                	jae    f0100ab0 <_kaddr+0x1f>
	return (void *)(pa + KERNBASE);
f0100aa5:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100aab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100aae:	c9                   	leave  
f0100aaf:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab0:	51                   	push   %ecx
f0100ab1:	68 f8 30 10 f0       	push   $0xf01030f8
f0100ab6:	52                   	push   %edx
f0100ab7:	50                   	push   %eax
f0100ab8:	e8 ce f5 ff ff       	call   f010008b <_panic>

f0100abd <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100abd:	55                   	push   %ebp
f0100abe:	89 e5                	mov    %esp,%ebp
f0100ac0:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100ac3:	e8 cd fe ff ff       	call   f0100995 <page2pa>
f0100ac8:	89 c1                	mov    %eax,%ecx
f0100aca:	ba 52 00 00 00       	mov    $0x52,%edx
f0100acf:	b8 26 37 10 f0       	mov    $0xf0103726,%eax
f0100ad4:	e8 b8 ff ff ff       	call   f0100a91 <_kaddr>
}
f0100ad9:	c9                   	leave  
f0100ada:	c3                   	ret    

f0100adb <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100adb:	89 d1                	mov    %edx,%ecx
f0100add:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100ae0:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100ae3:	f6 c1 01             	test   $0x1,%cl
f0100ae6:	74 50                	je     f0100b38 <check_va2pa+0x5d>
		return ~0;
	if (*pgdir & PTE_PS)
f0100ae8:	f6 c1 80             	test   $0x80,%cl
f0100aeb:	74 10                	je     f0100afd <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100aed:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100af3:	89 d0                	mov    %edx,%eax
f0100af5:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100afa:	09 c8                	or     %ecx,%eax
f0100afc:	c3                   	ret    
{
f0100afd:	55                   	push   %ebp
f0100afe:	89 e5                	mov    %esp,%ebp
f0100b00:	53                   	push   %ebx
f0100b01:	83 ec 04             	sub    $0x4,%esp
f0100b04:	89 d3                	mov    %edx,%ebx
	p = (pte_t *) KADDR(PTE_ADDR(*pgdir));
f0100b06:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b0c:	ba 1f 03 00 00       	mov    $0x31f,%edx
f0100b11:	b8 1a 37 10 f0       	mov    $0xf010371a,%eax
f0100b16:	e8 76 ff ff ff       	call   f0100a91 <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100b1b:	c1 eb 0c             	shr    $0xc,%ebx
f0100b1e:	89 da                	mov    %ebx,%edx
f0100b20:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b26:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100b29:	a8 01                	test   $0x1,%al
f0100b2b:	74 11                	je     f0100b3e <check_va2pa+0x63>
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b2d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f0100b32:	83 c4 04             	add    $0x4,%esp
f0100b35:	5b                   	pop    %ebx
f0100b36:	5d                   	pop    %ebp
f0100b37:	c3                   	ret    
		return ~0;
f0100b38:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100b3d:	c3                   	ret    
		return ~0;
f0100b3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b43:	eb ed                	jmp    f0100b32 <check_va2pa+0x57>

f0100b45 <_paddr>:
	if ((uint32_t)kva < KERNBASE)
f0100b45:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100b4b:	76 07                	jbe    f0100b54 <_paddr+0xf>
	return (physaddr_t)kva - KERNBASE;
f0100b4d:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100b53:	c3                   	ret    
{
f0100b54:	55                   	push   %ebp
f0100b55:	89 e5                	mov    %esp,%ebp
f0100b57:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b5a:	51                   	push   %ecx
f0100b5b:	68 1c 31 10 f0       	push   $0xf010311c
f0100b60:	52                   	push   %edx
f0100b61:	50                   	push   %eax
f0100b62:	e8 24 f5 ff ff       	call   f010008b <_panic>

f0100b67 <check_page_free_list>:
{
f0100b67:	55                   	push   %ebp
f0100b68:	89 e5                	mov    %esp,%ebp
f0100b6a:	57                   	push   %edi
f0100b6b:	56                   	push   %esi
f0100b6c:	53                   	push   %ebx
f0100b6d:	83 ec 2c             	sub    $0x2c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b70:	84 c0                	test   %al,%al
f0100b72:	0f 85 0d 02 00 00    	jne    f0100d85 <check_page_free_list+0x21e>
	if (!page_free_list)
f0100b78:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0100b7f:	74 0a                	je     f0100b8b <check_page_free_list+0x24>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b81:	be 00 04 00 00       	mov    $0x400,%esi
f0100b86:	e9 54 02 00 00       	jmp    f0100ddf <check_page_free_list+0x278>
		panic("'page_free_list' is a null pointer!");
f0100b8b:	83 ec 04             	sub    $0x4,%esp
f0100b8e:	68 40 31 10 f0       	push   $0xf0103140
f0100b93:	68 55 02 00 00       	push   $0x255
f0100b98:	68 1a 37 10 f0       	push   $0xf010371a
f0100b9d:	e8 e9 f4 ff ff       	call   f010008b <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba2:	8b 1b                	mov    (%ebx),%ebx
f0100ba4:	85 db                	test   %ebx,%ebx
f0100ba6:	74 2d                	je     f0100bd5 <check_page_free_list+0x6e>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ba8:	89 d8                	mov    %ebx,%eax
f0100baa:	e8 e6 fd ff ff       	call   f0100995 <page2pa>
f0100baf:	c1 e8 16             	shr    $0x16,%eax
f0100bb2:	39 f0                	cmp    %esi,%eax
f0100bb4:	73 ec                	jae    f0100ba2 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100bb6:	89 d8                	mov    %ebx,%eax
f0100bb8:	e8 00 ff ff ff       	call   f0100abd <page2kva>
f0100bbd:	83 ec 04             	sub    $0x4,%esp
f0100bc0:	68 80 00 00 00       	push   $0x80
f0100bc5:	68 97 00 00 00       	push   $0x97
f0100bca:	50                   	push   %eax
f0100bcb:	e8 f2 1b 00 00       	call   f01027c2 <memset>
f0100bd0:	83 c4 10             	add    $0x10,%esp
f0100bd3:	eb cd                	jmp    f0100ba2 <check_page_free_list+0x3b>
	first_free_page = (char *) boot_alloc(0);
f0100bd5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bda:	e8 57 fe ff ff       	call   f0100a36 <boot_alloc>
f0100bdf:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be2:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
		assert(pp >= pages);
f0100be8:	8b 35 4c 69 11 f0    	mov    0xf011694c,%esi
		assert(pp < pages + npages);
f0100bee:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0100bf3:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100bf6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bf9:	89 75 d0             	mov    %esi,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bfc:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100c03:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c08:	e9 c1 00 00 00       	jmp    f0100cce <check_page_free_list+0x167>
		assert(pp >= pages);
f0100c0d:	68 34 37 10 f0       	push   $0xf0103734
f0100c12:	68 40 37 10 f0       	push   $0xf0103740
f0100c17:	68 6f 02 00 00       	push   $0x26f
f0100c1c:	68 1a 37 10 f0       	push   $0xf010371a
f0100c21:	e8 65 f4 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100c26:	68 55 37 10 f0       	push   $0xf0103755
f0100c2b:	68 40 37 10 f0       	push   $0xf0103740
f0100c30:	68 70 02 00 00       	push   $0x270
f0100c35:	68 1a 37 10 f0       	push   $0xf010371a
f0100c3a:	e8 4c f4 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c3f:	68 64 31 10 f0       	push   $0xf0103164
f0100c44:	68 40 37 10 f0       	push   $0xf0103740
f0100c49:	68 71 02 00 00       	push   $0x271
f0100c4e:	68 1a 37 10 f0       	push   $0xf010371a
f0100c53:	e8 33 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != 0);
f0100c58:	68 69 37 10 f0       	push   $0xf0103769
f0100c5d:	68 40 37 10 f0       	push   $0xf0103740
f0100c62:	68 74 02 00 00       	push   $0x274
f0100c67:	68 1a 37 10 f0       	push   $0xf010371a
f0100c6c:	e8 1a f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c71:	68 7a 37 10 f0       	push   $0xf010377a
f0100c76:	68 40 37 10 f0       	push   $0xf0103740
f0100c7b:	68 75 02 00 00       	push   $0x275
f0100c80:	68 1a 37 10 f0       	push   $0xf010371a
f0100c85:	e8 01 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c8a:	68 98 31 10 f0       	push   $0xf0103198
f0100c8f:	68 40 37 10 f0       	push   $0xf0103740
f0100c94:	68 76 02 00 00       	push   $0x276
f0100c99:	68 1a 37 10 f0       	push   $0xf010371a
f0100c9e:	e8 e8 f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ca3:	68 93 37 10 f0       	push   $0xf0103793
f0100ca8:	68 40 37 10 f0       	push   $0xf0103740
f0100cad:	68 77 02 00 00       	push   $0x277
f0100cb2:	68 1a 37 10 f0       	push   $0xf010371a
f0100cb7:	e8 cf f3 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM ||
f0100cbc:	89 d8                	mov    %ebx,%eax
f0100cbe:	e8 fa fd ff ff       	call   f0100abd <page2kva>
f0100cc3:	3b 45 c8             	cmp    -0x38(%ebp),%eax
f0100cc6:	72 60                	jb     f0100d28 <check_page_free_list+0x1c1>
			++nfree_extmem;
f0100cc8:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ccc:	8b 1b                	mov    (%ebx),%ebx
f0100cce:	85 db                	test   %ebx,%ebx
f0100cd0:	74 6f                	je     f0100d41 <check_page_free_list+0x1da>
		assert(pp >= pages);
f0100cd2:	39 de                	cmp    %ebx,%esi
f0100cd4:	0f 87 33 ff ff ff    	ja     f0100c0d <check_page_free_list+0xa6>
		assert(pp < pages + npages);
f0100cda:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0100cdd:	0f 86 43 ff ff ff    	jbe    f0100c26 <check_page_free_list+0xbf>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ce3:	89 d8                	mov    %ebx,%eax
f0100ce5:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100ce8:	a8 07                	test   $0x7,%al
f0100cea:	0f 85 4f ff ff ff    	jne    f0100c3f <check_page_free_list+0xd8>
		assert(page2pa(pp) != 0);
f0100cf0:	89 d8                	mov    %ebx,%eax
f0100cf2:	e8 9e fc ff ff       	call   f0100995 <page2pa>
f0100cf7:	85 c0                	test   %eax,%eax
f0100cf9:	0f 84 59 ff ff ff    	je     f0100c58 <check_page_free_list+0xf1>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cff:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d04:	0f 84 67 ff ff ff    	je     f0100c71 <check_page_free_list+0x10a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d0a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d0f:	0f 84 75 ff ff ff    	je     f0100c8a <check_page_free_list+0x123>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d15:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d1a:	74 87                	je     f0100ca3 <check_page_free_list+0x13c>
		assert(page2pa(pp) < EXTPHYSMEM ||
f0100d1c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d21:	77 99                	ja     f0100cbc <check_page_free_list+0x155>
			++nfree_basemem;
f0100d23:	83 c7 01             	add    $0x1,%edi
f0100d26:	eb a4                	jmp    f0100ccc <check_page_free_list+0x165>
		assert(page2pa(pp) < EXTPHYSMEM ||
f0100d28:	68 bc 31 10 f0       	push   $0xf01031bc
f0100d2d:	68 40 37 10 f0       	push   $0xf0103740
f0100d32:	68 79 02 00 00       	push   $0x279
f0100d37:	68 1a 37 10 f0       	push   $0xf010371a
f0100d3c:	e8 4a f3 ff ff       	call   f010008b <_panic>
	assert(nfree_basemem > 0);
f0100d41:	85 ff                	test   %edi,%edi
f0100d43:	7e 0e                	jle    f0100d53 <check_page_free_list+0x1ec>
	assert(nfree_extmem > 0);
f0100d45:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100d49:	7e 21                	jle    f0100d6c <check_page_free_list+0x205>
}
f0100d4b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d4e:	5b                   	pop    %ebx
f0100d4f:	5e                   	pop    %esi
f0100d50:	5f                   	pop    %edi
f0100d51:	5d                   	pop    %ebp
f0100d52:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100d53:	68 ad 37 10 f0       	push   $0xf01037ad
f0100d58:	68 40 37 10 f0       	push   $0xf0103740
f0100d5d:	68 81 02 00 00       	push   $0x281
f0100d62:	68 1a 37 10 f0       	push   $0xf010371a
f0100d67:	e8 1f f3 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100d6c:	68 bf 37 10 f0       	push   $0xf01037bf
f0100d71:	68 40 37 10 f0       	push   $0xf0103740
f0100d76:	68 82 02 00 00       	push   $0x282
f0100d7b:	68 1a 37 10 f0       	push   $0xf010371a
f0100d80:	e8 06 f3 ff ff       	call   f010008b <_panic>
	if (!page_free_list)
f0100d85:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100d8b:	85 db                	test   %ebx,%ebx
f0100d8d:	0f 84 f8 fd ff ff    	je     f0100b8b <check_page_free_list+0x24>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100d93:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100d96:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d99:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100d9c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d9f:	89 d8                	mov    %ebx,%eax
f0100da1:	e8 ef fb ff ff       	call   f0100995 <page2pa>
f0100da6:	c1 e8 16             	shr    $0x16,%eax
f0100da9:	85 c0                	test   %eax,%eax
f0100dab:	0f 95 c0             	setne  %al
f0100dae:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100db1:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100db5:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100db7:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dbb:	8b 1b                	mov    (%ebx),%ebx
f0100dbd:	85 db                	test   %ebx,%ebx
f0100dbf:	75 de                	jne    f0100d9f <check_page_free_list+0x238>
		*tp[1] = 0;
f0100dc1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dc4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100dca:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dcd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100dd2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dd5:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dda:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ddf:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100de5:	e9 ba fd ff ff       	jmp    f0100ba4 <check_page_free_list+0x3d>

f0100dea <page_init>:
{
f0100dea:	55                   	push   %ebp
f0100deb:	89 e5                	mov    %esp,%ebp
f0100ded:	56                   	push   %esi
f0100dee:	53                   	push   %ebx
	for (size_t i = 1; i < npages; i++) {
f0100def:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100df4:	eb 1e                	jmp    f0100e14 <page_init+0x2a>
		  pages[i].pp_link = page_free_list;
f0100df6:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0100dfb:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100e01:	89 14 d8             	mov    %edx,(%eax,%ebx,8)
		  page_free_list = &pages[i];
f0100e04:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
f0100e09:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100e0c:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	for (size_t i = 1; i < npages; i++) {
f0100e11:	83 c3 01             	add    $0x1,%ebx
f0100e14:	39 1d 44 69 11 f0    	cmp    %ebx,0xf0116944
f0100e1a:	76 2e                	jbe    f0100e4a <page_init+0x60>
		paddr = i * PGSIZE;
f0100e1c:	89 de                	mov    %ebx,%esi
f0100e1e:	c1 e6 0c             	shl    $0xc,%esi
		if (paddr >= PADDR(boot_alloc(0)) || paddr < IOPHYSMEM) { // Si no es una dirección prohibida
f0100e21:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e26:	e8 0b fc ff ff       	call   f0100a36 <boot_alloc>
f0100e2b:	89 c1                	mov    %eax,%ecx
f0100e2d:	ba 33 01 00 00       	mov    $0x133,%edx
f0100e32:	b8 1a 37 10 f0       	mov    $0xf010371a,%eax
f0100e37:	e8 09 fd ff ff       	call   f0100b45 <_paddr>
f0100e3c:	81 fe ff ff 09 00    	cmp    $0x9ffff,%esi
f0100e42:	76 b2                	jbe    f0100df6 <page_init+0xc>
f0100e44:	39 f0                	cmp    %esi,%eax
f0100e46:	76 ae                	jbe    f0100df6 <page_init+0xc>
f0100e48:	eb c7                	jmp    f0100e11 <page_init+0x27>
}
f0100e4a:	5b                   	pop    %ebx
f0100e4b:	5e                   	pop    %esi
f0100e4c:	5d                   	pop    %ebp
f0100e4d:	c3                   	ret    

f0100e4e <page_alloc>:
{
f0100e4e:	55                   	push   %ebp
f0100e4f:	89 e5                	mov    %esp,%ebp
f0100e51:	53                   	push   %ebx
f0100e52:	83 ec 04             	sub    $0x4,%esp
	if (page_free_list) {
f0100e55:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100e5b:	85 db                	test   %ebx,%ebx
f0100e5d:	74 13                	je     f0100e72 <page_alloc+0x24>
	  page_free_list = page->pp_link;
f0100e5f:	8b 03                	mov    (%ebx),%eax
f0100e61:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	  page->pp_link = NULL;
f0100e66:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	  if (alloc_flags & ALLOC_ZERO) {
f0100e6c:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e70:	75 07                	jne    f0100e79 <page_alloc+0x2b>
}
f0100e72:	89 d8                	mov    %ebx,%eax
f0100e74:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e77:	c9                   	leave  
f0100e78:	c3                   	ret    
			memset(page2kva(page), 0, PGSIZE);
f0100e79:	89 d8                	mov    %ebx,%eax
f0100e7b:	e8 3d fc ff ff       	call   f0100abd <page2kva>
f0100e80:	83 ec 04             	sub    $0x4,%esp
f0100e83:	68 00 10 00 00       	push   $0x1000
f0100e88:	6a 00                	push   $0x0
f0100e8a:	50                   	push   %eax
f0100e8b:	e8 32 19 00 00       	call   f01027c2 <memset>
f0100e90:	83 c4 10             	add    $0x10,%esp
f0100e93:	eb dd                	jmp    f0100e72 <page_alloc+0x24>

f0100e95 <page_free>:
{
f0100e95:	55                   	push   %ebp
f0100e96:	89 e5                	mov    %esp,%ebp
f0100e98:	83 ec 08             	sub    $0x8,%esp
f0100e9b:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_link) {
f0100e9e:	83 38 00             	cmpl   $0x0,(%eax)
f0100ea1:	75 16                	jne    f0100eb9 <page_free+0x24>
	if (pp->pp_ref) {
f0100ea3:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ea8:	75 26                	jne    f0100ed0 <page_free+0x3b>
	pp->pp_link = page_free_list;
f0100eaa:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0100eb0:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100eb2:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f0100eb7:	c9                   	leave  
f0100eb8:	c3                   	ret    
		panic("page_free: try to free page with pp_link set\n");
f0100eb9:	83 ec 04             	sub    $0x4,%esp
f0100ebc:	68 04 32 10 f0       	push   $0xf0103204
f0100ec1:	68 67 01 00 00       	push   $0x167
f0100ec6:	68 1a 37 10 f0       	push   $0xf010371a
f0100ecb:	e8 bb f1 ff ff       	call   f010008b <_panic>
		panic("page_free: try to free page with pp_ref's\n");
f0100ed0:	83 ec 04             	sub    $0x4,%esp
f0100ed3:	68 34 32 10 f0       	push   $0xf0103234
f0100ed8:	68 6b 01 00 00       	push   $0x16b
f0100edd:	68 1a 37 10 f0       	push   $0xf010371a
f0100ee2:	e8 a4 f1 ff ff       	call   f010008b <_panic>

f0100ee7 <check_page_alloc>:
{
f0100ee7:	55                   	push   %ebp
f0100ee8:	89 e5                	mov    %esp,%ebp
f0100eea:	57                   	push   %edi
f0100eeb:	56                   	push   %esi
f0100eec:	53                   	push   %ebx
f0100eed:	83 ec 1c             	sub    $0x1c,%esp
	if (!pages)
f0100ef0:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f0100ef7:	74 0c                	je     f0100f05 <check_page_alloc+0x1e>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100ef9:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100efe:	be 00 00 00 00       	mov    $0x0,%esi
f0100f03:	eb 1c                	jmp    f0100f21 <check_page_alloc+0x3a>
		panic("'pages' is a null pointer!");
f0100f05:	83 ec 04             	sub    $0x4,%esp
f0100f08:	68 d0 37 10 f0       	push   $0xf01037d0
f0100f0d:	68 93 02 00 00       	push   $0x293
f0100f12:	68 1a 37 10 f0       	push   $0xf010371a
f0100f17:	e8 6f f1 ff ff       	call   f010008b <_panic>
		++nfree;
f0100f1c:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f1f:	8b 00                	mov    (%eax),%eax
f0100f21:	85 c0                	test   %eax,%eax
f0100f23:	75 f7                	jne    f0100f1c <check_page_alloc+0x35>
	assert((pp0 = page_alloc(0)));
f0100f25:	83 ec 0c             	sub    $0xc,%esp
f0100f28:	6a 00                	push   $0x0
f0100f2a:	e8 1f ff ff ff       	call   f0100e4e <page_alloc>
f0100f2f:	89 c7                	mov    %eax,%edi
f0100f31:	83 c4 10             	add    $0x10,%esp
f0100f34:	85 c0                	test   %eax,%eax
f0100f36:	0f 84 c9 01 00 00    	je     f0101105 <check_page_alloc+0x21e>
	assert((pp1 = page_alloc(0)));
f0100f3c:	83 ec 0c             	sub    $0xc,%esp
f0100f3f:	6a 00                	push   $0x0
f0100f41:	e8 08 ff ff ff       	call   f0100e4e <page_alloc>
f0100f46:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f49:	83 c4 10             	add    $0x10,%esp
f0100f4c:	85 c0                	test   %eax,%eax
f0100f4e:	0f 84 ca 01 00 00    	je     f010111e <check_page_alloc+0x237>
	assert((pp2 = page_alloc(0)));
f0100f54:	83 ec 0c             	sub    $0xc,%esp
f0100f57:	6a 00                	push   $0x0
f0100f59:	e8 f0 fe ff ff       	call   f0100e4e <page_alloc>
f0100f5e:	89 c3                	mov    %eax,%ebx
f0100f60:	83 c4 10             	add    $0x10,%esp
f0100f63:	85 c0                	test   %eax,%eax
f0100f65:	0f 84 cc 01 00 00    	je     f0101137 <check_page_alloc+0x250>
	assert(pp1 && pp1 != pp0);
f0100f6b:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0100f6e:	0f 84 dc 01 00 00    	je     f0101150 <check_page_alloc+0x269>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0100f74:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0100f77:	0f 84 ec 01 00 00    	je     f0101169 <check_page_alloc+0x282>
f0100f7d:	39 c7                	cmp    %eax,%edi
f0100f7f:	0f 84 e4 01 00 00    	je     f0101169 <check_page_alloc+0x282>
	assert(page2pa(pp0) < npages * PGSIZE);
f0100f85:	89 f8                	mov    %edi,%eax
f0100f87:	e8 09 fa ff ff       	call   f0100995 <page2pa>
f0100f8c:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0100f92:	c1 e1 0c             	shl    $0xc,%ecx
f0100f95:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100f98:	39 c8                	cmp    %ecx,%eax
f0100f9a:	0f 83 e2 01 00 00    	jae    f0101182 <check_page_alloc+0x29b>
	assert(page2pa(pp1) < npages * PGSIZE);
f0100fa0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fa3:	e8 ed f9 ff ff       	call   f0100995 <page2pa>
f0100fa8:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100fab:	0f 86 ea 01 00 00    	jbe    f010119b <check_page_alloc+0x2b4>
	assert(page2pa(pp2) < npages * PGSIZE);
f0100fb1:	89 d8                	mov    %ebx,%eax
f0100fb3:	e8 dd f9 ff ff       	call   f0100995 <page2pa>
f0100fb8:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100fbb:	0f 86 f3 01 00 00    	jbe    f01011b4 <check_page_alloc+0x2cd>
	fl = page_free_list;
f0100fc1:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0100fc6:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0100fc9:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0100fd0:	00 00 00 
	assert(!page_alloc(0));
f0100fd3:	83 ec 0c             	sub    $0xc,%esp
f0100fd6:	6a 00                	push   $0x0
f0100fd8:	e8 71 fe ff ff       	call   f0100e4e <page_alloc>
f0100fdd:	83 c4 10             	add    $0x10,%esp
f0100fe0:	85 c0                	test   %eax,%eax
f0100fe2:	0f 85 e5 01 00 00    	jne    f01011cd <check_page_alloc+0x2e6>
	page_free(pp0);
f0100fe8:	83 ec 0c             	sub    $0xc,%esp
f0100feb:	57                   	push   %edi
f0100fec:	e8 a4 fe ff ff       	call   f0100e95 <page_free>
	page_free(pp1);
f0100ff1:	83 c4 04             	add    $0x4,%esp
f0100ff4:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100ff7:	e8 99 fe ff ff       	call   f0100e95 <page_free>
	page_free(pp2);
f0100ffc:	89 1c 24             	mov    %ebx,(%esp)
f0100fff:	e8 91 fe ff ff       	call   f0100e95 <page_free>
	assert((pp0 = page_alloc(0)));
f0101004:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010100b:	e8 3e fe ff ff       	call   f0100e4e <page_alloc>
f0101010:	89 c3                	mov    %eax,%ebx
f0101012:	83 c4 10             	add    $0x10,%esp
f0101015:	85 c0                	test   %eax,%eax
f0101017:	0f 84 c9 01 00 00    	je     f01011e6 <check_page_alloc+0x2ff>
	assert((pp1 = page_alloc(0)));
f010101d:	83 ec 0c             	sub    $0xc,%esp
f0101020:	6a 00                	push   $0x0
f0101022:	e8 27 fe ff ff       	call   f0100e4e <page_alloc>
f0101027:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010102a:	83 c4 10             	add    $0x10,%esp
f010102d:	85 c0                	test   %eax,%eax
f010102f:	0f 84 ca 01 00 00    	je     f01011ff <check_page_alloc+0x318>
	assert((pp2 = page_alloc(0)));
f0101035:	83 ec 0c             	sub    $0xc,%esp
f0101038:	6a 00                	push   $0x0
f010103a:	e8 0f fe ff ff       	call   f0100e4e <page_alloc>
f010103f:	89 c7                	mov    %eax,%edi
f0101041:	83 c4 10             	add    $0x10,%esp
f0101044:	85 c0                	test   %eax,%eax
f0101046:	0f 84 cc 01 00 00    	je     f0101218 <check_page_alloc+0x331>
	assert(pp1 && pp1 != pp0);
f010104c:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010104f:	0f 84 dc 01 00 00    	je     f0101231 <check_page_alloc+0x34a>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101055:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101058:	0f 84 ec 01 00 00    	je     f010124a <check_page_alloc+0x363>
f010105e:	39 c3                	cmp    %eax,%ebx
f0101060:	0f 84 e4 01 00 00    	je     f010124a <check_page_alloc+0x363>
	assert(!page_alloc(0));
f0101066:	83 ec 0c             	sub    $0xc,%esp
f0101069:	6a 00                	push   $0x0
f010106b:	e8 de fd ff ff       	call   f0100e4e <page_alloc>
f0101070:	83 c4 10             	add    $0x10,%esp
f0101073:	85 c0                	test   %eax,%eax
f0101075:	0f 85 e8 01 00 00    	jne    f0101263 <check_page_alloc+0x37c>
	memset(page2kva(pp0), 1, PGSIZE);
f010107b:	89 d8                	mov    %ebx,%eax
f010107d:	e8 3b fa ff ff       	call   f0100abd <page2kva>
f0101082:	83 ec 04             	sub    $0x4,%esp
f0101085:	68 00 10 00 00       	push   $0x1000
f010108a:	6a 01                	push   $0x1
f010108c:	50                   	push   %eax
f010108d:	e8 30 17 00 00       	call   f01027c2 <memset>
	page_free(pp0);
f0101092:	89 1c 24             	mov    %ebx,(%esp)
f0101095:	e8 fb fd ff ff       	call   f0100e95 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010109a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01010a1:	e8 a8 fd ff ff       	call   f0100e4e <page_alloc>
f01010a6:	83 c4 10             	add    $0x10,%esp
f01010a9:	85 c0                	test   %eax,%eax
f01010ab:	0f 84 cb 01 00 00    	je     f010127c <check_page_alloc+0x395>
	assert(pp && pp0 == pp);
f01010b1:	39 c3                	cmp    %eax,%ebx
f01010b3:	0f 85 dc 01 00 00    	jne    f0101295 <check_page_alloc+0x3ae>
	c = page2kva(pp);
f01010b9:	e8 ff f9 ff ff       	call   f0100abd <page2kva>
f01010be:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
		assert(c[i] == 0);
f01010c4:	80 38 00             	cmpb   $0x0,(%eax)
f01010c7:	0f 85 e1 01 00 00    	jne    f01012ae <check_page_alloc+0x3c7>
f01010cd:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01010d0:	39 d0                	cmp    %edx,%eax
f01010d2:	75 f0                	jne    f01010c4 <check_page_alloc+0x1dd>
	page_free_list = fl;
f01010d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d7:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	page_free(pp0);
f01010dc:	83 ec 0c             	sub    $0xc,%esp
f01010df:	53                   	push   %ebx
f01010e0:	e8 b0 fd ff ff       	call   f0100e95 <page_free>
	page_free(pp1);
f01010e5:	83 c4 04             	add    $0x4,%esp
f01010e8:	ff 75 e4             	pushl  -0x1c(%ebp)
f01010eb:	e8 a5 fd ff ff       	call   f0100e95 <page_free>
	page_free(pp2);
f01010f0:	89 3c 24             	mov    %edi,(%esp)
f01010f3:	e8 9d fd ff ff       	call   f0100e95 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010f8:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f01010fd:	83 c4 10             	add    $0x10,%esp
f0101100:	e9 c7 01 00 00       	jmp    f01012cc <check_page_alloc+0x3e5>
	assert((pp0 = page_alloc(0)));
f0101105:	68 eb 37 10 f0       	push   $0xf01037eb
f010110a:	68 40 37 10 f0       	push   $0xf0103740
f010110f:	68 9b 02 00 00       	push   $0x29b
f0101114:	68 1a 37 10 f0       	push   $0xf010371a
f0101119:	e8 6d ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010111e:	68 01 38 10 f0       	push   $0xf0103801
f0101123:	68 40 37 10 f0       	push   $0xf0103740
f0101128:	68 9c 02 00 00       	push   $0x29c
f010112d:	68 1a 37 10 f0       	push   $0xf010371a
f0101132:	e8 54 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101137:	68 17 38 10 f0       	push   $0xf0103817
f010113c:	68 40 37 10 f0       	push   $0xf0103740
f0101141:	68 9d 02 00 00       	push   $0x29d
f0101146:	68 1a 37 10 f0       	push   $0xf010371a
f010114b:	e8 3b ef ff ff       	call   f010008b <_panic>
	assert(pp1 && pp1 != pp0);
f0101150:	68 2d 38 10 f0       	push   $0xf010382d
f0101155:	68 40 37 10 f0       	push   $0xf0103740
f010115a:	68 a0 02 00 00       	push   $0x2a0
f010115f:	68 1a 37 10 f0       	push   $0xf010371a
f0101164:	e8 22 ef ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101169:	68 60 32 10 f0       	push   $0xf0103260
f010116e:	68 40 37 10 f0       	push   $0xf0103740
f0101173:	68 a1 02 00 00       	push   $0x2a1
f0101178:	68 1a 37 10 f0       	push   $0xf010371a
f010117d:	e8 09 ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages * PGSIZE);
f0101182:	68 80 32 10 f0       	push   $0xf0103280
f0101187:	68 40 37 10 f0       	push   $0xf0103740
f010118c:	68 a2 02 00 00       	push   $0x2a2
f0101191:	68 1a 37 10 f0       	push   $0xf010371a
f0101196:	e8 f0 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f010119b:	68 a0 32 10 f0       	push   $0xf01032a0
f01011a0:	68 40 37 10 f0       	push   $0xf0103740
f01011a5:	68 a3 02 00 00       	push   $0x2a3
f01011aa:	68 1a 37 10 f0       	push   $0xf010371a
f01011af:	e8 d7 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f01011b4:	68 c0 32 10 f0       	push   $0xf01032c0
f01011b9:	68 40 37 10 f0       	push   $0xf0103740
f01011be:	68 a4 02 00 00       	push   $0x2a4
f01011c3:	68 1a 37 10 f0       	push   $0xf010371a
f01011c8:	e8 be ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011cd:	68 3f 38 10 f0       	push   $0xf010383f
f01011d2:	68 40 37 10 f0       	push   $0xf0103740
f01011d7:	68 ab 02 00 00       	push   $0x2ab
f01011dc:	68 1a 37 10 f0       	push   $0xf010371a
f01011e1:	e8 a5 ee ff ff       	call   f010008b <_panic>
	assert((pp0 = page_alloc(0)));
f01011e6:	68 eb 37 10 f0       	push   $0xf01037eb
f01011eb:	68 40 37 10 f0       	push   $0xf0103740
f01011f0:	68 b2 02 00 00       	push   $0x2b2
f01011f5:	68 1a 37 10 f0       	push   $0xf010371a
f01011fa:	e8 8c ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011ff:	68 01 38 10 f0       	push   $0xf0103801
f0101204:	68 40 37 10 f0       	push   $0xf0103740
f0101209:	68 b3 02 00 00       	push   $0x2b3
f010120e:	68 1a 37 10 f0       	push   $0xf010371a
f0101213:	e8 73 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101218:	68 17 38 10 f0       	push   $0xf0103817
f010121d:	68 40 37 10 f0       	push   $0xf0103740
f0101222:	68 b4 02 00 00       	push   $0x2b4
f0101227:	68 1a 37 10 f0       	push   $0xf010371a
f010122c:	e8 5a ee ff ff       	call   f010008b <_panic>
	assert(pp1 && pp1 != pp0);
f0101231:	68 2d 38 10 f0       	push   $0xf010382d
f0101236:	68 40 37 10 f0       	push   $0xf0103740
f010123b:	68 b6 02 00 00       	push   $0x2b6
f0101240:	68 1a 37 10 f0       	push   $0xf010371a
f0101245:	e8 41 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010124a:	68 60 32 10 f0       	push   $0xf0103260
f010124f:	68 40 37 10 f0       	push   $0xf0103740
f0101254:	68 b7 02 00 00       	push   $0x2b7
f0101259:	68 1a 37 10 f0       	push   $0xf010371a
f010125e:	e8 28 ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101263:	68 3f 38 10 f0       	push   $0xf010383f
f0101268:	68 40 37 10 f0       	push   $0xf0103740
f010126d:	68 b8 02 00 00       	push   $0x2b8
f0101272:	68 1a 37 10 f0       	push   $0xf010371a
f0101277:	e8 0f ee ff ff       	call   f010008b <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010127c:	68 4e 38 10 f0       	push   $0xf010384e
f0101281:	68 40 37 10 f0       	push   $0xf0103740
f0101286:	68 bd 02 00 00       	push   $0x2bd
f010128b:	68 1a 37 10 f0       	push   $0xf010371a
f0101290:	e8 f6 ed ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101295:	68 6c 38 10 f0       	push   $0xf010386c
f010129a:	68 40 37 10 f0       	push   $0xf0103740
f010129f:	68 be 02 00 00       	push   $0x2be
f01012a4:	68 1a 37 10 f0       	push   $0xf010371a
f01012a9:	e8 dd ed ff ff       	call   f010008b <_panic>
		assert(c[i] == 0);
f01012ae:	68 7c 38 10 f0       	push   $0xf010387c
f01012b3:	68 40 37 10 f0       	push   $0xf0103740
f01012b8:	68 c1 02 00 00       	push   $0x2c1
f01012bd:	68 1a 37 10 f0       	push   $0xf010371a
f01012c2:	e8 c4 ed ff ff       	call   f010008b <_panic>
		--nfree;
f01012c7:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012ca:	8b 00                	mov    (%eax),%eax
f01012cc:	85 c0                	test   %eax,%eax
f01012ce:	75 f7                	jne    f01012c7 <check_page_alloc+0x3e0>
	assert(nfree == 0);
f01012d0:	85 f6                	test   %esi,%esi
f01012d2:	75 18                	jne    f01012ec <check_page_alloc+0x405>
	cprintf("check_page_alloc() succeeded!\n");
f01012d4:	83 ec 0c             	sub    $0xc,%esp
f01012d7:	68 e0 32 10 f0       	push   $0xf01032e0
f01012dc:	e8 43 0a 00 00       	call   f0101d24 <cprintf>
}
f01012e1:	83 c4 10             	add    $0x10,%esp
f01012e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e7:	5b                   	pop    %ebx
f01012e8:	5e                   	pop    %esi
f01012e9:	5f                   	pop    %edi
f01012ea:	5d                   	pop    %ebp
f01012eb:	c3                   	ret    
	assert(nfree == 0);
f01012ec:	68 86 38 10 f0       	push   $0xf0103886
f01012f1:	68 40 37 10 f0       	push   $0xf0103740
f01012f6:	68 ce 02 00 00       	push   $0x2ce
f01012fb:	68 1a 37 10 f0       	push   $0xf010371a
f0101300:	e8 86 ed ff ff       	call   f010008b <_panic>

f0101305 <page_decref>:
{
f0101305:	55                   	push   %ebp
f0101306:	89 e5                	mov    %esp,%ebp
f0101308:	83 ec 08             	sub    $0x8,%esp
f010130b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010130e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101312:	83 e8 01             	sub    $0x1,%eax
f0101315:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101319:	66 85 c0             	test   %ax,%ax
f010131c:	74 02                	je     f0101320 <page_decref+0x1b>
}
f010131e:	c9                   	leave  
f010131f:	c3                   	ret    
		page_free(pp);
f0101320:	83 ec 0c             	sub    $0xc,%esp
f0101323:	52                   	push   %edx
f0101324:	e8 6c fb ff ff       	call   f0100e95 <page_free>
f0101329:	83 c4 10             	add    $0x10,%esp
}
f010132c:	eb f0                	jmp    f010131e <page_decref+0x19>

f010132e <pgdir_walk>:
{
f010132e:	55                   	push   %ebp
f010132f:	89 e5                	mov    %esp,%ebp
f0101331:	53                   	push   %ebx
f0101332:	83 ec 04             	sub    $0x4,%esp
f0101335:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pde_t pde = *(pgdir + PDX(va));
f0101338:	89 da                	mov    %ebx,%edx
f010133a:	c1 ea 16             	shr    $0x16,%edx
f010133d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101340:	8b 0c 90             	mov    (%eax,%edx,4),%ecx
	if ((pde & PTE_P)) {
f0101343:	f6 c1 01             	test   $0x1,%cl
f0101346:	75 31                	jne    f0101379 <pgdir_walk+0x4b>
	} else if (create) {
f0101348:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010134c:	74 4a                	je     f0101398 <pgdir_walk+0x6a>
		struct PageInfo * new_pt_page = page_alloc(ALLOC_ZERO);
f010134e:	83 ec 0c             	sub    $0xc,%esp
f0101351:	6a 01                	push   $0x1
f0101353:	e8 f6 fa ff ff       	call   f0100e4e <page_alloc>
		if (!new_pt_page) {
f0101358:	83 c4 10             	add    $0x10,%esp
f010135b:	85 c0                	test   %eax,%eax
f010135d:	74 40                	je     f010139f <pgdir_walk+0x71>
		new_pt_page->pp_ref++;
f010135f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		pte_t * new_pte = (pte_t *) (page2kva(new_pt_page) + PTX(va));
f0101364:	e8 54 f7 ff ff       	call   f0100abd <page2kva>
f0101369:	c1 eb 0c             	shr    $0xc,%ebx
f010136c:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0101372:	01 d8                	add    %ebx,%eax
}
f0101374:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101377:	c9                   	leave  
f0101378:	c3                   	ret    
		pte_t * ptbr = KADDR(PGNUM(pde));
f0101379:	c1 e9 0c             	shr    $0xc,%ecx
f010137c:	ba b1 01 00 00       	mov    $0x1b1,%edx
f0101381:	b8 1a 37 10 f0       	mov    $0xf010371a,%eax
f0101386:	e8 06 f7 ff ff       	call   f0100a91 <_kaddr>
		return (ptbr + PTX(va));
f010138b:	c1 eb 0a             	shr    $0xa,%ebx
f010138e:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101394:	01 d8                	add    %ebx,%eax
f0101396:	eb dc                	jmp    f0101374 <pgdir_walk+0x46>
		return NULL; 
f0101398:	b8 00 00 00 00       	mov    $0x0,%eax
f010139d:	eb d5                	jmp    f0101374 <pgdir_walk+0x46>
			return NULL;	// Fallo el page alloc porque no había mas memoria
f010139f:	b8 00 00 00 00       	mov    $0x0,%eax
f01013a4:	eb ce                	jmp    f0101374 <pgdir_walk+0x46>

f01013a6 <page_insert>:
{
f01013a6:	55                   	push   %ebp
f01013a7:	89 e5                	mov    %esp,%ebp
}
f01013a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ae:	5d                   	pop    %ebp
f01013af:	c3                   	ret    

f01013b0 <page_lookup>:
{
f01013b0:	55                   	push   %ebp
f01013b1:	89 e5                	mov    %esp,%ebp
}
f01013b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b8:	5d                   	pop    %ebp
f01013b9:	c3                   	ret    

f01013ba <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f01013ba:	55                   	push   %ebp
f01013bb:	89 e5                	mov    %esp,%ebp
f01013bd:	57                   	push   %edi
f01013be:	56                   	push   %esi
f01013bf:	53                   	push   %ebx
f01013c0:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013c3:	6a 00                	push   $0x0
f01013c5:	e8 84 fa ff ff       	call   f0100e4e <page_alloc>
f01013ca:	83 c4 10             	add    $0x10,%esp
f01013cd:	85 c0                	test   %eax,%eax
f01013cf:	0f 84 80 00 00 00    	je     f0101455 <check_page+0x9b>
f01013d5:	89 c3                	mov    %eax,%ebx
	assert((pp1 = page_alloc(0)));
f01013d7:	83 ec 0c             	sub    $0xc,%esp
f01013da:	6a 00                	push   $0x0
f01013dc:	e8 6d fa ff ff       	call   f0100e4e <page_alloc>
f01013e1:	89 c6                	mov    %eax,%esi
f01013e3:	83 c4 10             	add    $0x10,%esp
f01013e6:	85 c0                	test   %eax,%eax
f01013e8:	0f 84 80 00 00 00    	je     f010146e <check_page+0xb4>
	assert((pp2 = page_alloc(0)));
f01013ee:	83 ec 0c             	sub    $0xc,%esp
f01013f1:	6a 00                	push   $0x0
f01013f3:	e8 56 fa ff ff       	call   f0100e4e <page_alloc>
f01013f8:	89 c7                	mov    %eax,%edi
f01013fa:	83 c4 10             	add    $0x10,%esp
f01013fd:	85 c0                	test   %eax,%eax
f01013ff:	0f 84 82 00 00 00    	je     f0101487 <check_page+0xcd>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101405:	39 f3                	cmp    %esi,%ebx
f0101407:	0f 84 93 00 00 00    	je     f01014a0 <check_page+0xe6>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010140d:	39 c6                	cmp    %eax,%esi
f010140f:	0f 84 a4 00 00 00    	je     f01014b9 <check_page+0xff>
f0101415:	39 c3                	cmp    %eax,%ebx
f0101417:	0f 84 9c 00 00 00    	je     f01014b9 <check_page+0xff>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f010141d:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101424:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101427:	83 ec 0c             	sub    $0xc,%esp
f010142a:	6a 00                	push   $0x0
f010142c:	e8 1d fa ff ff       	call   f0100e4e <page_alloc>
f0101431:	83 c4 10             	add    $0x10,%esp
f0101434:	85 c0                	test   %eax,%eax
f0101436:	0f 84 96 00 00 00    	je     f01014d2 <check_page+0x118>
f010143c:	68 3f 38 10 f0       	push   $0xf010383f
f0101441:	68 40 37 10 f0       	push   $0xf0103740
f0101446:	68 40 03 00 00       	push   $0x340
f010144b:	68 1a 37 10 f0       	push   $0xf010371a
f0101450:	e8 36 ec ff ff       	call   f010008b <_panic>
	assert((pp0 = page_alloc(0)));
f0101455:	68 eb 37 10 f0       	push   $0xf01037eb
f010145a:	68 40 37 10 f0       	push   $0xf0103740
f010145f:	68 33 03 00 00       	push   $0x333
f0101464:	68 1a 37 10 f0       	push   $0xf010371a
f0101469:	e8 1d ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010146e:	68 01 38 10 f0       	push   $0xf0103801
f0101473:	68 40 37 10 f0       	push   $0xf0103740
f0101478:	68 34 03 00 00       	push   $0x334
f010147d:	68 1a 37 10 f0       	push   $0xf010371a
f0101482:	e8 04 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101487:	68 17 38 10 f0       	push   $0xf0103817
f010148c:	68 40 37 10 f0       	push   $0xf0103740
f0101491:	68 35 03 00 00       	push   $0x335
f0101496:	68 1a 37 10 f0       	push   $0xf010371a
f010149b:	e8 eb eb ff ff       	call   f010008b <_panic>
	assert(pp1 && pp1 != pp0);
f01014a0:	68 2d 38 10 f0       	push   $0xf010382d
f01014a5:	68 40 37 10 f0       	push   $0xf0103740
f01014aa:	68 38 03 00 00       	push   $0x338
f01014af:	68 1a 37 10 f0       	push   $0xf010371a
f01014b4:	e8 d2 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014b9:	68 60 32 10 f0       	push   $0xf0103260
f01014be:	68 40 37 10 f0       	push   $0xf0103740
f01014c3:	68 39 03 00 00       	push   $0x339
f01014c8:	68 1a 37 10 f0       	push   $0xf010371a
f01014cd:	e8 b9 eb ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01014d2:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01014d7:	89 c1                	mov    %eax,%ecx
f01014d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014dc:	83 ec 04             	sub    $0x4,%esp
f01014df:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01014e2:	50                   	push   %eax
f01014e3:	6a 00                	push   $0x0
f01014e5:	51                   	push   %ecx
f01014e6:	e8 c5 fe ff ff       	call   f01013b0 <page_lookup>
f01014eb:	83 c4 10             	add    $0x10,%esp
f01014ee:	85 c0                	test   %eax,%eax
f01014f0:	74 19                	je     f010150b <check_page+0x151>
f01014f2:	68 00 33 10 f0       	push   $0xf0103300
f01014f7:	68 40 37 10 f0       	push   $0xf0103740
f01014fc:	68 43 03 00 00       	push   $0x343
f0101501:	68 1a 37 10 f0       	push   $0xf010371a
f0101506:	e8 80 eb ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010150b:	6a 02                	push   $0x2
f010150d:	6a 00                	push   $0x0
f010150f:	56                   	push   %esi
f0101510:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101513:	e8 8e fe ff ff       	call   f01013a6 <page_insert>
f0101518:	83 c4 10             	add    $0x10,%esp
f010151b:	85 c0                	test   %eax,%eax
f010151d:	78 19                	js     f0101538 <check_page+0x17e>
f010151f:	68 38 33 10 f0       	push   $0xf0103338
f0101524:	68 40 37 10 f0       	push   $0xf0103740
f0101529:	68 46 03 00 00       	push   $0x346
f010152e:	68 1a 37 10 f0       	push   $0xf010371a
f0101533:	e8 53 eb ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101538:	83 ec 0c             	sub    $0xc,%esp
f010153b:	53                   	push   %ebx
f010153c:	e8 54 f9 ff ff       	call   f0100e95 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101541:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101546:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101549:	6a 02                	push   $0x2
f010154b:	6a 00                	push   $0x0
f010154d:	56                   	push   %esi
f010154e:	50                   	push   %eax
f010154f:	e8 52 fe ff ff       	call   f01013a6 <page_insert>
f0101554:	83 c4 20             	add    $0x20,%esp
f0101557:	85 c0                	test   %eax,%eax
f0101559:	75 2f                	jne    f010158a <check_page+0x1d0>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010155b:	89 d8                	mov    %ebx,%eax
f010155d:	e8 33 f4 ff ff       	call   f0100995 <page2pa>
f0101562:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101565:	8b 12                	mov    (%edx),%edx
f0101567:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010156d:	39 c2                	cmp    %eax,%edx
f010156f:	74 32                	je     f01015a3 <check_page+0x1e9>
f0101571:	68 98 33 10 f0       	push   $0xf0103398
f0101576:	68 40 37 10 f0       	push   $0xf0103740
f010157b:	68 4b 03 00 00       	push   $0x34b
f0101580:	68 1a 37 10 f0       	push   $0xf010371a
f0101585:	e8 01 eb ff ff       	call   f010008b <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010158a:	68 68 33 10 f0       	push   $0xf0103368
f010158f:	68 40 37 10 f0       	push   $0xf0103740
f0101594:	68 4a 03 00 00       	push   $0x34a
f0101599:	68 1a 37 10 f0       	push   $0xf010371a
f010159e:	e8 e8 ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01015a3:	ba 00 00 00 00       	mov    $0x0,%edx
f01015a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015ab:	e8 2b f5 ff ff       	call   f0100adb <check_va2pa>
f01015b0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015b3:	89 f0                	mov    %esi,%eax
f01015b5:	e8 db f3 ff ff       	call   f0100995 <page2pa>
f01015ba:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01015bd:	75 3e                	jne    f01015fd <check_page+0x243>
	assert(pp1->pp_ref == 1);
f01015bf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01015c4:	75 50                	jne    f0101616 <check_page+0x25c>
	assert(pp0->pp_ref == 1);
f01015c6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01015cb:	75 62                	jne    f010162f <check_page+0x275>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated
	// for page table
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W) == 0);
f01015cd:	6a 02                	push   $0x2
f01015cf:	68 00 10 00 00       	push   $0x1000
f01015d4:	57                   	push   %edi
f01015d5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015d8:	e8 c9 fd ff ff       	call   f01013a6 <page_insert>
f01015dd:	83 c4 10             	add    $0x10,%esp
f01015e0:	85 c0                	test   %eax,%eax
f01015e2:	74 64                	je     f0101648 <check_page+0x28e>
f01015e4:	68 f0 33 10 f0       	push   $0xf01033f0
f01015e9:	68 40 37 10 f0       	push   $0xf0103740
f01015ee:	68 52 03 00 00       	push   $0x352
f01015f3:	68 1a 37 10 f0       	push   $0xf010371a
f01015f8:	e8 8e ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01015fd:	68 c0 33 10 f0       	push   $0xf01033c0
f0101602:	68 40 37 10 f0       	push   $0xf0103740
f0101607:	68 4c 03 00 00       	push   $0x34c
f010160c:	68 1a 37 10 f0       	push   $0xf010371a
f0101611:	e8 75 ea ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101616:	68 91 38 10 f0       	push   $0xf0103891
f010161b:	68 40 37 10 f0       	push   $0xf0103740
f0101620:	68 4d 03 00 00       	push   $0x34d
f0101625:	68 1a 37 10 f0       	push   $0xf010371a
f010162a:	e8 5c ea ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010162f:	68 a2 38 10 f0       	push   $0xf01038a2
f0101634:	68 40 37 10 f0       	push   $0xf0103740
f0101639:	68 4e 03 00 00       	push   $0x34e
f010163e:	68 1a 37 10 f0       	push   $0xf010371a
f0101643:	e8 43 ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101648:	ba 00 10 00 00       	mov    $0x1000,%edx
f010164d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101650:	e8 86 f4 ff ff       	call   f0100adb <check_va2pa>
f0101655:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101658:	89 f8                	mov    %edi,%eax
f010165a:	e8 36 f3 ff ff       	call   f0100995 <page2pa>
f010165f:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101662:	75 20                	jne    f0101684 <check_page+0x2ca>
	assert(pp2->pp_ref == 1);
f0101664:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101669:	74 32                	je     f010169d <check_page+0x2e3>
f010166b:	68 b3 38 10 f0       	push   $0xf01038b3
f0101670:	68 40 37 10 f0       	push   $0xf0103740
f0101675:	68 54 03 00 00       	push   $0x354
f010167a:	68 1a 37 10 f0       	push   $0xf010371a
f010167f:	e8 07 ea ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101684:	68 2c 34 10 f0       	push   $0xf010342c
f0101689:	68 40 37 10 f0       	push   $0xf0103740
f010168e:	68 53 03 00 00       	push   $0x353
f0101693:	68 1a 37 10 f0       	push   $0xf010371a
f0101698:	e8 ee e9 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010169d:	83 ec 0c             	sub    $0xc,%esp
f01016a0:	6a 00                	push   $0x0
f01016a2:	e8 a7 f7 ff ff       	call   f0100e4e <page_alloc>
f01016a7:	83 c4 10             	add    $0x10,%esp
f01016aa:	85 c0                	test   %eax,%eax
f01016ac:	74 19                	je     f01016c7 <check_page+0x30d>
f01016ae:	68 3f 38 10 f0       	push   $0xf010383f
f01016b3:	68 40 37 10 f0       	push   $0xf0103740
f01016b8:	68 57 03 00 00       	push   $0x357
f01016bd:	68 1a 37 10 f0       	push   $0xf010371a
f01016c2:	e8 c4 e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W) == 0);
f01016c7:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01016cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016cf:	6a 02                	push   $0x2
f01016d1:	68 00 10 00 00       	push   $0x1000
f01016d6:	57                   	push   %edi
f01016d7:	50                   	push   %eax
f01016d8:	e8 c9 fc ff ff       	call   f01013a6 <page_insert>
f01016dd:	83 c4 10             	add    $0x10,%esp
f01016e0:	85 c0                	test   %eax,%eax
f01016e2:	74 19                	je     f01016fd <check_page+0x343>
f01016e4:	68 f0 33 10 f0       	push   $0xf01033f0
f01016e9:	68 40 37 10 f0       	push   $0xf0103740
f01016ee:	68 5a 03 00 00       	push   $0x35a
f01016f3:	68 1a 37 10 f0       	push   $0xf010371a
f01016f8:	e8 8e e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01016fd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101702:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101705:	e8 d1 f3 ff ff       	call   f0100adb <check_va2pa>
f010170a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010170d:	89 f8                	mov    %edi,%eax
f010170f:	e8 81 f2 ff ff       	call   f0100995 <page2pa>
f0101714:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101717:	74 19                	je     f0101732 <check_page+0x378>
f0101719:	68 2c 34 10 f0       	push   $0xf010342c
f010171e:	68 40 37 10 f0       	push   $0xf0103740
f0101723:	68 5b 03 00 00       	push   $0x35b
f0101728:	68 1a 37 10 f0       	push   $0xf010371a
f010172d:	e8 59 e9 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101732:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101737:	74 19                	je     f0101752 <check_page+0x398>
f0101739:	68 b3 38 10 f0       	push   $0xf01038b3
f010173e:	68 40 37 10 f0       	push   $0xf0103740
f0101743:	68 5c 03 00 00       	push   $0x35c
f0101748:	68 1a 37 10 f0       	push   $0xf010371a
f010174d:	e8 39 e9 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101752:	83 ec 0c             	sub    $0xc,%esp
f0101755:	6a 00                	push   $0x0
f0101757:	e8 f2 f6 ff ff       	call   f0100e4e <page_alloc>
f010175c:	83 c4 10             	add    $0x10,%esp
f010175f:	85 c0                	test   %eax,%eax
f0101761:	74 19                	je     f010177c <check_page+0x3c2>
f0101763:	68 3f 38 10 f0       	push   $0xf010383f
f0101768:	68 40 37 10 f0       	push   $0xf0103740
f010176d:	68 60 03 00 00       	push   $0x360
f0101772:	68 1a 37 10 f0       	push   $0xf010371a
f0101777:	e8 0f e9 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010177c:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f0101781:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101784:	8b 10                	mov    (%eax),%edx
f0101786:	89 d1                	mov    %edx,%ecx
f0101788:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010178e:	ba 63 03 00 00       	mov    $0x363,%edx
f0101793:	b8 1a 37 10 f0       	mov    $0xf010371a,%eax
f0101798:	e8 f4 f2 ff ff       	call   f0100a91 <_kaddr>
f010179d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01017a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) == ptep + PTX(PGSIZE));
f01017a3:	83 ec 04             	sub    $0x4,%esp
f01017a6:	6a 00                	push   $0x0
f01017a8:	68 00 10 00 00       	push   $0x1000
f01017ad:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017b0:	e8 79 fb ff ff       	call   f010132e <pgdir_walk>
f01017b5:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01017b8:	83 c2 04             	add    $0x4,%edx
f01017bb:	83 c4 10             	add    $0x10,%esp
f01017be:	39 d0                	cmp    %edx,%eax
f01017c0:	74 19                	je     f01017db <check_page+0x421>
f01017c2:	68 5c 34 10 f0       	push   $0xf010345c
f01017c7:	68 40 37 10 f0       	push   $0xf0103740
f01017cc:	68 64 03 00 00       	push   $0x364
f01017d1:	68 1a 37 10 f0       	push   $0xf010371a
f01017d6:	e8 b0 e8 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W | PTE_U) == 0);
f01017db:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f01017e0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017e3:	6a 06                	push   $0x6
f01017e5:	68 00 10 00 00       	push   $0x1000
f01017ea:	57                   	push   %edi
f01017eb:	50                   	push   %eax
f01017ec:	e8 b5 fb ff ff       	call   f01013a6 <page_insert>
f01017f1:	83 c4 10             	add    $0x10,%esp
f01017f4:	85 c0                	test   %eax,%eax
f01017f6:	74 19                	je     f0101811 <check_page+0x457>
f01017f8:	68 a0 34 10 f0       	push   $0xf01034a0
f01017fd:	68 40 37 10 f0       	push   $0xf0103740
f0101802:	68 67 03 00 00       	push   $0x367
f0101807:	68 1a 37 10 f0       	push   $0xf010371a
f010180c:	e8 7a e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101811:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101816:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101819:	e8 bd f2 ff ff       	call   f0100adb <check_va2pa>
f010181e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101821:	89 f8                	mov    %edi,%eax
f0101823:	e8 6d f1 ff ff       	call   f0100995 <page2pa>
f0101828:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010182b:	74 19                	je     f0101846 <check_page+0x48c>
f010182d:	68 2c 34 10 f0       	push   $0xf010342c
f0101832:	68 40 37 10 f0       	push   $0xf0103740
f0101837:	68 68 03 00 00       	push   $0x368
f010183c:	68 1a 37 10 f0       	push   $0xf010371a
f0101841:	e8 45 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101846:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010184b:	74 19                	je     f0101866 <check_page+0x4ac>
f010184d:	68 b3 38 10 f0       	push   $0xf01038b3
f0101852:	68 40 37 10 f0       	push   $0xf0103740
f0101857:	68 69 03 00 00       	push   $0x369
f010185c:	68 1a 37 10 f0       	push   $0xf010371a
f0101861:	e8 25 e8 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_U);
f0101866:	83 ec 04             	sub    $0x4,%esp
f0101869:	6a 00                	push   $0x0
f010186b:	68 00 10 00 00       	push   $0x1000
f0101870:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101873:	e8 b6 fa ff ff       	call   f010132e <pgdir_walk>
f0101878:	83 c4 10             	add    $0x10,%esp
f010187b:	f6 00 04             	testb  $0x4,(%eax)
f010187e:	75 19                	jne    f0101899 <check_page+0x4df>
f0101880:	68 e4 34 10 f0       	push   $0xf01034e4
f0101885:	68 40 37 10 f0       	push   $0xf0103740
f010188a:	68 6a 03 00 00       	push   $0x36a
f010188f:	68 1a 37 10 f0       	push   $0xf010371a
f0101894:	e8 f2 e7 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101899:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010189e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018a1:	f6 00 04             	testb  $0x4,(%eax)
f01018a4:	75 19                	jne    f01018bf <check_page+0x505>
f01018a6:	68 c4 38 10 f0       	push   $0xf01038c4
f01018ab:	68 40 37 10 f0       	push   $0xf0103740
f01018b0:	68 6b 03 00 00       	push   $0x36b
f01018b5:	68 1a 37 10 f0       	push   $0xf010371a
f01018ba:	e8 cc e7 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W) == 0);
f01018bf:	6a 02                	push   $0x2
f01018c1:	68 00 10 00 00       	push   $0x1000
f01018c6:	57                   	push   %edi
f01018c7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018ca:	e8 d7 fa ff ff       	call   f01013a6 <page_insert>
f01018cf:	83 c4 10             	add    $0x10,%esp
f01018d2:	85 c0                	test   %eax,%eax
f01018d4:	74 19                	je     f01018ef <check_page+0x535>
f01018d6:	68 f0 33 10 f0       	push   $0xf01033f0
f01018db:	68 40 37 10 f0       	push   $0xf0103740
f01018e0:	68 6e 03 00 00       	push   $0x36e
f01018e5:	68 1a 37 10 f0       	push   $0xf010371a
f01018ea:	e8 9c e7 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_W);
f01018ef:	83 ec 04             	sub    $0x4,%esp
f01018f2:	6a 00                	push   $0x0
f01018f4:	68 00 10 00 00       	push   $0x1000
f01018f9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018fc:	e8 2d fa ff ff       	call   f010132e <pgdir_walk>
f0101901:	83 c4 10             	add    $0x10,%esp
f0101904:	f6 00 02             	testb  $0x2,(%eax)
f0101907:	75 19                	jne    f0101922 <check_page+0x568>
f0101909:	68 18 35 10 f0       	push   $0xf0103518
f010190e:	68 40 37 10 f0       	push   $0xf0103740
f0101913:	68 6f 03 00 00       	push   $0x36f
f0101918:	68 1a 37 10 f0       	push   $0xf010371a
f010191d:	e8 69 e7 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_U));
f0101922:	83 ec 04             	sub    $0x4,%esp
f0101925:	6a 00                	push   $0x0
f0101927:	68 00 10 00 00       	push   $0x1000
f010192c:	ff 35 48 69 11 f0    	pushl  0xf0116948
f0101932:	e8 f7 f9 ff ff       	call   f010132e <pgdir_walk>
f0101937:	83 c4 10             	add    $0x10,%esp
f010193a:	f6 00 04             	testb  $0x4,(%eax)
f010193d:	74 19                	je     f0101958 <check_page+0x59e>
f010193f:	68 4c 35 10 f0       	push   $0xf010354c
f0101944:	68 40 37 10 f0       	push   $0xf0103740
f0101949:	68 70 03 00 00       	push   $0x370
f010194e:	68 1a 37 10 f0       	push   $0xf010371a
f0101953:	e8 33 e7 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page
	// table
	assert(page_insert(kern_pgdir, pp0, (void *) PTSIZE, PTE_W) < 0);
f0101958:	a1 48 69 11 f0       	mov    0xf0116948,%eax
f010195d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101960:	6a 02                	push   $0x2
f0101962:	68 00 00 40 00       	push   $0x400000
f0101967:	53                   	push   %ebx
f0101968:	50                   	push   %eax
f0101969:	e8 38 fa ff ff       	call   f01013a6 <page_insert>
f010196e:	83 c4 10             	add    $0x10,%esp
f0101971:	85 c0                	test   %eax,%eax
f0101973:	78 19                	js     f010198e <check_page+0x5d4>
f0101975:	68 84 35 10 f0       	push   $0xf0103584
f010197a:	68 40 37 10 f0       	push   $0xf0103740
f010197f:	68 74 03 00 00       	push   $0x374
f0101984:	68 1a 37 10 f0       	push   $0xf010371a
f0101989:	e8 fd e6 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *) PGSIZE, PTE_W) == 0);
f010198e:	6a 02                	push   $0x2
f0101990:	68 00 10 00 00       	push   $0x1000
f0101995:	56                   	push   %esi
f0101996:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101999:	e8 08 fa ff ff       	call   f01013a6 <page_insert>
f010199e:	83 c4 10             	add    $0x10,%esp
f01019a1:	85 c0                	test   %eax,%eax
f01019a3:	74 19                	je     f01019be <check_page+0x604>
f01019a5:	68 c0 35 10 f0       	push   $0xf01035c0
f01019aa:	68 40 37 10 f0       	push   $0xf0103740
f01019af:	68 77 03 00 00       	push   $0x377
f01019b4:	68 1a 37 10 f0       	push   $0xf010371a
f01019b9:	e8 cd e6 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_U));
f01019be:	83 ec 04             	sub    $0x4,%esp
f01019c1:	6a 00                	push   $0x0
f01019c3:	68 00 10 00 00       	push   $0x1000
f01019c8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019cb:	e8 5e f9 ff ff       	call   f010132e <pgdir_walk>
f01019d0:	83 c4 10             	add    $0x10,%esp
f01019d3:	f6 00 04             	testb  $0x4,(%eax)
f01019d6:	74 19                	je     f01019f1 <check_page+0x637>
f01019d8:	68 4c 35 10 f0       	push   $0xf010354c
f01019dd:	68 40 37 10 f0       	push   $0xf0103740
f01019e2:	68 78 03 00 00       	push   $0x378
f01019e7:	68 1a 37 10 f0       	push   $0xf010371a
f01019ec:	e8 9a e6 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01019f1:	8b 1d 48 69 11 f0    	mov    0xf0116948,%ebx
f01019f7:	ba 00 00 00 00       	mov    $0x0,%edx
f01019fc:	89 d8                	mov    %ebx,%eax
f01019fe:	e8 d8 f0 ff ff       	call   f0100adb <check_va2pa>
f0101a03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a06:	89 f0                	mov    %esi,%eax
f0101a08:	e8 88 ef ff ff       	call   f0100995 <page2pa>
f0101a0d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a10:	74 19                	je     f0101a2b <check_page+0x671>
f0101a12:	68 fc 35 10 f0       	push   $0xf01035fc
f0101a17:	68 40 37 10 f0       	push   $0xf0103740
f0101a1c:	68 7b 03 00 00       	push   $0x37b
f0101a21:	68 1a 37 10 f0       	push   $0xf010371a
f0101a26:	e8 60 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101a2b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a30:	89 d8                	mov    %ebx,%eax
f0101a32:	e8 a4 f0 ff ff       	call   f0100adb <check_va2pa>
f0101a37:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a3a:	74 19                	je     f0101a55 <check_page+0x69b>
f0101a3c:	68 28 36 10 f0       	push   $0xf0103628
f0101a41:	68 40 37 10 f0       	push   $0xf0103740
f0101a46:	68 7c 03 00 00       	push   $0x37c
f0101a4b:	68 1a 37 10 f0       	push   $0xf010371a
f0101a50:	e8 36 e6 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101a55:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101a5a:	74 19                	je     f0101a75 <check_page+0x6bb>
f0101a5c:	68 da 38 10 f0       	push   $0xf01038da
f0101a61:	68 40 37 10 f0       	push   $0xf0103740
f0101a66:	68 7e 03 00 00       	push   $0x37e
f0101a6b:	68 1a 37 10 f0       	push   $0xf010371a
f0101a70:	e8 16 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101a75:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101a7a:	74 19                	je     f0101a95 <check_page+0x6db>
f0101a7c:	68 eb 38 10 f0       	push   $0xf01038eb
f0101a81:	68 40 37 10 f0       	push   $0xf0103740
f0101a86:	68 7f 03 00 00       	push   $0x37f
f0101a8b:	68 1a 37 10 f0       	push   $0xf010371a
f0101a90:	e8 f6 e5 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101a95:	83 ec 0c             	sub    $0xc,%esp
f0101a98:	6a 00                	push   $0x0
f0101a9a:	e8 af f3 ff ff       	call   f0100e4e <page_alloc>
f0101a9f:	83 c4 10             	add    $0x10,%esp
f0101aa2:	39 c7                	cmp    %eax,%edi
f0101aa4:	75 04                	jne    f0101aaa <check_page+0x6f0>
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	75 19                	jne    f0101ac3 <check_page+0x709>
f0101aaa:	68 58 36 10 f0       	push   $0xf0103658
f0101aaf:	68 40 37 10 f0       	push   $0xf0103740
f0101ab4:	68 82 03 00 00       	push   $0x382
f0101ab9:	68 1a 37 10 f0       	push   $0xf010371a
f0101abe:	e8 c8 e5 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ac3:	8b 1d 48 69 11 f0    	mov    0xf0116948,%ebx
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101ac9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ace:	89 d8                	mov    %ebx,%eax
f0101ad0:	e8 06 f0 ff ff       	call   f0100adb <check_va2pa>
f0101ad5:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ad8:	74 19                	je     f0101af3 <check_page+0x739>
f0101ada:	68 7c 36 10 f0       	push   $0xf010367c
f0101adf:	68 40 37 10 f0       	push   $0xf0103740
f0101ae4:	68 86 03 00 00       	push   $0x386
f0101ae9:	68 1a 37 10 f0       	push   $0xf010371a
f0101aee:	e8 98 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101af3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af8:	89 d8                	mov    %ebx,%eax
f0101afa:	e8 dc ef ff ff       	call   f0100adb <check_va2pa>
f0101aff:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b02:	89 f0                	mov    %esi,%eax
f0101b04:	e8 8c ee ff ff       	call   f0100995 <page2pa>
f0101b09:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101b0c:	74 19                	je     f0101b27 <check_page+0x76d>
f0101b0e:	68 28 36 10 f0       	push   $0xf0103628
f0101b13:	68 40 37 10 f0       	push   $0xf0103740
f0101b18:	68 87 03 00 00       	push   $0x387
f0101b1d:	68 1a 37 10 f0       	push   $0xf010371a
f0101b22:	e8 64 e5 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101b27:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b2c:	74 19                	je     f0101b47 <check_page+0x78d>
f0101b2e:	68 91 38 10 f0       	push   $0xf0103891
f0101b33:	68 40 37 10 f0       	push   $0xf0103740
f0101b38:	68 88 03 00 00       	push   $0x388
f0101b3d:	68 1a 37 10 f0       	push   $0xf010371a
f0101b42:	e8 44 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101b47:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101b4c:	74 19                	je     f0101b67 <check_page+0x7ad>
f0101b4e:	68 eb 38 10 f0       	push   $0xf01038eb
f0101b53:	68 40 37 10 f0       	push   $0xf0103740
f0101b58:	68 89 03 00 00       	push   $0x389
f0101b5d:	68 1a 37 10 f0       	push   $0xf010371a
f0101b62:	e8 24 e5 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *) PGSIZE, 0) == 0);
f0101b67:	6a 00                	push   $0x0
f0101b69:	68 00 10 00 00       	push   $0x1000
f0101b6e:	56                   	push   %esi
f0101b6f:	53                   	push   %ebx
f0101b70:	e8 31 f8 ff ff       	call   f01013a6 <page_insert>
f0101b75:	83 c4 10             	add    $0x10,%esp
f0101b78:	85 c0                	test   %eax,%eax
f0101b7a:	74 19                	je     f0101b95 <check_page+0x7db>
f0101b7c:	68 a0 36 10 f0       	push   $0xf01036a0
f0101b81:	68 40 37 10 f0       	push   $0xf0103740
f0101b86:	68 8c 03 00 00       	push   $0x38c
f0101b8b:	68 1a 37 10 f0       	push   $0xf010371a
f0101b90:	e8 f6 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
	assert(pp1->pp_link == NULL);
f0101b95:	83 3e 00             	cmpl   $0x0,(%esi)
f0101b98:	74 19                	je     f0101bb3 <check_page+0x7f9>
f0101b9a:	68 fc 38 10 f0       	push   $0xf01038fc
f0101b9f:	68 40 37 10 f0       	push   $0xf0103740
f0101ba4:	68 8e 03 00 00       	push   $0x38e
f0101ba9:	68 1a 37 10 f0       	push   $0xf010371a
f0101bae:	e8 d8 e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *) PGSIZE);
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101bb3:	83 7d d4 ff          	cmpl   $0xffffffff,-0x2c(%ebp)
f0101bb7:	74 19                	je     f0101bd2 <check_page+0x818>
f0101bb9:	68 d8 36 10 f0       	push   $0xf01036d8
f0101bbe:	68 40 37 10 f0       	push   $0xf0103740
f0101bc3:	68 93 03 00 00       	push   $0x393
f0101bc8:	68 1a 37 10 f0       	push   $0xf010371a
f0101bcd:	e8 b9 e4 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101bd2:	68 11 39 10 f0       	push   $0xf0103911
f0101bd7:	68 40 37 10 f0       	push   $0xf0103740
f0101bdc:	68 94 03 00 00       	push   $0x394
f0101be1:	68 1a 37 10 f0       	push   $0xf010371a
f0101be6:	e8 a0 e4 ff ff       	call   f010008b <_panic>

f0101beb <mem_init>:
{
f0101beb:	55                   	push   %ebp
f0101bec:	89 e5                	mov    %esp,%ebp
f0101bee:	53                   	push   %ebx
f0101bef:	83 ec 04             	sub    $0x4,%esp
	i386_detect_memory();
f0101bf2:	e8 d8 ed ff ff       	call   f01009cf <i386_detect_memory>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101bf7:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101bfc:	e8 35 ee ff ff       	call   f0100a36 <boot_alloc>
f0101c01:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f0101c06:	83 ec 04             	sub    $0x4,%esp
f0101c09:	68 00 10 00 00       	push   $0x1000
f0101c0e:	6a 00                	push   $0x0
f0101c10:	50                   	push   %eax
f0101c11:	e8 ac 0b 00 00       	call   f01027c2 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101c16:	8b 1d 48 69 11 f0    	mov    0xf0116948,%ebx
f0101c1c:	89 d9                	mov    %ebx,%ecx
f0101c1e:	ba 9b 00 00 00       	mov    $0x9b,%edx
f0101c23:	b8 1a 37 10 f0       	mov    $0xf010371a,%eax
f0101c28:	e8 18 ef ff ff       	call   f0100b45 <_paddr>
f0101c2d:	83 c8 05             	or     $0x5,%eax
f0101c30:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101c36:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101c3b:	c1 e0 03             	shl    $0x3,%eax
f0101c3e:	e8 f3 ed ff ff       	call   f0100a36 <boot_alloc>
f0101c43:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101c48:	83 c4 0c             	add    $0xc,%esp
f0101c4b:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101c51:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101c58:	52                   	push   %edx
f0101c59:	6a 00                	push   $0x0
f0101c5b:	50                   	push   %eax
f0101c5c:	e8 61 0b 00 00       	call   f01027c2 <memset>
	page_init();
f0101c61:	e8 84 f1 ff ff       	call   f0100dea <page_init>
	check_page_free_list(1);
f0101c66:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c6b:	e8 f7 ee ff ff       	call   f0100b67 <check_page_free_list>
	check_page_alloc();
f0101c70:	e8 72 f2 ff ff       	call   f0100ee7 <check_page_alloc>
	check_page();
f0101c75:	e8 40 f7 ff ff       	call   f01013ba <check_page>

f0101c7a <page_remove>:
{
f0101c7a:	55                   	push   %ebp
f0101c7b:	89 e5                	mov    %esp,%ebp
}
f0101c7d:	5d                   	pop    %ebp
f0101c7e:	c3                   	ret    

f0101c7f <tlb_invalidate>:
{
f0101c7f:	55                   	push   %ebp
f0101c80:	89 e5                	mov    %esp,%ebp
	invlpg(va);
f0101c82:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c85:	e8 03 ed ff ff       	call   f010098d <invlpg>
}
f0101c8a:	5d                   	pop    %ebp
f0101c8b:	c3                   	ret    

f0101c8c <inb>:
{
f0101c8c:	55                   	push   %ebp
f0101c8d:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101c8f:	89 c2                	mov    %eax,%edx
f0101c91:	ec                   	in     (%dx),%al
}
f0101c92:	5d                   	pop    %ebp
f0101c93:	c3                   	ret    

f0101c94 <outb>:
{
f0101c94:	55                   	push   %ebp
f0101c95:	89 e5                	mov    %esp,%ebp
f0101c97:	89 c1                	mov    %eax,%ecx
f0101c99:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101c9b:	89 ca                	mov    %ecx,%edx
f0101c9d:	ee                   	out    %al,(%dx)
}
f0101c9e:	5d                   	pop    %ebp
f0101c9f:	c3                   	ret    

f0101ca0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101ca0:	55                   	push   %ebp
f0101ca1:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0101ca3:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0101ca7:	b8 70 00 00 00       	mov    $0x70,%eax
f0101cac:	e8 e3 ff ff ff       	call   f0101c94 <outb>
	return inb(IO_RTC+1);
f0101cb1:	b8 71 00 00 00       	mov    $0x71,%eax
f0101cb6:	e8 d1 ff ff ff       	call   f0101c8c <inb>
f0101cbb:	0f b6 c0             	movzbl %al,%eax
}
f0101cbe:	5d                   	pop    %ebp
f0101cbf:	c3                   	ret    

f0101cc0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101cc0:	55                   	push   %ebp
f0101cc1:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0101cc3:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0101cc7:	b8 70 00 00 00       	mov    $0x70,%eax
f0101ccc:	e8 c3 ff ff ff       	call   f0101c94 <outb>
	outb(IO_RTC+1, datum);
f0101cd1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0101cd5:	b8 71 00 00 00       	mov    $0x71,%eax
f0101cda:	e8 b5 ff ff ff       	call   f0101c94 <outb>
}
f0101cdf:	5d                   	pop    %ebp
f0101ce0:	c3                   	ret    

f0101ce1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101ce1:	55                   	push   %ebp
f0101ce2:	89 e5                	mov    %esp,%ebp
f0101ce4:	53                   	push   %ebx
f0101ce5:	83 ec 10             	sub    $0x10,%esp
f0101ce8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0101ceb:	ff 75 08             	pushl  0x8(%ebp)
f0101cee:	e8 30 ea ff ff       	call   f0100723 <cputchar>
	(*cnt)++;
f0101cf3:	83 03 01             	addl   $0x1,(%ebx)
}
f0101cf6:	83 c4 10             	add    $0x10,%esp
f0101cf9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101cfc:	c9                   	leave  
f0101cfd:	c3                   	ret    

f0101cfe <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101cfe:	55                   	push   %ebp
f0101cff:	89 e5                	mov    %esp,%ebp
f0101d01:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101d04:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101d0b:	ff 75 0c             	pushl  0xc(%ebp)
f0101d0e:	ff 75 08             	pushl  0x8(%ebp)
f0101d11:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101d14:	50                   	push   %eax
f0101d15:	68 e1 1c 10 f0       	push   $0xf0101ce1
f0101d1a:	e8 84 04 00 00       	call   f01021a3 <vprintfmt>
	return cnt;
}
f0101d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d22:	c9                   	leave  
f0101d23:	c3                   	ret    

f0101d24 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101d24:	55                   	push   %ebp
f0101d25:	89 e5                	mov    %esp,%ebp
f0101d27:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101d2a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101d2d:	50                   	push   %eax
f0101d2e:	ff 75 08             	pushl  0x8(%ebp)
f0101d31:	e8 c8 ff ff ff       	call   f0101cfe <vcprintf>
	va_end(ap);

	return cnt;
}
f0101d36:	c9                   	leave  
f0101d37:	c3                   	ret    

f0101d38 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0101d38:	55                   	push   %ebp
f0101d39:	89 e5                	mov    %esp,%ebp
f0101d3b:	57                   	push   %edi
f0101d3c:	56                   	push   %esi
f0101d3d:	53                   	push   %ebx
f0101d3e:	83 ec 14             	sub    $0x14,%esp
f0101d41:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d44:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101d47:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101d4a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101d4d:	8b 32                	mov    (%edx),%esi
f0101d4f:	8b 01                	mov    (%ecx),%eax
f0101d51:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101d54:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101d5b:	eb 2f                	jmp    f0101d8c <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0101d5d:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0101d60:	39 c6                	cmp    %eax,%esi
f0101d62:	7f 49                	jg     f0101dad <stab_binsearch+0x75>
f0101d64:	0f b6 0a             	movzbl (%edx),%ecx
f0101d67:	83 ea 0c             	sub    $0xc,%edx
f0101d6a:	39 f9                	cmp    %edi,%ecx
f0101d6c:	75 ef                	jne    f0101d5d <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101d6e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101d71:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101d74:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101d78:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101d7b:	73 35                	jae    f0101db2 <stab_binsearch+0x7a>
			*region_left = m;
f0101d7d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101d80:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0101d82:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0101d85:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0101d8c:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101d8f:	7f 4e                	jg     f0101ddf <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0101d91:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d94:	01 f0                	add    %esi,%eax
f0101d96:	89 c3                	mov    %eax,%ebx
f0101d98:	c1 eb 1f             	shr    $0x1f,%ebx
f0101d9b:	01 c3                	add    %eax,%ebx
f0101d9d:	d1 fb                	sar    %ebx
f0101d9f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101da2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101da5:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0101da9:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0101dab:	eb b3                	jmp    f0101d60 <stab_binsearch+0x28>
			l = true_m + 1;
f0101dad:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0101db0:	eb da                	jmp    f0101d8c <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0101db2:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101db5:	76 14                	jbe    f0101dcb <stab_binsearch+0x93>
			*region_right = m - 1;
f0101db7:	83 e8 01             	sub    $0x1,%eax
f0101dba:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101dbd:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101dc0:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0101dc2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101dc9:	eb c1                	jmp    f0101d8c <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101dcb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101dce:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101dd0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101dd4:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0101dd6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101ddd:	eb ad                	jmp    f0101d8c <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0101ddf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101de3:	74 16                	je     f0101dfb <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101de5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101de8:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101dea:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101ded:	8b 0e                	mov    (%esi),%ecx
f0101def:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101df2:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101df5:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0101df9:	eb 12                	jmp    f0101e0d <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0101dfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101dfe:	8b 00                	mov    (%eax),%eax
f0101e00:	83 e8 01             	sub    $0x1,%eax
f0101e03:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101e06:	89 07                	mov    %eax,(%edi)
f0101e08:	eb 16                	jmp    f0101e20 <stab_binsearch+0xe8>
		     l--)
f0101e0a:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0101e0d:	39 c1                	cmp    %eax,%ecx
f0101e0f:	7d 0a                	jge    f0101e1b <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0101e11:	0f b6 1a             	movzbl (%edx),%ebx
f0101e14:	83 ea 0c             	sub    $0xc,%edx
f0101e17:	39 fb                	cmp    %edi,%ebx
f0101e19:	75 ef                	jne    f0101e0a <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0101e1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101e1e:	89 07                	mov    %eax,(%edi)
	}
}
f0101e20:	83 c4 14             	add    $0x14,%esp
f0101e23:	5b                   	pop    %ebx
f0101e24:	5e                   	pop    %esi
f0101e25:	5f                   	pop    %edi
f0101e26:	5d                   	pop    %ebp
f0101e27:	c3                   	ret    

f0101e28 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101e28:	55                   	push   %ebp
f0101e29:	89 e5                	mov    %esp,%ebp
f0101e2b:	57                   	push   %edi
f0101e2c:	56                   	push   %esi
f0101e2d:	53                   	push   %ebx
f0101e2e:	83 ec 3c             	sub    $0x3c,%esp
f0101e31:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e34:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101e37:	c7 03 22 39 10 f0    	movl   $0xf0103922,(%ebx)
	info->eip_line = 0;
f0101e3d:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101e44:	c7 43 08 22 39 10 f0 	movl   $0xf0103922,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101e4b:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101e52:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101e55:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101e5c:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101e62:	0f 86 22 01 00 00    	jbe    f0101f8a <debuginfo_eip+0x162>
		// Can't search for user-level addresses yet!
		panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101e68:	b8 ef b0 10 f0       	mov    $0xf010b0ef,%eax
f0101e6d:	3d 29 91 10 f0       	cmp    $0xf0109129,%eax
f0101e72:	0f 86 b4 01 00 00    	jbe    f010202c <debuginfo_eip+0x204>
f0101e78:	80 3d ee b0 10 f0 00 	cmpb   $0x0,0xf010b0ee
f0101e7f:	0f 85 ae 01 00 00    	jne    f0102033 <debuginfo_eip+0x20b>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101e85:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101e8c:	b8 28 91 10 f0       	mov    $0xf0109128,%eax
f0101e91:	2d 48 3b 10 f0       	sub    $0xf0103b48,%eax
f0101e96:	c1 f8 02             	sar    $0x2,%eax
f0101e99:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101e9f:	83 e8 01             	sub    $0x1,%eax
f0101ea2:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101ea5:	83 ec 08             	sub    $0x8,%esp
f0101ea8:	56                   	push   %esi
f0101ea9:	6a 64                	push   $0x64
f0101eab:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101eae:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101eb1:	b8 48 3b 10 f0       	mov    $0xf0103b48,%eax
f0101eb6:	e8 7d fe ff ff       	call   f0101d38 <stab_binsearch>
	if (lfile == 0)
f0101ebb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ebe:	83 c4 10             	add    $0x10,%esp
f0101ec1:	85 c0                	test   %eax,%eax
f0101ec3:	0f 84 71 01 00 00    	je     f010203a <debuginfo_eip+0x212>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101ec9:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101ecc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ecf:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101ed2:	83 ec 08             	sub    $0x8,%esp
f0101ed5:	56                   	push   %esi
f0101ed6:	6a 24                	push   $0x24
f0101ed8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101edb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101ede:	b8 48 3b 10 f0       	mov    $0xf0103b48,%eax
f0101ee3:	e8 50 fe ff ff       	call   f0101d38 <stab_binsearch>

	if (lfun <= rfun) {
f0101ee8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101eeb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101eee:	83 c4 10             	add    $0x10,%esp
f0101ef1:	39 d0                	cmp    %edx,%eax
f0101ef3:	0f 8f a8 00 00 00    	jg     f0101fa1 <debuginfo_eip+0x179>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101ef9:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0101efc:	c1 e1 02             	shl    $0x2,%ecx
f0101eff:	8d b9 48 3b 10 f0    	lea    -0xfefc4b8(%ecx),%edi
f0101f05:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101f08:	8b b9 48 3b 10 f0    	mov    -0xfefc4b8(%ecx),%edi
f0101f0e:	b9 ef b0 10 f0       	mov    $0xf010b0ef,%ecx
f0101f13:	81 e9 29 91 10 f0    	sub    $0xf0109129,%ecx
f0101f19:	39 cf                	cmp    %ecx,%edi
f0101f1b:	73 09                	jae    f0101f26 <debuginfo_eip+0xfe>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101f1d:	81 c7 29 91 10 f0    	add    $0xf0109129,%edi
f0101f23:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101f26:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101f29:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101f2c:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101f2f:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101f31:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101f34:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101f37:	83 ec 08             	sub    $0x8,%esp
f0101f3a:	6a 3a                	push   $0x3a
f0101f3c:	ff 73 08             	pushl  0x8(%ebx)
f0101f3f:	e8 62 08 00 00       	call   f01027a6 <strfind>
f0101f44:	2b 43 08             	sub    0x8(%ebx),%eax
f0101f47:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101f4a:	83 c4 08             	add    $0x8,%esp
f0101f4d:	56                   	push   %esi
f0101f4e:	6a 44                	push   $0x44
f0101f50:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101f53:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101f56:	b8 48 3b 10 f0       	mov    $0xf0103b48,%eax
f0101f5b:	e8 d8 fd ff ff       	call   f0101d38 <stab_binsearch>
	if (lline <= rline) {
f0101f60:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f63:	83 c4 10             	add    $0x10,%esp
f0101f66:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0101f69:	7f 0e                	jg     f0101f79 <debuginfo_eip+0x151>
		info->eip_line = stabs[lline].n_desc;
f0101f6b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101f6e:	0f b7 14 95 4e 3b 10 	movzwl -0xfefc4b2(,%edx,4),%edx
f0101f75:	f0 
f0101f76:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0101f79:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101f7c:	89 c2                	mov    %eax,%edx
f0101f7e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0101f81:	8d 04 85 4c 3b 10 f0 	lea    -0xfefc4b4(,%eax,4),%eax
f0101f88:	eb 2e                	jmp    f0101fb8 <debuginfo_eip+0x190>
		panic("User address");
f0101f8a:	83 ec 04             	sub    $0x4,%esp
f0101f8d:	68 2c 39 10 f0       	push   $0xf010392c
f0101f92:	68 82 00 00 00       	push   $0x82
f0101f97:	68 39 39 10 f0       	push   $0xf0103939
f0101f9c:	e8 ea e0 ff ff       	call   f010008b <_panic>
		info->eip_fn_addr = addr;
f0101fa1:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101fa4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101fa7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101faa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101fad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fb0:	eb 85                	jmp    f0101f37 <debuginfo_eip+0x10f>
f0101fb2:	83 ea 01             	sub    $0x1,%edx
f0101fb5:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0101fb8:	39 d7                	cmp    %edx,%edi
f0101fba:	7f 33                	jg     f0101fef <debuginfo_eip+0x1c7>
f0101fbc:	0f b6 08             	movzbl (%eax),%ecx
f0101fbf:	80 f9 84             	cmp    $0x84,%cl
f0101fc2:	74 0b                	je     f0101fcf <debuginfo_eip+0x1a7>
f0101fc4:	80 f9 64             	cmp    $0x64,%cl
f0101fc7:	75 e9                	jne    f0101fb2 <debuginfo_eip+0x18a>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101fc9:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0101fcd:	74 e3                	je     f0101fb2 <debuginfo_eip+0x18a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101fcf:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0101fd2:	8b 14 85 48 3b 10 f0 	mov    -0xfefc4b8(,%eax,4),%edx
f0101fd9:	b8 ef b0 10 f0       	mov    $0xf010b0ef,%eax
f0101fde:	2d 29 91 10 f0       	sub    $0xf0109129,%eax
f0101fe3:	39 c2                	cmp    %eax,%edx
f0101fe5:	73 08                	jae    f0101fef <debuginfo_eip+0x1c7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101fe7:	81 c2 29 91 10 f0    	add    $0xf0109129,%edx
f0101fed:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101fef:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101ff2:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101ff5:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0101ffa:	39 f2                	cmp    %esi,%edx
f0101ffc:	7d 48                	jge    f0102046 <debuginfo_eip+0x21e>
		for (lline = lfun + 1;
f0101ffe:	83 c2 01             	add    $0x1,%edx
f0102001:	89 d0                	mov    %edx,%eax
f0102003:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102006:	8d 14 95 4c 3b 10 f0 	lea    -0xfefc4b4(,%edx,4),%edx
f010200d:	eb 04                	jmp    f0102013 <debuginfo_eip+0x1eb>
			info->eip_fn_narg++;
f010200f:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0102013:	39 c6                	cmp    %eax,%esi
f0102015:	7e 2a                	jle    f0102041 <debuginfo_eip+0x219>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102017:	0f b6 0a             	movzbl (%edx),%ecx
f010201a:	83 c0 01             	add    $0x1,%eax
f010201d:	83 c2 0c             	add    $0xc,%edx
f0102020:	80 f9 a0             	cmp    $0xa0,%cl
f0102023:	74 ea                	je     f010200f <debuginfo_eip+0x1e7>
	return 0;
f0102025:	b8 00 00 00 00       	mov    $0x0,%eax
f010202a:	eb 1a                	jmp    f0102046 <debuginfo_eip+0x21e>
		return -1;
f010202c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102031:	eb 13                	jmp    f0102046 <debuginfo_eip+0x21e>
f0102033:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102038:	eb 0c                	jmp    f0102046 <debuginfo_eip+0x21e>
		return -1;
f010203a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010203f:	eb 05                	jmp    f0102046 <debuginfo_eip+0x21e>
	return 0;
f0102041:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102046:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102049:	5b                   	pop    %ebx
f010204a:	5e                   	pop    %esi
f010204b:	5f                   	pop    %edi
f010204c:	5d                   	pop    %ebp
f010204d:	c3                   	ret    

f010204e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010204e:	55                   	push   %ebp
f010204f:	89 e5                	mov    %esp,%ebp
f0102051:	57                   	push   %edi
f0102052:	56                   	push   %esi
f0102053:	53                   	push   %ebx
f0102054:	83 ec 1c             	sub    $0x1c,%esp
f0102057:	89 c7                	mov    %eax,%edi
f0102059:	89 d6                	mov    %edx,%esi
f010205b:	8b 45 08             	mov    0x8(%ebp),%eax
f010205e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102061:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102064:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102067:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010206a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010206f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102072:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102075:	39 d3                	cmp    %edx,%ebx
f0102077:	72 05                	jb     f010207e <printnum+0x30>
f0102079:	39 45 10             	cmp    %eax,0x10(%ebp)
f010207c:	77 7a                	ja     f01020f8 <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010207e:	83 ec 0c             	sub    $0xc,%esp
f0102081:	ff 75 18             	pushl  0x18(%ebp)
f0102084:	8b 45 14             	mov    0x14(%ebp),%eax
f0102087:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010208a:	53                   	push   %ebx
f010208b:	ff 75 10             	pushl  0x10(%ebp)
f010208e:	83 ec 08             	sub    $0x8,%esp
f0102091:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102094:	ff 75 e0             	pushl  -0x20(%ebp)
f0102097:	ff 75 dc             	pushl  -0x24(%ebp)
f010209a:	ff 75 d8             	pushl  -0x28(%ebp)
f010209d:	e8 1e 09 00 00       	call   f01029c0 <__udivdi3>
f01020a2:	83 c4 18             	add    $0x18,%esp
f01020a5:	52                   	push   %edx
f01020a6:	50                   	push   %eax
f01020a7:	89 f2                	mov    %esi,%edx
f01020a9:	89 f8                	mov    %edi,%eax
f01020ab:	e8 9e ff ff ff       	call   f010204e <printnum>
f01020b0:	83 c4 20             	add    $0x20,%esp
f01020b3:	eb 13                	jmp    f01020c8 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01020b5:	83 ec 08             	sub    $0x8,%esp
f01020b8:	56                   	push   %esi
f01020b9:	ff 75 18             	pushl  0x18(%ebp)
f01020bc:	ff d7                	call   *%edi
f01020be:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01020c1:	83 eb 01             	sub    $0x1,%ebx
f01020c4:	85 db                	test   %ebx,%ebx
f01020c6:	7f ed                	jg     f01020b5 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01020c8:	83 ec 08             	sub    $0x8,%esp
f01020cb:	56                   	push   %esi
f01020cc:	83 ec 04             	sub    $0x4,%esp
f01020cf:	ff 75 e4             	pushl  -0x1c(%ebp)
f01020d2:	ff 75 e0             	pushl  -0x20(%ebp)
f01020d5:	ff 75 dc             	pushl  -0x24(%ebp)
f01020d8:	ff 75 d8             	pushl  -0x28(%ebp)
f01020db:	e8 00 0a 00 00       	call   f0102ae0 <__umoddi3>
f01020e0:	83 c4 14             	add    $0x14,%esp
f01020e3:	0f be 80 47 39 10 f0 	movsbl -0xfefc6b9(%eax),%eax
f01020ea:	50                   	push   %eax
f01020eb:	ff d7                	call   *%edi
}
f01020ed:	83 c4 10             	add    $0x10,%esp
f01020f0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01020f3:	5b                   	pop    %ebx
f01020f4:	5e                   	pop    %esi
f01020f5:	5f                   	pop    %edi
f01020f6:	5d                   	pop    %ebp
f01020f7:	c3                   	ret    
f01020f8:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01020fb:	eb c4                	jmp    f01020c1 <printnum+0x73>

f01020fd <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01020fd:	55                   	push   %ebp
f01020fe:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102100:	83 fa 01             	cmp    $0x1,%edx
f0102103:	7e 0e                	jle    f0102113 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102105:	8b 10                	mov    (%eax),%edx
f0102107:	8d 4a 08             	lea    0x8(%edx),%ecx
f010210a:	89 08                	mov    %ecx,(%eax)
f010210c:	8b 02                	mov    (%edx),%eax
f010210e:	8b 52 04             	mov    0x4(%edx),%edx
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
}
f0102111:	5d                   	pop    %ebp
f0102112:	c3                   	ret    
	else if (lflag)
f0102113:	85 d2                	test   %edx,%edx
f0102115:	75 10                	jne    f0102127 <getuint+0x2a>
		return va_arg(*ap, unsigned int);
f0102117:	8b 10                	mov    (%eax),%edx
f0102119:	8d 4a 04             	lea    0x4(%edx),%ecx
f010211c:	89 08                	mov    %ecx,(%eax)
f010211e:	8b 02                	mov    (%edx),%eax
f0102120:	ba 00 00 00 00       	mov    $0x0,%edx
f0102125:	eb ea                	jmp    f0102111 <getuint+0x14>
		return va_arg(*ap, unsigned long);
f0102127:	8b 10                	mov    (%eax),%edx
f0102129:	8d 4a 04             	lea    0x4(%edx),%ecx
f010212c:	89 08                	mov    %ecx,(%eax)
f010212e:	8b 02                	mov    (%edx),%eax
f0102130:	ba 00 00 00 00       	mov    $0x0,%edx
f0102135:	eb da                	jmp    f0102111 <getuint+0x14>

f0102137 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102137:	55                   	push   %ebp
f0102138:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010213a:	83 fa 01             	cmp    $0x1,%edx
f010213d:	7e 0e                	jle    f010214d <getint+0x16>
		return va_arg(*ap, long long);
f010213f:	8b 10                	mov    (%eax),%edx
f0102141:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102144:	89 08                	mov    %ecx,(%eax)
f0102146:	8b 02                	mov    (%edx),%eax
f0102148:	8b 52 04             	mov    0x4(%edx),%edx
	else if (lflag)
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
}
f010214b:	5d                   	pop    %ebp
f010214c:	c3                   	ret    
	else if (lflag)
f010214d:	85 d2                	test   %edx,%edx
f010214f:	75 0c                	jne    f010215d <getint+0x26>
		return va_arg(*ap, int);
f0102151:	8b 10                	mov    (%eax),%edx
f0102153:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102156:	89 08                	mov    %ecx,(%eax)
f0102158:	8b 02                	mov    (%edx),%eax
f010215a:	99                   	cltd   
f010215b:	eb ee                	jmp    f010214b <getint+0x14>
		return va_arg(*ap, long);
f010215d:	8b 10                	mov    (%eax),%edx
f010215f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102162:	89 08                	mov    %ecx,(%eax)
f0102164:	8b 02                	mov    (%edx),%eax
f0102166:	99                   	cltd   
f0102167:	eb e2                	jmp    f010214b <getint+0x14>

f0102169 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102169:	55                   	push   %ebp
f010216a:	89 e5                	mov    %esp,%ebp
f010216c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010216f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102173:	8b 10                	mov    (%eax),%edx
f0102175:	3b 50 04             	cmp    0x4(%eax),%edx
f0102178:	73 0a                	jae    f0102184 <sprintputch+0x1b>
		*b->buf++ = ch;
f010217a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010217d:	89 08                	mov    %ecx,(%eax)
f010217f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102182:	88 02                	mov    %al,(%edx)
}
f0102184:	5d                   	pop    %ebp
f0102185:	c3                   	ret    

f0102186 <printfmt>:
{
f0102186:	55                   	push   %ebp
f0102187:	89 e5                	mov    %esp,%ebp
f0102189:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010218c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010218f:	50                   	push   %eax
f0102190:	ff 75 10             	pushl  0x10(%ebp)
f0102193:	ff 75 0c             	pushl  0xc(%ebp)
f0102196:	ff 75 08             	pushl  0x8(%ebp)
f0102199:	e8 05 00 00 00       	call   f01021a3 <vprintfmt>
}
f010219e:	83 c4 10             	add    $0x10,%esp
f01021a1:	c9                   	leave  
f01021a2:	c3                   	ret    

f01021a3 <vprintfmt>:
{
f01021a3:	55                   	push   %ebp
f01021a4:	89 e5                	mov    %esp,%ebp
f01021a6:	57                   	push   %edi
f01021a7:	56                   	push   %esi
f01021a8:	53                   	push   %ebx
f01021a9:	83 ec 2c             	sub    $0x2c,%esp
f01021ac:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01021af:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021b2:	89 f7                	mov    %esi,%edi
f01021b4:	89 de                	mov    %ebx,%esi
f01021b6:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01021b9:	e9 9e 02 00 00       	jmp    f010245c <vprintfmt+0x2b9>
		padc = ' ';
f01021be:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01021c2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01021c9:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01021d0:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01021d7:	ba 00 00 00 00       	mov    $0x0,%edx
		switch (ch = *(unsigned char *) fmt++) {
f01021dc:	8d 43 01             	lea    0x1(%ebx),%eax
f01021df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021e2:	0f b6 0b             	movzbl (%ebx),%ecx
f01021e5:	8d 41 dd             	lea    -0x23(%ecx),%eax
f01021e8:	3c 55                	cmp    $0x55,%al
f01021ea:	0f 87 e8 02 00 00    	ja     f01024d8 <vprintfmt+0x335>
f01021f0:	0f b6 c0             	movzbl %al,%eax
f01021f3:	ff 24 85 c4 39 10 f0 	jmp    *-0xfefc63c(,%eax,4)
f01021fa:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f01021fd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0102201:	eb d9                	jmp    f01021dc <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0102203:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '0';
f0102206:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010220a:	eb d0                	jmp    f01021dc <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010220c:	0f b6 c9             	movzbl %cl,%ecx
f010220f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0102212:	b8 00 00 00 00       	mov    $0x0,%eax
f0102217:	89 55 e4             	mov    %edx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f010221a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010221d:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102221:	0f be 0b             	movsbl (%ebx),%ecx
				if (ch < '0' || ch > '9')
f0102224:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102227:	83 fa 09             	cmp    $0x9,%edx
f010222a:	77 52                	ja     f010227e <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f010222c:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f010222f:	eb e9                	jmp    f010221a <vprintfmt+0x77>
			precision = va_arg(ap, int);
f0102231:	8b 45 14             	mov    0x14(%ebp),%eax
f0102234:	8d 48 04             	lea    0x4(%eax),%ecx
f0102237:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010223a:	8b 00                	mov    (%eax),%eax
f010223c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010223f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0102242:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102246:	79 94                	jns    f01021dc <vprintfmt+0x39>
				width = precision, precision = -1;
f0102248:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010224b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010224e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102255:	eb 85                	jmp    f01021dc <vprintfmt+0x39>
f0102257:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010225a:	85 c0                	test   %eax,%eax
f010225c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102261:	0f 49 c8             	cmovns %eax,%ecx
f0102264:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0102267:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010226a:	e9 6d ff ff ff       	jmp    f01021dc <vprintfmt+0x39>
f010226f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0102272:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102279:	e9 5e ff ff ff       	jmp    f01021dc <vprintfmt+0x39>
f010227e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102281:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102284:	eb bc                	jmp    f0102242 <vprintfmt+0x9f>
			lflag++;
f0102286:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f0102289:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f010228c:	e9 4b ff ff ff       	jmp    f01021dc <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f0102291:	8b 45 14             	mov    0x14(%ebp),%eax
f0102294:	8d 50 04             	lea    0x4(%eax),%edx
f0102297:	89 55 14             	mov    %edx,0x14(%ebp)
f010229a:	83 ec 08             	sub    $0x8,%esp
f010229d:	57                   	push   %edi
f010229e:	ff 30                	pushl  (%eax)
f01022a0:	ff d6                	call   *%esi
			break;
f01022a2:	83 c4 10             	add    $0x10,%esp
f01022a5:	e9 af 01 00 00       	jmp    f0102459 <vprintfmt+0x2b6>
			err = va_arg(ap, int);
f01022aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01022ad:	8d 50 04             	lea    0x4(%eax),%edx
f01022b0:	89 55 14             	mov    %edx,0x14(%ebp)
f01022b3:	8b 00                	mov    (%eax),%eax
f01022b5:	99                   	cltd   
f01022b6:	31 d0                	xor    %edx,%eax
f01022b8:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01022ba:	83 f8 06             	cmp    $0x6,%eax
f01022bd:	7f 20                	jg     f01022df <vprintfmt+0x13c>
f01022bf:	8b 14 85 1c 3b 10 f0 	mov    -0xfefc4e4(,%eax,4),%edx
f01022c6:	85 d2                	test   %edx,%edx
f01022c8:	74 15                	je     f01022df <vprintfmt+0x13c>
				printfmt(putch, putdat, "%s", p);
f01022ca:	52                   	push   %edx
f01022cb:	68 52 37 10 f0       	push   $0xf0103752
f01022d0:	57                   	push   %edi
f01022d1:	56                   	push   %esi
f01022d2:	e8 af fe ff ff       	call   f0102186 <printfmt>
f01022d7:	83 c4 10             	add    $0x10,%esp
f01022da:	e9 7a 01 00 00       	jmp    f0102459 <vprintfmt+0x2b6>
				printfmt(putch, putdat, "error %d", err);
f01022df:	50                   	push   %eax
f01022e0:	68 5f 39 10 f0       	push   $0xf010395f
f01022e5:	57                   	push   %edi
f01022e6:	56                   	push   %esi
f01022e7:	e8 9a fe ff ff       	call   f0102186 <printfmt>
f01022ec:	83 c4 10             	add    $0x10,%esp
f01022ef:	e9 65 01 00 00       	jmp    f0102459 <vprintfmt+0x2b6>
			if ((p = va_arg(ap, char *)) == NULL)
f01022f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01022f7:	8d 50 04             	lea    0x4(%eax),%edx
f01022fa:	89 55 14             	mov    %edx,0x14(%ebp)
f01022fd:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01022ff:	85 db                	test   %ebx,%ebx
f0102301:	b8 58 39 10 f0       	mov    $0xf0103958,%eax
f0102306:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f0102309:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010230d:	0f 8e bd 00 00 00    	jle    f01023d0 <vprintfmt+0x22d>
f0102313:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102317:	75 0e                	jne    f0102327 <vprintfmt+0x184>
f0102319:	89 75 08             	mov    %esi,0x8(%ebp)
f010231c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010231f:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0102322:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102325:	eb 6d                	jmp    f0102394 <vprintfmt+0x1f1>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102327:	83 ec 08             	sub    $0x8,%esp
f010232a:	ff 75 d0             	pushl  -0x30(%ebp)
f010232d:	53                   	push   %ebx
f010232e:	e8 2f 03 00 00       	call   f0102662 <strnlen>
f0102333:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102336:	29 c1                	sub    %eax,%ecx
f0102338:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010233b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010233e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102342:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102345:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0102348:	89 cb                	mov    %ecx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f010234a:	eb 0f                	jmp    f010235b <vprintfmt+0x1b8>
					putch(padc, putdat);
f010234c:	83 ec 08             	sub    $0x8,%esp
f010234f:	57                   	push   %edi
f0102350:	ff 75 e0             	pushl  -0x20(%ebp)
f0102353:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0102355:	83 eb 01             	sub    $0x1,%ebx
f0102358:	83 c4 10             	add    $0x10,%esp
f010235b:	85 db                	test   %ebx,%ebx
f010235d:	7f ed                	jg     f010234c <vprintfmt+0x1a9>
f010235f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102362:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102365:	85 c9                	test   %ecx,%ecx
f0102367:	b8 00 00 00 00       	mov    $0x0,%eax
f010236c:	0f 49 c1             	cmovns %ecx,%eax
f010236f:	29 c1                	sub    %eax,%ecx
f0102371:	89 75 08             	mov    %esi,0x8(%ebp)
f0102374:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102377:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010237a:	89 cf                	mov    %ecx,%edi
f010237c:	eb 16                	jmp    f0102394 <vprintfmt+0x1f1>
				if (altflag && (ch < ' ' || ch > '~'))
f010237e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102382:	75 31                	jne    f01023b5 <vprintfmt+0x212>
					putch(ch, putdat);
f0102384:	83 ec 08             	sub    $0x8,%esp
f0102387:	ff 75 0c             	pushl  0xc(%ebp)
f010238a:	50                   	push   %eax
f010238b:	ff 55 08             	call   *0x8(%ebp)
f010238e:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102391:	83 ef 01             	sub    $0x1,%edi
f0102394:	83 c3 01             	add    $0x1,%ebx
f0102397:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f010239b:	0f be c2             	movsbl %dl,%eax
f010239e:	85 c0                	test   %eax,%eax
f01023a0:	74 50                	je     f01023f2 <vprintfmt+0x24f>
f01023a2:	85 f6                	test   %esi,%esi
f01023a4:	78 d8                	js     f010237e <vprintfmt+0x1db>
f01023a6:	83 ee 01             	sub    $0x1,%esi
f01023a9:	79 d3                	jns    f010237e <vprintfmt+0x1db>
f01023ab:	89 fb                	mov    %edi,%ebx
f01023ad:	8b 75 08             	mov    0x8(%ebp),%esi
f01023b0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01023b3:	eb 37                	jmp    f01023ec <vprintfmt+0x249>
				if (altflag && (ch < ' ' || ch > '~'))
f01023b5:	0f be d2             	movsbl %dl,%edx
f01023b8:	83 ea 20             	sub    $0x20,%edx
f01023bb:	83 fa 5e             	cmp    $0x5e,%edx
f01023be:	76 c4                	jbe    f0102384 <vprintfmt+0x1e1>
					putch('?', putdat);
f01023c0:	83 ec 08             	sub    $0x8,%esp
f01023c3:	ff 75 0c             	pushl  0xc(%ebp)
f01023c6:	6a 3f                	push   $0x3f
f01023c8:	ff 55 08             	call   *0x8(%ebp)
f01023cb:	83 c4 10             	add    $0x10,%esp
f01023ce:	eb c1                	jmp    f0102391 <vprintfmt+0x1ee>
f01023d0:	89 75 08             	mov    %esi,0x8(%ebp)
f01023d3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01023d6:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01023d9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01023dc:	eb b6                	jmp    f0102394 <vprintfmt+0x1f1>
				putch(' ', putdat);
f01023de:	83 ec 08             	sub    $0x8,%esp
f01023e1:	57                   	push   %edi
f01023e2:	6a 20                	push   $0x20
f01023e4:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01023e6:	83 eb 01             	sub    $0x1,%ebx
f01023e9:	83 c4 10             	add    $0x10,%esp
f01023ec:	85 db                	test   %ebx,%ebx
f01023ee:	7f ee                	jg     f01023de <vprintfmt+0x23b>
f01023f0:	eb 67                	jmp    f0102459 <vprintfmt+0x2b6>
f01023f2:	89 fb                	mov    %edi,%ebx
f01023f4:	8b 75 08             	mov    0x8(%ebp),%esi
f01023f7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01023fa:	eb f0                	jmp    f01023ec <vprintfmt+0x249>
			num = getint(&ap, lflag);
f01023fc:	8d 45 14             	lea    0x14(%ebp),%eax
f01023ff:	e8 33 fd ff ff       	call   f0102137 <getint>
f0102404:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102407:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 10;
f010240a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f010240f:	85 d2                	test   %edx,%edx
f0102411:	79 2c                	jns    f010243f <vprintfmt+0x29c>
				putch('-', putdat);
f0102413:	83 ec 08             	sub    $0x8,%esp
f0102416:	57                   	push   %edi
f0102417:	6a 2d                	push   $0x2d
f0102419:	ff d6                	call   *%esi
				num = -(long long) num;
f010241b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010241e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102421:	f7 d8                	neg    %eax
f0102423:	83 d2 00             	adc    $0x0,%edx
f0102426:	f7 da                	neg    %edx
f0102428:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010242b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102430:	eb 0d                	jmp    f010243f <vprintfmt+0x29c>
			num = getuint(&ap, lflag);
f0102432:	8d 45 14             	lea    0x14(%ebp),%eax
f0102435:	e8 c3 fc ff ff       	call   f01020fd <getuint>
			base = 10;
f010243a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			printnum(putch, putdat, num, base, width, padc);
f010243f:	83 ec 0c             	sub    $0xc,%esp
f0102442:	0f be 5d d4          	movsbl -0x2c(%ebp),%ebx
f0102446:	53                   	push   %ebx
f0102447:	ff 75 e0             	pushl  -0x20(%ebp)
f010244a:	51                   	push   %ecx
f010244b:	52                   	push   %edx
f010244c:	50                   	push   %eax
f010244d:	89 fa                	mov    %edi,%edx
f010244f:	89 f0                	mov    %esi,%eax
f0102451:	e8 f8 fb ff ff       	call   f010204e <printnum>
			break;
f0102456:	83 c4 20             	add    $0x20,%esp
{
f0102459:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010245c:	83 c3 01             	add    $0x1,%ebx
f010245f:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0102463:	83 f8 25             	cmp    $0x25,%eax
f0102466:	0f 84 52 fd ff ff    	je     f01021be <vprintfmt+0x1b>
			if (ch == '\0')
f010246c:	85 c0                	test   %eax,%eax
f010246e:	0f 84 84 00 00 00    	je     f01024f8 <vprintfmt+0x355>
			putch(ch, putdat);
f0102474:	83 ec 08             	sub    $0x8,%esp
f0102477:	57                   	push   %edi
f0102478:	50                   	push   %eax
f0102479:	ff d6                	call   *%esi
f010247b:	83 c4 10             	add    $0x10,%esp
f010247e:	eb dc                	jmp    f010245c <vprintfmt+0x2b9>
			num = getuint(&ap, lflag);
f0102480:	8d 45 14             	lea    0x14(%ebp),%eax
f0102483:	e8 75 fc ff ff       	call   f01020fd <getuint>
			base = 8;
f0102488:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010248d:	eb b0                	jmp    f010243f <vprintfmt+0x29c>
			putch('0', putdat);
f010248f:	83 ec 08             	sub    $0x8,%esp
f0102492:	57                   	push   %edi
f0102493:	6a 30                	push   $0x30
f0102495:	ff d6                	call   *%esi
			putch('x', putdat);
f0102497:	83 c4 08             	add    $0x8,%esp
f010249a:	57                   	push   %edi
f010249b:	6a 78                	push   $0x78
f010249d:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f010249f:	8b 45 14             	mov    0x14(%ebp),%eax
f01024a2:	8d 50 04             	lea    0x4(%eax),%edx
f01024a5:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01024a8:	8b 00                	mov    (%eax),%eax
f01024aa:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;
f01024af:	83 c4 10             	add    $0x10,%esp
			base = 16;
f01024b2:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01024b7:	eb 86                	jmp    f010243f <vprintfmt+0x29c>
			num = getuint(&ap, lflag);
f01024b9:	8d 45 14             	lea    0x14(%ebp),%eax
f01024bc:	e8 3c fc ff ff       	call   f01020fd <getuint>
			base = 16;
f01024c1:	b9 10 00 00 00       	mov    $0x10,%ecx
f01024c6:	e9 74 ff ff ff       	jmp    f010243f <vprintfmt+0x29c>
			putch(ch, putdat);
f01024cb:	83 ec 08             	sub    $0x8,%esp
f01024ce:	57                   	push   %edi
f01024cf:	6a 25                	push   $0x25
f01024d1:	ff d6                	call   *%esi
			break;
f01024d3:	83 c4 10             	add    $0x10,%esp
f01024d6:	eb 81                	jmp    f0102459 <vprintfmt+0x2b6>
			putch('%', putdat);
f01024d8:	83 ec 08             	sub    $0x8,%esp
f01024db:	57                   	push   %edi
f01024dc:	6a 25                	push   $0x25
f01024de:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01024e0:	83 c4 10             	add    $0x10,%esp
f01024e3:	89 d8                	mov    %ebx,%eax
f01024e5:	eb 03                	jmp    f01024ea <vprintfmt+0x347>
f01024e7:	83 e8 01             	sub    $0x1,%eax
f01024ea:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01024ee:	75 f7                	jne    f01024e7 <vprintfmt+0x344>
f01024f0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01024f3:	e9 61 ff ff ff       	jmp    f0102459 <vprintfmt+0x2b6>
}
f01024f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01024fb:	5b                   	pop    %ebx
f01024fc:	5e                   	pop    %esi
f01024fd:	5f                   	pop    %edi
f01024fe:	5d                   	pop    %ebp
f01024ff:	c3                   	ret    

f0102500 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102500:	55                   	push   %ebp
f0102501:	89 e5                	mov    %esp,%ebp
f0102503:	83 ec 18             	sub    $0x18,%esp
f0102506:	8b 45 08             	mov    0x8(%ebp),%eax
f0102509:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010250c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010250f:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102513:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102516:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010251d:	85 c0                	test   %eax,%eax
f010251f:	74 26                	je     f0102547 <vsnprintf+0x47>
f0102521:	85 d2                	test   %edx,%edx
f0102523:	7e 22                	jle    f0102547 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102525:	ff 75 14             	pushl  0x14(%ebp)
f0102528:	ff 75 10             	pushl  0x10(%ebp)
f010252b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010252e:	50                   	push   %eax
f010252f:	68 69 21 10 f0       	push   $0xf0102169
f0102534:	e8 6a fc ff ff       	call   f01021a3 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102539:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010253c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010253f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102542:	83 c4 10             	add    $0x10,%esp
}
f0102545:	c9                   	leave  
f0102546:	c3                   	ret    
		return -E_INVAL;
f0102547:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010254c:	eb f7                	jmp    f0102545 <vsnprintf+0x45>

f010254e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010254e:	55                   	push   %ebp
f010254f:	89 e5                	mov    %esp,%ebp
f0102551:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102554:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102557:	50                   	push   %eax
f0102558:	ff 75 10             	pushl  0x10(%ebp)
f010255b:	ff 75 0c             	pushl  0xc(%ebp)
f010255e:	ff 75 08             	pushl  0x8(%ebp)
f0102561:	e8 9a ff ff ff       	call   f0102500 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102566:	c9                   	leave  
f0102567:	c3                   	ret    

f0102568 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102568:	55                   	push   %ebp
f0102569:	89 e5                	mov    %esp,%ebp
f010256b:	57                   	push   %edi
f010256c:	56                   	push   %esi
f010256d:	53                   	push   %ebx
f010256e:	83 ec 0c             	sub    $0xc,%esp
f0102571:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102574:	85 c0                	test   %eax,%eax
f0102576:	74 11                	je     f0102589 <readline+0x21>
		cprintf("%s", prompt);
f0102578:	83 ec 08             	sub    $0x8,%esp
f010257b:	50                   	push   %eax
f010257c:	68 52 37 10 f0       	push   $0xf0103752
f0102581:	e8 9e f7 ff ff       	call   f0101d24 <cprintf>
f0102586:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102589:	83 ec 0c             	sub    $0xc,%esp
f010258c:	6a 00                	push   $0x0
f010258e:	e8 b1 e1 ff ff       	call   f0100744 <iscons>
f0102593:	89 c7                	mov    %eax,%edi
f0102595:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0102598:	be 00 00 00 00       	mov    $0x0,%esi
f010259d:	eb 3f                	jmp    f01025de <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010259f:	83 ec 08             	sub    $0x8,%esp
f01025a2:	50                   	push   %eax
f01025a3:	68 38 3b 10 f0       	push   $0xf0103b38
f01025a8:	e8 77 f7 ff ff       	call   f0101d24 <cprintf>
			return NULL;
f01025ad:	83 c4 10             	add    $0x10,%esp
f01025b0:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01025b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025b8:	5b                   	pop    %ebx
f01025b9:	5e                   	pop    %esi
f01025ba:	5f                   	pop    %edi
f01025bb:	5d                   	pop    %ebp
f01025bc:	c3                   	ret    
			if (echoing)
f01025bd:	85 ff                	test   %edi,%edi
f01025bf:	75 05                	jne    f01025c6 <readline+0x5e>
			i--;
f01025c1:	83 ee 01             	sub    $0x1,%esi
f01025c4:	eb 18                	jmp    f01025de <readline+0x76>
				cputchar('\b');
f01025c6:	83 ec 0c             	sub    $0xc,%esp
f01025c9:	6a 08                	push   $0x8
f01025cb:	e8 53 e1 ff ff       	call   f0100723 <cputchar>
f01025d0:	83 c4 10             	add    $0x10,%esp
f01025d3:	eb ec                	jmp    f01025c1 <readline+0x59>
			buf[i++] = c;
f01025d5:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f01025db:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01025de:	e8 50 e1 ff ff       	call   f0100733 <getchar>
f01025e3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01025e5:	85 c0                	test   %eax,%eax
f01025e7:	78 b6                	js     f010259f <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01025e9:	83 f8 08             	cmp    $0x8,%eax
f01025ec:	0f 94 c2             	sete   %dl
f01025ef:	83 f8 7f             	cmp    $0x7f,%eax
f01025f2:	0f 94 c0             	sete   %al
f01025f5:	08 c2                	or     %al,%dl
f01025f7:	74 04                	je     f01025fd <readline+0x95>
f01025f9:	85 f6                	test   %esi,%esi
f01025fb:	7f c0                	jg     f01025bd <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01025fd:	83 fb 1f             	cmp    $0x1f,%ebx
f0102600:	7e 1a                	jle    f010261c <readline+0xb4>
f0102602:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102608:	7f 12                	jg     f010261c <readline+0xb4>
			if (echoing)
f010260a:	85 ff                	test   %edi,%edi
f010260c:	74 c7                	je     f01025d5 <readline+0x6d>
				cputchar(c);
f010260e:	83 ec 0c             	sub    $0xc,%esp
f0102611:	53                   	push   %ebx
f0102612:	e8 0c e1 ff ff       	call   f0100723 <cputchar>
f0102617:	83 c4 10             	add    $0x10,%esp
f010261a:	eb b9                	jmp    f01025d5 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f010261c:	83 fb 0a             	cmp    $0xa,%ebx
f010261f:	74 05                	je     f0102626 <readline+0xbe>
f0102621:	83 fb 0d             	cmp    $0xd,%ebx
f0102624:	75 b8                	jne    f01025de <readline+0x76>
			if (echoing)
f0102626:	85 ff                	test   %edi,%edi
f0102628:	75 11                	jne    f010263b <readline+0xd3>
			buf[i] = 0;
f010262a:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f0102631:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
f0102636:	e9 7a ff ff ff       	jmp    f01025b5 <readline+0x4d>
				cputchar('\n');
f010263b:	83 ec 0c             	sub    $0xc,%esp
f010263e:	6a 0a                	push   $0xa
f0102640:	e8 de e0 ff ff       	call   f0100723 <cputchar>
f0102645:	83 c4 10             	add    $0x10,%esp
f0102648:	eb e0                	jmp    f010262a <readline+0xc2>

f010264a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010264a:	55                   	push   %ebp
f010264b:	89 e5                	mov    %esp,%ebp
f010264d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102650:	b8 00 00 00 00       	mov    $0x0,%eax
f0102655:	eb 03                	jmp    f010265a <strlen+0x10>
		n++;
f0102657:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010265a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010265e:	75 f7                	jne    f0102657 <strlen+0xd>
	return n;
}
f0102660:	5d                   	pop    %ebp
f0102661:	c3                   	ret    

f0102662 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102662:	55                   	push   %ebp
f0102663:	89 e5                	mov    %esp,%ebp
f0102665:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102668:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010266b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102670:	eb 03                	jmp    f0102675 <strnlen+0x13>
		n++;
f0102672:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102675:	39 d0                	cmp    %edx,%eax
f0102677:	74 06                	je     f010267f <strnlen+0x1d>
f0102679:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010267d:	75 f3                	jne    f0102672 <strnlen+0x10>
	return n;
}
f010267f:	5d                   	pop    %ebp
f0102680:	c3                   	ret    

f0102681 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102681:	55                   	push   %ebp
f0102682:	89 e5                	mov    %esp,%ebp
f0102684:	53                   	push   %ebx
f0102685:	8b 45 08             	mov    0x8(%ebp),%eax
f0102688:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010268b:	89 c2                	mov    %eax,%edx
f010268d:	83 c1 01             	add    $0x1,%ecx
f0102690:	83 c2 01             	add    $0x1,%edx
f0102693:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102697:	88 5a ff             	mov    %bl,-0x1(%edx)
f010269a:	84 db                	test   %bl,%bl
f010269c:	75 ef                	jne    f010268d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010269e:	5b                   	pop    %ebx
f010269f:	5d                   	pop    %ebp
f01026a0:	c3                   	ret    

f01026a1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01026a1:	55                   	push   %ebp
f01026a2:	89 e5                	mov    %esp,%ebp
f01026a4:	53                   	push   %ebx
f01026a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01026a8:	53                   	push   %ebx
f01026a9:	e8 9c ff ff ff       	call   f010264a <strlen>
f01026ae:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01026b1:	ff 75 0c             	pushl  0xc(%ebp)
f01026b4:	01 d8                	add    %ebx,%eax
f01026b6:	50                   	push   %eax
f01026b7:	e8 c5 ff ff ff       	call   f0102681 <strcpy>
	return dst;
}
f01026bc:	89 d8                	mov    %ebx,%eax
f01026be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01026c1:	c9                   	leave  
f01026c2:	c3                   	ret    

f01026c3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01026c3:	55                   	push   %ebp
f01026c4:	89 e5                	mov    %esp,%ebp
f01026c6:	56                   	push   %esi
f01026c7:	53                   	push   %ebx
f01026c8:	8b 75 08             	mov    0x8(%ebp),%esi
f01026cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01026ce:	89 f3                	mov    %esi,%ebx
f01026d0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01026d3:	89 f2                	mov    %esi,%edx
f01026d5:	eb 0f                	jmp    f01026e6 <strncpy+0x23>
		*dst++ = *src;
f01026d7:	83 c2 01             	add    $0x1,%edx
f01026da:	0f b6 01             	movzbl (%ecx),%eax
f01026dd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01026e0:	80 39 01             	cmpb   $0x1,(%ecx)
f01026e3:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01026e6:	39 da                	cmp    %ebx,%edx
f01026e8:	75 ed                	jne    f01026d7 <strncpy+0x14>
	}
	return ret;
}
f01026ea:	89 f0                	mov    %esi,%eax
f01026ec:	5b                   	pop    %ebx
f01026ed:	5e                   	pop    %esi
f01026ee:	5d                   	pop    %ebp
f01026ef:	c3                   	ret    

f01026f0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01026f0:	55                   	push   %ebp
f01026f1:	89 e5                	mov    %esp,%ebp
f01026f3:	56                   	push   %esi
f01026f4:	53                   	push   %ebx
f01026f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01026f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01026fb:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01026fe:	89 f0                	mov    %esi,%eax
f0102700:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102704:	85 c9                	test   %ecx,%ecx
f0102706:	75 0b                	jne    f0102713 <strlcpy+0x23>
f0102708:	eb 17                	jmp    f0102721 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010270a:	83 c2 01             	add    $0x1,%edx
f010270d:	83 c0 01             	add    $0x1,%eax
f0102710:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0102713:	39 d8                	cmp    %ebx,%eax
f0102715:	74 07                	je     f010271e <strlcpy+0x2e>
f0102717:	0f b6 0a             	movzbl (%edx),%ecx
f010271a:	84 c9                	test   %cl,%cl
f010271c:	75 ec                	jne    f010270a <strlcpy+0x1a>
		*dst = '\0';
f010271e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102721:	29 f0                	sub    %esi,%eax
}
f0102723:	5b                   	pop    %ebx
f0102724:	5e                   	pop    %esi
f0102725:	5d                   	pop    %ebp
f0102726:	c3                   	ret    

f0102727 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102727:	55                   	push   %ebp
f0102728:	89 e5                	mov    %esp,%ebp
f010272a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010272d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102730:	eb 06                	jmp    f0102738 <strcmp+0x11>
		p++, q++;
f0102732:	83 c1 01             	add    $0x1,%ecx
f0102735:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0102738:	0f b6 01             	movzbl (%ecx),%eax
f010273b:	84 c0                	test   %al,%al
f010273d:	74 04                	je     f0102743 <strcmp+0x1c>
f010273f:	3a 02                	cmp    (%edx),%al
f0102741:	74 ef                	je     f0102732 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102743:	0f b6 c0             	movzbl %al,%eax
f0102746:	0f b6 12             	movzbl (%edx),%edx
f0102749:	29 d0                	sub    %edx,%eax
}
f010274b:	5d                   	pop    %ebp
f010274c:	c3                   	ret    

f010274d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010274d:	55                   	push   %ebp
f010274e:	89 e5                	mov    %esp,%ebp
f0102750:	53                   	push   %ebx
f0102751:	8b 45 08             	mov    0x8(%ebp),%eax
f0102754:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102757:	89 c3                	mov    %eax,%ebx
f0102759:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010275c:	eb 06                	jmp    f0102764 <strncmp+0x17>
		n--, p++, q++;
f010275e:	83 c0 01             	add    $0x1,%eax
f0102761:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0102764:	39 d8                	cmp    %ebx,%eax
f0102766:	74 16                	je     f010277e <strncmp+0x31>
f0102768:	0f b6 08             	movzbl (%eax),%ecx
f010276b:	84 c9                	test   %cl,%cl
f010276d:	74 04                	je     f0102773 <strncmp+0x26>
f010276f:	3a 0a                	cmp    (%edx),%cl
f0102771:	74 eb                	je     f010275e <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102773:	0f b6 00             	movzbl (%eax),%eax
f0102776:	0f b6 12             	movzbl (%edx),%edx
f0102779:	29 d0                	sub    %edx,%eax
}
f010277b:	5b                   	pop    %ebx
f010277c:	5d                   	pop    %ebp
f010277d:	c3                   	ret    
		return 0;
f010277e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102783:	eb f6                	jmp    f010277b <strncmp+0x2e>

f0102785 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102785:	55                   	push   %ebp
f0102786:	89 e5                	mov    %esp,%ebp
f0102788:	8b 45 08             	mov    0x8(%ebp),%eax
f010278b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010278f:	0f b6 10             	movzbl (%eax),%edx
f0102792:	84 d2                	test   %dl,%dl
f0102794:	74 09                	je     f010279f <strchr+0x1a>
		if (*s == c)
f0102796:	38 ca                	cmp    %cl,%dl
f0102798:	74 0a                	je     f01027a4 <strchr+0x1f>
	for (; *s; s++)
f010279a:	83 c0 01             	add    $0x1,%eax
f010279d:	eb f0                	jmp    f010278f <strchr+0xa>
			return (char *) s;
	return 0;
f010279f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01027a4:	5d                   	pop    %ebp
f01027a5:	c3                   	ret    

f01027a6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01027a6:	55                   	push   %ebp
f01027a7:	89 e5                	mov    %esp,%ebp
f01027a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01027ac:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01027b0:	eb 03                	jmp    f01027b5 <strfind+0xf>
f01027b2:	83 c0 01             	add    $0x1,%eax
f01027b5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01027b8:	38 ca                	cmp    %cl,%dl
f01027ba:	74 04                	je     f01027c0 <strfind+0x1a>
f01027bc:	84 d2                	test   %dl,%dl
f01027be:	75 f2                	jne    f01027b2 <strfind+0xc>
			break;
	return (char *) s;
}
f01027c0:	5d                   	pop    %ebp
f01027c1:	c3                   	ret    

f01027c2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01027c2:	55                   	push   %ebp
f01027c3:	89 e5                	mov    %esp,%ebp
f01027c5:	57                   	push   %edi
f01027c6:	56                   	push   %esi
f01027c7:	53                   	push   %ebx
f01027c8:	8b 55 08             	mov    0x8(%ebp),%edx
f01027cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01027ce:	85 c9                	test   %ecx,%ecx
f01027d0:	74 12                	je     f01027e4 <memset+0x22>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01027d2:	f6 c2 03             	test   $0x3,%dl
f01027d5:	75 05                	jne    f01027dc <memset+0x1a>
f01027d7:	f6 c1 03             	test   $0x3,%cl
f01027da:	74 0f                	je     f01027eb <memset+0x29>
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01027dc:	89 d7                	mov    %edx,%edi
f01027de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027e1:	fc                   	cld    
f01027e2:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01027e4:	89 d0                	mov    %edx,%eax
f01027e6:	5b                   	pop    %ebx
f01027e7:	5e                   	pop    %esi
f01027e8:	5f                   	pop    %edi
f01027e9:	5d                   	pop    %ebp
f01027ea:	c3                   	ret    
		c &= 0xFF;
f01027eb:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01027ef:	89 d8                	mov    %ebx,%eax
f01027f1:	c1 e0 08             	shl    $0x8,%eax
f01027f4:	89 df                	mov    %ebx,%edi
f01027f6:	c1 e7 18             	shl    $0x18,%edi
f01027f9:	89 de                	mov    %ebx,%esi
f01027fb:	c1 e6 10             	shl    $0x10,%esi
f01027fe:	09 f7                	or     %esi,%edi
f0102800:	09 fb                	or     %edi,%ebx
			: "D" (p), "a" (c), "c" (n/4)
f0102802:	c1 e9 02             	shr    $0x2,%ecx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102805:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f0102807:	89 d7                	mov    %edx,%edi
f0102809:	fc                   	cld    
f010280a:	f3 ab                	rep stos %eax,%es:(%edi)
f010280c:	eb d6                	jmp    f01027e4 <memset+0x22>

f010280e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010280e:	55                   	push   %ebp
f010280f:	89 e5                	mov    %esp,%ebp
f0102811:	57                   	push   %edi
f0102812:	56                   	push   %esi
f0102813:	8b 45 08             	mov    0x8(%ebp),%eax
f0102816:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102819:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010281c:	39 c6                	cmp    %eax,%esi
f010281e:	73 35                	jae    f0102855 <memmove+0x47>
f0102820:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102823:	39 c2                	cmp    %eax,%edx
f0102825:	76 2e                	jbe    f0102855 <memmove+0x47>
		s += n;
		d += n;
f0102827:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010282a:	89 d6                	mov    %edx,%esi
f010282c:	09 fe                	or     %edi,%esi
f010282e:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102834:	74 0c                	je     f0102842 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0102836:	83 ef 01             	sub    $0x1,%edi
f0102839:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010283c:	fd                   	std    
f010283d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010283f:	fc                   	cld    
f0102840:	eb 21                	jmp    f0102863 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102842:	f6 c1 03             	test   $0x3,%cl
f0102845:	75 ef                	jne    f0102836 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0102847:	83 ef 04             	sub    $0x4,%edi
f010284a:	8d 72 fc             	lea    -0x4(%edx),%esi
f010284d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0102850:	fd                   	std    
f0102851:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102853:	eb ea                	jmp    f010283f <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102855:	89 f2                	mov    %esi,%edx
f0102857:	09 c2                	or     %eax,%edx
f0102859:	f6 c2 03             	test   $0x3,%dl
f010285c:	74 09                	je     f0102867 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010285e:	89 c7                	mov    %eax,%edi
f0102860:	fc                   	cld    
f0102861:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102863:	5e                   	pop    %esi
f0102864:	5f                   	pop    %edi
f0102865:	5d                   	pop    %ebp
f0102866:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102867:	f6 c1 03             	test   $0x3,%cl
f010286a:	75 f2                	jne    f010285e <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010286c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010286f:	89 c7                	mov    %eax,%edi
f0102871:	fc                   	cld    
f0102872:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102874:	eb ed                	jmp    f0102863 <memmove+0x55>

f0102876 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102876:	55                   	push   %ebp
f0102877:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102879:	ff 75 10             	pushl  0x10(%ebp)
f010287c:	ff 75 0c             	pushl  0xc(%ebp)
f010287f:	ff 75 08             	pushl  0x8(%ebp)
f0102882:	e8 87 ff ff ff       	call   f010280e <memmove>
}
f0102887:	c9                   	leave  
f0102888:	c3                   	ret    

f0102889 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102889:	55                   	push   %ebp
f010288a:	89 e5                	mov    %esp,%ebp
f010288c:	56                   	push   %esi
f010288d:	53                   	push   %ebx
f010288e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102891:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102894:	89 c6                	mov    %eax,%esi
f0102896:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102899:	39 f0                	cmp    %esi,%eax
f010289b:	74 1c                	je     f01028b9 <memcmp+0x30>
		if (*s1 != *s2)
f010289d:	0f b6 08             	movzbl (%eax),%ecx
f01028a0:	0f b6 1a             	movzbl (%edx),%ebx
f01028a3:	38 d9                	cmp    %bl,%cl
f01028a5:	75 08                	jne    f01028af <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01028a7:	83 c0 01             	add    $0x1,%eax
f01028aa:	83 c2 01             	add    $0x1,%edx
f01028ad:	eb ea                	jmp    f0102899 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01028af:	0f b6 c1             	movzbl %cl,%eax
f01028b2:	0f b6 db             	movzbl %bl,%ebx
f01028b5:	29 d8                	sub    %ebx,%eax
f01028b7:	eb 05                	jmp    f01028be <memcmp+0x35>
	}

	return 0;
f01028b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028be:	5b                   	pop    %ebx
f01028bf:	5e                   	pop    %esi
f01028c0:	5d                   	pop    %ebp
f01028c1:	c3                   	ret    

f01028c2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01028c2:	55                   	push   %ebp
f01028c3:	89 e5                	mov    %esp,%ebp
f01028c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01028c8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01028cb:	89 c2                	mov    %eax,%edx
f01028cd:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01028d0:	39 d0                	cmp    %edx,%eax
f01028d2:	73 09                	jae    f01028dd <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01028d4:	38 08                	cmp    %cl,(%eax)
f01028d6:	74 05                	je     f01028dd <memfind+0x1b>
	for (; s < ends; s++)
f01028d8:	83 c0 01             	add    $0x1,%eax
f01028db:	eb f3                	jmp    f01028d0 <memfind+0xe>
			break;
	return (void *) s;
}
f01028dd:	5d                   	pop    %ebp
f01028de:	c3                   	ret    

f01028df <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01028df:	55                   	push   %ebp
f01028e0:	89 e5                	mov    %esp,%ebp
f01028e2:	57                   	push   %edi
f01028e3:	56                   	push   %esi
f01028e4:	53                   	push   %ebx
f01028e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01028e8:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01028eb:	eb 03                	jmp    f01028f0 <strtol+0x11>
		s++;
f01028ed:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01028f0:	0f b6 01             	movzbl (%ecx),%eax
f01028f3:	3c 20                	cmp    $0x20,%al
f01028f5:	74 f6                	je     f01028ed <strtol+0xe>
f01028f7:	3c 09                	cmp    $0x9,%al
f01028f9:	74 f2                	je     f01028ed <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01028fb:	3c 2b                	cmp    $0x2b,%al
f01028fd:	74 2e                	je     f010292d <strtol+0x4e>
	int neg = 0;
f01028ff:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0102904:	3c 2d                	cmp    $0x2d,%al
f0102906:	74 2f                	je     f0102937 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102908:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010290e:	75 05                	jne    f0102915 <strtol+0x36>
f0102910:	80 39 30             	cmpb   $0x30,(%ecx)
f0102913:	74 2c                	je     f0102941 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102915:	85 db                	test   %ebx,%ebx
f0102917:	75 0a                	jne    f0102923 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102919:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010291e:	80 39 30             	cmpb   $0x30,(%ecx)
f0102921:	74 28                	je     f010294b <strtol+0x6c>
		base = 10;
f0102923:	b8 00 00 00 00       	mov    $0x0,%eax
f0102928:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010292b:	eb 50                	jmp    f010297d <strtol+0x9e>
		s++;
f010292d:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0102930:	bf 00 00 00 00       	mov    $0x0,%edi
f0102935:	eb d1                	jmp    f0102908 <strtol+0x29>
		s++, neg = 1;
f0102937:	83 c1 01             	add    $0x1,%ecx
f010293a:	bf 01 00 00 00       	mov    $0x1,%edi
f010293f:	eb c7                	jmp    f0102908 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102941:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102945:	74 0e                	je     f0102955 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0102947:	85 db                	test   %ebx,%ebx
f0102949:	75 d8                	jne    f0102923 <strtol+0x44>
		s++, base = 8;
f010294b:	83 c1 01             	add    $0x1,%ecx
f010294e:	bb 08 00 00 00       	mov    $0x8,%ebx
f0102953:	eb ce                	jmp    f0102923 <strtol+0x44>
		s += 2, base = 16;
f0102955:	83 c1 02             	add    $0x2,%ecx
f0102958:	bb 10 00 00 00       	mov    $0x10,%ebx
f010295d:	eb c4                	jmp    f0102923 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010295f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102962:	89 f3                	mov    %esi,%ebx
f0102964:	80 fb 19             	cmp    $0x19,%bl
f0102967:	77 29                	ja     f0102992 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0102969:	0f be d2             	movsbl %dl,%edx
f010296c:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010296f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102972:	7d 30                	jge    f01029a4 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0102974:	83 c1 01             	add    $0x1,%ecx
f0102977:	0f af 45 10          	imul   0x10(%ebp),%eax
f010297b:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010297d:	0f b6 11             	movzbl (%ecx),%edx
f0102980:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102983:	89 f3                	mov    %esi,%ebx
f0102985:	80 fb 09             	cmp    $0x9,%bl
f0102988:	77 d5                	ja     f010295f <strtol+0x80>
			dig = *s - '0';
f010298a:	0f be d2             	movsbl %dl,%edx
f010298d:	83 ea 30             	sub    $0x30,%edx
f0102990:	eb dd                	jmp    f010296f <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0102992:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102995:	89 f3                	mov    %esi,%ebx
f0102997:	80 fb 19             	cmp    $0x19,%bl
f010299a:	77 08                	ja     f01029a4 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010299c:	0f be d2             	movsbl %dl,%edx
f010299f:	83 ea 37             	sub    $0x37,%edx
f01029a2:	eb cb                	jmp    f010296f <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01029a4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01029a8:	74 05                	je     f01029af <strtol+0xd0>
		*endptr = (char *) s;
f01029aa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01029ad:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01029af:	89 c2                	mov    %eax,%edx
f01029b1:	f7 da                	neg    %edx
f01029b3:	85 ff                	test   %edi,%edi
f01029b5:	0f 45 c2             	cmovne %edx,%eax
}
f01029b8:	5b                   	pop    %ebx
f01029b9:	5e                   	pop    %esi
f01029ba:	5f                   	pop    %edi
f01029bb:	5d                   	pop    %ebp
f01029bc:	c3                   	ret    
f01029bd:	66 90                	xchg   %ax,%ax
f01029bf:	90                   	nop

f01029c0 <__udivdi3>:
f01029c0:	55                   	push   %ebp
f01029c1:	57                   	push   %edi
f01029c2:	56                   	push   %esi
f01029c3:	53                   	push   %ebx
f01029c4:	83 ec 1c             	sub    $0x1c,%esp
f01029c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01029cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01029cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01029d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01029d7:	85 d2                	test   %edx,%edx
f01029d9:	75 35                	jne    f0102a10 <__udivdi3+0x50>
f01029db:	39 f3                	cmp    %esi,%ebx
f01029dd:	0f 87 bd 00 00 00    	ja     f0102aa0 <__udivdi3+0xe0>
f01029e3:	85 db                	test   %ebx,%ebx
f01029e5:	89 d9                	mov    %ebx,%ecx
f01029e7:	75 0b                	jne    f01029f4 <__udivdi3+0x34>
f01029e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01029ee:	31 d2                	xor    %edx,%edx
f01029f0:	f7 f3                	div    %ebx
f01029f2:	89 c1                	mov    %eax,%ecx
f01029f4:	31 d2                	xor    %edx,%edx
f01029f6:	89 f0                	mov    %esi,%eax
f01029f8:	f7 f1                	div    %ecx
f01029fa:	89 c6                	mov    %eax,%esi
f01029fc:	89 e8                	mov    %ebp,%eax
f01029fe:	89 f7                	mov    %esi,%edi
f0102a00:	f7 f1                	div    %ecx
f0102a02:	89 fa                	mov    %edi,%edx
f0102a04:	83 c4 1c             	add    $0x1c,%esp
f0102a07:	5b                   	pop    %ebx
f0102a08:	5e                   	pop    %esi
f0102a09:	5f                   	pop    %edi
f0102a0a:	5d                   	pop    %ebp
f0102a0b:	c3                   	ret    
f0102a0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102a10:	39 f2                	cmp    %esi,%edx
f0102a12:	77 7c                	ja     f0102a90 <__udivdi3+0xd0>
f0102a14:	0f bd fa             	bsr    %edx,%edi
f0102a17:	83 f7 1f             	xor    $0x1f,%edi
f0102a1a:	0f 84 98 00 00 00    	je     f0102ab8 <__udivdi3+0xf8>
f0102a20:	89 f9                	mov    %edi,%ecx
f0102a22:	b8 20 00 00 00       	mov    $0x20,%eax
f0102a27:	29 f8                	sub    %edi,%eax
f0102a29:	d3 e2                	shl    %cl,%edx
f0102a2b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102a2f:	89 c1                	mov    %eax,%ecx
f0102a31:	89 da                	mov    %ebx,%edx
f0102a33:	d3 ea                	shr    %cl,%edx
f0102a35:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0102a39:	09 d1                	or     %edx,%ecx
f0102a3b:	89 f2                	mov    %esi,%edx
f0102a3d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102a41:	89 f9                	mov    %edi,%ecx
f0102a43:	d3 e3                	shl    %cl,%ebx
f0102a45:	89 c1                	mov    %eax,%ecx
f0102a47:	d3 ea                	shr    %cl,%edx
f0102a49:	89 f9                	mov    %edi,%ecx
f0102a4b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102a4f:	d3 e6                	shl    %cl,%esi
f0102a51:	89 eb                	mov    %ebp,%ebx
f0102a53:	89 c1                	mov    %eax,%ecx
f0102a55:	d3 eb                	shr    %cl,%ebx
f0102a57:	09 de                	or     %ebx,%esi
f0102a59:	89 f0                	mov    %esi,%eax
f0102a5b:	f7 74 24 08          	divl   0x8(%esp)
f0102a5f:	89 d6                	mov    %edx,%esi
f0102a61:	89 c3                	mov    %eax,%ebx
f0102a63:	f7 64 24 0c          	mull   0xc(%esp)
f0102a67:	39 d6                	cmp    %edx,%esi
f0102a69:	72 0c                	jb     f0102a77 <__udivdi3+0xb7>
f0102a6b:	89 f9                	mov    %edi,%ecx
f0102a6d:	d3 e5                	shl    %cl,%ebp
f0102a6f:	39 c5                	cmp    %eax,%ebp
f0102a71:	73 5d                	jae    f0102ad0 <__udivdi3+0x110>
f0102a73:	39 d6                	cmp    %edx,%esi
f0102a75:	75 59                	jne    f0102ad0 <__udivdi3+0x110>
f0102a77:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0102a7a:	31 ff                	xor    %edi,%edi
f0102a7c:	89 fa                	mov    %edi,%edx
f0102a7e:	83 c4 1c             	add    $0x1c,%esp
f0102a81:	5b                   	pop    %ebx
f0102a82:	5e                   	pop    %esi
f0102a83:	5f                   	pop    %edi
f0102a84:	5d                   	pop    %ebp
f0102a85:	c3                   	ret    
f0102a86:	8d 76 00             	lea    0x0(%esi),%esi
f0102a89:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102a90:	31 ff                	xor    %edi,%edi
f0102a92:	31 c0                	xor    %eax,%eax
f0102a94:	89 fa                	mov    %edi,%edx
f0102a96:	83 c4 1c             	add    $0x1c,%esp
f0102a99:	5b                   	pop    %ebx
f0102a9a:	5e                   	pop    %esi
f0102a9b:	5f                   	pop    %edi
f0102a9c:	5d                   	pop    %ebp
f0102a9d:	c3                   	ret    
f0102a9e:	66 90                	xchg   %ax,%ax
f0102aa0:	31 ff                	xor    %edi,%edi
f0102aa2:	89 e8                	mov    %ebp,%eax
f0102aa4:	89 f2                	mov    %esi,%edx
f0102aa6:	f7 f3                	div    %ebx
f0102aa8:	89 fa                	mov    %edi,%edx
f0102aaa:	83 c4 1c             	add    $0x1c,%esp
f0102aad:	5b                   	pop    %ebx
f0102aae:	5e                   	pop    %esi
f0102aaf:	5f                   	pop    %edi
f0102ab0:	5d                   	pop    %ebp
f0102ab1:	c3                   	ret    
f0102ab2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102ab8:	39 f2                	cmp    %esi,%edx
f0102aba:	72 06                	jb     f0102ac2 <__udivdi3+0x102>
f0102abc:	31 c0                	xor    %eax,%eax
f0102abe:	39 eb                	cmp    %ebp,%ebx
f0102ac0:	77 d2                	ja     f0102a94 <__udivdi3+0xd4>
f0102ac2:	b8 01 00 00 00       	mov    $0x1,%eax
f0102ac7:	eb cb                	jmp    f0102a94 <__udivdi3+0xd4>
f0102ac9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102ad0:	89 d8                	mov    %ebx,%eax
f0102ad2:	31 ff                	xor    %edi,%edi
f0102ad4:	eb be                	jmp    f0102a94 <__udivdi3+0xd4>
f0102ad6:	66 90                	xchg   %ax,%ax
f0102ad8:	66 90                	xchg   %ax,%ax
f0102ada:	66 90                	xchg   %ax,%ax
f0102adc:	66 90                	xchg   %ax,%ax
f0102ade:	66 90                	xchg   %ax,%ax

f0102ae0 <__umoddi3>:
f0102ae0:	55                   	push   %ebp
f0102ae1:	57                   	push   %edi
f0102ae2:	56                   	push   %esi
f0102ae3:	53                   	push   %ebx
f0102ae4:	83 ec 1c             	sub    $0x1c,%esp
f0102ae7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0102aeb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0102aef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0102af3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102af7:	85 ed                	test   %ebp,%ebp
f0102af9:	89 f0                	mov    %esi,%eax
f0102afb:	89 da                	mov    %ebx,%edx
f0102afd:	75 19                	jne    f0102b18 <__umoddi3+0x38>
f0102aff:	39 df                	cmp    %ebx,%edi
f0102b01:	0f 86 b1 00 00 00    	jbe    f0102bb8 <__umoddi3+0xd8>
f0102b07:	f7 f7                	div    %edi
f0102b09:	89 d0                	mov    %edx,%eax
f0102b0b:	31 d2                	xor    %edx,%edx
f0102b0d:	83 c4 1c             	add    $0x1c,%esp
f0102b10:	5b                   	pop    %ebx
f0102b11:	5e                   	pop    %esi
f0102b12:	5f                   	pop    %edi
f0102b13:	5d                   	pop    %ebp
f0102b14:	c3                   	ret    
f0102b15:	8d 76 00             	lea    0x0(%esi),%esi
f0102b18:	39 dd                	cmp    %ebx,%ebp
f0102b1a:	77 f1                	ja     f0102b0d <__umoddi3+0x2d>
f0102b1c:	0f bd cd             	bsr    %ebp,%ecx
f0102b1f:	83 f1 1f             	xor    $0x1f,%ecx
f0102b22:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0102b26:	0f 84 b4 00 00 00    	je     f0102be0 <__umoddi3+0x100>
f0102b2c:	b8 20 00 00 00       	mov    $0x20,%eax
f0102b31:	89 c2                	mov    %eax,%edx
f0102b33:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102b37:	29 c2                	sub    %eax,%edx
f0102b39:	89 c1                	mov    %eax,%ecx
f0102b3b:	89 f8                	mov    %edi,%eax
f0102b3d:	d3 e5                	shl    %cl,%ebp
f0102b3f:	89 d1                	mov    %edx,%ecx
f0102b41:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102b45:	d3 e8                	shr    %cl,%eax
f0102b47:	09 c5                	or     %eax,%ebp
f0102b49:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102b4d:	89 c1                	mov    %eax,%ecx
f0102b4f:	d3 e7                	shl    %cl,%edi
f0102b51:	89 d1                	mov    %edx,%ecx
f0102b53:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0102b57:	89 df                	mov    %ebx,%edi
f0102b59:	d3 ef                	shr    %cl,%edi
f0102b5b:	89 c1                	mov    %eax,%ecx
f0102b5d:	89 f0                	mov    %esi,%eax
f0102b5f:	d3 e3                	shl    %cl,%ebx
f0102b61:	89 d1                	mov    %edx,%ecx
f0102b63:	89 fa                	mov    %edi,%edx
f0102b65:	d3 e8                	shr    %cl,%eax
f0102b67:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102b6c:	09 d8                	or     %ebx,%eax
f0102b6e:	f7 f5                	div    %ebp
f0102b70:	d3 e6                	shl    %cl,%esi
f0102b72:	89 d1                	mov    %edx,%ecx
f0102b74:	f7 64 24 08          	mull   0x8(%esp)
f0102b78:	39 d1                	cmp    %edx,%ecx
f0102b7a:	89 c3                	mov    %eax,%ebx
f0102b7c:	89 d7                	mov    %edx,%edi
f0102b7e:	72 06                	jb     f0102b86 <__umoddi3+0xa6>
f0102b80:	75 0e                	jne    f0102b90 <__umoddi3+0xb0>
f0102b82:	39 c6                	cmp    %eax,%esi
f0102b84:	73 0a                	jae    f0102b90 <__umoddi3+0xb0>
f0102b86:	2b 44 24 08          	sub    0x8(%esp),%eax
f0102b8a:	19 ea                	sbb    %ebp,%edx
f0102b8c:	89 d7                	mov    %edx,%edi
f0102b8e:	89 c3                	mov    %eax,%ebx
f0102b90:	89 ca                	mov    %ecx,%edx
f0102b92:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0102b97:	29 de                	sub    %ebx,%esi
f0102b99:	19 fa                	sbb    %edi,%edx
f0102b9b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0102b9f:	89 d0                	mov    %edx,%eax
f0102ba1:	d3 e0                	shl    %cl,%eax
f0102ba3:	89 d9                	mov    %ebx,%ecx
f0102ba5:	d3 ee                	shr    %cl,%esi
f0102ba7:	d3 ea                	shr    %cl,%edx
f0102ba9:	09 f0                	or     %esi,%eax
f0102bab:	83 c4 1c             	add    $0x1c,%esp
f0102bae:	5b                   	pop    %ebx
f0102baf:	5e                   	pop    %esi
f0102bb0:	5f                   	pop    %edi
f0102bb1:	5d                   	pop    %ebp
f0102bb2:	c3                   	ret    
f0102bb3:	90                   	nop
f0102bb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102bb8:	85 ff                	test   %edi,%edi
f0102bba:	89 f9                	mov    %edi,%ecx
f0102bbc:	75 0b                	jne    f0102bc9 <__umoddi3+0xe9>
f0102bbe:	b8 01 00 00 00       	mov    $0x1,%eax
f0102bc3:	31 d2                	xor    %edx,%edx
f0102bc5:	f7 f7                	div    %edi
f0102bc7:	89 c1                	mov    %eax,%ecx
f0102bc9:	89 d8                	mov    %ebx,%eax
f0102bcb:	31 d2                	xor    %edx,%edx
f0102bcd:	f7 f1                	div    %ecx
f0102bcf:	89 f0                	mov    %esi,%eax
f0102bd1:	f7 f1                	div    %ecx
f0102bd3:	e9 31 ff ff ff       	jmp    f0102b09 <__umoddi3+0x29>
f0102bd8:	90                   	nop
f0102bd9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102be0:	39 dd                	cmp    %ebx,%ebp
f0102be2:	72 08                	jb     f0102bec <__umoddi3+0x10c>
f0102be4:	39 f7                	cmp    %esi,%edi
f0102be6:	0f 87 21 ff ff ff    	ja     f0102b0d <__umoddi3+0x2d>
f0102bec:	89 da                	mov    %ebx,%edx
f0102bee:	89 f0                	mov    %esi,%eax
f0102bf0:	29 f8                	sub    %edi,%eax
f0102bf2:	19 ea                	sbb    %ebp,%edx
f0102bf4:	e9 14 ff ff ff       	jmp    f0102b0d <__umoddi3+0x2d>
