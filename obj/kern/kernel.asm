
obj/kern/kernel:     formato del fichero elf32-i386


Desensamblado de la sección .text:

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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f0100046:	b8 50 39 11 f0       	mov    $0xf0113950,%eax
f010004b:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 33 11 f0       	push   $0xf0113300
f0100058:	e8 67 16 00 00       	call   f01016c4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 94 06 00 00       	call   f01006f6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 1b 10 f0       	push   $0xf0101b00
f010006f:	e8 b2 0b 00 00       	call   f0100c26 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 0b 0a 00 00       	call   f0100a84 <mem_init>
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
f0100093:	83 3d 40 39 11 f0 00 	cmpl   $0x0,0xf0113940
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
f01000ab:	89 35 40 39 11 f0    	mov    %esi,0xf0113940
	asm volatile("cli; cld");
f01000b1:	fa                   	cli    
f01000b2:	fc                   	cld    
	va_start(ap, fmt);
f01000b3:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000b6:	83 ec 04             	sub    $0x4,%esp
f01000b9:	ff 75 0c             	pushl  0xc(%ebp)
f01000bc:	ff 75 08             	pushl  0x8(%ebp)
f01000bf:	68 3c 1b 10 f0       	push   $0xf0101b3c
f01000c4:	e8 5d 0b 00 00       	call   f0100c26 <cprintf>
	vcprintf(fmt, ap);
f01000c9:	83 c4 08             	add    $0x8,%esp
f01000cc:	53                   	push   %ebx
f01000cd:	56                   	push   %esi
f01000ce:	e8 2d 0b 00 00       	call   f0100c00 <vcprintf>
	cprintf("\n>>>\n");
f01000d3:	c7 04 24 1b 1b 10 f0 	movl   $0xf0101b1b,(%esp)
f01000da:	e8 47 0b 00 00       	call   f0100c26 <cprintf>
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
f01000f4:	68 21 1b 10 f0       	push   $0xf0101b21
f01000f9:	e8 28 0b 00 00       	call   f0100c26 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	53                   	push   %ebx
f0100102:	ff 75 10             	pushl  0x10(%ebp)
f0100105:	e8 f6 0a 00 00       	call   f0100c00 <vcprintf>
	cprintf("\n");
f010010a:	c7 04 24 66 1b 10 f0 	movl   $0xf0101b66,(%esp)
f0100111:	e8 10 0b 00 00       	call   f0100c26 <cprintf>
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
f010023d:	0f 95 05 34 35 11 f0 	setne  0xf0113534
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
f01002dd:	c7 05 30 35 11 f0 b4 	movl   $0x3b4,0xf0113530
f01002e4:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002e7:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01002ee:	8b 35 30 35 11 f0    	mov    0xf0113530,%esi
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
f0100326:	89 0d 2c 35 11 f0    	mov    %ecx,0xf011352c
	pos |= inb(addr_6845 + 1);
f010032c:	0f b6 c0             	movzbl %al,%eax
f010032f:	09 c3                	or     %eax,%ebx
	crt_pos = pos;
f0100331:	66 89 1d 28 35 11 f0 	mov    %bx,0xf0113528
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
f0100347:	c7 05 30 35 11 f0 d4 	movl   $0x3d4,0xf0113530
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
f010036e:	8b 0d 24 35 11 f0    	mov    0xf0113524,%ecx
f0100374:	8d 51 01             	lea    0x1(%ecx),%edx
f0100377:	89 15 24 35 11 f0    	mov    %edx,0xf0113524
f010037d:	88 81 20 33 11 f0    	mov    %al,-0xfeecce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100383:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100389:	75 d8                	jne    f0100363 <cons_intr+0x9>
			cons.wpos = 0;
f010038b:	c7 05 24 35 11 f0 00 	movl   $0x0,0xf0113524
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
f01003d8:	8b 15 00 33 11 f0    	mov    0xf0113300,%edx
f01003de:	f6 c2 40             	test   $0x40,%dl
f01003e1:	74 0c                	je     f01003ef <kbd_proc_data+0x52>
		data |= 0x80;
f01003e3:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f01003e6:	83 e2 bf             	and    $0xffffffbf,%edx
f01003e9:	89 15 00 33 11 f0    	mov    %edx,0xf0113300
	shift |= shiftcode[data];
f01003ef:	0f b6 c0             	movzbl %al,%eax
f01003f2:	0f b6 90 c0 1c 10 f0 	movzbl -0xfefe340(%eax),%edx
f01003f9:	0b 15 00 33 11 f0    	or     0xf0113300,%edx
	shift ^= togglecode[data];
f01003ff:	0f b6 88 c0 1b 10 f0 	movzbl -0xfefe440(%eax),%ecx
f0100406:	31 ca                	xor    %ecx,%edx
f0100408:	89 15 00 33 11 f0    	mov    %edx,0xf0113300
	c = charcode[shift & (CTL | SHIFT)][data];
f010040e:	89 d1                	mov    %edx,%ecx
f0100410:	83 e1 03             	and    $0x3,%ecx
f0100413:	8b 0c 8d a0 1b 10 f0 	mov    -0xfefe460(,%ecx,4),%ecx
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
f0100445:	68 5c 1b 10 f0       	push   $0xf0101b5c
f010044a:	e8 d7 07 00 00       	call   f0100c26 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f010044f:	ba 03 00 00 00       	mov    $0x3,%edx
f0100454:	b8 92 00 00 00       	mov    $0x92,%eax
f0100459:	e8 c8 fc ff ff       	call   f0100126 <outb>
f010045e:	83 c4 10             	add    $0x10,%esp
f0100461:	eb 0c                	jmp    f010046f <kbd_proc_data+0xd2>
		shift |= E0ESC;
f0100463:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
		return 0;
f010046a:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010046f:	89 d8                	mov    %ebx,%eax
f0100471:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100474:	c9                   	leave  
f0100475:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100476:	8b 15 00 33 11 f0    	mov    0xf0113300,%edx
f010047c:	89 d3                	mov    %edx,%ebx
f010047e:	83 e3 40             	and    $0x40,%ebx
f0100481:	89 c1                	mov    %eax,%ecx
f0100483:	83 e1 7f             	and    $0x7f,%ecx
f0100486:	85 db                	test   %ebx,%ebx
f0100488:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f010048b:	0f b6 c0             	movzbl %al,%eax
f010048e:	0f b6 80 c0 1c 10 f0 	movzbl -0xfefe340(%eax),%eax
f0100495:	83 c8 40             	or     $0x40,%eax
f0100498:	0f b6 c0             	movzbl %al,%eax
f010049b:	f7 d0                	not    %eax
f010049d:	21 d0                	and    %edx,%eax
f010049f:	a3 00 33 11 f0       	mov    %eax,0xf0113300
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
f010050c:	0f b7 05 28 35 11 f0 	movzwl 0xf0113528,%eax
f0100513:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100519:	c1 e8 16             	shr    $0x16,%eax
f010051c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010051f:	c1 e0 04             	shl    $0x4,%eax
f0100522:	66 a3 28 35 11 f0    	mov    %ax,0xf0113528
	if (crt_pos >= CRT_SIZE) {
f0100528:	66 81 3d 28 35 11 f0 	cmpw   $0x7cf,0xf0113528
f010052f:	cf 07 
f0100531:	0f 87 dd 00 00 00    	ja     f0100614 <cga_putc+0x14a>
	outb(addr_6845, 14);
f0100537:	8b 3d 30 35 11 f0    	mov    0xf0113530,%edi
f010053d:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100542:	89 f8                	mov    %edi,%eax
f0100544:	e8 dd fb ff ff       	call   f0100126 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100549:	0f b7 1d 28 35 11 f0 	movzwl 0xf0113528,%ebx
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
f0100580:	0f b7 15 28 35 11 f0 	movzwl 0xf0113528,%edx
f0100587:	66 85 d2             	test   %dx,%dx
f010058a:	74 ab                	je     f0100537 <cga_putc+0x6d>
			crt_pos--;
f010058c:	83 ea 01             	sub    $0x1,%edx
f010058f:	66 89 15 28 35 11 f0 	mov    %dx,0xf0113528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100596:	0f b7 d2             	movzwl %dx,%edx
f0100599:	b0 00                	mov    $0x0,%al
f010059b:	83 c8 20             	or     $0x20,%eax
f010059e:	8b 0d 2c 35 11 f0    	mov    0xf011352c,%ecx
f01005a4:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f01005a8:	e9 7b ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		crt_pos += CRT_COLS;
f01005ad:	66 83 05 28 35 11 f0 	addw   $0x50,0xf0113528
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
f01005f1:	0f b7 15 28 35 11 f0 	movzwl 0xf0113528,%edx
f01005f8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005fb:	66 89 0d 28 35 11 f0 	mov    %cx,0xf0113528
f0100602:	0f b7 d2             	movzwl %dx,%edx
f0100605:	8b 0d 2c 35 11 f0    	mov    0xf011352c,%ecx
f010060b:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
f010060f:	e9 14 ff ff ff       	jmp    f0100528 <cga_putc+0x5e>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100614:	a1 2c 35 11 f0       	mov    0xf011352c,%eax
f0100619:	83 ec 04             	sub    $0x4,%esp
f010061c:	68 00 0f 00 00       	push   $0xf00
f0100621:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100627:	52                   	push   %edx
f0100628:	50                   	push   %eax
f0100629:	e8 e2 10 00 00       	call   f0101710 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010062e:	8b 15 2c 35 11 f0    	mov    0xf011352c,%edx
f0100634:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010063a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100640:	83 c4 10             	add    $0x10,%esp
f0100643:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100648:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010064b:	39 d0                	cmp    %edx,%eax
f010064d:	75 f4                	jne    f0100643 <cga_putc+0x179>
		crt_pos -= CRT_COLS;
f010064f:	66 83 2d 28 35 11 f0 	subw   $0x50,0xf0113528
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
f010067e:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
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
f01006bd:	8b 15 20 35 11 f0    	mov    0xf0113520,%edx
	return 0;
f01006c3:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01006c8:	3b 15 24 35 11 f0    	cmp    0xf0113524,%edx
f01006ce:	74 18                	je     f01006e8 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f01006d0:	8d 4a 01             	lea    0x1(%edx),%ecx
f01006d3:	89 0d 20 35 11 f0    	mov    %ecx,0xf0113520
f01006d9:	0f b6 82 20 33 11 f0 	movzbl -0xfeecce0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f01006e0:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01006e6:	74 02                	je     f01006ea <cons_getc+0x3d>
}
f01006e8:	c9                   	leave  
f01006e9:	c3                   	ret    
			cons.rpos = 0;
f01006ea:	c7 05 20 35 11 f0 00 	movl   $0x0,0xf0113520
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
f0100706:	80 3d 34 35 11 f0 00 	cmpb   $0x0,0xf0113534
f010070d:	74 02                	je     f0100711 <cons_init+0x1b>
		cprintf("Serial port does not exist!\n");
}
f010070f:	c9                   	leave  
f0100710:	c3                   	ret    
		cprintf("Serial port does not exist!\n");
f0100711:	83 ec 0c             	sub    $0xc,%esp
f0100714:	68 68 1b 10 f0       	push   $0xf0101b68
f0100719:	e8 08 05 00 00       	call   f0100c26 <cprintf>
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
f0100754:	68 c0 1d 10 f0       	push   $0xf0101dc0
f0100759:	68 de 1d 10 f0       	push   $0xf0101dde
f010075e:	68 e3 1d 10 f0       	push   $0xf0101de3
f0100763:	e8 be 04 00 00       	call   f0100c26 <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	68 4c 1e 10 f0       	push   $0xf0101e4c
f0100770:	68 ec 1d 10 f0       	push   $0xf0101dec
f0100775:	68 e3 1d 10 f0       	push   $0xf0101de3
f010077a:	e8 a7 04 00 00       	call   f0100c26 <cprintf>
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
f010078c:	68 f5 1d 10 f0       	push   $0xf0101df5
f0100791:	e8 90 04 00 00       	call   f0100c26 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100796:	83 c4 08             	add    $0x8,%esp
f0100799:	68 0c 00 10 00       	push   $0x10000c
f010079e:	68 74 1e 10 f0       	push   $0xf0101e74
f01007a3:	e8 7e 04 00 00       	call   f0100c26 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a8:	83 c4 0c             	add    $0xc,%esp
f01007ab:	68 0c 00 10 00       	push   $0x10000c
f01007b0:	68 0c 00 10 f0       	push   $0xf010000c
f01007b5:	68 9c 1e 10 f0       	push   $0xf0101e9c
f01007ba:	e8 67 04 00 00       	call   f0100c26 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 f9 1a 10 00       	push   $0x101af9
f01007c7:	68 f9 1a 10 f0       	push   $0xf0101af9
f01007cc:	68 c0 1e 10 f0       	push   $0xf0101ec0
f01007d1:	e8 50 04 00 00       	call   f0100c26 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 00 33 11 00       	push   $0x113300
f01007de:	68 00 33 11 f0       	push   $0xf0113300
f01007e3:	68 e4 1e 10 f0       	push   $0xf0101ee4
f01007e8:	e8 39 04 00 00       	call   f0100c26 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ed:	83 c4 0c             	add    $0xc,%esp
f01007f0:	68 50 39 11 00       	push   $0x113950
f01007f5:	68 50 39 11 f0       	push   $0xf0113950
f01007fa:	68 08 1f 10 f0       	push   $0xf0101f08
f01007ff:	e8 22 04 00 00       	call   f0100c26 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100804:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100807:	b8 4f 3d 11 f0       	mov    $0xf0113d4f,%eax
f010080c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100811:	c1 f8 0a             	sar    $0xa,%eax
f0100814:	50                   	push   %eax
f0100815:	68 2c 1f 10 f0       	push   $0xf0101f2c
f010081a:	e8 07 04 00 00       	call   f0100c26 <cprintf>
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
f0100849:	68 0e 1e 10 f0       	push   $0xf0101e0e
f010084e:	e8 34 0e 00 00       	call   f0101687 <strchr>
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
f0100882:	68 0e 1e 10 f0       	push   $0xf0101e0e
f0100887:	e8 fb 0d 00 00       	call   f0101687 <strchr>
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
f01008b5:	68 de 1d 10 f0       	push   $0xf0101dde
f01008ba:	ff 75 a8             	pushl  -0x58(%ebp)
f01008bd:	e8 67 0d 00 00       	call   f0101629 <strcmp>
f01008c2:	83 c4 10             	add    $0x10,%esp
f01008c5:	85 c0                	test   %eax,%eax
f01008c7:	74 57                	je     f0100920 <runcmd+0xfa>
f01008c9:	83 ec 08             	sub    $0x8,%esp
f01008cc:	68 ec 1d 10 f0       	push   $0xf0101dec
f01008d1:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d4:	e8 50 0d 00 00       	call   f0101629 <strcmp>
f01008d9:	83 c4 10             	add    $0x10,%esp
f01008dc:	85 c0                	test   %eax,%eax
f01008de:	74 3b                	je     f010091b <runcmd+0xf5>
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008e0:	83 ec 08             	sub    $0x8,%esp
f01008e3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e6:	68 30 1e 10 f0       	push   $0xf0101e30
f01008eb:	e8 36 03 00 00       	call   f0100c26 <cprintf>
	return 0;
f01008f0:	83 c4 10             	add    $0x10,%esp
f01008f3:	be 00 00 00 00       	mov    $0x0,%esi
f01008f8:	eb 17                	jmp    f0100911 <runcmd+0xeb>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008fa:	83 ec 08             	sub    $0x8,%esp
f01008fd:	6a 10                	push   $0x10
f01008ff:	68 13 1e 10 f0       	push   $0xf0101e13
f0100904:	e8 1d 03 00 00       	call   f0100c26 <cprintf>
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
f010092e:	ff 14 85 ac 1f 10 f0 	call   *-0xfefe054(,%eax,4)
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
f0100950:	68 58 1f 10 f0       	push   $0xf0101f58
f0100955:	e8 cc 02 00 00       	call   f0100c26 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010095a:	c7 04 24 7c 1f 10 f0 	movl   $0xf0101f7c,(%esp)
f0100961:	e8 c0 02 00 00       	call   f0100c26 <cprintf>
f0100966:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100969:	83 ec 0c             	sub    $0xc,%esp
f010096c:	68 46 1e 10 f0       	push   $0xf0101e46
f0100971:	e8 f4 0a 00 00       	call   f010146a <readline>
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

f0100995 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100995:	83 3d 38 35 11 f0 00 	cmpl   $0x0,0xf0113538
f010099c:	74 2c                	je     f01009ca <boot_alloc+0x35>
	// LAB 2: Your code here.

	// Están mapeados menos de 4 MB
	// por lo que no podemos pedir
	// más memoria que eso
	if ((uintptr_t)ROUNDUP(nextfree + n, PGSIZE) > (KERNBASE + (4 << 20))) {
f010099e:	89 c2                	mov    %eax,%edx
f01009a0:	03 15 38 35 11 f0    	add    0xf0113538,%edx
f01009a6:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009ac:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009b2:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f01009b8:	77 23                	ja     f01009dd <boot_alloc+0x48>
		panic("boot_alloc: out of memory");
	}

	if (n > 0) {
f01009ba:	85 c0                	test   %eax,%eax
f01009bc:	74 06                	je     f01009c4 <boot_alloc+0x2f>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);	
f01009be:	89 15 38 35 11 f0    	mov    %edx,0xf0113538
	}

	result = nextfree;

	return result;
}
f01009c4:	a1 38 35 11 f0       	mov    0xf0113538,%eax
f01009c9:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009ca:	ba 4f 49 11 f0       	mov    $0xf011494f,%edx
f01009cf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009d5:	89 15 38 35 11 f0    	mov    %edx,0xf0113538
f01009db:	eb c1                	jmp    f010099e <boot_alloc+0x9>
{
f01009dd:	55                   	push   %ebp
f01009de:	89 e5                	mov    %esp,%ebp
f01009e0:	83 ec 0c             	sub    $0xc,%esp
		panic("boot_alloc: out of memory");
f01009e3:	68 bc 1f 10 f0       	push   $0xf0101fbc
f01009e8:	6a 71                	push   $0x71
f01009ea:	68 d6 1f 10 f0       	push   $0xf0101fd6
f01009ef:	e8 97 f6 ff ff       	call   f010008b <_panic>

f01009f4 <nvram_read>:
{
f01009f4:	55                   	push   %ebp
f01009f5:	89 e5                	mov    %esp,%ebp
f01009f7:	56                   	push   %esi
f01009f8:	53                   	push   %ebx
f01009f9:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009fb:	83 ec 0c             	sub    $0xc,%esp
f01009fe:	50                   	push   %eax
f01009ff:	e8 9e 01 00 00       	call   f0100ba2 <mc146818_read>
f0100a04:	89 c3                	mov    %eax,%ebx
f0100a06:	83 c6 01             	add    $0x1,%esi
f0100a09:	89 34 24             	mov    %esi,(%esp)
f0100a0c:	e8 91 01 00 00       	call   f0100ba2 <mc146818_read>
f0100a11:	c1 e0 08             	shl    $0x8,%eax
f0100a14:	09 d8                	or     %ebx,%eax
}
f0100a16:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a19:	5b                   	pop    %ebx
f0100a1a:	5e                   	pop    %esi
f0100a1b:	5d                   	pop    %ebp
f0100a1c:	c3                   	ret    

f0100a1d <i386_detect_memory>:
{
f0100a1d:	55                   	push   %ebp
f0100a1e:	89 e5                	mov    %esp,%ebp
f0100a20:	56                   	push   %esi
f0100a21:	53                   	push   %ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100a22:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a27:	e8 c8 ff ff ff       	call   f01009f4 <nvram_read>
f0100a2c:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a2e:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a33:	e8 bc ff ff ff       	call   f01009f4 <nvram_read>
f0100a38:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a3a:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a3f:	e8 b0 ff ff ff       	call   f01009f4 <nvram_read>
f0100a44:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100a47:	85 c0                	test   %eax,%eax
f0100a49:	75 0e                	jne    f0100a59 <i386_detect_memory+0x3c>
		totalmem = basemem;
f0100a4b:	89 d8                	mov    %ebx,%eax
	else if (extmem)
f0100a4d:	85 f6                	test   %esi,%esi
f0100a4f:	74 0d                	je     f0100a5e <i386_detect_memory+0x41>
		totalmem = 1 * 1024 + extmem;
f0100a51:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100a57:	eb 05                	jmp    f0100a5e <i386_detect_memory+0x41>
		totalmem = 16 * 1024 + ext16mem;
f0100a59:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100a5e:	89 c2                	mov    %eax,%edx
f0100a60:	c1 ea 02             	shr    $0x2,%edx
f0100a63:	89 15 44 39 11 f0    	mov    %edx,0xf0113944
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a69:	89 c2                	mov    %eax,%edx
f0100a6b:	29 da                	sub    %ebx,%edx
f0100a6d:	52                   	push   %edx
f0100a6e:	53                   	push   %ebx
f0100a6f:	50                   	push   %eax
f0100a70:	68 00 20 10 f0       	push   $0xf0102000
f0100a75:	e8 ac 01 00 00       	call   f0100c26 <cprintf>
}
f0100a7a:	83 c4 10             	add    $0x10,%esp
f0100a7d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a80:	5b                   	pop    %ebx
f0100a81:	5e                   	pop    %esi
f0100a82:	5d                   	pop    %ebp
f0100a83:	c3                   	ret    

f0100a84 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100a84:	55                   	push   %ebp
f0100a85:	89 e5                	mov    %esp,%ebp
f0100a87:	83 ec 08             	sub    $0x8,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0100a8a:	e8 8e ff ff ff       	call   f0100a1d <i386_detect_memory>

	// Remove this line when you're ready to test this function.
	cprintf("Nextfree, la pagina inmediata luego de que termina el kernel en el AS: %p \n", boot_alloc(0));
f0100a8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a94:	e8 fc fe ff ff       	call   f0100995 <boot_alloc>
f0100a99:	83 ec 08             	sub    $0x8,%esp
f0100a9c:	50                   	push   %eax
f0100a9d:	68 3c 20 10 f0       	push   $0xf010203c
f0100aa2:	e8 7f 01 00 00       	call   f0100c26 <cprintf>
	cprintf("Npages cantidad de paginas fisicas: %lu \n", npages);
f0100aa7:	83 c4 08             	add    $0x8,%esp
f0100aaa:	ff 35 44 39 11 f0    	pushl  0xf0113944
f0100ab0:	68 88 20 10 f0       	push   $0xf0102088
f0100ab5:	e8 6c 01 00 00       	call   f0100c26 <cprintf>
	cprintf("Sizeof PageInfo struct: %lu", sizeof(struct PageInfo));
f0100aba:	83 c4 08             	add    $0x8,%esp
f0100abd:	6a 08                	push   $0x8
f0100abf:	68 e2 1f 10 f0       	push   $0xf0101fe2
f0100ac4:	e8 5d 01 00 00       	call   f0100c26 <cprintf>
	boot_alloc(0x2EC000);
f0100ac9:	b8 00 c0 2e 00       	mov    $0x2ec000,%eax
f0100ace:	e8 c2 fe ff ff       	call   f0100995 <boot_alloc>
		
	panic("mem_init: This function is not finished\n");
f0100ad3:	83 c4 0c             	add    $0xc,%esp
f0100ad6:	68 b4 20 10 f0       	push   $0xf01020b4
f0100adb:	68 95 00 00 00       	push   $0x95
f0100ae0:	68 d6 1f 10 f0       	push   $0xf0101fd6
f0100ae5:	e8 a1 f5 ff ff       	call   f010008b <_panic>

f0100aea <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100aea:	55                   	push   %ebp
f0100aeb:	89 e5                	mov    %esp,%ebp
f0100aed:	56                   	push   %esi
f0100aee:	53                   	push   %ebx
f0100aef:	8b 1d 3c 35 11 f0    	mov    0xf011353c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100af5:	ba 00 00 00 00       	mov    $0x0,%edx
f0100afa:	b8 00 00 00 00       	mov    $0x0,%eax
f0100aff:	be 01 00 00 00       	mov    $0x1,%esi
f0100b04:	eb 24                	jmp    f0100b2a <page_init+0x40>
f0100b06:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100b0d:	89 d1                	mov    %edx,%ecx
f0100b0f:	03 0d 4c 39 11 f0    	add    0xf011394c,%ecx
f0100b15:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100b1b:	89 19                	mov    %ebx,(%ecx)
	for (i = 0; i < npages; i++) {
f0100b1d:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100b20:	89 d3                	mov    %edx,%ebx
f0100b22:	03 1d 4c 39 11 f0    	add    0xf011394c,%ebx
f0100b28:	89 f2                	mov    %esi,%edx
	for (i = 0; i < npages; i++) {
f0100b2a:	39 05 44 39 11 f0    	cmp    %eax,0xf0113944
f0100b30:	77 d4                	ja     f0100b06 <page_init+0x1c>
f0100b32:	84 d2                	test   %dl,%dl
f0100b34:	75 04                	jne    f0100b3a <page_init+0x50>
	}
}
f0100b36:	5b                   	pop    %ebx
f0100b37:	5e                   	pop    %esi
f0100b38:	5d                   	pop    %ebp
f0100b39:	c3                   	ret    
f0100b3a:	89 1d 3c 35 11 f0    	mov    %ebx,0xf011353c
f0100b40:	eb f4                	jmp    f0100b36 <page_init+0x4c>

f0100b42 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100b42:	55                   	push   %ebp
f0100b43:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100b45:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b4a:	5d                   	pop    %ebp
f0100b4b:	c3                   	ret    

f0100b4c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100b4c:	55                   	push   %ebp
f0100b4d:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100b4f:	5d                   	pop    %ebp
f0100b50:	c3                   	ret    

f0100b51 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo *pp)
{
f0100b51:	55                   	push   %ebp
f0100b52:	89 e5                	mov    %esp,%ebp
f0100b54:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100b57:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100b5c:	5d                   	pop    %ebp
f0100b5d:	c3                   	ret    

f0100b5e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100b5e:	55                   	push   %ebp
f0100b5f:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100b61:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b66:	5d                   	pop    %ebp
f0100b67:	c3                   	ret    

f0100b68 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100b68:	55                   	push   %ebp
f0100b69:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100b6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b70:	5d                   	pop    %ebp
f0100b71:	c3                   	ret    

f0100b72 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100b72:	55                   	push   %ebp
f0100b73:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100b75:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b7a:	5d                   	pop    %ebp
f0100b7b:	c3                   	ret    

f0100b7c <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100b7c:	55                   	push   %ebp
f0100b7d:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100b7f:	5d                   	pop    %ebp
f0100b80:	c3                   	ret    

f0100b81 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100b81:	55                   	push   %ebp
f0100b82:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0100b84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b87:	e8 01 fe ff ff       	call   f010098d <invlpg>
}
f0100b8c:	5d                   	pop    %ebp
f0100b8d:	c3                   	ret    

f0100b8e <inb>:
{
f0100b8e:	55                   	push   %ebp
f0100b8f:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100b91:	89 c2                	mov    %eax,%edx
f0100b93:	ec                   	in     (%dx),%al
}
f0100b94:	5d                   	pop    %ebp
f0100b95:	c3                   	ret    

f0100b96 <outb>:
{
f0100b96:	55                   	push   %ebp
f0100b97:	89 e5                	mov    %esp,%ebp
f0100b99:	89 c1                	mov    %eax,%ecx
f0100b9b:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100b9d:	89 ca                	mov    %ecx,%edx
f0100b9f:	ee                   	out    %al,(%dx)
}
f0100ba0:	5d                   	pop    %ebp
f0100ba1:	c3                   	ret    

f0100ba2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100ba2:	55                   	push   %ebp
f0100ba3:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0100ba5:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0100ba9:	b8 70 00 00 00       	mov    $0x70,%eax
f0100bae:	e8 e3 ff ff ff       	call   f0100b96 <outb>
	return inb(IO_RTC+1);
f0100bb3:	b8 71 00 00 00       	mov    $0x71,%eax
f0100bb8:	e8 d1 ff ff ff       	call   f0100b8e <inb>
f0100bbd:	0f b6 c0             	movzbl %al,%eax
}
f0100bc0:	5d                   	pop    %ebp
f0100bc1:	c3                   	ret    

f0100bc2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100bc2:	55                   	push   %ebp
f0100bc3:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0100bc5:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0100bc9:	b8 70 00 00 00       	mov    $0x70,%eax
f0100bce:	e8 c3 ff ff ff       	call   f0100b96 <outb>
	outb(IO_RTC+1, datum);
f0100bd3:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0100bd7:	b8 71 00 00 00       	mov    $0x71,%eax
f0100bdc:	e8 b5 ff ff ff       	call   f0100b96 <outb>
}
f0100be1:	5d                   	pop    %ebp
f0100be2:	c3                   	ret    

f0100be3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100be3:	55                   	push   %ebp
f0100be4:	89 e5                	mov    %esp,%ebp
f0100be6:	53                   	push   %ebx
f0100be7:	83 ec 10             	sub    $0x10,%esp
f0100bea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0100bed:	ff 75 08             	pushl  0x8(%ebp)
f0100bf0:	e8 2e fb ff ff       	call   f0100723 <cputchar>
	(*cnt)++;
f0100bf5:	83 03 01             	addl   $0x1,(%ebx)
}
f0100bf8:	83 c4 10             	add    $0x10,%esp
f0100bfb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100bfe:	c9                   	leave  
f0100bff:	c3                   	ret    

f0100c00 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c00:	55                   	push   %ebp
f0100c01:	89 e5                	mov    %esp,%ebp
f0100c03:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100c06:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c0d:	ff 75 0c             	pushl  0xc(%ebp)
f0100c10:	ff 75 08             	pushl  0x8(%ebp)
f0100c13:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c16:	50                   	push   %eax
f0100c17:	68 e3 0b 10 f0       	push   $0xf0100be3
f0100c1c:	e8 84 04 00 00       	call   f01010a5 <vprintfmt>
	return cnt;
}
f0100c21:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c24:	c9                   	leave  
f0100c25:	c3                   	ret    

f0100c26 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100c26:	55                   	push   %ebp
f0100c27:	89 e5                	mov    %esp,%ebp
f0100c29:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100c2c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100c2f:	50                   	push   %eax
f0100c30:	ff 75 08             	pushl  0x8(%ebp)
f0100c33:	e8 c8 ff ff ff       	call   f0100c00 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100c38:	c9                   	leave  
f0100c39:	c3                   	ret    

f0100c3a <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0100c3a:	55                   	push   %ebp
f0100c3b:	89 e5                	mov    %esp,%ebp
f0100c3d:	57                   	push   %edi
f0100c3e:	56                   	push   %esi
f0100c3f:	53                   	push   %ebx
f0100c40:	83 ec 14             	sub    $0x14,%esp
f0100c43:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100c46:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100c49:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c4c:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100c4f:	8b 32                	mov    (%edx),%esi
f0100c51:	8b 01                	mov    (%ecx),%eax
f0100c53:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c56:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100c5d:	eb 2f                	jmp    f0100c8e <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100c5f:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100c62:	39 c6                	cmp    %eax,%esi
f0100c64:	7f 49                	jg     f0100caf <stab_binsearch+0x75>
f0100c66:	0f b6 0a             	movzbl (%edx),%ecx
f0100c69:	83 ea 0c             	sub    $0xc,%edx
f0100c6c:	39 f9                	cmp    %edi,%ecx
f0100c6e:	75 ef                	jne    f0100c5f <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100c70:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c73:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100c76:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100c7a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100c7d:	73 35                	jae    f0100cb4 <stab_binsearch+0x7a>
			*region_left = m;
f0100c7f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c82:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100c84:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100c87:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100c8e:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100c91:	7f 4e                	jg     f0100ce1 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100c93:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c96:	01 f0                	add    %esi,%eax
f0100c98:	89 c3                	mov    %eax,%ebx
f0100c9a:	c1 eb 1f             	shr    $0x1f,%ebx
f0100c9d:	01 c3                	add    %eax,%ebx
f0100c9f:	d1 fb                	sar    %ebx
f0100ca1:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ca4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ca7:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100cab:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100cad:	eb b3                	jmp    f0100c62 <stab_binsearch+0x28>
			l = true_m + 1;
f0100caf:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100cb2:	eb da                	jmp    f0100c8e <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100cb4:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100cb7:	76 14                	jbe    f0100ccd <stab_binsearch+0x93>
			*region_right = m - 1;
f0100cb9:	83 e8 01             	sub    $0x1,%eax
f0100cbc:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100cbf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100cc2:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100cc4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100ccb:	eb c1                	jmp    f0100c8e <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ccd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cd0:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100cd2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100cd6:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100cd8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100cdf:	eb ad                	jmp    f0100c8e <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100ce1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100ce5:	74 16                	je     f0100cfd <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ce7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cea:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100cec:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cef:	8b 0e                	mov    (%esi),%ecx
f0100cf1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cf4:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100cf7:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100cfb:	eb 12                	jmp    f0100d0f <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100cfd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d00:	8b 00                	mov    (%eax),%eax
f0100d02:	83 e8 01             	sub    $0x1,%eax
f0100d05:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100d08:	89 07                	mov    %eax,(%edi)
f0100d0a:	eb 16                	jmp    f0100d22 <stab_binsearch+0xe8>
		     l--)
f0100d0c:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100d0f:	39 c1                	cmp    %eax,%ecx
f0100d11:	7d 0a                	jge    f0100d1d <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100d13:	0f b6 1a             	movzbl (%edx),%ebx
f0100d16:	83 ea 0c             	sub    $0xc,%edx
f0100d19:	39 fb                	cmp    %edi,%ebx
f0100d1b:	75 ef                	jne    f0100d0c <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100d1d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100d20:	89 07                	mov    %eax,(%edi)
	}
}
f0100d22:	83 c4 14             	add    $0x14,%esp
f0100d25:	5b                   	pop    %ebx
f0100d26:	5e                   	pop    %esi
f0100d27:	5f                   	pop    %edi
f0100d28:	5d                   	pop    %ebp
f0100d29:	c3                   	ret    

f0100d2a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100d2a:	55                   	push   %ebp
f0100d2b:	89 e5                	mov    %esp,%ebp
f0100d2d:	57                   	push   %edi
f0100d2e:	56                   	push   %esi
f0100d2f:	53                   	push   %ebx
f0100d30:	83 ec 3c             	sub    $0x3c,%esp
f0100d33:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100d39:	c7 03 e0 20 10 f0    	movl   $0xf01020e0,(%ebx)
	info->eip_line = 0;
f0100d3f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100d46:	c7 43 08 e0 20 10 f0 	movl   $0xf01020e0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100d4d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100d54:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100d57:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100d5e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100d64:	0f 86 22 01 00 00    	jbe    f0100e8c <debuginfo_eip+0x162>
		// Can't search for user-level addresses yet!
		panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100d6a:	b8 d0 86 10 f0       	mov    $0xf01086d0,%eax
f0100d6f:	3d 1d 69 10 f0       	cmp    $0xf010691d,%eax
f0100d74:	0f 86 b4 01 00 00    	jbe    f0100f2e <debuginfo_eip+0x204>
f0100d7a:	80 3d cf 86 10 f0 00 	cmpb   $0x0,0xf01086cf
f0100d81:	0f 85 ae 01 00 00    	jne    f0100f35 <debuginfo_eip+0x20b>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100d87:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100d8e:	b8 1c 69 10 f0       	mov    $0xf010691c,%eax
f0100d93:	2d 08 23 10 f0       	sub    $0xf0102308,%eax
f0100d98:	c1 f8 02             	sar    $0x2,%eax
f0100d9b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100da1:	83 e8 01             	sub    $0x1,%eax
f0100da4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100da7:	83 ec 08             	sub    $0x8,%esp
f0100daa:	56                   	push   %esi
f0100dab:	6a 64                	push   $0x64
f0100dad:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100db0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100db3:	b8 08 23 10 f0       	mov    $0xf0102308,%eax
f0100db8:	e8 7d fe ff ff       	call   f0100c3a <stab_binsearch>
	if (lfile == 0)
f0100dbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dc0:	83 c4 10             	add    $0x10,%esp
f0100dc3:	85 c0                	test   %eax,%eax
f0100dc5:	0f 84 71 01 00 00    	je     f0100f3c <debuginfo_eip+0x212>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100dcb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100dce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100dd4:	83 ec 08             	sub    $0x8,%esp
f0100dd7:	56                   	push   %esi
f0100dd8:	6a 24                	push   $0x24
f0100dda:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ddd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100de0:	b8 08 23 10 f0       	mov    $0xf0102308,%eax
f0100de5:	e8 50 fe ff ff       	call   f0100c3a <stab_binsearch>

	if (lfun <= rfun) {
f0100dea:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ded:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100df0:	83 c4 10             	add    $0x10,%esp
f0100df3:	39 d0                	cmp    %edx,%eax
f0100df5:	0f 8f a8 00 00 00    	jg     f0100ea3 <debuginfo_eip+0x179>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100dfb:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100dfe:	c1 e1 02             	shl    $0x2,%ecx
f0100e01:	8d b9 08 23 10 f0    	lea    -0xfefdcf8(%ecx),%edi
f0100e07:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100e0a:	8b b9 08 23 10 f0    	mov    -0xfefdcf8(%ecx),%edi
f0100e10:	b9 d0 86 10 f0       	mov    $0xf01086d0,%ecx
f0100e15:	81 e9 1d 69 10 f0    	sub    $0xf010691d,%ecx
f0100e1b:	39 cf                	cmp    %ecx,%edi
f0100e1d:	73 09                	jae    f0100e28 <debuginfo_eip+0xfe>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100e1f:	81 c7 1d 69 10 f0    	add    $0xf010691d,%edi
f0100e25:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100e28:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100e2b:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100e2e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100e31:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100e33:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100e36:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100e39:	83 ec 08             	sub    $0x8,%esp
f0100e3c:	6a 3a                	push   $0x3a
f0100e3e:	ff 73 08             	pushl  0x8(%ebx)
f0100e41:	e8 62 08 00 00       	call   f01016a8 <strfind>
f0100e46:	2b 43 08             	sub    0x8(%ebx),%eax
f0100e49:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100e4c:	83 c4 08             	add    $0x8,%esp
f0100e4f:	56                   	push   %esi
f0100e50:	6a 44                	push   $0x44
f0100e52:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100e55:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100e58:	b8 08 23 10 f0       	mov    $0xf0102308,%eax
f0100e5d:	e8 d8 fd ff ff       	call   f0100c3a <stab_binsearch>
	if (lline <= rline) {
f0100e62:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e65:	83 c4 10             	add    $0x10,%esp
f0100e68:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100e6b:	7f 0e                	jg     f0100e7b <debuginfo_eip+0x151>
		info->eip_line = stabs[lline].n_desc;
f0100e6d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e70:	0f b7 14 95 0e 23 10 	movzwl -0xfefdcf2(,%edx,4),%edx
f0100e77:	f0 
f0100e78:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0100e7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e7e:	89 c2                	mov    %eax,%edx
f0100e80:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100e83:	8d 04 85 0c 23 10 f0 	lea    -0xfefdcf4(,%eax,4),%eax
f0100e8a:	eb 2e                	jmp    f0100eba <debuginfo_eip+0x190>
		panic("User address");
f0100e8c:	83 ec 04             	sub    $0x4,%esp
f0100e8f:	68 ea 20 10 f0       	push   $0xf01020ea
f0100e94:	68 82 00 00 00       	push   $0x82
f0100e99:	68 f7 20 10 f0       	push   $0xf01020f7
f0100e9e:	e8 e8 f1 ff ff       	call   f010008b <_panic>
		info->eip_fn_addr = addr;
f0100ea3:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100ea6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ea9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100eac:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eaf:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100eb2:	eb 85                	jmp    f0100e39 <debuginfo_eip+0x10f>
f0100eb4:	83 ea 01             	sub    $0x1,%edx
f0100eb7:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0100eba:	39 d7                	cmp    %edx,%edi
f0100ebc:	7f 33                	jg     f0100ef1 <debuginfo_eip+0x1c7>
f0100ebe:	0f b6 08             	movzbl (%eax),%ecx
f0100ec1:	80 f9 84             	cmp    $0x84,%cl
f0100ec4:	74 0b                	je     f0100ed1 <debuginfo_eip+0x1a7>
f0100ec6:	80 f9 64             	cmp    $0x64,%cl
f0100ec9:	75 e9                	jne    f0100eb4 <debuginfo_eip+0x18a>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ecb:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100ecf:	74 e3                	je     f0100eb4 <debuginfo_eip+0x18a>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ed1:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100ed4:	8b 14 85 08 23 10 f0 	mov    -0xfefdcf8(,%eax,4),%edx
f0100edb:	b8 d0 86 10 f0       	mov    $0xf01086d0,%eax
f0100ee0:	2d 1d 69 10 f0       	sub    $0xf010691d,%eax
f0100ee5:	39 c2                	cmp    %eax,%edx
f0100ee7:	73 08                	jae    f0100ef1 <debuginfo_eip+0x1c7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ee9:	81 c2 1d 69 10 f0    	add    $0xf010691d,%edx
f0100eef:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ef1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ef4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ef7:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100efc:	39 f2                	cmp    %esi,%edx
f0100efe:	7d 48                	jge    f0100f48 <debuginfo_eip+0x21e>
		for (lline = lfun + 1;
f0100f00:	83 c2 01             	add    $0x1,%edx
f0100f03:	89 d0                	mov    %edx,%eax
f0100f05:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100f08:	8d 14 95 0c 23 10 f0 	lea    -0xfefdcf4(,%edx,4),%edx
f0100f0f:	eb 04                	jmp    f0100f15 <debuginfo_eip+0x1eb>
			info->eip_fn_narg++;
f0100f11:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		for (lline = lfun + 1;
f0100f15:	39 c6                	cmp    %eax,%esi
f0100f17:	7e 2a                	jle    f0100f43 <debuginfo_eip+0x219>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100f19:	0f b6 0a             	movzbl (%edx),%ecx
f0100f1c:	83 c0 01             	add    $0x1,%eax
f0100f1f:	83 c2 0c             	add    $0xc,%edx
f0100f22:	80 f9 a0             	cmp    $0xa0,%cl
f0100f25:	74 ea                	je     f0100f11 <debuginfo_eip+0x1e7>
	return 0;
f0100f27:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f2c:	eb 1a                	jmp    f0100f48 <debuginfo_eip+0x21e>
		return -1;
f0100f2e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f33:	eb 13                	jmp    f0100f48 <debuginfo_eip+0x21e>
f0100f35:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f3a:	eb 0c                	jmp    f0100f48 <debuginfo_eip+0x21e>
		return -1;
f0100f3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f41:	eb 05                	jmp    f0100f48 <debuginfo_eip+0x21e>
	return 0;
f0100f43:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f48:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f4b:	5b                   	pop    %ebx
f0100f4c:	5e                   	pop    %esi
f0100f4d:	5f                   	pop    %edi
f0100f4e:	5d                   	pop    %ebp
f0100f4f:	c3                   	ret    

f0100f50 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100f50:	55                   	push   %ebp
f0100f51:	89 e5                	mov    %esp,%ebp
f0100f53:	57                   	push   %edi
f0100f54:	56                   	push   %esi
f0100f55:	53                   	push   %ebx
f0100f56:	83 ec 1c             	sub    $0x1c,%esp
f0100f59:	89 c7                	mov    %eax,%edi
f0100f5b:	89 d6                	mov    %edx,%esi
f0100f5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f60:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100f63:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f66:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100f69:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100f6c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f71:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100f74:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100f77:	39 d3                	cmp    %edx,%ebx
f0100f79:	72 05                	jb     f0100f80 <printnum+0x30>
f0100f7b:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100f7e:	77 7a                	ja     f0100ffa <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100f80:	83 ec 0c             	sub    $0xc,%esp
f0100f83:	ff 75 18             	pushl  0x18(%ebp)
f0100f86:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f89:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100f8c:	53                   	push   %ebx
f0100f8d:	ff 75 10             	pushl  0x10(%ebp)
f0100f90:	83 ec 08             	sub    $0x8,%esp
f0100f93:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100f96:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f99:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f9c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f9f:	e8 1c 09 00 00       	call   f01018c0 <__udivdi3>
f0100fa4:	83 c4 18             	add    $0x18,%esp
f0100fa7:	52                   	push   %edx
f0100fa8:	50                   	push   %eax
f0100fa9:	89 f2                	mov    %esi,%edx
f0100fab:	89 f8                	mov    %edi,%eax
f0100fad:	e8 9e ff ff ff       	call   f0100f50 <printnum>
f0100fb2:	83 c4 20             	add    $0x20,%esp
f0100fb5:	eb 13                	jmp    f0100fca <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100fb7:	83 ec 08             	sub    $0x8,%esp
f0100fba:	56                   	push   %esi
f0100fbb:	ff 75 18             	pushl  0x18(%ebp)
f0100fbe:	ff d7                	call   *%edi
f0100fc0:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100fc3:	83 eb 01             	sub    $0x1,%ebx
f0100fc6:	85 db                	test   %ebx,%ebx
f0100fc8:	7f ed                	jg     f0100fb7 <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100fca:	83 ec 08             	sub    $0x8,%esp
f0100fcd:	56                   	push   %esi
f0100fce:	83 ec 04             	sub    $0x4,%esp
f0100fd1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100fd4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100fd7:	ff 75 dc             	pushl  -0x24(%ebp)
f0100fda:	ff 75 d8             	pushl  -0x28(%ebp)
f0100fdd:	e8 fe 09 00 00       	call   f01019e0 <__umoddi3>
f0100fe2:	83 c4 14             	add    $0x14,%esp
f0100fe5:	0f be 80 05 21 10 f0 	movsbl -0xfefdefb(%eax),%eax
f0100fec:	50                   	push   %eax
f0100fed:	ff d7                	call   *%edi
}
f0100fef:	83 c4 10             	add    $0x10,%esp
f0100ff2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ff5:	5b                   	pop    %ebx
f0100ff6:	5e                   	pop    %esi
f0100ff7:	5f                   	pop    %edi
f0100ff8:	5d                   	pop    %ebp
f0100ff9:	c3                   	ret    
f0100ffa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100ffd:	eb c4                	jmp    f0100fc3 <printnum+0x73>

f0100fff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100fff:	55                   	push   %ebp
f0101000:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101002:	83 fa 01             	cmp    $0x1,%edx
f0101005:	7e 0e                	jle    f0101015 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101007:	8b 10                	mov    (%eax),%edx
f0101009:	8d 4a 08             	lea    0x8(%edx),%ecx
f010100c:	89 08                	mov    %ecx,(%eax)
f010100e:	8b 02                	mov    (%edx),%eax
f0101010:	8b 52 04             	mov    0x4(%edx),%edx
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
}
f0101013:	5d                   	pop    %ebp
f0101014:	c3                   	ret    
	else if (lflag)
f0101015:	85 d2                	test   %edx,%edx
f0101017:	75 10                	jne    f0101029 <getuint+0x2a>
		return va_arg(*ap, unsigned int);
f0101019:	8b 10                	mov    (%eax),%edx
f010101b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010101e:	89 08                	mov    %ecx,(%eax)
f0101020:	8b 02                	mov    (%edx),%eax
f0101022:	ba 00 00 00 00       	mov    $0x0,%edx
f0101027:	eb ea                	jmp    f0101013 <getuint+0x14>
		return va_arg(*ap, unsigned long);
f0101029:	8b 10                	mov    (%eax),%edx
f010102b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010102e:	89 08                	mov    %ecx,(%eax)
f0101030:	8b 02                	mov    (%edx),%eax
f0101032:	ba 00 00 00 00       	mov    $0x0,%edx
f0101037:	eb da                	jmp    f0101013 <getuint+0x14>

f0101039 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0101039:	55                   	push   %ebp
f010103a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010103c:	83 fa 01             	cmp    $0x1,%edx
f010103f:	7e 0e                	jle    f010104f <getint+0x16>
		return va_arg(*ap, long long);
f0101041:	8b 10                	mov    (%eax),%edx
f0101043:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101046:	89 08                	mov    %ecx,(%eax)
f0101048:	8b 02                	mov    (%edx),%eax
f010104a:	8b 52 04             	mov    0x4(%edx),%edx
	else if (lflag)
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
}
f010104d:	5d                   	pop    %ebp
f010104e:	c3                   	ret    
	else if (lflag)
f010104f:	85 d2                	test   %edx,%edx
f0101051:	75 0c                	jne    f010105f <getint+0x26>
		return va_arg(*ap, int);
f0101053:	8b 10                	mov    (%eax),%edx
f0101055:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101058:	89 08                	mov    %ecx,(%eax)
f010105a:	8b 02                	mov    (%edx),%eax
f010105c:	99                   	cltd   
f010105d:	eb ee                	jmp    f010104d <getint+0x14>
		return va_arg(*ap, long);
f010105f:	8b 10                	mov    (%eax),%edx
f0101061:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101064:	89 08                	mov    %ecx,(%eax)
f0101066:	8b 02                	mov    (%edx),%eax
f0101068:	99                   	cltd   
f0101069:	eb e2                	jmp    f010104d <getint+0x14>

f010106b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010106b:	55                   	push   %ebp
f010106c:	89 e5                	mov    %esp,%ebp
f010106e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101071:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101075:	8b 10                	mov    (%eax),%edx
f0101077:	3b 50 04             	cmp    0x4(%eax),%edx
f010107a:	73 0a                	jae    f0101086 <sprintputch+0x1b>
		*b->buf++ = ch;
f010107c:	8d 4a 01             	lea    0x1(%edx),%ecx
f010107f:	89 08                	mov    %ecx,(%eax)
f0101081:	8b 45 08             	mov    0x8(%ebp),%eax
f0101084:	88 02                	mov    %al,(%edx)
}
f0101086:	5d                   	pop    %ebp
f0101087:	c3                   	ret    

f0101088 <printfmt>:
{
f0101088:	55                   	push   %ebp
f0101089:	89 e5                	mov    %esp,%ebp
f010108b:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010108e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101091:	50                   	push   %eax
f0101092:	ff 75 10             	pushl  0x10(%ebp)
f0101095:	ff 75 0c             	pushl  0xc(%ebp)
f0101098:	ff 75 08             	pushl  0x8(%ebp)
f010109b:	e8 05 00 00 00       	call   f01010a5 <vprintfmt>
}
f01010a0:	83 c4 10             	add    $0x10,%esp
f01010a3:	c9                   	leave  
f01010a4:	c3                   	ret    

f01010a5 <vprintfmt>:
{
f01010a5:	55                   	push   %ebp
f01010a6:	89 e5                	mov    %esp,%ebp
f01010a8:	57                   	push   %edi
f01010a9:	56                   	push   %esi
f01010aa:	53                   	push   %ebx
f01010ab:	83 ec 2c             	sub    $0x2c,%esp
f01010ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01010b1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010b4:	89 f7                	mov    %esi,%edi
f01010b6:	89 de                	mov    %ebx,%esi
f01010b8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010bb:	e9 9e 02 00 00       	jmp    f010135e <vprintfmt+0x2b9>
		padc = ' ';
f01010c0:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01010c4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01010cb:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01010d2:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01010d9:	ba 00 00 00 00       	mov    $0x0,%edx
		switch (ch = *(unsigned char *) fmt++) {
f01010de:	8d 43 01             	lea    0x1(%ebx),%eax
f01010e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010e4:	0f b6 0b             	movzbl (%ebx),%ecx
f01010e7:	8d 41 dd             	lea    -0x23(%ecx),%eax
f01010ea:	3c 55                	cmp    $0x55,%al
f01010ec:	0f 87 e8 02 00 00    	ja     f01013da <vprintfmt+0x335>
f01010f2:	0f b6 c0             	movzbl %al,%eax
f01010f5:	ff 24 85 84 21 10 f0 	jmp    *-0xfefde7c(,%eax,4)
f01010fc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f01010ff:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101103:	eb d9                	jmp    f01010de <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f0101105:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '0';
f0101108:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010110c:	eb d0                	jmp    f01010de <vprintfmt+0x39>
		switch (ch = *(unsigned char *) fmt++) {
f010110e:	0f b6 c9             	movzbl %cl,%ecx
f0101111:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0101114:	b8 00 00 00 00       	mov    $0x0,%eax
f0101119:	89 55 e4             	mov    %edx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f010111c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010111f:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101123:	0f be 0b             	movsbl (%ebx),%ecx
				if (ch < '0' || ch > '9')
f0101126:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101129:	83 fa 09             	cmp    $0x9,%edx
f010112c:	77 52                	ja     f0101180 <vprintfmt+0xdb>
			for (precision = 0; ; ++fmt) {
f010112e:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0101131:	eb e9                	jmp    f010111c <vprintfmt+0x77>
			precision = va_arg(ap, int);
f0101133:	8b 45 14             	mov    0x14(%ebp),%eax
f0101136:	8d 48 04             	lea    0x4(%eax),%ecx
f0101139:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010113c:	8b 00                	mov    (%eax),%eax
f010113e:	89 45 d0             	mov    %eax,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101141:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f0101144:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101148:	79 94                	jns    f01010de <vprintfmt+0x39>
				width = precision, precision = -1;
f010114a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010114d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101150:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101157:	eb 85                	jmp    f01010de <vprintfmt+0x39>
f0101159:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010115c:	85 c0                	test   %eax,%eax
f010115e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101163:	0f 49 c8             	cmovns %eax,%ecx
f0101166:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101169:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010116c:	e9 6d ff ff ff       	jmp    f01010de <vprintfmt+0x39>
f0101171:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f0101174:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010117b:	e9 5e ff ff ff       	jmp    f01010de <vprintfmt+0x39>
f0101180:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101183:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101186:	eb bc                	jmp    f0101144 <vprintfmt+0x9f>
			lflag++;
f0101188:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f010118b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f010118e:	e9 4b ff ff ff       	jmp    f01010de <vprintfmt+0x39>
			putch(va_arg(ap, int), putdat);
f0101193:	8b 45 14             	mov    0x14(%ebp),%eax
f0101196:	8d 50 04             	lea    0x4(%eax),%edx
f0101199:	89 55 14             	mov    %edx,0x14(%ebp)
f010119c:	83 ec 08             	sub    $0x8,%esp
f010119f:	57                   	push   %edi
f01011a0:	ff 30                	pushl  (%eax)
f01011a2:	ff d6                	call   *%esi
			break;
f01011a4:	83 c4 10             	add    $0x10,%esp
f01011a7:	e9 af 01 00 00       	jmp    f010135b <vprintfmt+0x2b6>
			err = va_arg(ap, int);
f01011ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01011af:	8d 50 04             	lea    0x4(%eax),%edx
f01011b2:	89 55 14             	mov    %edx,0x14(%ebp)
f01011b5:	8b 00                	mov    (%eax),%eax
f01011b7:	99                   	cltd   
f01011b8:	31 d0                	xor    %edx,%eax
f01011ba:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01011bc:	83 f8 06             	cmp    $0x6,%eax
f01011bf:	7f 20                	jg     f01011e1 <vprintfmt+0x13c>
f01011c1:	8b 14 85 dc 22 10 f0 	mov    -0xfefdd24(,%eax,4),%edx
f01011c8:	85 d2                	test   %edx,%edx
f01011ca:	74 15                	je     f01011e1 <vprintfmt+0x13c>
				printfmt(putch, putdat, "%s", p);
f01011cc:	52                   	push   %edx
f01011cd:	68 26 21 10 f0       	push   $0xf0102126
f01011d2:	57                   	push   %edi
f01011d3:	56                   	push   %esi
f01011d4:	e8 af fe ff ff       	call   f0101088 <printfmt>
f01011d9:	83 c4 10             	add    $0x10,%esp
f01011dc:	e9 7a 01 00 00       	jmp    f010135b <vprintfmt+0x2b6>
				printfmt(putch, putdat, "error %d", err);
f01011e1:	50                   	push   %eax
f01011e2:	68 1d 21 10 f0       	push   $0xf010211d
f01011e7:	57                   	push   %edi
f01011e8:	56                   	push   %esi
f01011e9:	e8 9a fe ff ff       	call   f0101088 <printfmt>
f01011ee:	83 c4 10             	add    $0x10,%esp
f01011f1:	e9 65 01 00 00       	jmp    f010135b <vprintfmt+0x2b6>
			if ((p = va_arg(ap, char *)) == NULL)
f01011f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f9:	8d 50 04             	lea    0x4(%eax),%edx
f01011fc:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ff:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0101201:	85 db                	test   %ebx,%ebx
f0101203:	b8 16 21 10 f0       	mov    $0xf0102116,%eax
f0101208:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010120b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010120f:	0f 8e bd 00 00 00    	jle    f01012d2 <vprintfmt+0x22d>
f0101215:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101219:	75 0e                	jne    f0101229 <vprintfmt+0x184>
f010121b:	89 75 08             	mov    %esi,0x8(%ebp)
f010121e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101221:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0101224:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101227:	eb 6d                	jmp    f0101296 <vprintfmt+0x1f1>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101229:	83 ec 08             	sub    $0x8,%esp
f010122c:	ff 75 d0             	pushl  -0x30(%ebp)
f010122f:	53                   	push   %ebx
f0101230:	e8 2f 03 00 00       	call   f0101564 <strnlen>
f0101235:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101238:	29 c1                	sub    %eax,%ecx
f010123a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010123d:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101240:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101244:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101247:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f010124a:	89 cb                	mov    %ecx,%ebx
				for (width -= strnlen(p, precision); width > 0; width--)
f010124c:	eb 0f                	jmp    f010125d <vprintfmt+0x1b8>
					putch(padc, putdat);
f010124e:	83 ec 08             	sub    $0x8,%esp
f0101251:	57                   	push   %edi
f0101252:	ff 75 e0             	pushl  -0x20(%ebp)
f0101255:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101257:	83 eb 01             	sub    $0x1,%ebx
f010125a:	83 c4 10             	add    $0x10,%esp
f010125d:	85 db                	test   %ebx,%ebx
f010125f:	7f ed                	jg     f010124e <vprintfmt+0x1a9>
f0101261:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101264:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101267:	85 c9                	test   %ecx,%ecx
f0101269:	b8 00 00 00 00       	mov    $0x0,%eax
f010126e:	0f 49 c1             	cmovns %ecx,%eax
f0101271:	29 c1                	sub    %eax,%ecx
f0101273:	89 75 08             	mov    %esi,0x8(%ebp)
f0101276:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101279:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010127c:	89 cf                	mov    %ecx,%edi
f010127e:	eb 16                	jmp    f0101296 <vprintfmt+0x1f1>
				if (altflag && (ch < ' ' || ch > '~'))
f0101280:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101284:	75 31                	jne    f01012b7 <vprintfmt+0x212>
					putch(ch, putdat);
f0101286:	83 ec 08             	sub    $0x8,%esp
f0101289:	ff 75 0c             	pushl  0xc(%ebp)
f010128c:	50                   	push   %eax
f010128d:	ff 55 08             	call   *0x8(%ebp)
f0101290:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101293:	83 ef 01             	sub    $0x1,%edi
f0101296:	83 c3 01             	add    $0x1,%ebx
f0101299:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f010129d:	0f be c2             	movsbl %dl,%eax
f01012a0:	85 c0                	test   %eax,%eax
f01012a2:	74 50                	je     f01012f4 <vprintfmt+0x24f>
f01012a4:	85 f6                	test   %esi,%esi
f01012a6:	78 d8                	js     f0101280 <vprintfmt+0x1db>
f01012a8:	83 ee 01             	sub    $0x1,%esi
f01012ab:	79 d3                	jns    f0101280 <vprintfmt+0x1db>
f01012ad:	89 fb                	mov    %edi,%ebx
f01012af:	8b 75 08             	mov    0x8(%ebp),%esi
f01012b2:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01012b5:	eb 37                	jmp    f01012ee <vprintfmt+0x249>
				if (altflag && (ch < ' ' || ch > '~'))
f01012b7:	0f be d2             	movsbl %dl,%edx
f01012ba:	83 ea 20             	sub    $0x20,%edx
f01012bd:	83 fa 5e             	cmp    $0x5e,%edx
f01012c0:	76 c4                	jbe    f0101286 <vprintfmt+0x1e1>
					putch('?', putdat);
f01012c2:	83 ec 08             	sub    $0x8,%esp
f01012c5:	ff 75 0c             	pushl  0xc(%ebp)
f01012c8:	6a 3f                	push   $0x3f
f01012ca:	ff 55 08             	call   *0x8(%ebp)
f01012cd:	83 c4 10             	add    $0x10,%esp
f01012d0:	eb c1                	jmp    f0101293 <vprintfmt+0x1ee>
f01012d2:	89 75 08             	mov    %esi,0x8(%ebp)
f01012d5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01012d8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01012db:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01012de:	eb b6                	jmp    f0101296 <vprintfmt+0x1f1>
				putch(' ', putdat);
f01012e0:	83 ec 08             	sub    $0x8,%esp
f01012e3:	57                   	push   %edi
f01012e4:	6a 20                	push   $0x20
f01012e6:	ff d6                	call   *%esi
			for (; width > 0; width--)
f01012e8:	83 eb 01             	sub    $0x1,%ebx
f01012eb:	83 c4 10             	add    $0x10,%esp
f01012ee:	85 db                	test   %ebx,%ebx
f01012f0:	7f ee                	jg     f01012e0 <vprintfmt+0x23b>
f01012f2:	eb 67                	jmp    f010135b <vprintfmt+0x2b6>
f01012f4:	89 fb                	mov    %edi,%ebx
f01012f6:	8b 75 08             	mov    0x8(%ebp),%esi
f01012f9:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01012fc:	eb f0                	jmp    f01012ee <vprintfmt+0x249>
			num = getint(&ap, lflag);
f01012fe:	8d 45 14             	lea    0x14(%ebp),%eax
f0101301:	e8 33 fd ff ff       	call   f0101039 <getint>
f0101306:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101309:	89 55 dc             	mov    %edx,-0x24(%ebp)
			base = 10;
f010130c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0101311:	85 d2                	test   %edx,%edx
f0101313:	79 2c                	jns    f0101341 <vprintfmt+0x29c>
				putch('-', putdat);
f0101315:	83 ec 08             	sub    $0x8,%esp
f0101318:	57                   	push   %edi
f0101319:	6a 2d                	push   $0x2d
f010131b:	ff d6                	call   *%esi
				num = -(long long) num;
f010131d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101320:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101323:	f7 d8                	neg    %eax
f0101325:	83 d2 00             	adc    $0x0,%edx
f0101328:	f7 da                	neg    %edx
f010132a:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010132d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101332:	eb 0d                	jmp    f0101341 <vprintfmt+0x29c>
			num = getuint(&ap, lflag);
f0101334:	8d 45 14             	lea    0x14(%ebp),%eax
f0101337:	e8 c3 fc ff ff       	call   f0100fff <getuint>
			base = 10;
f010133c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			printnum(putch, putdat, num, base, width, padc);
f0101341:	83 ec 0c             	sub    $0xc,%esp
f0101344:	0f be 5d d4          	movsbl -0x2c(%ebp),%ebx
f0101348:	53                   	push   %ebx
f0101349:	ff 75 e0             	pushl  -0x20(%ebp)
f010134c:	51                   	push   %ecx
f010134d:	52                   	push   %edx
f010134e:	50                   	push   %eax
f010134f:	89 fa                	mov    %edi,%edx
f0101351:	89 f0                	mov    %esi,%eax
f0101353:	e8 f8 fb ff ff       	call   f0100f50 <printnum>
			break;
f0101358:	83 c4 20             	add    $0x20,%esp
{
f010135b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010135e:	83 c3 01             	add    $0x1,%ebx
f0101361:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0101365:	83 f8 25             	cmp    $0x25,%eax
f0101368:	0f 84 52 fd ff ff    	je     f01010c0 <vprintfmt+0x1b>
			if (ch == '\0')
f010136e:	85 c0                	test   %eax,%eax
f0101370:	0f 84 84 00 00 00    	je     f01013fa <vprintfmt+0x355>
			putch(ch, putdat);
f0101376:	83 ec 08             	sub    $0x8,%esp
f0101379:	57                   	push   %edi
f010137a:	50                   	push   %eax
f010137b:	ff d6                	call   *%esi
f010137d:	83 c4 10             	add    $0x10,%esp
f0101380:	eb dc                	jmp    f010135e <vprintfmt+0x2b9>
			num = getuint(&ap, lflag);
f0101382:	8d 45 14             	lea    0x14(%ebp),%eax
f0101385:	e8 75 fc ff ff       	call   f0100fff <getuint>
			base = 8;
f010138a:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010138f:	eb b0                	jmp    f0101341 <vprintfmt+0x29c>
			putch('0', putdat);
f0101391:	83 ec 08             	sub    $0x8,%esp
f0101394:	57                   	push   %edi
f0101395:	6a 30                	push   $0x30
f0101397:	ff d6                	call   *%esi
			putch('x', putdat);
f0101399:	83 c4 08             	add    $0x8,%esp
f010139c:	57                   	push   %edi
f010139d:	6a 78                	push   $0x78
f010139f:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f01013a1:	8b 45 14             	mov    0x14(%ebp),%eax
f01013a4:	8d 50 04             	lea    0x4(%eax),%edx
f01013a7:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01013aa:	8b 00                	mov    (%eax),%eax
f01013ac:	ba 00 00 00 00       	mov    $0x0,%edx
			goto number;
f01013b1:	83 c4 10             	add    $0x10,%esp
			base = 16;
f01013b4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01013b9:	eb 86                	jmp    f0101341 <vprintfmt+0x29c>
			num = getuint(&ap, lflag);
f01013bb:	8d 45 14             	lea    0x14(%ebp),%eax
f01013be:	e8 3c fc ff ff       	call   f0100fff <getuint>
			base = 16;
f01013c3:	b9 10 00 00 00       	mov    $0x10,%ecx
f01013c8:	e9 74 ff ff ff       	jmp    f0101341 <vprintfmt+0x29c>
			putch(ch, putdat);
f01013cd:	83 ec 08             	sub    $0x8,%esp
f01013d0:	57                   	push   %edi
f01013d1:	6a 25                	push   $0x25
f01013d3:	ff d6                	call   *%esi
			break;
f01013d5:	83 c4 10             	add    $0x10,%esp
f01013d8:	eb 81                	jmp    f010135b <vprintfmt+0x2b6>
			putch('%', putdat);
f01013da:	83 ec 08             	sub    $0x8,%esp
f01013dd:	57                   	push   %edi
f01013de:	6a 25                	push   $0x25
f01013e0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01013e2:	83 c4 10             	add    $0x10,%esp
f01013e5:	89 d8                	mov    %ebx,%eax
f01013e7:	eb 03                	jmp    f01013ec <vprintfmt+0x347>
f01013e9:	83 e8 01             	sub    $0x1,%eax
f01013ec:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01013f0:	75 f7                	jne    f01013e9 <vprintfmt+0x344>
f01013f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013f5:	e9 61 ff ff ff       	jmp    f010135b <vprintfmt+0x2b6>
}
f01013fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013fd:	5b                   	pop    %ebx
f01013fe:	5e                   	pop    %esi
f01013ff:	5f                   	pop    %edi
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	83 ec 18             	sub    $0x18,%esp
f0101408:	8b 45 08             	mov    0x8(%ebp),%eax
f010140b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010140e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101411:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101415:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101418:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010141f:	85 c0                	test   %eax,%eax
f0101421:	74 26                	je     f0101449 <vsnprintf+0x47>
f0101423:	85 d2                	test   %edx,%edx
f0101425:	7e 22                	jle    f0101449 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101427:	ff 75 14             	pushl  0x14(%ebp)
f010142a:	ff 75 10             	pushl  0x10(%ebp)
f010142d:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101430:	50                   	push   %eax
f0101431:	68 6b 10 10 f0       	push   $0xf010106b
f0101436:	e8 6a fc ff ff       	call   f01010a5 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010143b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010143e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101441:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101444:	83 c4 10             	add    $0x10,%esp
}
f0101447:	c9                   	leave  
f0101448:	c3                   	ret    
		return -E_INVAL;
f0101449:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010144e:	eb f7                	jmp    f0101447 <vsnprintf+0x45>

f0101450 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101450:	55                   	push   %ebp
f0101451:	89 e5                	mov    %esp,%ebp
f0101453:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101456:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101459:	50                   	push   %eax
f010145a:	ff 75 10             	pushl  0x10(%ebp)
f010145d:	ff 75 0c             	pushl  0xc(%ebp)
f0101460:	ff 75 08             	pushl  0x8(%ebp)
f0101463:	e8 9a ff ff ff       	call   f0101402 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101468:	c9                   	leave  
f0101469:	c3                   	ret    

f010146a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010146a:	55                   	push   %ebp
f010146b:	89 e5                	mov    %esp,%ebp
f010146d:	57                   	push   %edi
f010146e:	56                   	push   %esi
f010146f:	53                   	push   %ebx
f0101470:	83 ec 0c             	sub    $0xc,%esp
f0101473:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101476:	85 c0                	test   %eax,%eax
f0101478:	74 11                	je     f010148b <readline+0x21>
		cprintf("%s", prompt);
f010147a:	83 ec 08             	sub    $0x8,%esp
f010147d:	50                   	push   %eax
f010147e:	68 26 21 10 f0       	push   $0xf0102126
f0101483:	e8 9e f7 ff ff       	call   f0100c26 <cprintf>
f0101488:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010148b:	83 ec 0c             	sub    $0xc,%esp
f010148e:	6a 00                	push   $0x0
f0101490:	e8 af f2 ff ff       	call   f0100744 <iscons>
f0101495:	89 c7                	mov    %eax,%edi
f0101497:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010149a:	be 00 00 00 00       	mov    $0x0,%esi
f010149f:	eb 3f                	jmp    f01014e0 <readline+0x76>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01014a1:	83 ec 08             	sub    $0x8,%esp
f01014a4:	50                   	push   %eax
f01014a5:	68 f8 22 10 f0       	push   $0xf01022f8
f01014aa:	e8 77 f7 ff ff       	call   f0100c26 <cprintf>
			return NULL;
f01014af:	83 c4 10             	add    $0x10,%esp
f01014b2:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01014b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014ba:	5b                   	pop    %ebx
f01014bb:	5e                   	pop    %esi
f01014bc:	5f                   	pop    %edi
f01014bd:	5d                   	pop    %ebp
f01014be:	c3                   	ret    
			if (echoing)
f01014bf:	85 ff                	test   %edi,%edi
f01014c1:	75 05                	jne    f01014c8 <readline+0x5e>
			i--;
f01014c3:	83 ee 01             	sub    $0x1,%esi
f01014c6:	eb 18                	jmp    f01014e0 <readline+0x76>
				cputchar('\b');
f01014c8:	83 ec 0c             	sub    $0xc,%esp
f01014cb:	6a 08                	push   $0x8
f01014cd:	e8 51 f2 ff ff       	call   f0100723 <cputchar>
f01014d2:	83 c4 10             	add    $0x10,%esp
f01014d5:	eb ec                	jmp    f01014c3 <readline+0x59>
			buf[i++] = c;
f01014d7:	88 9e 40 35 11 f0    	mov    %bl,-0xfeecac0(%esi)
f01014dd:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f01014e0:	e8 4e f2 ff ff       	call   f0100733 <getchar>
f01014e5:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01014e7:	85 c0                	test   %eax,%eax
f01014e9:	78 b6                	js     f01014a1 <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01014eb:	83 f8 08             	cmp    $0x8,%eax
f01014ee:	0f 94 c2             	sete   %dl
f01014f1:	83 f8 7f             	cmp    $0x7f,%eax
f01014f4:	0f 94 c0             	sete   %al
f01014f7:	08 c2                	or     %al,%dl
f01014f9:	74 04                	je     f01014ff <readline+0x95>
f01014fb:	85 f6                	test   %esi,%esi
f01014fd:	7f c0                	jg     f01014bf <readline+0x55>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01014ff:	83 fb 1f             	cmp    $0x1f,%ebx
f0101502:	7e 1a                	jle    f010151e <readline+0xb4>
f0101504:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010150a:	7f 12                	jg     f010151e <readline+0xb4>
			if (echoing)
f010150c:	85 ff                	test   %edi,%edi
f010150e:	74 c7                	je     f01014d7 <readline+0x6d>
				cputchar(c);
f0101510:	83 ec 0c             	sub    $0xc,%esp
f0101513:	53                   	push   %ebx
f0101514:	e8 0a f2 ff ff       	call   f0100723 <cputchar>
f0101519:	83 c4 10             	add    $0x10,%esp
f010151c:	eb b9                	jmp    f01014d7 <readline+0x6d>
		} else if (c == '\n' || c == '\r') {
f010151e:	83 fb 0a             	cmp    $0xa,%ebx
f0101521:	74 05                	je     f0101528 <readline+0xbe>
f0101523:	83 fb 0d             	cmp    $0xd,%ebx
f0101526:	75 b8                	jne    f01014e0 <readline+0x76>
			if (echoing)
f0101528:	85 ff                	test   %edi,%edi
f010152a:	75 11                	jne    f010153d <readline+0xd3>
			buf[i] = 0;
f010152c:	c6 86 40 35 11 f0 00 	movb   $0x0,-0xfeecac0(%esi)
			return buf;
f0101533:	b8 40 35 11 f0       	mov    $0xf0113540,%eax
f0101538:	e9 7a ff ff ff       	jmp    f01014b7 <readline+0x4d>
				cputchar('\n');
f010153d:	83 ec 0c             	sub    $0xc,%esp
f0101540:	6a 0a                	push   $0xa
f0101542:	e8 dc f1 ff ff       	call   f0100723 <cputchar>
f0101547:	83 c4 10             	add    $0x10,%esp
f010154a:	eb e0                	jmp    f010152c <readline+0xc2>

f010154c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010154c:	55                   	push   %ebp
f010154d:	89 e5                	mov    %esp,%ebp
f010154f:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101552:	b8 00 00 00 00       	mov    $0x0,%eax
f0101557:	eb 03                	jmp    f010155c <strlen+0x10>
		n++;
f0101559:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010155c:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101560:	75 f7                	jne    f0101559 <strlen+0xd>
	return n;
}
f0101562:	5d                   	pop    %ebp
f0101563:	c3                   	ret    

f0101564 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
f0101567:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010156a:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010156d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101572:	eb 03                	jmp    f0101577 <strnlen+0x13>
		n++;
f0101574:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101577:	39 d0                	cmp    %edx,%eax
f0101579:	74 06                	je     f0101581 <strnlen+0x1d>
f010157b:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010157f:	75 f3                	jne    f0101574 <strnlen+0x10>
	return n;
}
f0101581:	5d                   	pop    %ebp
f0101582:	c3                   	ret    

f0101583 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101583:	55                   	push   %ebp
f0101584:	89 e5                	mov    %esp,%ebp
f0101586:	53                   	push   %ebx
f0101587:	8b 45 08             	mov    0x8(%ebp),%eax
f010158a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010158d:	89 c2                	mov    %eax,%edx
f010158f:	83 c1 01             	add    $0x1,%ecx
f0101592:	83 c2 01             	add    $0x1,%edx
f0101595:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101599:	88 5a ff             	mov    %bl,-0x1(%edx)
f010159c:	84 db                	test   %bl,%bl
f010159e:	75 ef                	jne    f010158f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01015a0:	5b                   	pop    %ebx
f01015a1:	5d                   	pop    %ebp
f01015a2:	c3                   	ret    

f01015a3 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01015a3:	55                   	push   %ebp
f01015a4:	89 e5                	mov    %esp,%ebp
f01015a6:	53                   	push   %ebx
f01015a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01015aa:	53                   	push   %ebx
f01015ab:	e8 9c ff ff ff       	call   f010154c <strlen>
f01015b0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01015b3:	ff 75 0c             	pushl  0xc(%ebp)
f01015b6:	01 d8                	add    %ebx,%eax
f01015b8:	50                   	push   %eax
f01015b9:	e8 c5 ff ff ff       	call   f0101583 <strcpy>
	return dst;
}
f01015be:	89 d8                	mov    %ebx,%eax
f01015c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015c3:	c9                   	leave  
f01015c4:	c3                   	ret    

f01015c5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01015c5:	55                   	push   %ebp
f01015c6:	89 e5                	mov    %esp,%ebp
f01015c8:	56                   	push   %esi
f01015c9:	53                   	push   %ebx
f01015ca:	8b 75 08             	mov    0x8(%ebp),%esi
f01015cd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015d0:	89 f3                	mov    %esi,%ebx
f01015d2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01015d5:	89 f2                	mov    %esi,%edx
f01015d7:	eb 0f                	jmp    f01015e8 <strncpy+0x23>
		*dst++ = *src;
f01015d9:	83 c2 01             	add    $0x1,%edx
f01015dc:	0f b6 01             	movzbl (%ecx),%eax
f01015df:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01015e2:	80 39 01             	cmpb   $0x1,(%ecx)
f01015e5:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01015e8:	39 da                	cmp    %ebx,%edx
f01015ea:	75 ed                	jne    f01015d9 <strncpy+0x14>
	}
	return ret;
}
f01015ec:	89 f0                	mov    %esi,%eax
f01015ee:	5b                   	pop    %ebx
f01015ef:	5e                   	pop    %esi
f01015f0:	5d                   	pop    %ebp
f01015f1:	c3                   	ret    

f01015f2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01015f2:	55                   	push   %ebp
f01015f3:	89 e5                	mov    %esp,%ebp
f01015f5:	56                   	push   %esi
f01015f6:	53                   	push   %ebx
f01015f7:	8b 75 08             	mov    0x8(%ebp),%esi
f01015fa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101600:	89 f0                	mov    %esi,%eax
f0101602:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101606:	85 c9                	test   %ecx,%ecx
f0101608:	75 0b                	jne    f0101615 <strlcpy+0x23>
f010160a:	eb 17                	jmp    f0101623 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010160c:	83 c2 01             	add    $0x1,%edx
f010160f:	83 c0 01             	add    $0x1,%eax
f0101612:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101615:	39 d8                	cmp    %ebx,%eax
f0101617:	74 07                	je     f0101620 <strlcpy+0x2e>
f0101619:	0f b6 0a             	movzbl (%edx),%ecx
f010161c:	84 c9                	test   %cl,%cl
f010161e:	75 ec                	jne    f010160c <strlcpy+0x1a>
		*dst = '\0';
f0101620:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101623:	29 f0                	sub    %esi,%eax
}
f0101625:	5b                   	pop    %ebx
f0101626:	5e                   	pop    %esi
f0101627:	5d                   	pop    %ebp
f0101628:	c3                   	ret    

f0101629 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101629:	55                   	push   %ebp
f010162a:	89 e5                	mov    %esp,%ebp
f010162c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010162f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101632:	eb 06                	jmp    f010163a <strcmp+0x11>
		p++, q++;
f0101634:	83 c1 01             	add    $0x1,%ecx
f0101637:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010163a:	0f b6 01             	movzbl (%ecx),%eax
f010163d:	84 c0                	test   %al,%al
f010163f:	74 04                	je     f0101645 <strcmp+0x1c>
f0101641:	3a 02                	cmp    (%edx),%al
f0101643:	74 ef                	je     f0101634 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101645:	0f b6 c0             	movzbl %al,%eax
f0101648:	0f b6 12             	movzbl (%edx),%edx
f010164b:	29 d0                	sub    %edx,%eax
}
f010164d:	5d                   	pop    %ebp
f010164e:	c3                   	ret    

f010164f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010164f:	55                   	push   %ebp
f0101650:	89 e5                	mov    %esp,%ebp
f0101652:	53                   	push   %ebx
f0101653:	8b 45 08             	mov    0x8(%ebp),%eax
f0101656:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101659:	89 c3                	mov    %eax,%ebx
f010165b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010165e:	eb 06                	jmp    f0101666 <strncmp+0x17>
		n--, p++, q++;
f0101660:	83 c0 01             	add    $0x1,%eax
f0101663:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101666:	39 d8                	cmp    %ebx,%eax
f0101668:	74 16                	je     f0101680 <strncmp+0x31>
f010166a:	0f b6 08             	movzbl (%eax),%ecx
f010166d:	84 c9                	test   %cl,%cl
f010166f:	74 04                	je     f0101675 <strncmp+0x26>
f0101671:	3a 0a                	cmp    (%edx),%cl
f0101673:	74 eb                	je     f0101660 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101675:	0f b6 00             	movzbl (%eax),%eax
f0101678:	0f b6 12             	movzbl (%edx),%edx
f010167b:	29 d0                	sub    %edx,%eax
}
f010167d:	5b                   	pop    %ebx
f010167e:	5d                   	pop    %ebp
f010167f:	c3                   	ret    
		return 0;
f0101680:	b8 00 00 00 00       	mov    $0x0,%eax
f0101685:	eb f6                	jmp    f010167d <strncmp+0x2e>

f0101687 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101687:	55                   	push   %ebp
f0101688:	89 e5                	mov    %esp,%ebp
f010168a:	8b 45 08             	mov    0x8(%ebp),%eax
f010168d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101691:	0f b6 10             	movzbl (%eax),%edx
f0101694:	84 d2                	test   %dl,%dl
f0101696:	74 09                	je     f01016a1 <strchr+0x1a>
		if (*s == c)
f0101698:	38 ca                	cmp    %cl,%dl
f010169a:	74 0a                	je     f01016a6 <strchr+0x1f>
	for (; *s; s++)
f010169c:	83 c0 01             	add    $0x1,%eax
f010169f:	eb f0                	jmp    f0101691 <strchr+0xa>
			return (char *) s;
	return 0;
f01016a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016a6:	5d                   	pop    %ebp
f01016a7:	c3                   	ret    

f01016a8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01016a8:	55                   	push   %ebp
f01016a9:	89 e5                	mov    %esp,%ebp
f01016ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ae:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016b2:	eb 03                	jmp    f01016b7 <strfind+0xf>
f01016b4:	83 c0 01             	add    $0x1,%eax
f01016b7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01016ba:	38 ca                	cmp    %cl,%dl
f01016bc:	74 04                	je     f01016c2 <strfind+0x1a>
f01016be:	84 d2                	test   %dl,%dl
f01016c0:	75 f2                	jne    f01016b4 <strfind+0xc>
			break;
	return (char *) s;
}
f01016c2:	5d                   	pop    %ebp
f01016c3:	c3                   	ret    

f01016c4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016c4:	55                   	push   %ebp
f01016c5:	89 e5                	mov    %esp,%ebp
f01016c7:	57                   	push   %edi
f01016c8:	56                   	push   %esi
f01016c9:	53                   	push   %ebx
f01016ca:	8b 55 08             	mov    0x8(%ebp),%edx
f01016cd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01016d0:	85 c9                	test   %ecx,%ecx
f01016d2:	74 12                	je     f01016e6 <memset+0x22>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016d4:	f6 c2 03             	test   $0x3,%dl
f01016d7:	75 05                	jne    f01016de <memset+0x1a>
f01016d9:	f6 c1 03             	test   $0x3,%cl
f01016dc:	74 0f                	je     f01016ed <memset+0x29>
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016de:	89 d7                	mov    %edx,%edi
f01016e0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016e3:	fc                   	cld    
f01016e4:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01016e6:	89 d0                	mov    %edx,%eax
f01016e8:	5b                   	pop    %ebx
f01016e9:	5e                   	pop    %esi
f01016ea:	5f                   	pop    %edi
f01016eb:	5d                   	pop    %ebp
f01016ec:	c3                   	ret    
		c &= 0xFF;
f01016ed:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016f1:	89 d8                	mov    %ebx,%eax
f01016f3:	c1 e0 08             	shl    $0x8,%eax
f01016f6:	89 df                	mov    %ebx,%edi
f01016f8:	c1 e7 18             	shl    $0x18,%edi
f01016fb:	89 de                	mov    %ebx,%esi
f01016fd:	c1 e6 10             	shl    $0x10,%esi
f0101700:	09 f7                	or     %esi,%edi
f0101702:	09 fb                	or     %edi,%ebx
			: "D" (p), "a" (c), "c" (n/4)
f0101704:	c1 e9 02             	shr    $0x2,%ecx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101707:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f0101709:	89 d7                	mov    %edx,%edi
f010170b:	fc                   	cld    
f010170c:	f3 ab                	rep stos %eax,%es:(%edi)
f010170e:	eb d6                	jmp    f01016e6 <memset+0x22>

f0101710 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101710:	55                   	push   %ebp
f0101711:	89 e5                	mov    %esp,%ebp
f0101713:	57                   	push   %edi
f0101714:	56                   	push   %esi
f0101715:	8b 45 08             	mov    0x8(%ebp),%eax
f0101718:	8b 75 0c             	mov    0xc(%ebp),%esi
f010171b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010171e:	39 c6                	cmp    %eax,%esi
f0101720:	73 35                	jae    f0101757 <memmove+0x47>
f0101722:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101725:	39 c2                	cmp    %eax,%edx
f0101727:	76 2e                	jbe    f0101757 <memmove+0x47>
		s += n;
		d += n;
f0101729:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010172c:	89 d6                	mov    %edx,%esi
f010172e:	09 fe                	or     %edi,%esi
f0101730:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101736:	74 0c                	je     f0101744 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101738:	83 ef 01             	sub    $0x1,%edi
f010173b:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010173e:	fd                   	std    
f010173f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101741:	fc                   	cld    
f0101742:	eb 21                	jmp    f0101765 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101744:	f6 c1 03             	test   $0x3,%cl
f0101747:	75 ef                	jne    f0101738 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101749:	83 ef 04             	sub    $0x4,%edi
f010174c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010174f:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101752:	fd                   	std    
f0101753:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101755:	eb ea                	jmp    f0101741 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101757:	89 f2                	mov    %esi,%edx
f0101759:	09 c2                	or     %eax,%edx
f010175b:	f6 c2 03             	test   $0x3,%dl
f010175e:	74 09                	je     f0101769 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101760:	89 c7                	mov    %eax,%edi
f0101762:	fc                   	cld    
f0101763:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101765:	5e                   	pop    %esi
f0101766:	5f                   	pop    %edi
f0101767:	5d                   	pop    %ebp
f0101768:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101769:	f6 c1 03             	test   $0x3,%cl
f010176c:	75 f2                	jne    f0101760 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010176e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101771:	89 c7                	mov    %eax,%edi
f0101773:	fc                   	cld    
f0101774:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101776:	eb ed                	jmp    f0101765 <memmove+0x55>

f0101778 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101778:	55                   	push   %ebp
f0101779:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010177b:	ff 75 10             	pushl  0x10(%ebp)
f010177e:	ff 75 0c             	pushl  0xc(%ebp)
f0101781:	ff 75 08             	pushl  0x8(%ebp)
f0101784:	e8 87 ff ff ff       	call   f0101710 <memmove>
}
f0101789:	c9                   	leave  
f010178a:	c3                   	ret    

f010178b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010178b:	55                   	push   %ebp
f010178c:	89 e5                	mov    %esp,%ebp
f010178e:	56                   	push   %esi
f010178f:	53                   	push   %ebx
f0101790:	8b 45 08             	mov    0x8(%ebp),%eax
f0101793:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101796:	89 c6                	mov    %eax,%esi
f0101798:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010179b:	39 f0                	cmp    %esi,%eax
f010179d:	74 1c                	je     f01017bb <memcmp+0x30>
		if (*s1 != *s2)
f010179f:	0f b6 08             	movzbl (%eax),%ecx
f01017a2:	0f b6 1a             	movzbl (%edx),%ebx
f01017a5:	38 d9                	cmp    %bl,%cl
f01017a7:	75 08                	jne    f01017b1 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01017a9:	83 c0 01             	add    $0x1,%eax
f01017ac:	83 c2 01             	add    $0x1,%edx
f01017af:	eb ea                	jmp    f010179b <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01017b1:	0f b6 c1             	movzbl %cl,%eax
f01017b4:	0f b6 db             	movzbl %bl,%ebx
f01017b7:	29 d8                	sub    %ebx,%eax
f01017b9:	eb 05                	jmp    f01017c0 <memcmp+0x35>
	}

	return 0;
f01017bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017c0:	5b                   	pop    %ebx
f01017c1:	5e                   	pop    %esi
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    

f01017c4 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017c4:	55                   	push   %ebp
f01017c5:	89 e5                	mov    %esp,%ebp
f01017c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01017cd:	89 c2                	mov    %eax,%edx
f01017cf:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017d2:	39 d0                	cmp    %edx,%eax
f01017d4:	73 09                	jae    f01017df <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017d6:	38 08                	cmp    %cl,(%eax)
f01017d8:	74 05                	je     f01017df <memfind+0x1b>
	for (; s < ends; s++)
f01017da:	83 c0 01             	add    $0x1,%eax
f01017dd:	eb f3                	jmp    f01017d2 <memfind+0xe>
			break;
	return (void *) s;
}
f01017df:	5d                   	pop    %ebp
f01017e0:	c3                   	ret    

f01017e1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017e1:	55                   	push   %ebp
f01017e2:	89 e5                	mov    %esp,%ebp
f01017e4:	57                   	push   %edi
f01017e5:	56                   	push   %esi
f01017e6:	53                   	push   %ebx
f01017e7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017ed:	eb 03                	jmp    f01017f2 <strtol+0x11>
		s++;
f01017ef:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01017f2:	0f b6 01             	movzbl (%ecx),%eax
f01017f5:	3c 20                	cmp    $0x20,%al
f01017f7:	74 f6                	je     f01017ef <strtol+0xe>
f01017f9:	3c 09                	cmp    $0x9,%al
f01017fb:	74 f2                	je     f01017ef <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01017fd:	3c 2b                	cmp    $0x2b,%al
f01017ff:	74 2e                	je     f010182f <strtol+0x4e>
	int neg = 0;
f0101801:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101806:	3c 2d                	cmp    $0x2d,%al
f0101808:	74 2f                	je     f0101839 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010180a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101810:	75 05                	jne    f0101817 <strtol+0x36>
f0101812:	80 39 30             	cmpb   $0x30,(%ecx)
f0101815:	74 2c                	je     f0101843 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101817:	85 db                	test   %ebx,%ebx
f0101819:	75 0a                	jne    f0101825 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010181b:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0101820:	80 39 30             	cmpb   $0x30,(%ecx)
f0101823:	74 28                	je     f010184d <strtol+0x6c>
		base = 10;
f0101825:	b8 00 00 00 00       	mov    $0x0,%eax
f010182a:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010182d:	eb 50                	jmp    f010187f <strtol+0x9e>
		s++;
f010182f:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101832:	bf 00 00 00 00       	mov    $0x0,%edi
f0101837:	eb d1                	jmp    f010180a <strtol+0x29>
		s++, neg = 1;
f0101839:	83 c1 01             	add    $0x1,%ecx
f010183c:	bf 01 00 00 00       	mov    $0x1,%edi
f0101841:	eb c7                	jmp    f010180a <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101843:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101847:	74 0e                	je     f0101857 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101849:	85 db                	test   %ebx,%ebx
f010184b:	75 d8                	jne    f0101825 <strtol+0x44>
		s++, base = 8;
f010184d:	83 c1 01             	add    $0x1,%ecx
f0101850:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101855:	eb ce                	jmp    f0101825 <strtol+0x44>
		s += 2, base = 16;
f0101857:	83 c1 02             	add    $0x2,%ecx
f010185a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010185f:	eb c4                	jmp    f0101825 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101861:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101864:	89 f3                	mov    %esi,%ebx
f0101866:	80 fb 19             	cmp    $0x19,%bl
f0101869:	77 29                	ja     f0101894 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010186b:	0f be d2             	movsbl %dl,%edx
f010186e:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101871:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101874:	7d 30                	jge    f01018a6 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101876:	83 c1 01             	add    $0x1,%ecx
f0101879:	0f af 45 10          	imul   0x10(%ebp),%eax
f010187d:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010187f:	0f b6 11             	movzbl (%ecx),%edx
f0101882:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101885:	89 f3                	mov    %esi,%ebx
f0101887:	80 fb 09             	cmp    $0x9,%bl
f010188a:	77 d5                	ja     f0101861 <strtol+0x80>
			dig = *s - '0';
f010188c:	0f be d2             	movsbl %dl,%edx
f010188f:	83 ea 30             	sub    $0x30,%edx
f0101892:	eb dd                	jmp    f0101871 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101894:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101897:	89 f3                	mov    %esi,%ebx
f0101899:	80 fb 19             	cmp    $0x19,%bl
f010189c:	77 08                	ja     f01018a6 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010189e:	0f be d2             	movsbl %dl,%edx
f01018a1:	83 ea 37             	sub    $0x37,%edx
f01018a4:	eb cb                	jmp    f0101871 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01018a6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018aa:	74 05                	je     f01018b1 <strtol+0xd0>
		*endptr = (char *) s;
f01018ac:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018af:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01018b1:	89 c2                	mov    %eax,%edx
f01018b3:	f7 da                	neg    %edx
f01018b5:	85 ff                	test   %edi,%edi
f01018b7:	0f 45 c2             	cmovne %edx,%eax
}
f01018ba:	5b                   	pop    %ebx
f01018bb:	5e                   	pop    %esi
f01018bc:	5f                   	pop    %edi
f01018bd:	5d                   	pop    %ebp
f01018be:	c3                   	ret    
f01018bf:	90                   	nop

f01018c0 <__udivdi3>:
f01018c0:	55                   	push   %ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	53                   	push   %ebx
f01018c4:	83 ec 1c             	sub    $0x1c,%esp
f01018c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01018cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01018cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01018d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01018d7:	85 d2                	test   %edx,%edx
f01018d9:	75 35                	jne    f0101910 <__udivdi3+0x50>
f01018db:	39 f3                	cmp    %esi,%ebx
f01018dd:	0f 87 bd 00 00 00    	ja     f01019a0 <__udivdi3+0xe0>
f01018e3:	85 db                	test   %ebx,%ebx
f01018e5:	89 d9                	mov    %ebx,%ecx
f01018e7:	75 0b                	jne    f01018f4 <__udivdi3+0x34>
f01018e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01018ee:	31 d2                	xor    %edx,%edx
f01018f0:	f7 f3                	div    %ebx
f01018f2:	89 c1                	mov    %eax,%ecx
f01018f4:	31 d2                	xor    %edx,%edx
f01018f6:	89 f0                	mov    %esi,%eax
f01018f8:	f7 f1                	div    %ecx
f01018fa:	89 c6                	mov    %eax,%esi
f01018fc:	89 e8                	mov    %ebp,%eax
f01018fe:	89 f7                	mov    %esi,%edi
f0101900:	f7 f1                	div    %ecx
f0101902:	89 fa                	mov    %edi,%edx
f0101904:	83 c4 1c             	add    $0x1c,%esp
f0101907:	5b                   	pop    %ebx
f0101908:	5e                   	pop    %esi
f0101909:	5f                   	pop    %edi
f010190a:	5d                   	pop    %ebp
f010190b:	c3                   	ret    
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	39 f2                	cmp    %esi,%edx
f0101912:	77 7c                	ja     f0101990 <__udivdi3+0xd0>
f0101914:	0f bd fa             	bsr    %edx,%edi
f0101917:	83 f7 1f             	xor    $0x1f,%edi
f010191a:	0f 84 98 00 00 00    	je     f01019b8 <__udivdi3+0xf8>
f0101920:	89 f9                	mov    %edi,%ecx
f0101922:	b8 20 00 00 00       	mov    $0x20,%eax
f0101927:	29 f8                	sub    %edi,%eax
f0101929:	d3 e2                	shl    %cl,%edx
f010192b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010192f:	89 c1                	mov    %eax,%ecx
f0101931:	89 da                	mov    %ebx,%edx
f0101933:	d3 ea                	shr    %cl,%edx
f0101935:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101939:	09 d1                	or     %edx,%ecx
f010193b:	89 f2                	mov    %esi,%edx
f010193d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101941:	89 f9                	mov    %edi,%ecx
f0101943:	d3 e3                	shl    %cl,%ebx
f0101945:	89 c1                	mov    %eax,%ecx
f0101947:	d3 ea                	shr    %cl,%edx
f0101949:	89 f9                	mov    %edi,%ecx
f010194b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010194f:	d3 e6                	shl    %cl,%esi
f0101951:	89 eb                	mov    %ebp,%ebx
f0101953:	89 c1                	mov    %eax,%ecx
f0101955:	d3 eb                	shr    %cl,%ebx
f0101957:	09 de                	or     %ebx,%esi
f0101959:	89 f0                	mov    %esi,%eax
f010195b:	f7 74 24 08          	divl   0x8(%esp)
f010195f:	89 d6                	mov    %edx,%esi
f0101961:	89 c3                	mov    %eax,%ebx
f0101963:	f7 64 24 0c          	mull   0xc(%esp)
f0101967:	39 d6                	cmp    %edx,%esi
f0101969:	72 0c                	jb     f0101977 <__udivdi3+0xb7>
f010196b:	89 f9                	mov    %edi,%ecx
f010196d:	d3 e5                	shl    %cl,%ebp
f010196f:	39 c5                	cmp    %eax,%ebp
f0101971:	73 5d                	jae    f01019d0 <__udivdi3+0x110>
f0101973:	39 d6                	cmp    %edx,%esi
f0101975:	75 59                	jne    f01019d0 <__udivdi3+0x110>
f0101977:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010197a:	31 ff                	xor    %edi,%edi
f010197c:	89 fa                	mov    %edi,%edx
f010197e:	83 c4 1c             	add    $0x1c,%esp
f0101981:	5b                   	pop    %ebx
f0101982:	5e                   	pop    %esi
f0101983:	5f                   	pop    %edi
f0101984:	5d                   	pop    %ebp
f0101985:	c3                   	ret    
f0101986:	8d 76 00             	lea    0x0(%esi),%esi
f0101989:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101990:	31 ff                	xor    %edi,%edi
f0101992:	31 c0                	xor    %eax,%eax
f0101994:	89 fa                	mov    %edi,%edx
f0101996:	83 c4 1c             	add    $0x1c,%esp
f0101999:	5b                   	pop    %ebx
f010199a:	5e                   	pop    %esi
f010199b:	5f                   	pop    %edi
f010199c:	5d                   	pop    %ebp
f010199d:	c3                   	ret    
f010199e:	66 90                	xchg   %ax,%ax
f01019a0:	31 ff                	xor    %edi,%edi
f01019a2:	89 e8                	mov    %ebp,%eax
f01019a4:	89 f2                	mov    %esi,%edx
f01019a6:	f7 f3                	div    %ebx
f01019a8:	89 fa                	mov    %edi,%edx
f01019aa:	83 c4 1c             	add    $0x1c,%esp
f01019ad:	5b                   	pop    %ebx
f01019ae:	5e                   	pop    %esi
f01019af:	5f                   	pop    %edi
f01019b0:	5d                   	pop    %ebp
f01019b1:	c3                   	ret    
f01019b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019b8:	39 f2                	cmp    %esi,%edx
f01019ba:	72 06                	jb     f01019c2 <__udivdi3+0x102>
f01019bc:	31 c0                	xor    %eax,%eax
f01019be:	39 eb                	cmp    %ebp,%ebx
f01019c0:	77 d2                	ja     f0101994 <__udivdi3+0xd4>
f01019c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01019c7:	eb cb                	jmp    f0101994 <__udivdi3+0xd4>
f01019c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019d0:	89 d8                	mov    %ebx,%eax
f01019d2:	31 ff                	xor    %edi,%edi
f01019d4:	eb be                	jmp    f0101994 <__udivdi3+0xd4>
f01019d6:	66 90                	xchg   %ax,%ax
f01019d8:	66 90                	xchg   %ax,%ax
f01019da:	66 90                	xchg   %ax,%ax
f01019dc:	66 90                	xchg   %ax,%ax
f01019de:	66 90                	xchg   %ax,%ax

f01019e0 <__umoddi3>:
f01019e0:	55                   	push   %ebp
f01019e1:	57                   	push   %edi
f01019e2:	56                   	push   %esi
f01019e3:	53                   	push   %ebx
f01019e4:	83 ec 1c             	sub    $0x1c,%esp
f01019e7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01019eb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01019ef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01019f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01019f7:	85 ed                	test   %ebp,%ebp
f01019f9:	89 f0                	mov    %esi,%eax
f01019fb:	89 da                	mov    %ebx,%edx
f01019fd:	75 19                	jne    f0101a18 <__umoddi3+0x38>
f01019ff:	39 df                	cmp    %ebx,%edi
f0101a01:	0f 86 b1 00 00 00    	jbe    f0101ab8 <__umoddi3+0xd8>
f0101a07:	f7 f7                	div    %edi
f0101a09:	89 d0                	mov    %edx,%eax
f0101a0b:	31 d2                	xor    %edx,%edx
f0101a0d:	83 c4 1c             	add    $0x1c,%esp
f0101a10:	5b                   	pop    %ebx
f0101a11:	5e                   	pop    %esi
f0101a12:	5f                   	pop    %edi
f0101a13:	5d                   	pop    %ebp
f0101a14:	c3                   	ret    
f0101a15:	8d 76 00             	lea    0x0(%esi),%esi
f0101a18:	39 dd                	cmp    %ebx,%ebp
f0101a1a:	77 f1                	ja     f0101a0d <__umoddi3+0x2d>
f0101a1c:	0f bd cd             	bsr    %ebp,%ecx
f0101a1f:	83 f1 1f             	xor    $0x1f,%ecx
f0101a22:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101a26:	0f 84 b4 00 00 00    	je     f0101ae0 <__umoddi3+0x100>
f0101a2c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a31:	89 c2                	mov    %eax,%edx
f0101a33:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a37:	29 c2                	sub    %eax,%edx
f0101a39:	89 c1                	mov    %eax,%ecx
f0101a3b:	89 f8                	mov    %edi,%eax
f0101a3d:	d3 e5                	shl    %cl,%ebp
f0101a3f:	89 d1                	mov    %edx,%ecx
f0101a41:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101a45:	d3 e8                	shr    %cl,%eax
f0101a47:	09 c5                	or     %eax,%ebp
f0101a49:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a4d:	89 c1                	mov    %eax,%ecx
f0101a4f:	d3 e7                	shl    %cl,%edi
f0101a51:	89 d1                	mov    %edx,%ecx
f0101a53:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101a57:	89 df                	mov    %ebx,%edi
f0101a59:	d3 ef                	shr    %cl,%edi
f0101a5b:	89 c1                	mov    %eax,%ecx
f0101a5d:	89 f0                	mov    %esi,%eax
f0101a5f:	d3 e3                	shl    %cl,%ebx
f0101a61:	89 d1                	mov    %edx,%ecx
f0101a63:	89 fa                	mov    %edi,%edx
f0101a65:	d3 e8                	shr    %cl,%eax
f0101a67:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a6c:	09 d8                	or     %ebx,%eax
f0101a6e:	f7 f5                	div    %ebp
f0101a70:	d3 e6                	shl    %cl,%esi
f0101a72:	89 d1                	mov    %edx,%ecx
f0101a74:	f7 64 24 08          	mull   0x8(%esp)
f0101a78:	39 d1                	cmp    %edx,%ecx
f0101a7a:	89 c3                	mov    %eax,%ebx
f0101a7c:	89 d7                	mov    %edx,%edi
f0101a7e:	72 06                	jb     f0101a86 <__umoddi3+0xa6>
f0101a80:	75 0e                	jne    f0101a90 <__umoddi3+0xb0>
f0101a82:	39 c6                	cmp    %eax,%esi
f0101a84:	73 0a                	jae    f0101a90 <__umoddi3+0xb0>
f0101a86:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101a8a:	19 ea                	sbb    %ebp,%edx
f0101a8c:	89 d7                	mov    %edx,%edi
f0101a8e:	89 c3                	mov    %eax,%ebx
f0101a90:	89 ca                	mov    %ecx,%edx
f0101a92:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101a97:	29 de                	sub    %ebx,%esi
f0101a99:	19 fa                	sbb    %edi,%edx
f0101a9b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101a9f:	89 d0                	mov    %edx,%eax
f0101aa1:	d3 e0                	shl    %cl,%eax
f0101aa3:	89 d9                	mov    %ebx,%ecx
f0101aa5:	d3 ee                	shr    %cl,%esi
f0101aa7:	d3 ea                	shr    %cl,%edx
f0101aa9:	09 f0                	or     %esi,%eax
f0101aab:	83 c4 1c             	add    $0x1c,%esp
f0101aae:	5b                   	pop    %ebx
f0101aaf:	5e                   	pop    %esi
f0101ab0:	5f                   	pop    %edi
f0101ab1:	5d                   	pop    %ebp
f0101ab2:	c3                   	ret    
f0101ab3:	90                   	nop
f0101ab4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ab8:	85 ff                	test   %edi,%edi
f0101aba:	89 f9                	mov    %edi,%ecx
f0101abc:	75 0b                	jne    f0101ac9 <__umoddi3+0xe9>
f0101abe:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ac3:	31 d2                	xor    %edx,%edx
f0101ac5:	f7 f7                	div    %edi
f0101ac7:	89 c1                	mov    %eax,%ecx
f0101ac9:	89 d8                	mov    %ebx,%eax
f0101acb:	31 d2                	xor    %edx,%edx
f0101acd:	f7 f1                	div    %ecx
f0101acf:	89 f0                	mov    %esi,%eax
f0101ad1:	f7 f1                	div    %ecx
f0101ad3:	e9 31 ff ff ff       	jmp    f0101a09 <__umoddi3+0x29>
f0101ad8:	90                   	nop
f0101ad9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ae0:	39 dd                	cmp    %ebx,%ebp
f0101ae2:	72 08                	jb     f0101aec <__umoddi3+0x10c>
f0101ae4:	39 f7                	cmp    %esi,%edi
f0101ae6:	0f 87 21 ff ff ff    	ja     f0101a0d <__umoddi3+0x2d>
f0101aec:	89 da                	mov    %ebx,%edx
f0101aee:	89 f0                	mov    %esi,%eax
f0101af0:	29 f8                	sub    %edi,%eax
f0101af2:	19 ea                	sbb    %ebp,%edx
f0101af4:	e9 14 ff ff ff       	jmp    f0101a0d <__umoddi3+0x2d>
