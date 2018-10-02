
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100046:	b8 50 79 11 f0       	mov    $0xf0117950,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 f7 30 00 00       	call   f0103154 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 78 06 00 00       	call   f01006da <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 36 10 f0       	push   $0xf0103600
f010006f:	e8 39 26 00 00       	call   f01026ad <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 3f 24 00 00       	call   f01024b8 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 bd 08 00 00       	call   f0100943 <monitor>
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
f0100093:	83 3d 40 79 11 f0 00 	cmpl   $0x0,0xf0117940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 79 11 f0    	mov    %esi,0xf0117940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 3c 36 10 f0       	push   $0xf010363c
f01000b5:	e8 f3 25 00 00       	call   f01026ad <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 c3 25 00 00       	call   f0102687 <vcprintf>
	cprintf("\n>>>\n");
f01000c4:	c7 04 24 1b 36 10 f0 	movl   $0xf010361b,(%esp)
f01000cb:	e8 dd 25 00 00       	call   f01026ad <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 66 08 00 00       	call   f0100943 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 21 36 10 f0       	push   $0xf0103621
f01000f7:	e8 b1 25 00 00       	call   f01026ad <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 7f 25 00 00       	call   f0102687 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 c8 45 10 f0 	movl   $0xf01045c8,(%esp)
f010010f:	e8 99 25 00 00       	call   f01026ad <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	89 c2                	mov    %eax,%edx
f0100121:	ec                   	in     (%dx),%al
	return data;
}
f0100122:	5d                   	pop    %ebp
f0100123:	c3                   	ret    

f0100124 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100124:	55                   	push   %ebp
f0100125:	89 e5                	mov    %esp,%ebp
f0100127:	89 c1                	mov    %eax,%ecx
f0100129:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010012b:	89 ca                	mov    %ecx,%edx
f010012d:	ee                   	out    %al,(%dx)
}
f010012e:	5d                   	pop    %ebp
f010012f:	c3                   	ret    

f0100130 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100130:	55                   	push   %ebp
f0100131:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100133:	b8 84 00 00 00       	mov    $0x84,%eax
f0100138:	e8 df ff ff ff       	call   f010011c <inb>
	inb(0x84);
f010013d:	b8 84 00 00 00       	mov    $0x84,%eax
f0100142:	e8 d5 ff ff ff       	call   f010011c <inb>
	inb(0x84);
f0100147:	b8 84 00 00 00       	mov    $0x84,%eax
f010014c:	e8 cb ff ff ff       	call   f010011c <inb>
	inb(0x84);
f0100151:	b8 84 00 00 00       	mov    $0x84,%eax
f0100156:	e8 c1 ff ff ff       	call   f010011c <inb>
}
f010015b:	5d                   	pop    %ebp
f010015c:	c3                   	ret    

f010015d <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010015d:	55                   	push   %ebp
f010015e:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100160:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100165:	e8 b2 ff ff ff       	call   f010011c <inb>
f010016a:	a8 01                	test   $0x1,%al
f010016c:	74 0f                	je     f010017d <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f010016e:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100173:	e8 a4 ff ff ff       	call   f010011c <inb>
f0100178:	0f b6 c0             	movzbl %al,%eax
f010017b:	eb 05                	jmp    f0100182 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010017d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100182:	5d                   	pop    %ebp
f0100183:	c3                   	ret    

f0100184 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f0100184:	55                   	push   %ebp
f0100185:	89 e5                	mov    %esp,%ebp
f0100187:	56                   	push   %esi
f0100188:	53                   	push   %ebx
f0100189:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f010018b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100190:	eb 08                	jmp    f010019a <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100192:	e8 99 ff ff ff       	call   f0100130 <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100197:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010019a:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f010019f:	e8 78 ff ff ff       	call   f010011c <inb>
f01001a4:	a8 20                	test   $0x20,%al
f01001a6:	75 08                	jne    f01001b0 <serial_putc+0x2c>
f01001a8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001ae:	7e e2                	jle    f0100192 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001b0:	89 f0                	mov    %esi,%eax
f01001b2:	0f b6 d0             	movzbl %al,%edx
f01001b5:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001ba:	e8 65 ff ff ff       	call   f0100124 <outb>
}
f01001bf:	5b                   	pop    %ebx
f01001c0:	5e                   	pop    %esi
f01001c1:	5d                   	pop    %ebp
f01001c2:	c3                   	ret    

f01001c3 <serial_init>:

static void
serial_init(void)
{
f01001c3:	55                   	push   %ebp
f01001c4:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01001cb:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001d0:	e8 4f ff ff ff       	call   f0100124 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001d5:	ba 80 00 00 00       	mov    $0x80,%edx
f01001da:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001df:	e8 40 ff ff ff       	call   f0100124 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f01001e4:	ba 0c 00 00 00       	mov    $0xc,%edx
f01001e9:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001ee:	e8 31 ff ff ff       	call   f0100124 <outb>
	outb(COM1+COM_DLM, 0);
f01001f3:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f8:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f01001fd:	e8 22 ff ff ff       	call   f0100124 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100202:	ba 03 00 00 00       	mov    $0x3,%edx
f0100207:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010020c:	e8 13 ff ff ff       	call   f0100124 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f0100211:	ba 00 00 00 00       	mov    $0x0,%edx
f0100216:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f010021b:	e8 04 ff ff ff       	call   f0100124 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f0100220:	ba 01 00 00 00       	mov    $0x1,%edx
f0100225:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010022a:	e8 f5 fe ff ff       	call   f0100124 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010022f:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100234:	e8 e3 fe ff ff       	call   f010011c <inb>
f0100239:	3c ff                	cmp    $0xff,%al
f010023b:	0f 95 05 34 75 11 f0 	setne  0xf0117534
	(void) inb(COM1+COM_IIR);
f0100242:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100247:	e8 d0 fe ff ff       	call   f010011c <inb>
	(void) inb(COM1+COM_RX);
f010024c:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100251:	e8 c6 fe ff ff       	call   f010011c <inb>

}
f0100256:	5d                   	pop    %ebp
f0100257:	c3                   	ret    

f0100258 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100258:	55                   	push   %ebp
f0100259:	89 e5                	mov    %esp,%ebp
f010025b:	56                   	push   %esi
f010025c:	53                   	push   %ebx
f010025d:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100264:	eb 08                	jmp    f010026e <lpt_putc+0x16>
		delay();
f0100266:	e8 c5 fe ff ff       	call   f0100130 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010026b:	83 c3 01             	add    $0x1,%ebx
f010026e:	b8 79 03 00 00       	mov    $0x379,%eax
f0100273:	e8 a4 fe ff ff       	call   f010011c <inb>
f0100278:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010027e:	7f 04                	jg     f0100284 <lpt_putc+0x2c>
f0100280:	84 c0                	test   %al,%al
f0100282:	79 e2                	jns    f0100266 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f0100284:	89 f0                	mov    %esi,%eax
f0100286:	0f b6 d0             	movzbl %al,%edx
f0100289:	b8 78 03 00 00       	mov    $0x378,%eax
f010028e:	e8 91 fe ff ff       	call   f0100124 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f0100293:	ba 0d 00 00 00       	mov    $0xd,%edx
f0100298:	b8 7a 03 00 00       	mov    $0x37a,%eax
f010029d:	e8 82 fe ff ff       	call   f0100124 <outb>
	outb(0x378+2, 0x08);
f01002a2:	ba 08 00 00 00       	mov    $0x8,%edx
f01002a7:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002ac:	e8 73 fe ff ff       	call   f0100124 <outb>
}
f01002b1:	5b                   	pop    %ebx
f01002b2:	5e                   	pop    %esi
f01002b3:	5d                   	pop    %ebp
f01002b4:	c3                   	ret    

f01002b5 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002b5:	55                   	push   %ebp
f01002b6:	89 e5                	mov    %esp,%ebp
f01002b8:	57                   	push   %edi
f01002b9:	56                   	push   %esi
f01002ba:	53                   	push   %ebx
f01002bb:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002be:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002c5:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002cc:	5a a5 
	if (*cp != 0xA55A) {
f01002ce:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002d5:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002d9:	74 13                	je     f01002ee <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002db:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f01002e2:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002e5:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f01002ec:	eb 18                	jmp    f0100306 <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01002ee:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01002f5:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f01002fc:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01002ff:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100306:	8b 35 30 75 11 f0    	mov    0xf0117530,%esi
f010030c:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100311:	89 f0                	mov    %esi,%eax
f0100313:	e8 0c fe ff ff       	call   f0100124 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100318:	8d 7e 01             	lea    0x1(%esi),%edi
f010031b:	89 f8                	mov    %edi,%eax
f010031d:	e8 fa fd ff ff       	call   f010011c <inb>
f0100322:	0f b6 d8             	movzbl %al,%ebx
f0100325:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100328:	ba 0f 00 00 00       	mov    $0xf,%edx
f010032d:	89 f0                	mov    %esi,%eax
f010032f:	e8 f0 fd ff ff       	call   f0100124 <outb>
	pos |= inb(addr_6845 + 1);
f0100334:	89 f8                	mov    %edi,%eax
f0100336:	e8 e1 fd ff ff       	call   f010011c <inb>

	crt_buf = (uint16_t*) cp;
f010033b:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010033e:	89 0d 2c 75 11 f0    	mov    %ecx,0xf011752c
	crt_pos = pos;
f0100344:	0f b6 c0             	movzbl %al,%eax
f0100347:	09 c3                	or     %eax,%ebx
f0100349:	66 89 1d 28 75 11 f0 	mov    %bx,0xf0117528
}
f0100350:	83 c4 04             	add    $0x4,%esp
f0100353:	5b                   	pop    %ebx
f0100354:	5e                   	pop    %esi
f0100355:	5f                   	pop    %edi
f0100356:	5d                   	pop    %ebp
f0100357:	c3                   	ret    

f0100358 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100358:	55                   	push   %ebp
f0100359:	89 e5                	mov    %esp,%ebp
f010035b:	53                   	push   %ebx
f010035c:	83 ec 04             	sub    $0x4,%esp
f010035f:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100361:	eb 2b                	jmp    f010038e <cons_intr+0x36>
		if (c == 0)
f0100363:	85 c0                	test   %eax,%eax
f0100365:	74 27                	je     f010038e <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100367:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f010036d:	8d 51 01             	lea    0x1(%ecx),%edx
f0100370:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100376:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010037c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100382:	75 0a                	jne    f010038e <cons_intr+0x36>
			cons.wpos = 0;
f0100384:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010038b:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010038e:	ff d3                	call   *%ebx
f0100390:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100393:	75 ce                	jne    f0100363 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100395:	83 c4 04             	add    $0x4,%esp
f0100398:	5b                   	pop    %ebx
f0100399:	5d                   	pop    %ebp
f010039a:	c3                   	ret    

f010039b <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010039b:	55                   	push   %ebp
f010039c:	89 e5                	mov    %esp,%ebp
f010039e:	53                   	push   %ebx
f010039f:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003a2:	b8 64 00 00 00       	mov    $0x64,%eax
f01003a7:	e8 70 fd ff ff       	call   f010011c <inb>
	if ((stat & KBS_DIB) == 0)
f01003ac:	a8 01                	test   $0x1,%al
f01003ae:	0f 84 fe 00 00 00    	je     f01004b2 <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003b4:	a8 20                	test   $0x20,%al
f01003b6:	0f 85 fd 00 00 00    	jne    f01004b9 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f01003bc:	b8 60 00 00 00       	mov    $0x60,%eax
f01003c1:	e8 56 fd ff ff       	call   f010011c <inb>

	if (data == 0xE0) {
f01003c6:	3c e0                	cmp    $0xe0,%al
f01003c8:	75 11                	jne    f01003db <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003ca:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01003d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01003d6:	e9 e7 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003db:	84 c0                	test   %al,%al
f01003dd:	79 38                	jns    f0100417 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003df:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01003e5:	89 cb                	mov    %ecx,%ebx
f01003e7:	83 e3 40             	and    $0x40,%ebx
f01003ea:	89 c2                	mov    %eax,%edx
f01003ec:	83 e2 7f             	and    $0x7f,%edx
f01003ef:	85 db                	test   %ebx,%ebx
f01003f1:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01003f4:	0f b6 c0             	movzbl %al,%eax
f01003f7:	0f b6 80 c0 37 10 f0 	movzbl -0xfefc840(%eax),%eax
f01003fe:	83 c8 40             	or     $0x40,%eax
f0100401:	0f b6 c0             	movzbl %al,%eax
f0100404:	f7 d0                	not    %eax
f0100406:	21 c8                	and    %ecx,%eax
f0100408:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f010040d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100412:	e9 ab 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100417:	8b 15 00 73 11 f0    	mov    0xf0117300,%edx
f010041d:	f6 c2 40             	test   $0x40,%dl
f0100420:	74 0c                	je     f010042e <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100422:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100425:	83 e2 bf             	and    $0xffffffbf,%edx
f0100428:	89 15 00 73 11 f0    	mov    %edx,0xf0117300
	}

	shift |= shiftcode[data];
f010042e:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f0100431:	0f b6 90 c0 37 10 f0 	movzbl -0xfefc840(%eax),%edx
f0100438:	0b 15 00 73 11 f0    	or     0xf0117300,%edx
f010043e:	0f b6 88 c0 36 10 f0 	movzbl -0xfefc940(%eax),%ecx
f0100445:	31 ca                	xor    %ecx,%edx
f0100447:	89 15 00 73 11 f0    	mov    %edx,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 d1                	mov    %edx,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d a0 36 10 f0 	mov    -0xfefc960(,%ecx,4),%ecx
f0100459:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010045d:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100460:	f6 c2 08             	test   $0x8,%dl
f0100463:	74 1b                	je     f0100480 <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010046a:	83 f9 19             	cmp    $0x19,%ecx
f010046d:	77 05                	ja     f0100474 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f010046f:	83 eb 20             	sub    $0x20,%ebx
f0100472:	eb 0c                	jmp    f0100480 <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f0100474:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100477:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010047a:	83 f8 19             	cmp    $0x19,%eax
f010047d:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100480:	f7 d2                	not    %edx
f0100482:	f6 c2 06             	test   $0x6,%dl
f0100485:	75 39                	jne    f01004c0 <kbd_proc_data+0x125>
f0100487:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010048d:	75 31                	jne    f01004c0 <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f010048f:	83 ec 0c             	sub    $0xc,%esp
f0100492:	68 5c 36 10 f0       	push   $0xf010365c
f0100497:	e8 11 22 00 00       	call   f01026ad <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f010049c:	ba 03 00 00 00       	mov    $0x3,%edx
f01004a1:	b8 92 00 00 00       	mov    $0x92,%eax
f01004a6:	e8 79 fc ff ff       	call   f0100124 <outb>
f01004ab:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f01004ae:	89 d8                	mov    %ebx,%eax
f01004b0:	eb 10                	jmp    f01004c2 <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004b7:	eb 09                	jmp    f01004c2 <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004be:	eb 02                	jmp    f01004c2 <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004c0:	89 d8                	mov    %ebx,%eax
}
f01004c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004c5:	c9                   	leave  
f01004c6:	c3                   	ret    

f01004c7 <cga_putc>:



static void
cga_putc(int c)
{
f01004c7:	55                   	push   %ebp
f01004c8:	89 e5                	mov    %esp,%ebp
f01004ca:	57                   	push   %edi
f01004cb:	56                   	push   %esi
f01004cc:	53                   	push   %ebx
f01004cd:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004d0:	89 c1                	mov    %eax,%ecx
f01004d2:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004d8:	89 c2                	mov    %eax,%edx
f01004da:	80 ce 07             	or     $0x7,%dh
f01004dd:	85 c9                	test   %ecx,%ecx
f01004df:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004e2:	0f b6 d0             	movzbl %al,%edx
f01004e5:	83 fa 09             	cmp    $0x9,%edx
f01004e8:	74 72                	je     f010055c <cga_putc+0x95>
f01004ea:	83 fa 09             	cmp    $0x9,%edx
f01004ed:	7f 0a                	jg     f01004f9 <cga_putc+0x32>
f01004ef:	83 fa 08             	cmp    $0x8,%edx
f01004f2:	74 14                	je     f0100508 <cga_putc+0x41>
f01004f4:	e9 97 00 00 00       	jmp    f0100590 <cga_putc+0xc9>
f01004f9:	83 fa 0a             	cmp    $0xa,%edx
f01004fc:	74 38                	je     f0100536 <cga_putc+0x6f>
f01004fe:	83 fa 0d             	cmp    $0xd,%edx
f0100501:	74 3b                	je     f010053e <cga_putc+0x77>
f0100503:	e9 88 00 00 00       	jmp    f0100590 <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100508:	0f b7 15 28 75 11 f0 	movzwl 0xf0117528,%edx
f010050f:	66 85 d2             	test   %dx,%dx
f0100512:	0f 84 e4 00 00 00    	je     f01005fc <cga_putc+0x135>
			crt_pos--;
f0100518:	83 ea 01             	sub    $0x1,%edx
f010051b:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100522:	0f b7 d2             	movzwl %dx,%edx
f0100525:	b0 00                	mov    $0x0,%al
f0100527:	83 c8 20             	or     $0x20,%eax
f010052a:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f0100530:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100534:	eb 78                	jmp    f01005ae <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100536:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010053d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010053e:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100545:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010054b:	c1 e8 16             	shr    $0x16,%eax
f010054e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100551:	c1 e0 04             	shl    $0x4,%eax
f0100554:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
		break;
f010055a:	eb 52                	jmp    f01005ae <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f010055c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100561:	e8 da 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f0100566:	b8 20 00 00 00       	mov    $0x20,%eax
f010056b:	e8 d0 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f0100570:	b8 20 00 00 00       	mov    $0x20,%eax
f0100575:	e8 c6 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f010057a:	b8 20 00 00 00       	mov    $0x20,%eax
f010057f:	e8 bc 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f0100584:	b8 20 00 00 00       	mov    $0x20,%eax
f0100589:	e8 b2 00 00 00       	call   f0100640 <cons_putc>
		break;
f010058e:	eb 1e                	jmp    f01005ae <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100590:	0f b7 15 28 75 11 f0 	movzwl 0xf0117528,%edx
f0100597:	8d 4a 01             	lea    0x1(%edx),%ecx
f010059a:	66 89 0d 28 75 11 f0 	mov    %cx,0xf0117528
f01005a1:	0f b7 d2             	movzwl %dx,%edx
f01005a4:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f01005aa:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ae:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f01005b5:	cf 07 
f01005b7:	76 43                	jbe    f01005fc <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005b9:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f01005be:	83 ec 04             	sub    $0x4,%esp
f01005c1:	68 00 0f 00 00       	push   $0xf00
f01005c6:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005cc:	52                   	push   %edx
f01005cd:	50                   	push   %eax
f01005ce:	e8 cf 2b 00 00       	call   f01031a2 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005d3:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01005d9:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005df:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005e5:	83 c4 10             	add    $0x10,%esp
f01005e8:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005ed:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f0:	39 d0                	cmp    %edx,%eax
f01005f2:	75 f4                	jne    f01005e8 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005f4:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f01005fb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005fc:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f0100602:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100607:	89 f8                	mov    %edi,%eax
f0100609:	e8 16 fb ff ff       	call   f0100124 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010060e:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100615:	8d 77 01             	lea    0x1(%edi),%esi
f0100618:	0f b6 d7             	movzbl %bh,%edx
f010061b:	89 f0                	mov    %esi,%eax
f010061d:	e8 02 fb ff ff       	call   f0100124 <outb>
	outb(addr_6845, 15);
f0100622:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100627:	89 f8                	mov    %edi,%eax
f0100629:	e8 f6 fa ff ff       	call   f0100124 <outb>
	outb(addr_6845 + 1, crt_pos);
f010062e:	0f b6 d3             	movzbl %bl,%edx
f0100631:	89 f0                	mov    %esi,%eax
f0100633:	e8 ec fa ff ff       	call   f0100124 <outb>
}
f0100638:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010063b:	5b                   	pop    %ebx
f010063c:	5e                   	pop    %esi
f010063d:	5f                   	pop    %edi
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	53                   	push   %ebx
f0100644:	83 ec 04             	sub    $0x4,%esp
f0100647:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100649:	e8 36 fb ff ff       	call   f0100184 <serial_putc>
	lpt_putc(c);
f010064e:	89 d8                	mov    %ebx,%eax
f0100650:	e8 03 fc ff ff       	call   f0100258 <lpt_putc>
	cga_putc(c);
f0100655:	89 d8                	mov    %ebx,%eax
f0100657:	e8 6b fe ff ff       	call   f01004c7 <cga_putc>
}
f010065c:	83 c4 04             	add    $0x4,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5d                   	pop    %ebp
f0100661:	c3                   	ret    

f0100662 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100662:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100669:	74 11                	je     f010067c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100671:	b8 5d 01 10 f0       	mov    $0xf010015d,%eax
f0100676:	e8 dd fc ff ff       	call   f0100358 <cons_intr>
}
f010067b:	c9                   	leave  
f010067c:	f3 c3                	repz ret 

f010067e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010067e:	55                   	push   %ebp
f010067f:	89 e5                	mov    %esp,%ebp
f0100681:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100684:	b8 9b 03 10 f0       	mov    $0xf010039b,%eax
f0100689:	e8 ca fc ff ff       	call   f0100358 <cons_intr>
}
f010068e:	c9                   	leave  
f010068f:	c3                   	ret    

f0100690 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100696:	e8 c7 ff ff ff       	call   f0100662 <serial_intr>
	kbd_intr();
f010069b:	e8 de ff ff ff       	call   f010067e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006a0:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01006a5:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01006ab:	74 26                	je     f01006d3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006ad:	8d 50 01             	lea    0x1(%eax),%edx
f01006b0:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01006b6:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006bd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006bf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006c5:	75 11                	jne    f01006d8 <cons_getc+0x48>
			cons.rpos = 0;
f01006c7:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01006ce:	00 00 00 
f01006d1:	eb 05                	jmp    f01006d8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01006d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006d8:	c9                   	leave  
f01006d9:	c3                   	ret    

f01006da <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006da:	55                   	push   %ebp
f01006db:	89 e5                	mov    %esp,%ebp
f01006dd:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006e0:	e8 d0 fb ff ff       	call   f01002b5 <cga_init>
	kbd_init();
	serial_init();
f01006e5:	e8 d9 fa ff ff       	call   f01001c3 <serial_init>

	if (!serial_exists)
f01006ea:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f01006f1:	75 10                	jne    f0100703 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f01006f3:	83 ec 0c             	sub    $0xc,%esp
f01006f6:	68 68 36 10 f0       	push   $0xf0103668
f01006fb:	e8 ad 1f 00 00       	call   f01026ad <cprintf>
f0100700:	83 c4 10             	add    $0x10,%esp
}
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
f0100708:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010070b:	8b 45 08             	mov    0x8(%ebp),%eax
f010070e:	e8 2d ff ff ff       	call   f0100640 <cons_putc>
}
f0100713:	c9                   	leave  
f0100714:	c3                   	ret    

f0100715 <getchar>:

int
getchar(void)
{
f0100715:	55                   	push   %ebp
f0100716:	89 e5                	mov    %esp,%ebp
f0100718:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010071b:	e8 70 ff ff ff       	call   f0100690 <cons_getc>
f0100720:	85 c0                	test   %eax,%eax
f0100722:	74 f7                	je     f010071b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100724:	c9                   	leave  
f0100725:	c3                   	ret    

f0100726 <iscons>:

int
iscons(int fdnum)
{
f0100726:	55                   	push   %ebp
f0100727:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100729:	b8 01 00 00 00       	mov    $0x1,%eax
f010072e:	5d                   	pop    %ebp
f010072f:	c3                   	ret    

f0100730 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100730:	55                   	push   %ebp
f0100731:	89 e5                	mov    %esp,%ebp
f0100733:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100736:	68 c0 38 10 f0       	push   $0xf01038c0
f010073b:	68 de 38 10 f0       	push   $0xf01038de
f0100740:	68 e3 38 10 f0       	push   $0xf01038e3
f0100745:	e8 63 1f 00 00       	call   f01026ad <cprintf>
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 4c 39 10 f0       	push   $0xf010394c
f0100752:	68 ec 38 10 f0       	push   $0xf01038ec
f0100757:	68 e3 38 10 f0       	push   $0xf01038e3
f010075c:	e8 4c 1f 00 00       	call   f01026ad <cprintf>
	return 0;
}
f0100761:	b8 00 00 00 00       	mov    $0x0,%eax
f0100766:	c9                   	leave  
f0100767:	c3                   	ret    

f0100768 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100768:	55                   	push   %ebp
f0100769:	89 e5                	mov    %esp,%ebp
f010076b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010076e:	68 f5 38 10 f0       	push   $0xf01038f5
f0100773:	e8 35 1f 00 00       	call   f01026ad <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100778:	83 c4 08             	add    $0x8,%esp
f010077b:	68 0c 00 10 00       	push   $0x10000c
f0100780:	68 74 39 10 f0       	push   $0xf0103974
f0100785:	e8 23 1f 00 00       	call   f01026ad <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010078a:	83 c4 0c             	add    $0xc,%esp
f010078d:	68 0c 00 10 00       	push   $0x10000c
f0100792:	68 0c 00 10 f0       	push   $0xf010000c
f0100797:	68 9c 39 10 f0       	push   $0xf010399c
f010079c:	e8 0c 1f 00 00       	call   f01026ad <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 e1 35 10 00       	push   $0x1035e1
f01007a9:	68 e1 35 10 f0       	push   $0xf01035e1
f01007ae:	68 c0 39 10 f0       	push   $0xf01039c0
f01007b3:	e8 f5 1e 00 00       	call   f01026ad <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b8:	83 c4 0c             	add    $0xc,%esp
f01007bb:	68 00 73 11 00       	push   $0x117300
f01007c0:	68 00 73 11 f0       	push   $0xf0117300
f01007c5:	68 e4 39 10 f0       	push   $0xf01039e4
f01007ca:	e8 de 1e 00 00       	call   f01026ad <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	68 50 79 11 00       	push   $0x117950
f01007d7:	68 50 79 11 f0       	push   $0xf0117950
f01007dc:	68 08 3a 10 f0       	push   $0xf0103a08
f01007e1:	e8 c7 1e 00 00       	call   f01026ad <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007e6:	b8 4f 7d 11 f0       	mov    $0xf0117d4f,%eax
f01007eb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f0:	83 c4 08             	add    $0x8,%esp
f01007f3:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01007f8:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01007fe:	85 c0                	test   %eax,%eax
f0100800:	0f 48 c2             	cmovs  %edx,%eax
f0100803:	c1 f8 0a             	sar    $0xa,%eax
f0100806:	50                   	push   %eax
f0100807:	68 2c 3a 10 f0       	push   $0xf0103a2c
f010080c:	e8 9c 1e 00 00       	call   f01026ad <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100811:	b8 00 00 00 00       	mov    $0x0,%eax
f0100816:	c9                   	leave  
f0100817:	c3                   	ret    

f0100818 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100818:	55                   	push   %ebp
f0100819:	89 e5                	mov    %esp,%ebp
f010081b:	57                   	push   %edi
f010081c:	56                   	push   %esi
f010081d:	53                   	push   %ebx
f010081e:	83 ec 5c             	sub    $0x5c,%esp
f0100821:	89 c3                	mov    %eax,%ebx
f0100823:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100826:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010082d:	be 00 00 00 00       	mov    $0x0,%esi
f0100832:	eb 0a                	jmp    f010083e <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100834:	c6 03 00             	movb   $0x0,(%ebx)
f0100837:	89 f7                	mov    %esi,%edi
f0100839:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010083c:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010083e:	0f b6 03             	movzbl (%ebx),%eax
f0100841:	84 c0                	test   %al,%al
f0100843:	74 6d                	je     f01008b2 <runcmd+0x9a>
f0100845:	83 ec 08             	sub    $0x8,%esp
f0100848:	0f be c0             	movsbl %al,%eax
f010084b:	50                   	push   %eax
f010084c:	68 0e 39 10 f0       	push   $0xf010390e
f0100851:	e8 c1 28 00 00       	call   f0103117 <strchr>
f0100856:	83 c4 10             	add    $0x10,%esp
f0100859:	85 c0                	test   %eax,%eax
f010085b:	75 d7                	jne    f0100834 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f010085d:	0f b6 03             	movzbl (%ebx),%eax
f0100860:	84 c0                	test   %al,%al
f0100862:	74 4e                	je     f01008b2 <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100864:	83 fe 0f             	cmp    $0xf,%esi
f0100867:	75 1c                	jne    f0100885 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100869:	83 ec 08             	sub    $0x8,%esp
f010086c:	6a 10                	push   $0x10
f010086e:	68 13 39 10 f0       	push   $0xf0103913
f0100873:	e8 35 1e 00 00       	call   f01026ad <cprintf>
			return 0;
f0100878:	83 c4 10             	add    $0x10,%esp
f010087b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100880:	e9 ac 00 00 00       	jmp    f0100931 <runcmd+0x119>
		}
		argv[argc++] = buf;
f0100885:	8d 7e 01             	lea    0x1(%esi),%edi
f0100888:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010088c:	eb 0a                	jmp    f0100898 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010088e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100891:	0f b6 03             	movzbl (%ebx),%eax
f0100894:	84 c0                	test   %al,%al
f0100896:	74 a4                	je     f010083c <runcmd+0x24>
f0100898:	83 ec 08             	sub    $0x8,%esp
f010089b:	0f be c0             	movsbl %al,%eax
f010089e:	50                   	push   %eax
f010089f:	68 0e 39 10 f0       	push   $0xf010390e
f01008a4:	e8 6e 28 00 00       	call   f0103117 <strchr>
f01008a9:	83 c4 10             	add    $0x10,%esp
f01008ac:	85 c0                	test   %eax,%eax
f01008ae:	74 de                	je     f010088e <runcmd+0x76>
f01008b0:	eb 8a                	jmp    f010083c <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f01008b2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b9:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f01008ba:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f01008bf:	85 f6                	test   %esi,%esi
f01008c1:	74 6e                	je     f0100931 <runcmd+0x119>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c3:	83 ec 08             	sub    $0x8,%esp
f01008c6:	68 de 38 10 f0       	push   $0xf01038de
f01008cb:	ff 75 a8             	pushl  -0x58(%ebp)
f01008ce:	e8 e6 27 00 00       	call   f01030b9 <strcmp>
f01008d3:	83 c4 10             	add    $0x10,%esp
f01008d6:	85 c0                	test   %eax,%eax
f01008d8:	74 1e                	je     f01008f8 <runcmd+0xe0>
f01008da:	83 ec 08             	sub    $0x8,%esp
f01008dd:	68 ec 38 10 f0       	push   $0xf01038ec
f01008e2:	ff 75 a8             	pushl  -0x58(%ebp)
f01008e5:	e8 cf 27 00 00       	call   f01030b9 <strcmp>
f01008ea:	83 c4 10             	add    $0x10,%esp
f01008ed:	85 c0                	test   %eax,%eax
f01008ef:	75 28                	jne    f0100919 <runcmd+0x101>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01008f6:	eb 05                	jmp    f01008fd <runcmd+0xe5>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008f8:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008fd:	83 ec 04             	sub    $0x4,%esp
f0100900:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100903:	01 d0                	add    %edx,%eax
f0100905:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100908:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010090b:	52                   	push   %edx
f010090c:	56                   	push   %esi
f010090d:	ff 14 85 ac 3a 10 f0 	call   *-0xfefc554(,%eax,4)
f0100914:	83 c4 10             	add    $0x10,%esp
f0100917:	eb 18                	jmp    f0100931 <runcmd+0x119>
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100919:	83 ec 08             	sub    $0x8,%esp
f010091c:	ff 75 a8             	pushl  -0x58(%ebp)
f010091f:	68 30 39 10 f0       	push   $0xf0103930
f0100924:	e8 84 1d 00 00       	call   f01026ad <cprintf>
	return 0;
f0100929:	83 c4 10             	add    $0x10,%esp
f010092c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100931:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100934:	5b                   	pop    %ebx
f0100935:	5e                   	pop    %esi
f0100936:	5f                   	pop    %edi
f0100937:	5d                   	pop    %ebp
f0100938:	c3                   	ret    

f0100939 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100939:	55                   	push   %ebp
f010093a:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010093c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100941:	5d                   	pop    %ebp
f0100942:	c3                   	ret    

f0100943 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100943:	55                   	push   %ebp
f0100944:	89 e5                	mov    %esp,%ebp
f0100946:	53                   	push   %ebx
f0100947:	83 ec 10             	sub    $0x10,%esp
f010094a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010094d:	68 58 3a 10 f0       	push   $0xf0103a58
f0100952:	e8 56 1d 00 00       	call   f01026ad <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100957:	c7 04 24 7c 3a 10 f0 	movl   $0xf0103a7c,(%esp)
f010095e:	e8 4a 1d 00 00       	call   f01026ad <cprintf>
f0100963:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100966:	83 ec 0c             	sub    $0xc,%esp
f0100969:	68 46 39 10 f0       	push   $0xf0103946
f010096e:	e8 8a 25 00 00       	call   f0102efd <readline>
		if (buf != NULL)
f0100973:	83 c4 10             	add    $0x10,%esp
f0100976:	85 c0                	test   %eax,%eax
f0100978:	74 ec                	je     f0100966 <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f010097a:	89 da                	mov    %ebx,%edx
f010097c:	e8 97 fe ff ff       	call   f0100818 <runcmd>
f0100981:	85 c0                	test   %eax,%eax
f0100983:	79 e1                	jns    f0100966 <monitor+0x23>
				break;
	}
}
f0100985:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100988:	c9                   	leave  
f0100989:	c3                   	ret    

f010098a <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f010098a:	55                   	push   %ebp
f010098b:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010098d:	0f 01 38             	invlpg (%eax)
}
f0100990:	5d                   	pop    %ebp
f0100991:	c3                   	ret    

f0100992 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100992:	55                   	push   %ebp
f0100993:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100995:	0f 22 c0             	mov    %eax,%cr0
}
f0100998:	5d                   	pop    %ebp
f0100999:	c3                   	ret    

f010099a <rcr0>:

static inline uint32_t
rcr0(void)
{
f010099a:	55                   	push   %ebp
f010099b:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010099d:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f01009a0:	5d                   	pop    %ebp
f01009a1:	c3                   	ret    

f01009a2 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f01009a2:	55                   	push   %ebp
f01009a3:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01009a5:	0f 22 d8             	mov    %eax,%cr3
}
f01009a8:	5d                   	pop    %ebp
f01009a9:	c3                   	ret    

f01009aa <page2pa>:

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f01009aa:	55                   	push   %ebp
f01009ab:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f01009ad:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01009b3:	c1 f8 03             	sar    $0x3,%eax
f01009b6:	c1 e0 0c             	shl    $0xc,%eax
}
f01009b9:	5d                   	pop    %ebp
f01009ba:	c3                   	ret    

f01009bb <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009bb:	55                   	push   %ebp
f01009bc:	89 e5                	mov    %esp,%ebp
f01009be:	56                   	push   %esi
f01009bf:	53                   	push   %ebx
f01009c0:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009c2:	83 ec 0c             	sub    $0xc,%esp
f01009c5:	50                   	push   %eax
f01009c6:	e8 5e 1c 00 00       	call   f0102629 <mc146818_read>
f01009cb:	89 c6                	mov    %eax,%esi
f01009cd:	83 c3 01             	add    $0x1,%ebx
f01009d0:	89 1c 24             	mov    %ebx,(%esp)
f01009d3:	e8 51 1c 00 00       	call   f0102629 <mc146818_read>
f01009d8:	c1 e0 08             	shl    $0x8,%eax
f01009db:	09 f0                	or     %esi,%eax
}
f01009dd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01009e0:	5b                   	pop    %ebx
f01009e1:	5e                   	pop    %esi
f01009e2:	5d                   	pop    %ebp
f01009e3:	c3                   	ret    

f01009e4 <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f01009e4:	55                   	push   %ebp
f01009e5:	89 e5                	mov    %esp,%ebp
f01009e7:	56                   	push   %esi
f01009e8:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01009e9:	b8 15 00 00 00       	mov    $0x15,%eax
f01009ee:	e8 c8 ff ff ff       	call   f01009bb <nvram_read>
f01009f3:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01009f5:	b8 17 00 00 00       	mov    $0x17,%eax
f01009fa:	e8 bc ff ff ff       	call   f01009bb <nvram_read>
f01009ff:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a01:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a06:	e8 b0 ff ff ff       	call   f01009bb <nvram_read>
f0100a0b:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100a0e:	85 c0                	test   %eax,%eax
f0100a10:	74 07                	je     f0100a19 <i386_detect_memory+0x35>
		totalmem = 16 * 1024 + ext16mem;
f0100a12:	05 00 40 00 00       	add    $0x4000,%eax
f0100a17:	eb 0b                	jmp    f0100a24 <i386_detect_memory+0x40>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100a19:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100a1f:	85 f6                	test   %esi,%esi
f0100a21:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100a24:	89 c2                	mov    %eax,%edx
f0100a26:	c1 ea 02             	shr    $0x2,%edx
f0100a29:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a2f:	89 c2                	mov    %eax,%edx
f0100a31:	29 da                	sub    %ebx,%edx
f0100a33:	52                   	push   %edx
f0100a34:	53                   	push   %ebx
f0100a35:	50                   	push   %eax
f0100a36:	68 bc 3a 10 f0       	push   $0xf0103abc
f0100a3b:	e8 6d 1c 00 00       	call   f01026ad <cprintf>
	        totalmem,
	        basemem,
	        totalmem - basemem);
}
f0100a40:	83 c4 10             	add    $0x10,%esp
f0100a43:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a46:	5b                   	pop    %ebx
f0100a47:	5e                   	pop    %esi
f0100a48:	5d                   	pop    %ebp
f0100a49:	c3                   	ret    

f0100a4a <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a4a:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100a51:	75 11                	jne    f0100a64 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a53:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f0100a58:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a5e:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// LAB 2: Your code here.

	// Están mapeados menos de 4 MB
	// por lo que no podemos pedir
	// más memoria que eso
	if ((uintptr_t)ROUNDUP(nextfree + n, PGSIZE) > (KERNBASE + (4 << 20))) {
f0100a64:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
f0100a6a:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100a71:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a77:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f0100a7d:	76 17                	jbe    f0100a96 <boot_alloc+0x4c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a7f:	55                   	push   %ebp
f0100a80:	89 e5                	mov    %esp,%ebp
f0100a82:	83 ec 0c             	sub    $0xc,%esp

	// Están mapeados menos de 4 MB
	// por lo que no podemos pedir
	// más memoria que eso
	if ((uintptr_t)ROUNDUP(nextfree + n, PGSIZE) > (KERNBASE + (4 << 20))) {
		panic("boot_alloc: out of memory");
f0100a85:	68 d8 42 10 f0       	push   $0xf01042d8
f0100a8a:	6a 71                	push   $0x71
f0100a8c:	68 f2 42 10 f0       	push   $0xf01042f2
f0100a91:	e8 f5 f5 ff ff       	call   f010008b <_panic>
	}

	result = nextfree;

	if (n > 0) {
f0100a96:	85 c0                	test   %eax,%eax
f0100a98:	74 06                	je     f0100aa0 <boot_alloc+0x56>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);	
f0100a9a:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	}

	return result;
}
f0100aa0:	89 c8                	mov    %ecx,%eax
f0100aa2:	c3                   	ret    

f0100aa3 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100aa3:	55                   	push   %ebp
f0100aa4:	89 e5                	mov    %esp,%ebp
f0100aa6:	53                   	push   %ebx
f0100aa7:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100aaa:	89 cb                	mov    %ecx,%ebx
f0100aac:	c1 eb 0c             	shr    $0xc,%ebx
f0100aaf:	3b 1d 44 79 11 f0    	cmp    0xf0117944,%ebx
f0100ab5:	72 0d                	jb     f0100ac4 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab7:	51                   	push   %ecx
f0100ab8:	68 f8 3a 10 f0       	push   $0xf0103af8
f0100abd:	52                   	push   %edx
f0100abe:	50                   	push   %eax
f0100abf:	e8 c7 f5 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100ac4:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100aca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100acd:	c9                   	leave  
f0100ace:	c3                   	ret    

f0100acf <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100acf:	55                   	push   %ebp
f0100ad0:	89 e5                	mov    %esp,%ebp
f0100ad2:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100ad5:	e8 d0 fe ff ff       	call   f01009aa <page2pa>
f0100ada:	89 c1                	mov    %eax,%ecx
f0100adc:	ba 52 00 00 00       	mov    $0x52,%edx
f0100ae1:	b8 fe 42 10 f0       	mov    $0xf01042fe,%eax
f0100ae6:	e8 b8 ff ff ff       	call   f0100aa3 <_kaddr>
}
f0100aeb:	c9                   	leave  
f0100aec:	c3                   	ret    

f0100aed <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100aed:	89 d1                	mov    %edx,%ecx
f0100aef:	c1 e9 16             	shr    $0x16,%ecx
f0100af2:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100af5:	f6 c1 01             	test   $0x1,%cl
f0100af8:	74 57                	je     f0100b51 <check_va2pa+0x64>
		return ~0;
	if (*pgdir & PTE_PS)
f0100afa:	f6 c1 80             	test   $0x80,%cl
f0100afd:	74 10                	je     f0100b0f <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100aff:	89 d0                	mov    %edx,%eax
f0100b01:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100b06:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100b0c:	09 c8                	or     %ecx,%eax
f0100b0e:	c3                   	ret    
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b0f:	55                   	push   %ebp
f0100b10:	89 e5                	mov    %esp,%ebp
f0100b12:	53                   	push   %ebx
f0100b13:	83 ec 04             	sub    $0x4,%esp
f0100b16:	89 d3                	mov    %edx,%ebx
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	if (*pgdir & PTE_PS)
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t *) KADDR(PTE_ADDR(*pgdir));
f0100b18:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b1e:	ba 67 03 00 00       	mov    $0x367,%edx
f0100b23:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0100b28:	e8 76 ff ff ff       	call   f0100aa3 <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100b2d:	c1 eb 0c             	shr    $0xc,%ebx
f0100b30:	89 da                	mov    %ebx,%edx
f0100b32:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b38:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100b3b:	89 c2                	mov    %eax,%edx
f0100b3d:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b40:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b45:	85 d2                	test   %edx,%edx
f0100b47:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f0100b4c:	0f 44 c1             	cmove  %ecx,%eax
f0100b4f:	eb 06                	jmp    f0100b57 <check_va2pa+0x6a>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b56:	c3                   	ret    
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t *) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b57:	83 c4 04             	add    $0x4,%esp
f0100b5a:	5b                   	pop    %ebx
f0100b5b:	5d                   	pop    %ebp
f0100b5c:	c3                   	ret    

f0100b5d <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b5d:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100b63:	77 13                	ja     f0100b78 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100b65:	55                   	push   %ebp
f0100b66:	89 e5                	mov    %esp,%ebp
f0100b68:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b6b:	51                   	push   %ecx
f0100b6c:	68 1c 3b 10 f0       	push   $0xf0103b1c
f0100b71:	52                   	push   %edx
f0100b72:	50                   	push   %eax
f0100b73:	e8 13 f5 ff ff       	call   f010008b <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100b78:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100b7e:	c3                   	ret    

f0100b7f <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100b7f:	55                   	push   %ebp
f0100b80:	89 e5                	mov    %esp,%ebp
f0100b82:	57                   	push   %edi
f0100b83:	56                   	push   %esi
f0100b84:	53                   	push   %ebx
f0100b85:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100b88:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
f0100b8e:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100b93:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100b96:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100b9d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ba2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100ba5:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100baa:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100bad:	be 00 00 00 00       	mov    $0x0,%esi
f0100bb2:	eb 46                	jmp    f0100bfa <check_kern_pgdir+0x7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100bb4:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0100bba:	89 d8                	mov    %ebx,%eax
f0100bbc:	e8 2c ff ff ff       	call   f0100aed <check_va2pa>
f0100bc1:	89 c7                	mov    %eax,%edi
f0100bc3:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100bc6:	ba 2e 03 00 00       	mov    $0x32e,%edx
f0100bcb:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0100bd0:	e8 88 ff ff ff       	call   f0100b5d <_paddr>
f0100bd5:	01 f0                	add    %esi,%eax
f0100bd7:	39 c7                	cmp    %eax,%edi
f0100bd9:	74 19                	je     f0100bf4 <check_kern_pgdir+0x75>
f0100bdb:	68 40 3b 10 f0       	push   $0xf0103b40
f0100be0:	68 0c 43 10 f0       	push   $0xf010430c
f0100be5:	68 2e 03 00 00       	push   $0x32e
f0100bea:	68 f2 42 10 f0       	push   $0xf01042f2
f0100bef:	e8 97 f4 ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100bf4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100bfa:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100bfd:	72 b5                	jb     f0100bb4 <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100bff:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100c02:	c1 e7 0c             	shl    $0xc,%edi
f0100c05:	be 00 00 00 00       	mov    $0x0,%esi
f0100c0a:	eb 30                	jmp    f0100c3c <check_kern_pgdir+0xbd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100c0c:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0100c12:	89 d8                	mov    %ebx,%eax
f0100c14:	e8 d4 fe ff ff       	call   f0100aed <check_va2pa>
f0100c19:	39 c6                	cmp    %eax,%esi
f0100c1b:	74 19                	je     f0100c36 <check_kern_pgdir+0xb7>
f0100c1d:	68 74 3b 10 f0       	push   $0xf0103b74
f0100c22:	68 0c 43 10 f0       	push   $0xf010430c
f0100c27:	68 33 03 00 00       	push   $0x333
f0100c2c:	68 f2 42 10 f0       	push   $0xf01042f2
f0100c31:	e8 55 f4 ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100c36:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100c3c:	39 fe                	cmp    %edi,%esi
f0100c3e:	72 cc                	jb     f0100c0c <check_kern_pgdir+0x8d>
f0100c40:	be 00 00 00 00       	mov    $0x0,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) ==
f0100c45:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
f0100c4b:	89 d8                	mov    %ebx,%eax
f0100c4d:	e8 9b fe ff ff       	call   f0100aed <check_va2pa>
f0100c52:	89 c7                	mov    %eax,%edi
f0100c54:	b9 00 d0 10 f0       	mov    $0xf010d000,%ecx
f0100c59:	ba 38 03 00 00       	mov    $0x338,%edx
f0100c5e:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0100c63:	e8 f5 fe ff ff       	call   f0100b5d <_paddr>
f0100c68:	01 f0                	add    %esi,%eax
f0100c6a:	39 c7                	cmp    %eax,%edi
f0100c6c:	74 19                	je     f0100c87 <check_kern_pgdir+0x108>
f0100c6e:	68 9c 3b 10 f0       	push   $0xf0103b9c
f0100c73:	68 0c 43 10 f0       	push   $0xf010430c
f0100c78:	68 38 03 00 00       	push   $0x338
f0100c7d:	68 f2 42 10 f0       	push   $0xf01042f2
f0100c82:	e8 04 f4 ff ff       	call   f010008b <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100c87:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100c8d:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100c93:	75 b0                	jne    f0100c45 <check_kern_pgdir+0xc6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) ==
		       PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100c95:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100c9a:	89 d8                	mov    %ebx,%eax
f0100c9c:	e8 4c fe ff ff       	call   f0100aed <check_va2pa>
f0100ca1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100ca4:	74 51                	je     f0100cf7 <check_kern_pgdir+0x178>
f0100ca6:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100cab:	68 0c 43 10 f0       	push   $0xf010430c
f0100cb0:	68 39 03 00 00       	push   $0x339
f0100cb5:	68 f2 42 10 f0       	push   $0xf01042f2
f0100cba:	e8 cc f3 ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100cbf:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0100cc4:	72 36                	jb     f0100cfc <check_kern_pgdir+0x17d>
f0100cc6:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100ccb:	76 07                	jbe    f0100cd4 <check_kern_pgdir+0x155>
f0100ccd:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100cd2:	75 28                	jne    f0100cfc <check_kern_pgdir+0x17d>
		case PDX(UVPT):
		case PDX(KSTACKTOP - 1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0100cd4:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100cd8:	0f 85 83 00 00 00    	jne    f0100d61 <check_kern_pgdir+0x1e2>
f0100cde:	68 21 43 10 f0       	push   $0xf0104321
f0100ce3:	68 0c 43 10 f0       	push   $0xf010430c
f0100ce8:	68 41 03 00 00       	push   $0x341
f0100ced:	68 f2 42 10 f0       	push   $0xf01042f2
f0100cf2:	e8 94 f3 ff ff       	call   f010008b <_panic>
f0100cf7:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100cfc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100d01:	76 3f                	jbe    f0100d42 <check_kern_pgdir+0x1c3>
				assert(pgdir[i] & PTE_P);
f0100d03:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100d06:	f6 c2 01             	test   $0x1,%dl
f0100d09:	75 19                	jne    f0100d24 <check_kern_pgdir+0x1a5>
f0100d0b:	68 21 43 10 f0       	push   $0xf0104321
f0100d10:	68 0c 43 10 f0       	push   $0xf010430c
f0100d15:	68 45 03 00 00       	push   $0x345
f0100d1a:	68 f2 42 10 f0       	push   $0xf01042f2
f0100d1f:	e8 67 f3 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0100d24:	f6 c2 02             	test   $0x2,%dl
f0100d27:	75 38                	jne    f0100d61 <check_kern_pgdir+0x1e2>
f0100d29:	68 32 43 10 f0       	push   $0xf0104332
f0100d2e:	68 0c 43 10 f0       	push   $0xf010430c
f0100d33:	68 46 03 00 00       	push   $0x346
f0100d38:	68 f2 42 10 f0       	push   $0xf01042f2
f0100d3d:	e8 49 f3 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0100d42:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100d46:	74 19                	je     f0100d61 <check_kern_pgdir+0x1e2>
f0100d48:	68 43 43 10 f0       	push   $0xf0104343
f0100d4d:	68 0c 43 10 f0       	push   $0xf010430c
f0100d52:	68 48 03 00 00       	push   $0x348
f0100d57:	68 f2 42 10 f0       	push   $0xf01042f2
f0100d5c:	e8 2a f3 ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) ==
		       PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100d61:	83 c0 01             	add    $0x1,%eax
f0100d64:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0100d69:	0f 86 50 ff ff ff    	jbe    f0100cbf <check_kern_pgdir+0x140>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100d6f:	83 ec 0c             	sub    $0xc,%esp
f0100d72:	68 14 3c 10 f0       	push   $0xf0103c14
f0100d77:	e8 31 19 00 00       	call   f01026ad <cprintf>
		assert(pgdir[i] & PTE_PS);
		assert(PTE_ADDR(pgdir[i]) == (i - kern_pdx) << PDXSHIFT);
	}
	cprintf("check_kern_pgdir_pse() succeeded!\n");
#endif
}
f0100d7c:	83 c4 10             	add    $0x10,%esp
f0100d7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d82:	5b                   	pop    %ebx
f0100d83:	5e                   	pop    %esi
f0100d84:	5f                   	pop    %edi
f0100d85:	5d                   	pop    %ebp
f0100d86:	c3                   	ret    

f0100d87 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100d87:	55                   	push   %ebp
f0100d88:	89 e5                	mov    %esp,%ebp
f0100d8a:	57                   	push   %edi
f0100d8b:	56                   	push   %esi
f0100d8c:	53                   	push   %ebx
f0100d8d:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d90:	84 c0                	test   %al,%al
f0100d92:	0f 85 35 02 00 00    	jne    f0100fcd <check_page_free_list+0x246>
f0100d98:	e9 43 02 00 00       	jmp    f0100fe0 <check_page_free_list+0x259>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100d9d:	83 ec 04             	sub    $0x4,%esp
f0100da0:	68 34 3c 10 f0       	push   $0xf0103c34
f0100da5:	68 9d 02 00 00       	push   $0x29d
f0100daa:	68 f2 42 10 f0       	push   $0xf01042f2
f0100daf:	e8 d7 f2 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100db4:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100db7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dba:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100dbd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100dc0:	89 d8                	mov    %ebx,%eax
f0100dc2:	e8 e3 fb ff ff       	call   f01009aa <page2pa>
f0100dc7:	c1 e8 16             	shr    $0x16,%eax
f0100dca:	85 c0                	test   %eax,%eax
f0100dcc:	0f 95 c0             	setne  %al
f0100dcf:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100dd2:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100dd6:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100dd8:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ddc:	8b 1b                	mov    (%ebx),%ebx
f0100dde:	85 db                	test   %ebx,%ebx
f0100de0:	75 de                	jne    f0100dc0 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100de2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100de5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100deb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dee:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100df1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100df3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100df6:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dfb:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e00:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e06:	eb 2d                	jmp    f0100e35 <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100e08:	89 d8                	mov    %ebx,%eax
f0100e0a:	e8 9b fb ff ff       	call   f01009aa <page2pa>
f0100e0f:	c1 e8 16             	shr    $0x16,%eax
f0100e12:	39 f0                	cmp    %esi,%eax
f0100e14:	73 1d                	jae    f0100e33 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f0100e16:	89 d8                	mov    %ebx,%eax
f0100e18:	e8 b2 fc ff ff       	call   f0100acf <page2kva>
f0100e1d:	83 ec 04             	sub    $0x4,%esp
f0100e20:	68 80 00 00 00       	push   $0x80
f0100e25:	68 97 00 00 00       	push   $0x97
f0100e2a:	50                   	push   %eax
f0100e2b:	e8 24 23 00 00       	call   f0103154 <memset>
f0100e30:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e33:	8b 1b                	mov    (%ebx),%ebx
f0100e35:	85 db                	test   %ebx,%ebx
f0100e37:	75 cf                	jne    f0100e08 <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100e39:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e3e:	e8 07 fc ff ff       	call   f0100a4a <boot_alloc>
f0100e43:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e46:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e4c:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi
		assert(pp < pages + npages);
f0100e52:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100e57:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100e5a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e5d:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100e60:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100e67:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e6c:	e9 18 01 00 00       	jmp    f0100f89 <check_page_free_list+0x202>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e71:	39 f3                	cmp    %esi,%ebx
f0100e73:	73 19                	jae    f0100e8e <check_page_free_list+0x107>
f0100e75:	68 51 43 10 f0       	push   $0xf0104351
f0100e7a:	68 0c 43 10 f0       	push   $0xf010430c
f0100e7f:	68 b7 02 00 00       	push   $0x2b7
f0100e84:	68 f2 42 10 f0       	push   $0xf01042f2
f0100e89:	e8 fd f1 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100e8e:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100e91:	72 19                	jb     f0100eac <check_page_free_list+0x125>
f0100e93:	68 5d 43 10 f0       	push   $0xf010435d
f0100e98:	68 0c 43 10 f0       	push   $0xf010430c
f0100e9d:	68 b8 02 00 00       	push   $0x2b8
f0100ea2:	68 f2 42 10 f0       	push   $0xf01042f2
f0100ea7:	e8 df f1 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100eac:	89 d8                	mov    %ebx,%eax
f0100eae:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100eb1:	a8 07                	test   $0x7,%al
f0100eb3:	74 19                	je     f0100ece <check_page_free_list+0x147>
f0100eb5:	68 58 3c 10 f0       	push   $0xf0103c58
f0100eba:	68 0c 43 10 f0       	push   $0xf010430c
f0100ebf:	68 b9 02 00 00       	push   $0x2b9
f0100ec4:	68 f2 42 10 f0       	push   $0xf01042f2
f0100ec9:	e8 bd f1 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ece:	89 d8                	mov    %ebx,%eax
f0100ed0:	e8 d5 fa ff ff       	call   f01009aa <page2pa>
f0100ed5:	85 c0                	test   %eax,%eax
f0100ed7:	75 19                	jne    f0100ef2 <check_page_free_list+0x16b>
f0100ed9:	68 71 43 10 f0       	push   $0xf0104371
f0100ede:	68 0c 43 10 f0       	push   $0xf010430c
f0100ee3:	68 bc 02 00 00       	push   $0x2bc
f0100ee8:	68 f2 42 10 f0       	push   $0xf01042f2
f0100eed:	e8 99 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ef2:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ef7:	75 19                	jne    f0100f12 <check_page_free_list+0x18b>
f0100ef9:	68 82 43 10 f0       	push   $0xf0104382
f0100efe:	68 0c 43 10 f0       	push   $0xf010430c
f0100f03:	68 bd 02 00 00       	push   $0x2bd
f0100f08:	68 f2 42 10 f0       	push   $0xf01042f2
f0100f0d:	e8 79 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f12:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f17:	75 19                	jne    f0100f32 <check_page_free_list+0x1ab>
f0100f19:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0100f1e:	68 0c 43 10 f0       	push   $0xf010430c
f0100f23:	68 be 02 00 00       	push   $0x2be
f0100f28:	68 f2 42 10 f0       	push   $0xf01042f2
f0100f2d:	e8 59 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f32:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f37:	75 19                	jne    f0100f52 <check_page_free_list+0x1cb>
f0100f39:	68 9b 43 10 f0       	push   $0xf010439b
f0100f3e:	68 0c 43 10 f0       	push   $0xf010430c
f0100f43:	68 bf 02 00 00       	push   $0x2bf
f0100f48:	68 f2 42 10 f0       	push   $0xf01042f2
f0100f4d:	e8 39 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM ||
f0100f52:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f57:	76 25                	jbe    f0100f7e <check_page_free_list+0x1f7>
f0100f59:	89 d8                	mov    %ebx,%eax
f0100f5b:	e8 6f fb ff ff       	call   f0100acf <page2kva>
f0100f60:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100f63:	76 1e                	jbe    f0100f83 <check_page_free_list+0x1fc>
f0100f65:	68 b0 3c 10 f0       	push   $0xf0103cb0
f0100f6a:	68 0c 43 10 f0       	push   $0xf010430c
f0100f6f:	68 c1 02 00 00       	push   $0x2c1
f0100f74:	68 f2 42 10 f0       	push   $0xf01042f2
f0100f79:	e8 0d f1 ff ff       	call   f010008b <_panic>
		       (char *) page2kva(pp) >= first_free_page);

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f7e:	83 c7 01             	add    $0x1,%edi
f0100f81:	eb 04                	jmp    f0100f87 <check_page_free_list+0x200>
		else
			++nfree_extmem;
f0100f83:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f87:	8b 1b                	mov    (%ebx),%ebx
f0100f89:	85 db                	test   %ebx,%ebx
f0100f8b:	0f 85 e0 fe ff ff    	jne    f0100e71 <check_page_free_list+0xea>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f91:	85 ff                	test   %edi,%edi
f0100f93:	7f 19                	jg     f0100fae <check_page_free_list+0x227>
f0100f95:	68 b5 43 10 f0       	push   $0xf01043b5
f0100f9a:	68 0c 43 10 f0       	push   $0xf010430c
f0100f9f:	68 c9 02 00 00       	push   $0x2c9
f0100fa4:	68 f2 42 10 f0       	push   $0xf01042f2
f0100fa9:	e8 dd f0 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100fae:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100fb2:	7f 43                	jg     f0100ff7 <check_page_free_list+0x270>
f0100fb4:	68 c7 43 10 f0       	push   $0xf01043c7
f0100fb9:	68 0c 43 10 f0       	push   $0xf010430c
f0100fbe:	68 ca 02 00 00       	push   $0x2ca
f0100fc3:	68 f2 42 10 f0       	push   $0xf01042f2
f0100fc8:	e8 be f0 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100fcd:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100fd3:	85 db                	test   %ebx,%ebx
f0100fd5:	0f 85 d9 fd ff ff    	jne    f0100db4 <check_page_free_list+0x2d>
f0100fdb:	e9 bd fd ff ff       	jmp    f0100d9d <check_page_free_list+0x16>
f0100fe0:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100fe7:	0f 84 b0 fd ff ff    	je     f0100d9d <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fed:	be 00 04 00 00       	mov    $0x400,%esi
f0100ff2:	e9 09 fe ff ff       	jmp    f0100e00 <check_page_free_list+0x79>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100ff7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ffa:	5b                   	pop    %ebx
f0100ffb:	5e                   	pop    %esi
f0100ffc:	5f                   	pop    %edi
f0100ffd:	5d                   	pop    %ebp
f0100ffe:	c3                   	ret    

f0100fff <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fff:	c1 e8 0c             	shr    $0xc,%eax
f0101002:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0101008:	72 17                	jb     f0101021 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f010100a:	55                   	push   %ebp
f010100b:	89 e5                	mov    %esp,%ebp
f010100d:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0101010:	68 f8 3c 10 f0       	push   $0xf0103cf8
f0101015:	6a 4b                	push   $0x4b
f0101017:	68 fe 42 10 f0       	push   $0xf01042fe
f010101c:	e8 6a f0 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101021:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f0101027:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010102a:	c3                   	ret    

f010102b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010102b:	55                   	push   %ebp
f010102c:	89 e5                	mov    %esp,%ebp
f010102e:	56                   	push   %esi
f010102f:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	physaddr_t paddr;
	for (size_t i = 1; i < npages; i++) {
f0101030:	bb 01 00 00 00       	mov    $0x1,%ebx
f0101035:	eb 4a                	jmp    f0101081 <page_init+0x56>
		paddr = i * PGSIZE;
f0101037:	89 de                	mov    %ebx,%esi
f0101039:	c1 e6 0c             	shl    $0xc,%esi
		if (paddr >= PADDR(boot_alloc(0)) || paddr < IOPHYSMEM) { // Si no es una dirección prohibida
f010103c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101041:	e8 04 fa ff ff       	call   f0100a4a <boot_alloc>
f0101046:	89 c1                	mov    %eax,%ecx
f0101048:	ba 3c 01 00 00       	mov    $0x13c,%edx
f010104d:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0101052:	e8 06 fb ff ff       	call   f0100b5d <_paddr>
f0101057:	81 fe ff ff 09 00    	cmp    $0x9ffff,%esi
f010105d:	76 04                	jbe    f0101063 <page_init+0x38>
f010105f:	39 c6                	cmp    %eax,%esi
f0101061:	72 1b                	jb     f010107e <page_init+0x53>
			// pages[i].pp_ref = 0; // Fue seteado con memset
		  pages[i].pp_link = page_free_list;
f0101063:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0101069:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f010106e:	89 14 d8             	mov    %edx,(%eax,%ebx,8)
		  page_free_list = &pages[i];
f0101071:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0101076:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0101079:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	physaddr_t paddr;
	for (size_t i = 1; i < npages; i++) {
f010107e:	83 c3 01             	add    $0x1,%ebx
f0101081:	3b 1d 44 79 11 f0    	cmp    0xf0117944,%ebx
f0101087:	72 ae                	jb     f0101037 <page_init+0xc>
			// pages[i].pp_ref = 0; // Fue seteado con memset
		  pages[i].pp_link = page_free_list;
		  page_free_list = &pages[i];
		}
	}
}
f0101089:	5b                   	pop    %ebx
f010108a:	5e                   	pop    %esi
f010108b:	5d                   	pop    %ebp
f010108c:	c3                   	ret    

f010108d <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f010108d:	55                   	push   %ebp
f010108e:	89 e5                	mov    %esp,%ebp
f0101090:	53                   	push   %ebx
f0101091:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if (page_free_list) {
f0101094:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f010109a:	85 db                	test   %ebx,%ebx
f010109c:	74 2d                	je     f01010cb <page_alloc+0x3e>
		struct PageInfo * page = page_free_list;
	  page_free_list = page->pp_link;
f010109e:	8b 03                	mov    (%ebx),%eax
f01010a0:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	  page->pp_link = NULL;
f01010a5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	  if (alloc_flags & ALLOC_ZERO) {
f01010ab:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010af:	74 1a                	je     f01010cb <page_alloc+0x3e>
			// Seteamos a cero la pagina fisica
			// no el struct PageInfo
			memset(page2kva(page), 0, PGSIZE);
f01010b1:	89 d8                	mov    %ebx,%eax
f01010b3:	e8 17 fa ff ff       	call   f0100acf <page2kva>
f01010b8:	83 ec 04             	sub    $0x4,%esp
f01010bb:	68 00 10 00 00       	push   $0x1000
f01010c0:	6a 00                	push   $0x0
f01010c2:	50                   	push   %eax
f01010c3:	e8 8c 20 00 00       	call   f0103154 <memset>
f01010c8:	83 c4 10             	add    $0x10,%esp

		return page;
	}

	return NULL; // No free pages
}
f01010cb:	89 d8                	mov    %ebx,%eax
f01010cd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010d0:	c9                   	leave  
f01010d1:	c3                   	ret    

f01010d2 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01010d2:	55                   	push   %ebp
f01010d3:	89 e5                	mov    %esp,%ebp
f01010d5:	83 ec 08             	sub    $0x8,%esp
f01010d8:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_link) {
f01010db:	83 38 00             	cmpl   $0x0,(%eax)
f01010de:	74 17                	je     f01010f7 <page_free+0x25>
		panic("page_free: try to free page with pp_link set\n");
f01010e0:	83 ec 04             	sub    $0x4,%esp
f01010e3:	68 18 3d 10 f0       	push   $0xf0103d18
f01010e8:	68 70 01 00 00       	push   $0x170
f01010ed:	68 f2 42 10 f0       	push   $0xf01042f2
f01010f2:	e8 94 ef ff ff       	call   f010008b <_panic>
	}

	if (pp->pp_ref) {
f01010f7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010fc:	74 17                	je     f0101115 <page_free+0x43>
		panic("page_free: try to free page with pp_ref's\n");
f01010fe:	83 ec 04             	sub    $0x4,%esp
f0101101:	68 48 3d 10 f0       	push   $0xf0103d48
f0101106:	68 74 01 00 00       	push   $0x174
f010110b:	68 f2 42 10 f0       	push   $0xf01042f2
f0101110:	e8 76 ef ff ff       	call   f010008b <_panic>
	}

	pp->pp_link = page_free_list;
f0101115:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f010111b:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010111d:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0101122:	c9                   	leave  
f0101123:	c3                   	ret    

f0101124 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f0101124:	55                   	push   %ebp
f0101125:	89 e5                	mov    %esp,%ebp
f0101127:	57                   	push   %edi
f0101128:	56                   	push   %esi
f0101129:	53                   	push   %ebx
f010112a:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010112d:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f0101134:	75 17                	jne    f010114d <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f0101136:	83 ec 04             	sub    $0x4,%esp
f0101139:	68 d8 43 10 f0       	push   $0xf01043d8
f010113e:	68 db 02 00 00       	push   $0x2db
f0101143:	68 f2 42 10 f0       	push   $0xf01042f2
f0101148:	e8 3e ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010114d:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101152:	be 00 00 00 00       	mov    $0x0,%esi
f0101157:	eb 05                	jmp    f010115e <check_page_alloc+0x3a>
		++nfree;
f0101159:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010115c:	8b 00                	mov    (%eax),%eax
f010115e:	85 c0                	test   %eax,%eax
f0101160:	75 f7                	jne    f0101159 <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101162:	83 ec 0c             	sub    $0xc,%esp
f0101165:	6a 00                	push   $0x0
f0101167:	e8 21 ff ff ff       	call   f010108d <page_alloc>
f010116c:	89 c7                	mov    %eax,%edi
f010116e:	83 c4 10             	add    $0x10,%esp
f0101171:	85 c0                	test   %eax,%eax
f0101173:	75 19                	jne    f010118e <check_page_alloc+0x6a>
f0101175:	68 f3 43 10 f0       	push   $0xf01043f3
f010117a:	68 0c 43 10 f0       	push   $0xf010430c
f010117f:	68 e3 02 00 00       	push   $0x2e3
f0101184:	68 f2 42 10 f0       	push   $0xf01042f2
f0101189:	e8 fd ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010118e:	83 ec 0c             	sub    $0xc,%esp
f0101191:	6a 00                	push   $0x0
f0101193:	e8 f5 fe ff ff       	call   f010108d <page_alloc>
f0101198:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010119b:	83 c4 10             	add    $0x10,%esp
f010119e:	85 c0                	test   %eax,%eax
f01011a0:	75 19                	jne    f01011bb <check_page_alloc+0x97>
f01011a2:	68 09 44 10 f0       	push   $0xf0104409
f01011a7:	68 0c 43 10 f0       	push   $0xf010430c
f01011ac:	68 e4 02 00 00       	push   $0x2e4
f01011b1:	68 f2 42 10 f0       	push   $0xf01042f2
f01011b6:	e8 d0 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01011bb:	83 ec 0c             	sub    $0xc,%esp
f01011be:	6a 00                	push   $0x0
f01011c0:	e8 c8 fe ff ff       	call   f010108d <page_alloc>
f01011c5:	89 c3                	mov    %eax,%ebx
f01011c7:	83 c4 10             	add    $0x10,%esp
f01011ca:	85 c0                	test   %eax,%eax
f01011cc:	75 19                	jne    f01011e7 <check_page_alloc+0xc3>
f01011ce:	68 1f 44 10 f0       	push   $0xf010441f
f01011d3:	68 0c 43 10 f0       	push   $0xf010430c
f01011d8:	68 e5 02 00 00       	push   $0x2e5
f01011dd:	68 f2 42 10 f0       	push   $0xf01042f2
f01011e2:	e8 a4 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011e7:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01011ea:	75 19                	jne    f0101205 <check_page_alloc+0xe1>
f01011ec:	68 35 44 10 f0       	push   $0xf0104435
f01011f1:	68 0c 43 10 f0       	push   $0xf010430c
f01011f6:	68 e8 02 00 00       	push   $0x2e8
f01011fb:	68 f2 42 10 f0       	push   $0xf01042f2
f0101200:	e8 86 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101205:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101208:	74 04                	je     f010120e <check_page_alloc+0xea>
f010120a:	39 c7                	cmp    %eax,%edi
f010120c:	75 19                	jne    f0101227 <check_page_alloc+0x103>
f010120e:	68 74 3d 10 f0       	push   $0xf0103d74
f0101213:	68 0c 43 10 f0       	push   $0xf010430c
f0101218:	68 e9 02 00 00       	push   $0x2e9
f010121d:	68 f2 42 10 f0       	push   $0xf01042f2
f0101222:	e8 64 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages * PGSIZE);
f0101227:	89 f8                	mov    %edi,%eax
f0101229:	e8 7c f7 ff ff       	call   f01009aa <page2pa>
f010122e:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0101234:	c1 e1 0c             	shl    $0xc,%ecx
f0101237:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010123a:	39 c8                	cmp    %ecx,%eax
f010123c:	72 19                	jb     f0101257 <check_page_alloc+0x133>
f010123e:	68 94 3d 10 f0       	push   $0xf0103d94
f0101243:	68 0c 43 10 f0       	push   $0xf010430c
f0101248:	68 ea 02 00 00       	push   $0x2ea
f010124d:	68 f2 42 10 f0       	push   $0xf01042f2
f0101252:	e8 34 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages * PGSIZE);
f0101257:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010125a:	e8 4b f7 ff ff       	call   f01009aa <page2pa>
f010125f:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101262:	77 19                	ja     f010127d <check_page_alloc+0x159>
f0101264:	68 b4 3d 10 f0       	push   $0xf0103db4
f0101269:	68 0c 43 10 f0       	push   $0xf010430c
f010126e:	68 eb 02 00 00       	push   $0x2eb
f0101273:	68 f2 42 10 f0       	push   $0xf01042f2
f0101278:	e8 0e ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages * PGSIZE);
f010127d:	89 d8                	mov    %ebx,%eax
f010127f:	e8 26 f7 ff ff       	call   f01009aa <page2pa>
f0101284:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101287:	77 19                	ja     f01012a2 <check_page_alloc+0x17e>
f0101289:	68 d4 3d 10 f0       	push   $0xf0103dd4
f010128e:	68 0c 43 10 f0       	push   $0xf010430c
f0101293:	68 ec 02 00 00       	push   $0x2ec
f0101298:	68 f2 42 10 f0       	push   $0xf01042f2
f010129d:	e8 e9 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01012a2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01012a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01012aa:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01012b1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01012b4:	83 ec 0c             	sub    $0xc,%esp
f01012b7:	6a 00                	push   $0x0
f01012b9:	e8 cf fd ff ff       	call   f010108d <page_alloc>
f01012be:	83 c4 10             	add    $0x10,%esp
f01012c1:	85 c0                	test   %eax,%eax
f01012c3:	74 19                	je     f01012de <check_page_alloc+0x1ba>
f01012c5:	68 47 44 10 f0       	push   $0xf0104447
f01012ca:	68 0c 43 10 f0       	push   $0xf010430c
f01012cf:	68 f3 02 00 00       	push   $0x2f3
f01012d4:	68 f2 42 10 f0       	push   $0xf01042f2
f01012d9:	e8 ad ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012de:	83 ec 0c             	sub    $0xc,%esp
f01012e1:	57                   	push   %edi
f01012e2:	e8 eb fd ff ff       	call   f01010d2 <page_free>
	page_free(pp1);
f01012e7:	83 c4 04             	add    $0x4,%esp
f01012ea:	ff 75 e4             	pushl  -0x1c(%ebp)
f01012ed:	e8 e0 fd ff ff       	call   f01010d2 <page_free>
	page_free(pp2);
f01012f2:	89 1c 24             	mov    %ebx,(%esp)
f01012f5:	e8 d8 fd ff ff       	call   f01010d2 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101301:	e8 87 fd ff ff       	call   f010108d <page_alloc>
f0101306:	89 c3                	mov    %eax,%ebx
f0101308:	83 c4 10             	add    $0x10,%esp
f010130b:	85 c0                	test   %eax,%eax
f010130d:	75 19                	jne    f0101328 <check_page_alloc+0x204>
f010130f:	68 f3 43 10 f0       	push   $0xf01043f3
f0101314:	68 0c 43 10 f0       	push   $0xf010430c
f0101319:	68 fa 02 00 00       	push   $0x2fa
f010131e:	68 f2 42 10 f0       	push   $0xf01042f2
f0101323:	e8 63 ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101328:	83 ec 0c             	sub    $0xc,%esp
f010132b:	6a 00                	push   $0x0
f010132d:	e8 5b fd ff ff       	call   f010108d <page_alloc>
f0101332:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101335:	83 c4 10             	add    $0x10,%esp
f0101338:	85 c0                	test   %eax,%eax
f010133a:	75 19                	jne    f0101355 <check_page_alloc+0x231>
f010133c:	68 09 44 10 f0       	push   $0xf0104409
f0101341:	68 0c 43 10 f0       	push   $0xf010430c
f0101346:	68 fb 02 00 00       	push   $0x2fb
f010134b:	68 f2 42 10 f0       	push   $0xf01042f2
f0101350:	e8 36 ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101355:	83 ec 0c             	sub    $0xc,%esp
f0101358:	6a 00                	push   $0x0
f010135a:	e8 2e fd ff ff       	call   f010108d <page_alloc>
f010135f:	89 c7                	mov    %eax,%edi
f0101361:	83 c4 10             	add    $0x10,%esp
f0101364:	85 c0                	test   %eax,%eax
f0101366:	75 19                	jne    f0101381 <check_page_alloc+0x25d>
f0101368:	68 1f 44 10 f0       	push   $0xf010441f
f010136d:	68 0c 43 10 f0       	push   $0xf010430c
f0101372:	68 fc 02 00 00       	push   $0x2fc
f0101377:	68 f2 42 10 f0       	push   $0xf01042f2
f010137c:	e8 0a ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101381:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101384:	75 19                	jne    f010139f <check_page_alloc+0x27b>
f0101386:	68 35 44 10 f0       	push   $0xf0104435
f010138b:	68 0c 43 10 f0       	push   $0xf010430c
f0101390:	68 fe 02 00 00       	push   $0x2fe
f0101395:	68 f2 42 10 f0       	push   $0xf01042f2
f010139a:	e8 ec ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010139f:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01013a2:	74 04                	je     f01013a8 <check_page_alloc+0x284>
f01013a4:	39 c3                	cmp    %eax,%ebx
f01013a6:	75 19                	jne    f01013c1 <check_page_alloc+0x29d>
f01013a8:	68 74 3d 10 f0       	push   $0xf0103d74
f01013ad:	68 0c 43 10 f0       	push   $0xf010430c
f01013b2:	68 ff 02 00 00       	push   $0x2ff
f01013b7:	68 f2 42 10 f0       	push   $0xf01042f2
f01013bc:	e8 ca ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013c1:	83 ec 0c             	sub    $0xc,%esp
f01013c4:	6a 00                	push   $0x0
f01013c6:	e8 c2 fc ff ff       	call   f010108d <page_alloc>
f01013cb:	83 c4 10             	add    $0x10,%esp
f01013ce:	85 c0                	test   %eax,%eax
f01013d0:	74 19                	je     f01013eb <check_page_alloc+0x2c7>
f01013d2:	68 47 44 10 f0       	push   $0xf0104447
f01013d7:	68 0c 43 10 f0       	push   $0xf010430c
f01013dc:	68 00 03 00 00       	push   $0x300
f01013e1:	68 f2 42 10 f0       	push   $0xf01042f2
f01013e6:	e8 a0 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01013eb:	89 d8                	mov    %ebx,%eax
f01013ed:	e8 dd f6 ff ff       	call   f0100acf <page2kva>
f01013f2:	83 ec 04             	sub    $0x4,%esp
f01013f5:	68 00 10 00 00       	push   $0x1000
f01013fa:	6a 01                	push   $0x1
f01013fc:	50                   	push   %eax
f01013fd:	e8 52 1d 00 00       	call   f0103154 <memset>
	page_free(pp0);
f0101402:	89 1c 24             	mov    %ebx,(%esp)
f0101405:	e8 c8 fc ff ff       	call   f01010d2 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010140a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101411:	e8 77 fc ff ff       	call   f010108d <page_alloc>
f0101416:	83 c4 10             	add    $0x10,%esp
f0101419:	85 c0                	test   %eax,%eax
f010141b:	75 19                	jne    f0101436 <check_page_alloc+0x312>
f010141d:	68 56 44 10 f0       	push   $0xf0104456
f0101422:	68 0c 43 10 f0       	push   $0xf010430c
f0101427:	68 05 03 00 00       	push   $0x305
f010142c:	68 f2 42 10 f0       	push   $0xf01042f2
f0101431:	e8 55 ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101436:	39 c3                	cmp    %eax,%ebx
f0101438:	74 19                	je     f0101453 <check_page_alloc+0x32f>
f010143a:	68 74 44 10 f0       	push   $0xf0104474
f010143f:	68 0c 43 10 f0       	push   $0xf010430c
f0101444:	68 06 03 00 00       	push   $0x306
f0101449:	68 f2 42 10 f0       	push   $0xf01042f2
f010144e:	e8 38 ec ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f0101453:	89 d8                	mov    %ebx,%eax
f0101455:	e8 75 f6 ff ff       	call   f0100acf <page2kva>
f010145a:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101460:	80 38 00             	cmpb   $0x0,(%eax)
f0101463:	74 19                	je     f010147e <check_page_alloc+0x35a>
f0101465:	68 84 44 10 f0       	push   $0xf0104484
f010146a:	68 0c 43 10 f0       	push   $0xf010430c
f010146f:	68 09 03 00 00       	push   $0x309
f0101474:	68 f2 42 10 f0       	push   $0xf01042f2
f0101479:	e8 0d ec ff ff       	call   f010008b <_panic>
f010147e:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101481:	39 d0                	cmp    %edx,%eax
f0101483:	75 db                	jne    f0101460 <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101485:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101488:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f010148d:	83 ec 0c             	sub    $0xc,%esp
f0101490:	53                   	push   %ebx
f0101491:	e8 3c fc ff ff       	call   f01010d2 <page_free>
	page_free(pp1);
f0101496:	83 c4 04             	add    $0x4,%esp
f0101499:	ff 75 e4             	pushl  -0x1c(%ebp)
f010149c:	e8 31 fc ff ff       	call   f01010d2 <page_free>
	page_free(pp2);
f01014a1:	89 3c 24             	mov    %edi,(%esp)
f01014a4:	e8 29 fc ff ff       	call   f01010d2 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014a9:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01014ae:	83 c4 10             	add    $0x10,%esp
f01014b1:	eb 05                	jmp    f01014b8 <check_page_alloc+0x394>
		--nfree;
f01014b3:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014b6:	8b 00                	mov    (%eax),%eax
f01014b8:	85 c0                	test   %eax,%eax
f01014ba:	75 f7                	jne    f01014b3 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f01014bc:	85 f6                	test   %esi,%esi
f01014be:	74 19                	je     f01014d9 <check_page_alloc+0x3b5>
f01014c0:	68 8e 44 10 f0       	push   $0xf010448e
f01014c5:	68 0c 43 10 f0       	push   $0xf010430c
f01014ca:	68 16 03 00 00       	push   $0x316
f01014cf:	68 f2 42 10 f0       	push   $0xf01042f2
f01014d4:	e8 b2 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01014d9:	83 ec 0c             	sub    $0xc,%esp
f01014dc:	68 f4 3d 10 f0       	push   $0xf0103df4
f01014e1:	e8 c7 11 00 00       	call   f01026ad <cprintf>
}
f01014e6:	83 c4 10             	add    $0x10,%esp
f01014e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014ec:	5b                   	pop    %ebx
f01014ed:	5e                   	pop    %esi
f01014ee:	5f                   	pop    %edi
f01014ef:	5d                   	pop    %ebp
f01014f0:	c3                   	ret    

f01014f1 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo *pp)
{
f01014f1:	55                   	push   %ebp
f01014f2:	89 e5                	mov    %esp,%ebp
f01014f4:	83 ec 08             	sub    $0x8,%esp
f01014f7:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01014fa:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01014fe:	83 e8 01             	sub    $0x1,%eax
f0101501:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101505:	66 85 c0             	test   %ax,%ax
f0101508:	75 0c                	jne    f0101516 <page_decref+0x25>
		page_free(pp);
f010150a:	83 ec 0c             	sub    $0xc,%esp
f010150d:	52                   	push   %edx
f010150e:	e8 bf fb ff ff       	call   f01010d2 <page_free>
f0101513:	83 c4 10             	add    $0x10,%esp
}
f0101516:	c9                   	leave  
f0101517:	c3                   	ret    

f0101518 <pgdir_walk>:

	Retorna un puntero (direccion virtual) a la page table
*/
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101518:	55                   	push   %ebp
f0101519:	89 e5                	mov    %esp,%ebp
f010151b:	57                   	push   %edi
f010151c:	56                   	push   %esi
f010151d:	53                   	push   %ebx
f010151e:	83 ec 0c             	sub    $0xc,%esp
f0101521:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Obtengo la entrada en la PD sumando a pgdir el indice de la VA
	pde_t * pde = pgdir + PDX(va);
f0101524:	89 f3                	mov    %esi,%ebx
f0101526:	c1 eb 16             	shr    $0x16,%ebx
f0101529:	c1 e3 02             	shl    $0x2,%ebx
f010152c:	03 5d 08             	add    0x8(%ebp),%ebx

	if ((*pde & PTE_P)) {
f010152f:	8b 0b                	mov    (%ebx),%ecx
f0101531:	f6 c1 01             	test   $0x1,%cl
f0101534:	74 22                	je     f0101558 <pgdir_walk+0x40>
		// Obtengo la direccion virtual del PT base register
		pte_t * ptbr = KADDR(PTE_ADDR(*pde));
f0101536:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010153c:	ba b8 01 00 00       	mov    $0x1b8,%edx
f0101541:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0101546:	e8 58 f5 ff ff       	call   f0100aa3 <_kaddr>

		// Si ya existe retornamos el PTE correspondiente
		return ptbr + PTX(va);
f010154b:	c1 ee 0a             	shr    $0xa,%esi
f010154e:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101554:	01 f0                	add    %esi,%eax
f0101556:	eb 56                	jmp    f01015ae <pgdir_walk+0x96>
		// Devolvemos el puntero a PTE
		return ptbr + PTX(va);
	} else {
		// No está presente la page table 
		// buscada y el flag de create está desactivado
		return NULL; 
f0101558:	b8 00 00 00 00       	mov    $0x0,%eax
		// Obtengo la direccion virtual del PT base register
		pte_t * ptbr = KADDR(PTE_ADDR(*pde));

		// Si ya existe retornamos el PTE correspondiente
		return ptbr + PTX(va);
	} else if (create) {
f010155d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101561:	74 4b                	je     f01015ae <pgdir_walk+0x96>
		// Si la page table buscada no está presente y el flag de create esta activado
		struct PageInfo * new_pt_page = page_alloc(ALLOC_ZERO);
f0101563:	83 ec 0c             	sub    $0xc,%esp
f0101566:	6a 01                	push   $0x1
f0101568:	e8 20 fb ff ff       	call   f010108d <page_alloc>
f010156d:	89 c7                	mov    %eax,%edi

		if (!new_pt_page) {
f010156f:	83 c4 10             	add    $0x10,%esp
f0101572:	85 c0                	test   %eax,%eax
f0101574:	74 33                	je     f01015a9 <pgdir_walk+0x91>
			return NULL;	// Fallo el page alloc porque no había mas memoria
		}

		// Obtengo la direccion física de la entrada a la page table alocada
		physaddr_t pt_phyaddr = page2pa(new_pt_page);
f0101576:	e8 2f f4 ff ff       	call   f01009aa <page2pa>

		// Escribimos la direccion fisica y los flags correspondientes
		*pde = (pt_phyaddr | PTE_P | PTE_W | PTE_U);
f010157b:	83 c8 07             	or     $0x7,%eax
f010157e:	89 03                	mov    %eax,(%ebx)

		// Marco como referenciado la page info asociada a la pagina fisica alocada para la page table
		new_pt_page->pp_ref++;
f0101580:	66 83 47 04 01       	addw   $0x1,0x4(%edi)

		// Obtengo la direccion virtual del PT base register
		pte_t * ptbr = KADDR(PTE_ADDR(*pde));
f0101585:	8b 0b                	mov    (%ebx),%ecx
f0101587:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010158d:	ba ce 01 00 00       	mov    $0x1ce,%edx
f0101592:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0101597:	e8 07 f5 ff ff       	call   f0100aa3 <_kaddr>
		
		// Devolvemos el puntero a PTE
		return ptbr + PTX(va);
f010159c:	c1 ee 0a             	shr    $0xa,%esi
f010159f:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01015a5:	01 f0                	add    %esi,%eax
f01015a7:	eb 05                	jmp    f01015ae <pgdir_walk+0x96>
	} else if (create) {
		// Si la page table buscada no está presente y el flag de create esta activado
		struct PageInfo * new_pt_page = page_alloc(ALLOC_ZERO);

		if (!new_pt_page) {
			return NULL;	// Fallo el page alloc porque no había mas memoria
f01015a9:	b8 00 00 00 00       	mov    $0x0,%eax
	} else {
		// No está presente la page table 
		// buscada y el flag de create está desactivado
		return NULL; 
	}
}
f01015ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015b1:	5b                   	pop    %ebx
f01015b2:	5e                   	pop    %esi
f01015b3:	5f                   	pop    %edi
f01015b4:	5d                   	pop    %ebp
f01015b5:	c3                   	ret    

f01015b6 <boot_map_region>:
// boot_map_region(kern_pgdir, UPAGES, npages, PADDR(pages), PTE_U | PTE_P);

// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01015b6:	55                   	push   %ebp
f01015b7:	89 e5                	mov    %esp,%ebp
f01015b9:	57                   	push   %edi
f01015ba:	56                   	push   %esi
f01015bb:	53                   	push   %ebx
f01015bc:	83 ec 1c             	sub    $0x1c,%esp
f01015bf:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01015c2:	8b 75 08             	mov    0x8(%ebp),%esi
f01015c5:	8b 45 0c             	mov    0xc(%ebp),%eax
	assert(va % PGSIZE == 0);
f01015c8:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01015ce:	74 19                	je     f01015e9 <boot_map_region+0x33>
f01015d0:	68 99 44 10 f0       	push   $0xf0104499
f01015d5:	68 0c 43 10 f0       	push   $0xf010430c
f01015da:	68 ea 01 00 00       	push   $0x1ea
f01015df:	68 f2 42 10 f0       	push   $0xf01042f2
f01015e4:	e8 a2 ea ff ff       	call   f010008b <_panic>
	assert(pa % PGSIZE == 0);
f01015e9:	f7 c6 ff 0f 00 00    	test   $0xfff,%esi
f01015ef:	74 19                	je     f010160a <boot_map_region+0x54>
f01015f1:	68 aa 44 10 f0       	push   $0xf01044aa
f01015f6:	68 0c 43 10 f0       	push   $0xf010430c
f01015fb:	68 eb 01 00 00       	push   $0x1eb
f0101600:	68 f2 42 10 f0       	push   $0xf01042f2
f0101605:	e8 81 ea ff ff       	call   f010008b <_panic>
	assert(size % PGSIZE == 0);
f010160a:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f0101610:	74 19                	je     f010162b <boot_map_region+0x75>
f0101612:	68 bb 44 10 f0       	push   $0xf01044bb
f0101617:	68 0c 43 10 f0       	push   $0xf010430c
f010161c:	68 ec 01 00 00       	push   $0x1ec
f0101621:	68 f2 42 10 f0       	push   $0xf01042f2
f0101626:	e8 60 ea ff ff       	call   f010008b <_panic>
	assert(perm < (1 << PTXSHIFT));
f010162b:	3d ff 0f 00 00       	cmp    $0xfff,%eax
f0101630:	7f 1a                	jg     f010164c <boot_map_region+0x96>

	for (size_t i = 0; i < size/PGSIZE; i++, va+=PGSIZE, pa+=PGSIZE) {
f0101632:	c1 e9 0c             	shr    $0xc,%ecx
f0101635:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101638:	89 d3                	mov    %edx,%ebx
f010163a:	bf 00 00 00 00       	mov    $0x0,%edi
f010163f:	29 d6                	sub    %edx,%esi
f0101641:	89 75 e0             	mov    %esi,-0x20(%ebp)
		pte_t * pte = pgdir_walk(pgdir, (const void *) va, 1);
		*pte |= pa | perm | PTE_P;
f0101644:	83 c8 01             	or     $0x1,%eax
f0101647:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010164a:	eb 38                	jmp    f0101684 <boot_map_region+0xce>
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	assert(va % PGSIZE == 0);
	assert(pa % PGSIZE == 0);
	assert(size % PGSIZE == 0);
	assert(perm < (1 << PTXSHIFT));
f010164c:	68 ce 44 10 f0       	push   $0xf01044ce
f0101651:	68 0c 43 10 f0       	push   $0xf010430c
f0101656:	68 ed 01 00 00       	push   $0x1ed
f010165b:	68 f2 42 10 f0       	push   $0xf01042f2
f0101660:	e8 26 ea ff ff       	call   f010008b <_panic>

	for (size_t i = 0; i < size/PGSIZE; i++, va+=PGSIZE, pa+=PGSIZE) {
		pte_t * pte = pgdir_walk(pgdir, (const void *) va, 1);
f0101665:	83 ec 04             	sub    $0x4,%esp
f0101668:	6a 01                	push   $0x1
f010166a:	53                   	push   %ebx
f010166b:	ff 75 dc             	pushl  -0x24(%ebp)
f010166e:	e8 a5 fe ff ff       	call   f0101518 <pgdir_walk>
		*pte |= pa | perm | PTE_P;
f0101673:	0b 75 d8             	or     -0x28(%ebp),%esi
f0101676:	09 30                	or     %esi,(%eax)
	assert(va % PGSIZE == 0);
	assert(pa % PGSIZE == 0);
	assert(size % PGSIZE == 0);
	assert(perm < (1 << PTXSHIFT));

	for (size_t i = 0; i < size/PGSIZE; i++, va+=PGSIZE, pa+=PGSIZE) {
f0101678:	83 c7 01             	add    $0x1,%edi
f010167b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101681:	83 c4 10             	add    $0x10,%esp
f0101684:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101687:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f010168a:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f010168d:	75 d6                	jne    f0101665 <boot_map_region+0xaf>
		pte_t * pte = pgdir_walk(pgdir, (const void *) va, 1);
		*pte |= pa | perm | PTE_P;
	}
}
f010168f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101692:	5b                   	pop    %ebx
f0101693:	5e                   	pop    %esi
f0101694:	5f                   	pop    %edi
f0101695:	5d                   	pop    %ebp
f0101696:	c3                   	ret    

f0101697 <page_lookup>:
	pa2page(f) -> Me retorna la página de la dirección física y retornamos esto
*/

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101697:	55                   	push   %ebp
f0101698:	89 e5                	mov    %esp,%ebp
f010169a:	53                   	push   %ebx
f010169b:	83 ec 08             	sub    $0x8,%esp
f010169e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t * pte = pgdir_walk(pgdir, va, 0);
f01016a1:	6a 00                	push   $0x0
f01016a3:	ff 75 0c             	pushl  0xc(%ebp)
f01016a6:	ff 75 08             	pushl  0x8(%ebp)
f01016a9:	e8 6a fe ff ff       	call   f0101518 <pgdir_walk>

	if (pte == NULL || !(*pte & PTE_P)) {
f01016ae:	83 c4 10             	add    $0x10,%esp
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	74 19                	je     f01016ce <page_lookup+0x37>
f01016b5:	f6 00 01             	testb  $0x1,(%eax)
f01016b8:	74 1b                	je     f01016d5 <page_lookup+0x3e>
		// No hay pagina mapeada para va
		return NULL; 
	}

	if (pte_store) {
f01016ba:	85 db                	test   %ebx,%ebx
f01016bc:	74 02                	je     f01016c0 <page_lookup+0x29>
		// Guardamos en pte_store la direccion de PTE
		*pte_store = pte;
f01016be:	89 03                	mov    %eax,(%ebx)
	}

	physaddr_t page_paddr = PTE_ADDR(*pte);
	return pa2page(page_paddr);
f01016c0:	8b 00                	mov    (%eax),%eax
f01016c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01016c7:	e8 33 f9 ff ff       	call   f0100fff <pa2page>
f01016cc:	eb 0c                	jmp    f01016da <page_lookup+0x43>
{
	pte_t * pte = pgdir_walk(pgdir, va, 0);

	if (pte == NULL || !(*pte & PTE_P)) {
		// No hay pagina mapeada para va
		return NULL; 
f01016ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01016d3:	eb 05                	jmp    f01016da <page_lookup+0x43>
f01016d5:	b8 00 00 00 00       	mov    $0x0,%eax
		*pte_store = pte;
	}

	physaddr_t page_paddr = PTE_ADDR(*pte);
	return pa2page(page_paddr);
}
f01016da:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016dd:	c9                   	leave  
f01016de:	c3                   	ret    

f01016df <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01016df:	55                   	push   %ebp
f01016e0:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01016e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016e5:	e8 a0 f2 ff ff       	call   f010098a <invlpg>
}
f01016ea:	5d                   	pop    %ebp
f01016eb:	c3                   	ret    

f01016ec <page_remove>:
		decrementa el pageref y si queda en cero llama a free de la pagina automaticamente.
	- limpiar PTE (Pone la page table entry a cero)
*/
void
page_remove(pde_t *pgdir, void *va)
{
f01016ec:	55                   	push   %ebp
f01016ed:	89 e5                	mov    %esp,%ebp
f01016ef:	56                   	push   %esi
f01016f0:	53                   	push   %ebx
f01016f1:	83 ec 14             	sub    $0x14,%esp
f01016f4:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016f7:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t * pte;

	// Conseguimos el struct PageInfo asociado y guardamos su PTE
	struct PageInfo * page_to_remove = page_lookup(pgdir, va, &pte);
f01016fa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01016fd:	50                   	push   %eax
f01016fe:	56                   	push   %esi
f01016ff:	53                   	push   %ebx
f0101700:	e8 92 ff ff ff       	call   f0101697 <page_lookup>

	// Decrementamos pp_ref y liberamos si es necesario
	page_decref(page_to_remove);
f0101705:	89 04 24             	mov    %eax,(%esp)
f0101708:	e8 e4 fd ff ff       	call   f01014f1 <page_decref>

	// Escribimos PTE en 0
	*pte = 0;
f010170d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101710:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Realizamos la invalidacion de la entrada de la TLB
	tlb_invalidate(pgdir, va);
f0101716:	83 c4 08             	add    $0x8,%esp
f0101719:	56                   	push   %esi
f010171a:	53                   	push   %ebx
f010171b:	e8 bf ff ff ff       	call   f01016df <tlb_invalidate>
}
f0101720:	83 c4 10             	add    $0x10,%esp
f0101723:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101726:	5b                   	pop    %ebx
f0101727:	5e                   	pop    %esi
f0101728:	5d                   	pop    %ebp
f0101729:	c3                   	ret    

f010172a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010172a:	55                   	push   %ebp
f010172b:	89 e5                	mov    %esp,%ebp
f010172d:	57                   	push   %edi
f010172e:	56                   	push   %esi
f010172f:	53                   	push   %ebx
f0101730:	83 ec 10             	sub    $0x10,%esp
f0101733:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101736:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t * pte = pgdir_walk(pgdir, va, 1);
f0101739:	6a 01                	push   $0x1
f010173b:	57                   	push   %edi
f010173c:	ff 75 08             	pushl  0x8(%ebp)
f010173f:	e8 d4 fd ff ff       	call   f0101518 <pgdir_walk>

	if (pte == NULL) {
f0101744:	83 c4 10             	add    $0x10,%esp
f0101747:	85 c0                	test   %eax,%eax
f0101749:	74 33                	je     f010177e <page_insert+0x54>
f010174b:	89 c6                	mov    %eax,%esi

	// Actualizamos el estado de PageInfo
	// Antes de page_remove ya que esta funcion
	// puede llegar a liberar la pagina si es la ultima
	// referencia. Esto evita el caso borde
	pp->pp_ref++;
f010174d:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

	if (*pte & PTE_P) {
f0101752:	f6 00 01             	testb  $0x1,(%eax)
f0101755:	74 0f                	je     f0101766 <page_insert+0x3c>
		// Si ya estaba ocupada la removemos
		page_remove(pgdir, va);
f0101757:	83 ec 08             	sub    $0x8,%esp
f010175a:	57                   	push   %edi
f010175b:	ff 75 08             	pushl  0x8(%ebp)
f010175e:	e8 89 ff ff ff       	call   f01016ec <page_remove>
f0101763:	83 c4 10             	add    $0x10,%esp
	}

	// Obtenemos la direccion fisica del struct PageInfo
	physaddr_t padrr = page2pa(pp);
f0101766:	89 d8                	mov    %ebx,%eax
f0101768:	e8 3d f2 ff ff       	call   f01009aa <page2pa>

	// No hace falta el shift porque los 12 bits de phadrr son 0
	// pues las paginas estan alineadas a multiplos de 4096
	// seteamos la direccion fisica y los permisos
	*pte = padrr | perm | PTE_P;
f010176d:	8b 55 14             	mov    0x14(%ebp),%edx
f0101770:	83 ca 01             	or     $0x1,%edx
f0101773:	09 d0                	or     %edx,%eax
f0101775:	89 06                	mov    %eax,(%esi)

	// pp_link ya fue puesto a null en la llamada
	// correspondiente a page_alloc

	return 0;
f0101777:	b8 00 00 00 00       	mov    $0x0,%eax
f010177c:	eb 05                	jmp    f0101783 <page_insert+0x59>
{
	pte_t * pte = pgdir_walk(pgdir, va, 1);

	if (pte == NULL) {
		// pgdir_walk pudo fallar por falta de memoria
		return -E_NO_MEM;
f010177e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax

	// pp_link ya fue puesto a null en la llamada
	// correspondiente a page_alloc

	return 0;
}
f0101783:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101786:	5b                   	pop    %ebx
f0101787:	5e                   	pop    %esi
f0101788:	5f                   	pop    %edi
f0101789:	5d                   	pop    %ebp
f010178a:	c3                   	ret    

f010178b <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f010178b:	55                   	push   %ebp
f010178c:	89 e5                	mov    %esp,%ebp
f010178e:	57                   	push   %edi
f010178f:	56                   	push   %esi
f0101790:	53                   	push   %ebx
f0101791:	83 ec 38             	sub    $0x38,%esp
	void *va;
	int i;
	extern pde_t entry_pgdir[];
	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101794:	6a 00                	push   $0x0
f0101796:	e8 f2 f8 ff ff       	call   f010108d <page_alloc>
f010179b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010179e:	83 c4 10             	add    $0x10,%esp
f01017a1:	85 c0                	test   %eax,%eax
f01017a3:	75 19                	jne    f01017be <check_page+0x33>
f01017a5:	68 f3 43 10 f0       	push   $0xf01043f3
f01017aa:	68 0c 43 10 f0       	push   $0xf010430c
f01017af:	68 7a 03 00 00       	push   $0x37a
f01017b4:	68 f2 42 10 f0       	push   $0xf01042f2
f01017b9:	e8 cd e8 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01017be:	83 ec 0c             	sub    $0xc,%esp
f01017c1:	6a 00                	push   $0x0
f01017c3:	e8 c5 f8 ff ff       	call   f010108d <page_alloc>
f01017c8:	89 c6                	mov    %eax,%esi
f01017ca:	83 c4 10             	add    $0x10,%esp
f01017cd:	85 c0                	test   %eax,%eax
f01017cf:	75 19                	jne    f01017ea <check_page+0x5f>
f01017d1:	68 09 44 10 f0       	push   $0xf0104409
f01017d6:	68 0c 43 10 f0       	push   $0xf010430c
f01017db:	68 7b 03 00 00       	push   $0x37b
f01017e0:	68 f2 42 10 f0       	push   $0xf01042f2
f01017e5:	e8 a1 e8 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01017ea:	83 ec 0c             	sub    $0xc,%esp
f01017ed:	6a 00                	push   $0x0
f01017ef:	e8 99 f8 ff ff       	call   f010108d <page_alloc>
f01017f4:	89 c3                	mov    %eax,%ebx
f01017f6:	83 c4 10             	add    $0x10,%esp
f01017f9:	85 c0                	test   %eax,%eax
f01017fb:	75 19                	jne    f0101816 <check_page+0x8b>
f01017fd:	68 1f 44 10 f0       	push   $0xf010441f
f0101802:	68 0c 43 10 f0       	push   $0xf010430c
f0101807:	68 7c 03 00 00       	push   $0x37c
f010180c:	68 f2 42 10 f0       	push   $0xf01042f2
f0101811:	e8 75 e8 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101816:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101819:	75 19                	jne    f0101834 <check_page+0xa9>
f010181b:	68 35 44 10 f0       	push   $0xf0104435
f0101820:	68 0c 43 10 f0       	push   $0xf010430c
f0101825:	68 7f 03 00 00       	push   $0x37f
f010182a:	68 f2 42 10 f0       	push   $0xf01042f2
f010182f:	e8 57 e8 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101834:	39 c6                	cmp    %eax,%esi
f0101836:	74 05                	je     f010183d <check_page+0xb2>
f0101838:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010183b:	75 19                	jne    f0101856 <check_page+0xcb>
f010183d:	68 74 3d 10 f0       	push   $0xf0103d74
f0101842:	68 0c 43 10 f0       	push   $0xf010430c
f0101847:	68 80 03 00 00       	push   $0x380
f010184c:	68 f2 42 10 f0       	push   $0xf01042f2
f0101851:	e8 35 e8 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101856:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010185b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010185e:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101865:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101868:	83 ec 0c             	sub    $0xc,%esp
f010186b:	6a 00                	push   $0x0
f010186d:	e8 1b f8 ff ff       	call   f010108d <page_alloc>
f0101872:	83 c4 10             	add    $0x10,%esp
f0101875:	85 c0                	test   %eax,%eax
f0101877:	74 19                	je     f0101892 <check_page+0x107>
f0101879:	68 47 44 10 f0       	push   $0xf0104447
f010187e:	68 0c 43 10 f0       	push   $0xf010430c
f0101883:	68 87 03 00 00       	push   $0x387
f0101888:	68 f2 42 10 f0       	push   $0xf01042f2
f010188d:	e8 f9 e7 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101892:	83 ec 04             	sub    $0x4,%esp
f0101895:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101898:	50                   	push   %eax
f0101899:	6a 00                	push   $0x0
f010189b:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018a1:	e8 f1 fd ff ff       	call   f0101697 <page_lookup>
f01018a6:	83 c4 10             	add    $0x10,%esp
f01018a9:	85 c0                	test   %eax,%eax
f01018ab:	74 19                	je     f01018c6 <check_page+0x13b>
f01018ad:	68 14 3e 10 f0       	push   $0xf0103e14
f01018b2:	68 0c 43 10 f0       	push   $0xf010430c
f01018b7:	68 8a 03 00 00       	push   $0x38a
f01018bc:	68 f2 42 10 f0       	push   $0xf01042f2
f01018c1:	e8 c5 e7 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018c6:	6a 02                	push   $0x2
f01018c8:	6a 00                	push   $0x0
f01018ca:	56                   	push   %esi
f01018cb:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018d1:	e8 54 fe ff ff       	call   f010172a <page_insert>
f01018d6:	83 c4 10             	add    $0x10,%esp
f01018d9:	85 c0                	test   %eax,%eax
f01018db:	78 19                	js     f01018f6 <check_page+0x16b>
f01018dd:	68 4c 3e 10 f0       	push   $0xf0103e4c
f01018e2:	68 0c 43 10 f0       	push   $0xf010430c
f01018e7:	68 8d 03 00 00       	push   $0x38d
f01018ec:	68 f2 42 10 f0       	push   $0xf01042f2
f01018f1:	e8 95 e7 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01018f6:	83 ec 0c             	sub    $0xc,%esp
f01018f9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018fc:	e8 d1 f7 ff ff       	call   f01010d2 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101901:	6a 02                	push   $0x2
f0101903:	6a 00                	push   $0x0
f0101905:	56                   	push   %esi
f0101906:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010190c:	e8 19 fe ff ff       	call   f010172a <page_insert>
f0101911:	83 c4 20             	add    $0x20,%esp
f0101914:	85 c0                	test   %eax,%eax
f0101916:	74 19                	je     f0101931 <check_page+0x1a6>
f0101918:	68 7c 3e 10 f0       	push   $0xf0103e7c
f010191d:	68 0c 43 10 f0       	push   $0xf010430c
f0101922:	68 91 03 00 00       	push   $0x391
f0101927:	68 f2 42 10 f0       	push   $0xf01042f2
f010192c:	e8 5a e7 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101931:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101937:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010193a:	e8 6b f0 ff ff       	call   f01009aa <page2pa>
f010193f:	8b 17                	mov    (%edi),%edx
f0101941:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101947:	39 c2                	cmp    %eax,%edx
f0101949:	74 19                	je     f0101964 <check_page+0x1d9>
f010194b:	68 ac 3e 10 f0       	push   $0xf0103eac
f0101950:	68 0c 43 10 f0       	push   $0xf010430c
f0101955:	68 92 03 00 00       	push   $0x392
f010195a:	68 f2 42 10 f0       	push   $0xf01042f2
f010195f:	e8 27 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101964:	ba 00 00 00 00       	mov    $0x0,%edx
f0101969:	89 f8                	mov    %edi,%eax
f010196b:	e8 7d f1 ff ff       	call   f0100aed <check_va2pa>
f0101970:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101973:	89 f0                	mov    %esi,%eax
f0101975:	e8 30 f0 ff ff       	call   f01009aa <page2pa>
f010197a:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010197d:	74 19                	je     f0101998 <check_page+0x20d>
f010197f:	68 d4 3e 10 f0       	push   $0xf0103ed4
f0101984:	68 0c 43 10 f0       	push   $0xf010430c
f0101989:	68 93 03 00 00       	push   $0x393
f010198e:	68 f2 42 10 f0       	push   $0xf01042f2
f0101993:	e8 f3 e6 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101998:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010199d:	74 19                	je     f01019b8 <check_page+0x22d>
f010199f:	68 e5 44 10 f0       	push   $0xf01044e5
f01019a4:	68 0c 43 10 f0       	push   $0xf010430c
f01019a9:	68 94 03 00 00       	push   $0x394
f01019ae:	68 f2 42 10 f0       	push   $0xf01042f2
f01019b3:	e8 d3 e6 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01019b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019bb:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019c0:	74 19                	je     f01019db <check_page+0x250>
f01019c2:	68 f6 44 10 f0       	push   $0xf01044f6
f01019c7:	68 0c 43 10 f0       	push   $0xf010430c
f01019cc:	68 95 03 00 00       	push   $0x395
f01019d1:	68 f2 42 10 f0       	push   $0xf01042f2
f01019d6:	e8 b0 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated
	// for page table
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W) == 0);
f01019db:	6a 02                	push   $0x2
f01019dd:	68 00 10 00 00       	push   $0x1000
f01019e2:	53                   	push   %ebx
f01019e3:	57                   	push   %edi
f01019e4:	e8 41 fd ff ff       	call   f010172a <page_insert>
f01019e9:	83 c4 10             	add    $0x10,%esp
f01019ec:	85 c0                	test   %eax,%eax
f01019ee:	74 19                	je     f0101a09 <check_page+0x27e>
f01019f0:	68 04 3f 10 f0       	push   $0xf0103f04
f01019f5:	68 0c 43 10 f0       	push   $0xf010430c
f01019fa:	68 99 03 00 00       	push   $0x399
f01019ff:	68 f2 42 10 f0       	push   $0xf01042f2
f0101a04:	e8 82 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a09:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a0e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101a13:	e8 d5 f0 ff ff       	call   f0100aed <check_va2pa>
f0101a18:	89 c7                	mov    %eax,%edi
f0101a1a:	89 d8                	mov    %ebx,%eax
f0101a1c:	e8 89 ef ff ff       	call   f01009aa <page2pa>
f0101a21:	39 c7                	cmp    %eax,%edi
f0101a23:	74 19                	je     f0101a3e <check_page+0x2b3>
f0101a25:	68 40 3f 10 f0       	push   $0xf0103f40
f0101a2a:	68 0c 43 10 f0       	push   $0xf010430c
f0101a2f:	68 9a 03 00 00       	push   $0x39a
f0101a34:	68 f2 42 10 f0       	push   $0xf01042f2
f0101a39:	e8 4d e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a3e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a43:	74 19                	je     f0101a5e <check_page+0x2d3>
f0101a45:	68 07 45 10 f0       	push   $0xf0104507
f0101a4a:	68 0c 43 10 f0       	push   $0xf010430c
f0101a4f:	68 9b 03 00 00       	push   $0x39b
f0101a54:	68 f2 42 10 f0       	push   $0xf01042f2
f0101a59:	e8 2d e6 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a5e:	83 ec 0c             	sub    $0xc,%esp
f0101a61:	6a 00                	push   $0x0
f0101a63:	e8 25 f6 ff ff       	call   f010108d <page_alloc>
f0101a68:	83 c4 10             	add    $0x10,%esp
f0101a6b:	85 c0                	test   %eax,%eax
f0101a6d:	74 19                	je     f0101a88 <check_page+0x2fd>
f0101a6f:	68 47 44 10 f0       	push   $0xf0104447
f0101a74:	68 0c 43 10 f0       	push   $0xf010430c
f0101a79:	68 9e 03 00 00       	push   $0x39e
f0101a7e:	68 f2 42 10 f0       	push   $0xf01042f2
f0101a83:	e8 03 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W) == 0);
f0101a88:	6a 02                	push   $0x2
f0101a8a:	68 00 10 00 00       	push   $0x1000
f0101a8f:	53                   	push   %ebx
f0101a90:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101a96:	e8 8f fc ff ff       	call   f010172a <page_insert>
f0101a9b:	83 c4 10             	add    $0x10,%esp
f0101a9e:	85 c0                	test   %eax,%eax
f0101aa0:	74 19                	je     f0101abb <check_page+0x330>
f0101aa2:	68 04 3f 10 f0       	push   $0xf0103f04
f0101aa7:	68 0c 43 10 f0       	push   $0xf010430c
f0101aac:	68 a1 03 00 00       	push   $0x3a1
f0101ab1:	68 f2 42 10 f0       	push   $0xf01042f2
f0101ab6:	e8 d0 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101abb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac0:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ac5:	e8 23 f0 ff ff       	call   f0100aed <check_va2pa>
f0101aca:	89 c7                	mov    %eax,%edi
f0101acc:	89 d8                	mov    %ebx,%eax
f0101ace:	e8 d7 ee ff ff       	call   f01009aa <page2pa>
f0101ad3:	39 c7                	cmp    %eax,%edi
f0101ad5:	74 19                	je     f0101af0 <check_page+0x365>
f0101ad7:	68 40 3f 10 f0       	push   $0xf0103f40
f0101adc:	68 0c 43 10 f0       	push   $0xf010430c
f0101ae1:	68 a2 03 00 00       	push   $0x3a2
f0101ae6:	68 f2 42 10 f0       	push   $0xf01042f2
f0101aeb:	e8 9b e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101af0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101af5:	74 19                	je     f0101b10 <check_page+0x385>
f0101af7:	68 07 45 10 f0       	push   $0xf0104507
f0101afc:	68 0c 43 10 f0       	push   $0xf010430c
f0101b01:	68 a3 03 00 00       	push   $0x3a3
f0101b06:	68 f2 42 10 f0       	push   $0xf01042f2
f0101b0b:	e8 7b e5 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b10:	83 ec 0c             	sub    $0xc,%esp
f0101b13:	6a 00                	push   $0x0
f0101b15:	e8 73 f5 ff ff       	call   f010108d <page_alloc>
f0101b1a:	83 c4 10             	add    $0x10,%esp
f0101b1d:	85 c0                	test   %eax,%eax
f0101b1f:	74 19                	je     f0101b3a <check_page+0x3af>
f0101b21:	68 47 44 10 f0       	push   $0xf0104447
f0101b26:	68 0c 43 10 f0       	push   $0xf010430c
f0101b2b:	68 a7 03 00 00       	push   $0x3a7
f0101b30:	68 f2 42 10 f0       	push   $0xf01042f2
f0101b35:	e8 51 e5 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b3a:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101b40:	8b 0f                	mov    (%edi),%ecx
f0101b42:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101b48:	ba aa 03 00 00       	mov    $0x3aa,%edx
f0101b4d:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0101b52:	e8 4c ef ff ff       	call   f0100aa3 <_kaddr>
f0101b57:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) == ptep + PTX(PGSIZE));
f0101b5a:	83 ec 04             	sub    $0x4,%esp
f0101b5d:	6a 00                	push   $0x0
f0101b5f:	68 00 10 00 00       	push   $0x1000
f0101b64:	57                   	push   %edi
f0101b65:	e8 ae f9 ff ff       	call   f0101518 <pgdir_walk>
f0101b6a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b6d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b70:	83 c4 10             	add    $0x10,%esp
f0101b73:	39 d0                	cmp    %edx,%eax
f0101b75:	74 19                	je     f0101b90 <check_page+0x405>
f0101b77:	68 70 3f 10 f0       	push   $0xf0103f70
f0101b7c:	68 0c 43 10 f0       	push   $0xf010430c
f0101b81:	68 ab 03 00 00       	push   $0x3ab
f0101b86:	68 f2 42 10 f0       	push   $0xf01042f2
f0101b8b:	e8 fb e4 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W | PTE_U) == 0);
f0101b90:	6a 06                	push   $0x6
f0101b92:	68 00 10 00 00       	push   $0x1000
f0101b97:	53                   	push   %ebx
f0101b98:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b9e:	e8 87 fb ff ff       	call   f010172a <page_insert>
f0101ba3:	83 c4 10             	add    $0x10,%esp
f0101ba6:	85 c0                	test   %eax,%eax
f0101ba8:	74 19                	je     f0101bc3 <check_page+0x438>
f0101baa:	68 b4 3f 10 f0       	push   $0xf0103fb4
f0101baf:	68 0c 43 10 f0       	push   $0xf010430c
f0101bb4:	68 ae 03 00 00       	push   $0x3ae
f0101bb9:	68 f2 42 10 f0       	push   $0xf01042f2
f0101bbe:	e8 c8 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc3:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101bc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bce:	89 f8                	mov    %edi,%eax
f0101bd0:	e8 18 ef ff ff       	call   f0100aed <check_va2pa>
f0101bd5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101bd8:	89 d8                	mov    %ebx,%eax
f0101bda:	e8 cb ed ff ff       	call   f01009aa <page2pa>
f0101bdf:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101be2:	74 19                	je     f0101bfd <check_page+0x472>
f0101be4:	68 40 3f 10 f0       	push   $0xf0103f40
f0101be9:	68 0c 43 10 f0       	push   $0xf010430c
f0101bee:	68 af 03 00 00       	push   $0x3af
f0101bf3:	68 f2 42 10 f0       	push   $0xf01042f2
f0101bf8:	e8 8e e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101bfd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c02:	74 19                	je     f0101c1d <check_page+0x492>
f0101c04:	68 07 45 10 f0       	push   $0xf0104507
f0101c09:	68 0c 43 10 f0       	push   $0xf010430c
f0101c0e:	68 b0 03 00 00       	push   $0x3b0
f0101c13:	68 f2 42 10 f0       	push   $0xf01042f2
f0101c18:	e8 6e e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_U);
f0101c1d:	83 ec 04             	sub    $0x4,%esp
f0101c20:	6a 00                	push   $0x0
f0101c22:	68 00 10 00 00       	push   $0x1000
f0101c27:	57                   	push   %edi
f0101c28:	e8 eb f8 ff ff       	call   f0101518 <pgdir_walk>
f0101c2d:	83 c4 10             	add    $0x10,%esp
f0101c30:	f6 00 04             	testb  $0x4,(%eax)
f0101c33:	75 19                	jne    f0101c4e <check_page+0x4c3>
f0101c35:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0101c3a:	68 0c 43 10 f0       	push   $0xf010430c
f0101c3f:	68 b1 03 00 00       	push   $0x3b1
f0101c44:	68 f2 42 10 f0       	push   $0xf01042f2
f0101c49:	e8 3d e4 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c4e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101c53:	f6 00 04             	testb  $0x4,(%eax)
f0101c56:	75 19                	jne    f0101c71 <check_page+0x4e6>
f0101c58:	68 18 45 10 f0       	push   $0xf0104518
f0101c5d:	68 0c 43 10 f0       	push   $0xf010430c
f0101c62:	68 b2 03 00 00       	push   $0x3b2
f0101c67:	68 f2 42 10 f0       	push   $0xf01042f2
f0101c6c:	e8 1a e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W) == 0);
f0101c71:	6a 02                	push   $0x2
f0101c73:	68 00 10 00 00       	push   $0x1000
f0101c78:	53                   	push   %ebx
f0101c79:	50                   	push   %eax
f0101c7a:	e8 ab fa ff ff       	call   f010172a <page_insert>
f0101c7f:	83 c4 10             	add    $0x10,%esp
f0101c82:	85 c0                	test   %eax,%eax
f0101c84:	74 19                	je     f0101c9f <check_page+0x514>
f0101c86:	68 04 3f 10 f0       	push   $0xf0103f04
f0101c8b:	68 0c 43 10 f0       	push   $0xf010430c
f0101c90:	68 b5 03 00 00       	push   $0x3b5
f0101c95:	68 f2 42 10 f0       	push   $0xf01042f2
f0101c9a:	e8 ec e3 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_W);
f0101c9f:	83 ec 04             	sub    $0x4,%esp
f0101ca2:	6a 00                	push   $0x0
f0101ca4:	68 00 10 00 00       	push   $0x1000
f0101ca9:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101caf:	e8 64 f8 ff ff       	call   f0101518 <pgdir_walk>
f0101cb4:	83 c4 10             	add    $0x10,%esp
f0101cb7:	f6 00 02             	testb  $0x2,(%eax)
f0101cba:	75 19                	jne    f0101cd5 <check_page+0x54a>
f0101cbc:	68 2c 40 10 f0       	push   $0xf010402c
f0101cc1:	68 0c 43 10 f0       	push   $0xf010430c
f0101cc6:	68 b6 03 00 00       	push   $0x3b6
f0101ccb:	68 f2 42 10 f0       	push   $0xf01042f2
f0101cd0:	e8 b6 e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_U));
f0101cd5:	83 ec 04             	sub    $0x4,%esp
f0101cd8:	6a 00                	push   $0x0
f0101cda:	68 00 10 00 00       	push   $0x1000
f0101cdf:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ce5:	e8 2e f8 ff ff       	call   f0101518 <pgdir_walk>
f0101cea:	83 c4 10             	add    $0x10,%esp
f0101ced:	f6 00 04             	testb  $0x4,(%eax)
f0101cf0:	74 19                	je     f0101d0b <check_page+0x580>
f0101cf2:	68 60 40 10 f0       	push   $0xf0104060
f0101cf7:	68 0c 43 10 f0       	push   $0xf010430c
f0101cfc:	68 b7 03 00 00       	push   $0x3b7
f0101d01:	68 f2 42 10 f0       	push   $0xf01042f2
f0101d06:	e8 80 e3 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page
	// table
	assert(page_insert(kern_pgdir, pp0, (void *) PTSIZE, PTE_W) < 0);
f0101d0b:	6a 02                	push   $0x2
f0101d0d:	68 00 00 40 00       	push   $0x400000
f0101d12:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d15:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d1b:	e8 0a fa ff ff       	call   f010172a <page_insert>
f0101d20:	83 c4 10             	add    $0x10,%esp
f0101d23:	85 c0                	test   %eax,%eax
f0101d25:	78 19                	js     f0101d40 <check_page+0x5b5>
f0101d27:	68 98 40 10 f0       	push   $0xf0104098
f0101d2c:	68 0c 43 10 f0       	push   $0xf010430c
f0101d31:	68 bb 03 00 00       	push   $0x3bb
f0101d36:	68 f2 42 10 f0       	push   $0xf01042f2
f0101d3b:	e8 4b e3 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void *) PGSIZE, PTE_W) == 0);
f0101d40:	6a 02                	push   $0x2
f0101d42:	68 00 10 00 00       	push   $0x1000
f0101d47:	56                   	push   %esi
f0101d48:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d4e:	e8 d7 f9 ff ff       	call   f010172a <page_insert>
f0101d53:	83 c4 10             	add    $0x10,%esp
f0101d56:	85 c0                	test   %eax,%eax
f0101d58:	74 19                	je     f0101d73 <check_page+0x5e8>
f0101d5a:	68 d4 40 10 f0       	push   $0xf01040d4
f0101d5f:	68 0c 43 10 f0       	push   $0xf010430c
f0101d64:	68 be 03 00 00       	push   $0x3be
f0101d69:	68 f2 42 10 f0       	push   $0xf01042f2
f0101d6e:	e8 18 e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void *) PGSIZE, 0) & PTE_U));
f0101d73:	83 ec 04             	sub    $0x4,%esp
f0101d76:	6a 00                	push   $0x0
f0101d78:	68 00 10 00 00       	push   $0x1000
f0101d7d:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d83:	e8 90 f7 ff ff       	call   f0101518 <pgdir_walk>
f0101d88:	83 c4 10             	add    $0x10,%esp
f0101d8b:	f6 00 04             	testb  $0x4,(%eax)
f0101d8e:	74 19                	je     f0101da9 <check_page+0x61e>
f0101d90:	68 60 40 10 f0       	push   $0xf0104060
f0101d95:	68 0c 43 10 f0       	push   $0xf010430c
f0101d9a:	68 bf 03 00 00       	push   $0x3bf
f0101d9f:	68 f2 42 10 f0       	push   $0xf01042f2
f0101da4:	e8 e2 e2 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101da9:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101daf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101db4:	89 f8                	mov    %edi,%eax
f0101db6:	e8 32 ed ff ff       	call   f0100aed <check_va2pa>
f0101dbb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101dbe:	89 f0                	mov    %esi,%eax
f0101dc0:	e8 e5 eb ff ff       	call   f01009aa <page2pa>
f0101dc5:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101dc8:	74 19                	je     f0101de3 <check_page+0x658>
f0101dca:	68 10 41 10 f0       	push   $0xf0104110
f0101dcf:	68 0c 43 10 f0       	push   $0xf010430c
f0101dd4:	68 c2 03 00 00       	push   $0x3c2
f0101dd9:	68 f2 42 10 f0       	push   $0xf01042f2
f0101dde:	e8 a8 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101de3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101de8:	89 f8                	mov    %edi,%eax
f0101dea:	e8 fe ec ff ff       	call   f0100aed <check_va2pa>
f0101def:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101df2:	74 19                	je     f0101e0d <check_page+0x682>
f0101df4:	68 3c 41 10 f0       	push   $0xf010413c
f0101df9:	68 0c 43 10 f0       	push   $0xf010430c
f0101dfe:	68 c3 03 00 00       	push   $0x3c3
f0101e03:	68 f2 42 10 f0       	push   $0xf01042f2
f0101e08:	e8 7e e2 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e0d:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101e12:	74 19                	je     f0101e2d <check_page+0x6a2>
f0101e14:	68 2e 45 10 f0       	push   $0xf010452e
f0101e19:	68 0c 43 10 f0       	push   $0xf010430c
f0101e1e:	68 c5 03 00 00       	push   $0x3c5
f0101e23:	68 f2 42 10 f0       	push   $0xf01042f2
f0101e28:	e8 5e e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e2d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e32:	74 19                	je     f0101e4d <check_page+0x6c2>
f0101e34:	68 3f 45 10 f0       	push   $0xf010453f
f0101e39:	68 0c 43 10 f0       	push   $0xf010430c
f0101e3e:	68 c6 03 00 00       	push   $0x3c6
f0101e43:	68 f2 42 10 f0       	push   $0xf01042f2
f0101e48:	e8 3e e2 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e4d:	83 ec 0c             	sub    $0xc,%esp
f0101e50:	6a 00                	push   $0x0
f0101e52:	e8 36 f2 ff ff       	call   f010108d <page_alloc>
f0101e57:	83 c4 10             	add    $0x10,%esp
f0101e5a:	39 c3                	cmp    %eax,%ebx
f0101e5c:	75 04                	jne    f0101e62 <check_page+0x6d7>
f0101e5e:	85 c0                	test   %eax,%eax
f0101e60:	75 19                	jne    f0101e7b <check_page+0x6f0>
f0101e62:	68 6c 41 10 f0       	push   $0xf010416c
f0101e67:	68 0c 43 10 f0       	push   $0xf010430c
f0101e6c:	68 c9 03 00 00       	push   $0x3c9
f0101e71:	68 f2 42 10 f0       	push   $0xf01042f2
f0101e76:	e8 10 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e7b:	83 ec 08             	sub    $0x8,%esp
f0101e7e:	6a 00                	push   $0x0
f0101e80:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e86:	e8 61 f8 ff ff       	call   f01016ec <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e8b:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101e91:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e96:	89 f8                	mov    %edi,%eax
f0101e98:	e8 50 ec ff ff       	call   f0100aed <check_va2pa>
f0101e9d:	83 c4 10             	add    $0x10,%esp
f0101ea0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea3:	74 19                	je     f0101ebe <check_page+0x733>
f0101ea5:	68 90 41 10 f0       	push   $0xf0104190
f0101eaa:	68 0c 43 10 f0       	push   $0xf010430c
f0101eaf:	68 cd 03 00 00       	push   $0x3cd
f0101eb4:	68 f2 42 10 f0       	push   $0xf01042f2
f0101eb9:	e8 cd e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ebe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec3:	89 f8                	mov    %edi,%eax
f0101ec5:	e8 23 ec ff ff       	call   f0100aed <check_va2pa>
f0101eca:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ecd:	89 f0                	mov    %esi,%eax
f0101ecf:	e8 d6 ea ff ff       	call   f01009aa <page2pa>
f0101ed4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101ed7:	74 19                	je     f0101ef2 <check_page+0x767>
f0101ed9:	68 3c 41 10 f0       	push   $0xf010413c
f0101ede:	68 0c 43 10 f0       	push   $0xf010430c
f0101ee3:	68 ce 03 00 00       	push   $0x3ce
f0101ee8:	68 f2 42 10 f0       	push   $0xf01042f2
f0101eed:	e8 99 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101ef2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ef7:	74 19                	je     f0101f12 <check_page+0x787>
f0101ef9:	68 e5 44 10 f0       	push   $0xf01044e5
f0101efe:	68 0c 43 10 f0       	push   $0xf010430c
f0101f03:	68 cf 03 00 00       	push   $0x3cf
f0101f08:	68 f2 42 10 f0       	push   $0xf01042f2
f0101f0d:	e8 79 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101f12:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f17:	74 19                	je     f0101f32 <check_page+0x7a7>
f0101f19:	68 3f 45 10 f0       	push   $0xf010453f
f0101f1e:	68 0c 43 10 f0       	push   $0xf010430c
f0101f23:	68 d0 03 00 00       	push   $0x3d0
f0101f28:	68 f2 42 10 f0       	push   $0xf01042f2
f0101f2d:	e8 59 e1 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void *) PGSIZE, 0) == 0);
f0101f32:	6a 00                	push   $0x0
f0101f34:	68 00 10 00 00       	push   $0x1000
f0101f39:	56                   	push   %esi
f0101f3a:	57                   	push   %edi
f0101f3b:	e8 ea f7 ff ff       	call   f010172a <page_insert>
f0101f40:	83 c4 10             	add    $0x10,%esp
f0101f43:	85 c0                	test   %eax,%eax
f0101f45:	74 19                	je     f0101f60 <check_page+0x7d5>
f0101f47:	68 b4 41 10 f0       	push   $0xf01041b4
f0101f4c:	68 0c 43 10 f0       	push   $0xf010430c
f0101f51:	68 d3 03 00 00       	push   $0x3d3
f0101f56:	68 f2 42 10 f0       	push   $0xf01042f2
f0101f5b:	e8 2b e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101f60:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f65:	75 19                	jne    f0101f80 <check_page+0x7f5>
f0101f67:	68 50 45 10 f0       	push   $0xf0104550
f0101f6c:	68 0c 43 10 f0       	push   $0xf010430c
f0101f71:	68 d4 03 00 00       	push   $0x3d4
f0101f76:	68 f2 42 10 f0       	push   $0xf01042f2
f0101f7b:	e8 0b e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101f80:	83 3e 00             	cmpl   $0x0,(%esi)
f0101f83:	74 19                	je     f0101f9e <check_page+0x813>
f0101f85:	68 5c 45 10 f0       	push   $0xf010455c
f0101f8a:	68 0c 43 10 f0       	push   $0xf010430c
f0101f8f:	68 d5 03 00 00       	push   $0x3d5
f0101f94:	68 f2 42 10 f0       	push   $0xf01042f2
f0101f99:	e8 ed e0 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void *) PGSIZE);
f0101f9e:	83 ec 08             	sub    $0x8,%esp
f0101fa1:	68 00 10 00 00       	push   $0x1000
f0101fa6:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101fac:	e8 3b f7 ff ff       	call   f01016ec <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fb1:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101fb7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fbc:	89 f8                	mov    %edi,%eax
f0101fbe:	e8 2a eb ff ff       	call   f0100aed <check_va2pa>
f0101fc3:	83 c4 10             	add    $0x10,%esp
f0101fc6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fc9:	74 19                	je     f0101fe4 <check_page+0x859>
f0101fcb:	68 90 41 10 f0       	push   $0xf0104190
f0101fd0:	68 0c 43 10 f0       	push   $0xf010430c
f0101fd5:	68 d9 03 00 00       	push   $0x3d9
f0101fda:	68 f2 42 10 f0       	push   $0xf01042f2
f0101fdf:	e8 a7 e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fe4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fe9:	89 f8                	mov    %edi,%eax
f0101feb:	e8 fd ea ff ff       	call   f0100aed <check_va2pa>
f0101ff0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ff3:	74 19                	je     f010200e <check_page+0x883>
f0101ff5:	68 ec 41 10 f0       	push   $0xf01041ec
f0101ffa:	68 0c 43 10 f0       	push   $0xf010430c
f0101fff:	68 da 03 00 00       	push   $0x3da
f0102004:	68 f2 42 10 f0       	push   $0xf01042f2
f0102009:	e8 7d e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010200e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102013:	74 19                	je     f010202e <check_page+0x8a3>
f0102015:	68 71 45 10 f0       	push   $0xf0104571
f010201a:	68 0c 43 10 f0       	push   $0xf010430c
f010201f:	68 db 03 00 00       	push   $0x3db
f0102024:	68 f2 42 10 f0       	push   $0xf01042f2
f0102029:	e8 5d e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f010202e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102033:	74 19                	je     f010204e <check_page+0x8c3>
f0102035:	68 3f 45 10 f0       	push   $0xf010453f
f010203a:	68 0c 43 10 f0       	push   $0xf010430c
f010203f:	68 dc 03 00 00       	push   $0x3dc
f0102044:	68 f2 42 10 f0       	push   $0xf01042f2
f0102049:	e8 3d e0 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010204e:	83 ec 0c             	sub    $0xc,%esp
f0102051:	6a 00                	push   $0x0
f0102053:	e8 35 f0 ff ff       	call   f010108d <page_alloc>
f0102058:	83 c4 10             	add    $0x10,%esp
f010205b:	39 c6                	cmp    %eax,%esi
f010205d:	75 04                	jne    f0102063 <check_page+0x8d8>
f010205f:	85 c0                	test   %eax,%eax
f0102061:	75 19                	jne    f010207c <check_page+0x8f1>
f0102063:	68 14 42 10 f0       	push   $0xf0104214
f0102068:	68 0c 43 10 f0       	push   $0xf010430c
f010206d:	68 df 03 00 00       	push   $0x3df
f0102072:	68 f2 42 10 f0       	push   $0xf01042f2
f0102077:	e8 0f e0 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010207c:	83 ec 0c             	sub    $0xc,%esp
f010207f:	6a 00                	push   $0x0
f0102081:	e8 07 f0 ff ff       	call   f010108d <page_alloc>
f0102086:	83 c4 10             	add    $0x10,%esp
f0102089:	85 c0                	test   %eax,%eax
f010208b:	74 19                	je     f01020a6 <check_page+0x91b>
f010208d:	68 47 44 10 f0       	push   $0xf0104447
f0102092:	68 0c 43 10 f0       	push   $0xf010430c
f0102097:	68 e2 03 00 00       	push   $0x3e2
f010209c:	68 f2 42 10 f0       	push   $0xf01042f2
f01020a1:	e8 e5 df ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01020a6:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f01020ac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020af:	e8 f6 e8 ff ff       	call   f01009aa <page2pa>
f01020b4:	8b 17                	mov    (%edi),%edx
f01020b6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01020bc:	39 c2                	cmp    %eax,%edx
f01020be:	74 19                	je     f01020d9 <check_page+0x94e>
f01020c0:	68 ac 3e 10 f0       	push   $0xf0103eac
f01020c5:	68 0c 43 10 f0       	push   $0xf010430c
f01020ca:	68 e5 03 00 00       	push   $0x3e5
f01020cf:	68 f2 42 10 f0       	push   $0xf01042f2
f01020d4:	e8 b2 df ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01020d9:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01020df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020e7:	74 19                	je     f0102102 <check_page+0x977>
f01020e9:	68 f6 44 10 f0       	push   $0xf01044f6
f01020ee:	68 0c 43 10 f0       	push   $0xf010430c
f01020f3:	68 e7 03 00 00       	push   $0x3e7
f01020f8:	68 f2 42 10 f0       	push   $0xf01042f2
f01020fd:	e8 89 df ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102102:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102105:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010210b:	83 ec 0c             	sub    $0xc,%esp
f010210e:	50                   	push   %eax
f010210f:	e8 be ef ff ff       	call   f01010d2 <page_free>
	va = (void *) (PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102114:	83 c4 0c             	add    $0xc,%esp
f0102117:	6a 01                	push   $0x1
f0102119:	68 00 10 40 00       	push   $0x401000
f010211e:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102124:	e8 ef f3 ff ff       	call   f0101518 <pgdir_walk>
f0102129:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010212c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010212f:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102135:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102138:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010213e:	ba ee 03 00 00       	mov    $0x3ee,%edx
f0102143:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0102148:	e8 56 e9 ff ff       	call   f0100aa3 <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f010214d:	83 c0 04             	add    $0x4,%eax
f0102150:	83 c4 10             	add    $0x10,%esp
f0102153:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102156:	74 19                	je     f0102171 <check_page+0x9e6>
f0102158:	68 82 45 10 f0       	push   $0xf0104582
f010215d:	68 0c 43 10 f0       	push   $0xf010430c
f0102162:	68 ef 03 00 00       	push   $0x3ef
f0102167:	68 f2 42 10 f0       	push   $0xf01042f2
f010216c:	e8 1a df ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102171:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102178:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010217b:	89 f8                	mov    %edi,%eax
f010217d:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102183:	e8 47 e9 ff ff       	call   f0100acf <page2kva>
f0102188:	83 ec 04             	sub    $0x4,%esp
f010218b:	68 00 10 00 00       	push   $0x1000
f0102190:	68 ff 00 00 00       	push   $0xff
f0102195:	50                   	push   %eax
f0102196:	e8 b9 0f 00 00       	call   f0103154 <memset>
	page_free(pp0);
f010219b:	89 3c 24             	mov    %edi,(%esp)
f010219e:	e8 2f ef ff ff       	call   f01010d2 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021a3:	83 c4 0c             	add    $0xc,%esp
f01021a6:	6a 01                	push   $0x1
f01021a8:	6a 00                	push   $0x0
f01021aa:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01021b0:	e8 63 f3 ff ff       	call   f0101518 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f01021b5:	89 f8                	mov    %edi,%eax
f01021b7:	e8 13 e9 ff ff       	call   f0100acf <page2kva>
f01021bc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021bf:	89 c2                	mov    %eax,%edx
f01021c1:	05 00 10 00 00       	add    $0x1000,%eax
f01021c6:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021c9:	f6 02 01             	testb  $0x1,(%edx)
f01021cc:	74 19                	je     f01021e7 <check_page+0xa5c>
f01021ce:	68 9a 45 10 f0       	push   $0xf010459a
f01021d3:	68 0c 43 10 f0       	push   $0xf010430c
f01021d8:	68 f9 03 00 00       	push   $0x3f9
f01021dd:	68 f2 42 10 f0       	push   $0xf01042f2
f01021e2:	e8 a4 de ff ff       	call   f010008b <_panic>
f01021e7:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for (i = 0; i < NPTENTRIES; i++)
f01021ea:	39 c2                	cmp    %eax,%edx
f01021ec:	75 db                	jne    f01021c9 <check_page+0xa3e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01021ee:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021fc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102202:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102205:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010220b:	83 ec 0c             	sub    $0xc,%esp
f010220e:	50                   	push   %eax
f010220f:	e8 be ee ff ff       	call   f01010d2 <page_free>
	page_free(pp1);
f0102214:	89 34 24             	mov    %esi,(%esp)
f0102217:	e8 b6 ee ff ff       	call   f01010d2 <page_free>
	page_free(pp2);
f010221c:	89 1c 24             	mov    %ebx,(%esp)
f010221f:	e8 ae ee ff ff       	call   f01010d2 <page_free>

	cprintf("check_page() succeeded!\n");
f0102224:	c7 04 24 b1 45 10 f0 	movl   $0xf01045b1,(%esp)
f010222b:	e8 7d 04 00 00       	call   f01026ad <cprintf>
}
f0102230:	83 c4 10             	add    $0x10,%esp
f0102233:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102236:	5b                   	pop    %ebx
f0102237:	5e                   	pop    %esi
f0102238:	5f                   	pop    %edi
f0102239:	5d                   	pop    %ebp
f010223a:	c3                   	ret    

f010223b <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f010223b:	55                   	push   %ebp
f010223c:	89 e5                	mov    %esp,%ebp
f010223e:	57                   	push   %edi
f010223f:	56                   	push   %esi
f0102240:	53                   	push   %ebx
f0102241:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102244:	6a 00                	push   $0x0
f0102246:	e8 42 ee ff ff       	call   f010108d <page_alloc>
f010224b:	83 c4 10             	add    $0x10,%esp
f010224e:	85 c0                	test   %eax,%eax
f0102250:	75 19                	jne    f010226b <check_page_installed_pgdir+0x30>
f0102252:	68 f3 43 10 f0       	push   $0xf01043f3
f0102257:	68 0c 43 10 f0       	push   $0xf010430c
f010225c:	68 14 04 00 00       	push   $0x414
f0102261:	68 f2 42 10 f0       	push   $0xf01042f2
f0102266:	e8 20 de ff ff       	call   f010008b <_panic>
f010226b:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f010226d:	83 ec 0c             	sub    $0xc,%esp
f0102270:	6a 00                	push   $0x0
f0102272:	e8 16 ee ff ff       	call   f010108d <page_alloc>
f0102277:	89 c7                	mov    %eax,%edi
f0102279:	83 c4 10             	add    $0x10,%esp
f010227c:	85 c0                	test   %eax,%eax
f010227e:	75 19                	jne    f0102299 <check_page_installed_pgdir+0x5e>
f0102280:	68 09 44 10 f0       	push   $0xf0104409
f0102285:	68 0c 43 10 f0       	push   $0xf010430c
f010228a:	68 15 04 00 00       	push   $0x415
f010228f:	68 f2 42 10 f0       	push   $0xf01042f2
f0102294:	e8 f2 dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102299:	83 ec 0c             	sub    $0xc,%esp
f010229c:	6a 00                	push   $0x0
f010229e:	e8 ea ed ff ff       	call   f010108d <page_alloc>
f01022a3:	89 c3                	mov    %eax,%ebx
f01022a5:	83 c4 10             	add    $0x10,%esp
f01022a8:	85 c0                	test   %eax,%eax
f01022aa:	75 19                	jne    f01022c5 <check_page_installed_pgdir+0x8a>
f01022ac:	68 1f 44 10 f0       	push   $0xf010441f
f01022b1:	68 0c 43 10 f0       	push   $0xf010430c
f01022b6:	68 16 04 00 00       	push   $0x416
f01022bb:	68 f2 42 10 f0       	push   $0xf01042f2
f01022c0:	e8 c6 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01022c5:	83 ec 0c             	sub    $0xc,%esp
f01022c8:	56                   	push   %esi
f01022c9:	e8 04 ee ff ff       	call   f01010d2 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01022ce:	89 f8                	mov    %edi,%eax
f01022d0:	e8 fa e7 ff ff       	call   f0100acf <page2kva>
f01022d5:	83 c4 0c             	add    $0xc,%esp
f01022d8:	68 00 10 00 00       	push   $0x1000
f01022dd:	6a 01                	push   $0x1
f01022df:	50                   	push   %eax
f01022e0:	e8 6f 0e 00 00       	call   f0103154 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01022e5:	89 d8                	mov    %ebx,%eax
f01022e7:	e8 e3 e7 ff ff       	call   f0100acf <page2kva>
f01022ec:	83 c4 0c             	add    $0xc,%esp
f01022ef:	68 00 10 00 00       	push   $0x1000
f01022f4:	6a 02                	push   $0x2
f01022f6:	50                   	push   %eax
f01022f7:	e8 58 0e 00 00       	call   f0103154 <memset>
	page_insert(kern_pgdir, pp1, (void *) PGSIZE, PTE_W);
f01022fc:	6a 02                	push   $0x2
f01022fe:	68 00 10 00 00       	push   $0x1000
f0102303:	57                   	push   %edi
f0102304:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010230a:	e8 1b f4 ff ff       	call   f010172a <page_insert>
	assert(pp1->pp_ref == 1);
f010230f:	83 c4 20             	add    $0x20,%esp
f0102312:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102317:	74 19                	je     f0102332 <check_page_installed_pgdir+0xf7>
f0102319:	68 e5 44 10 f0       	push   $0xf01044e5
f010231e:	68 0c 43 10 f0       	push   $0xf010430c
f0102323:	68 1b 04 00 00       	push   $0x41b
f0102328:	68 f2 42 10 f0       	push   $0xf01042f2
f010232d:	e8 59 dd ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *) PGSIZE == 0x01010101U);
f0102332:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102339:	01 01 01 
f010233c:	74 19                	je     f0102357 <check_page_installed_pgdir+0x11c>
f010233e:	68 38 42 10 f0       	push   $0xf0104238
f0102343:	68 0c 43 10 f0       	push   $0xf010430c
f0102348:	68 1c 04 00 00       	push   $0x41c
f010234d:	68 f2 42 10 f0       	push   $0xf01042f2
f0102352:	e8 34 dd ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void *) PGSIZE, PTE_W);
f0102357:	6a 02                	push   $0x2
f0102359:	68 00 10 00 00       	push   $0x1000
f010235e:	53                   	push   %ebx
f010235f:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102365:	e8 c0 f3 ff ff       	call   f010172a <page_insert>
	assert(*(uint32_t *) PGSIZE == 0x02020202U);
f010236a:	83 c4 10             	add    $0x10,%esp
f010236d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102374:	02 02 02 
f0102377:	74 19                	je     f0102392 <check_page_installed_pgdir+0x157>
f0102379:	68 5c 42 10 f0       	push   $0xf010425c
f010237e:	68 0c 43 10 f0       	push   $0xf010430c
f0102383:	68 1e 04 00 00       	push   $0x41e
f0102388:	68 f2 42 10 f0       	push   $0xf01042f2
f010238d:	e8 f9 dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0102392:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102397:	74 19                	je     f01023b2 <check_page_installed_pgdir+0x177>
f0102399:	68 07 45 10 f0       	push   $0xf0104507
f010239e:	68 0c 43 10 f0       	push   $0xf010430c
f01023a3:	68 1f 04 00 00       	push   $0x41f
f01023a8:	68 f2 42 10 f0       	push   $0xf01042f2
f01023ad:	e8 d9 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01023b2:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01023b7:	74 19                	je     f01023d2 <check_page_installed_pgdir+0x197>
f01023b9:	68 71 45 10 f0       	push   $0xf0104571
f01023be:	68 0c 43 10 f0       	push   $0xf010430c
f01023c3:	68 20 04 00 00       	push   $0x420
f01023c8:	68 f2 42 10 f0       	push   $0xf01042f2
f01023cd:	e8 b9 dc ff ff       	call   f010008b <_panic>
	*(uint32_t *) PGSIZE = 0x03030303U;
f01023d2:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01023d9:	03 03 03 
	assert(*(uint32_t *) page2kva(pp2) == 0x03030303U);
f01023dc:	89 d8                	mov    %ebx,%eax
f01023de:	e8 ec e6 ff ff       	call   f0100acf <page2kva>
f01023e3:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01023e9:	74 19                	je     f0102404 <check_page_installed_pgdir+0x1c9>
f01023eb:	68 80 42 10 f0       	push   $0xf0104280
f01023f0:	68 0c 43 10 f0       	push   $0xf010430c
f01023f5:	68 22 04 00 00       	push   $0x422
f01023fa:	68 f2 42 10 f0       	push   $0xf01042f2
f01023ff:	e8 87 dc ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void *) PGSIZE);
f0102404:	83 ec 08             	sub    $0x8,%esp
f0102407:	68 00 10 00 00       	push   $0x1000
f010240c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102412:	e8 d5 f2 ff ff       	call   f01016ec <page_remove>
	assert(pp2->pp_ref == 0);
f0102417:	83 c4 10             	add    $0x10,%esp
f010241a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010241f:	74 19                	je     f010243a <check_page_installed_pgdir+0x1ff>
f0102421:	68 3f 45 10 f0       	push   $0xf010453f
f0102426:	68 0c 43 10 f0       	push   $0xf010430c
f010242b:	68 24 04 00 00       	push   $0x424
f0102430:	68 f2 42 10 f0       	push   $0xf01042f2
f0102435:	e8 51 dc ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010243a:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f0102440:	89 f0                	mov    %esi,%eax
f0102442:	e8 63 e5 ff ff       	call   f01009aa <page2pa>
f0102447:	8b 13                	mov    (%ebx),%edx
f0102449:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010244f:	39 c2                	cmp    %eax,%edx
f0102451:	74 19                	je     f010246c <check_page_installed_pgdir+0x231>
f0102453:	68 ac 3e 10 f0       	push   $0xf0103eac
f0102458:	68 0c 43 10 f0       	push   $0xf010430c
f010245d:	68 27 04 00 00       	push   $0x427
f0102462:	68 f2 42 10 f0       	push   $0xf01042f2
f0102467:	e8 1f dc ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010246c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102472:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102477:	74 19                	je     f0102492 <check_page_installed_pgdir+0x257>
f0102479:	68 f6 44 10 f0       	push   $0xf01044f6
f010247e:	68 0c 43 10 f0       	push   $0xf010430c
f0102483:	68 29 04 00 00       	push   $0x429
f0102488:	68 f2 42 10 f0       	push   $0xf01042f2
f010248d:	e8 f9 db ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102492:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102498:	83 ec 0c             	sub    $0xc,%esp
f010249b:	56                   	push   %esi
f010249c:	e8 31 ec ff ff       	call   f01010d2 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01024a1:	c7 04 24 ac 42 10 f0 	movl   $0xf01042ac,(%esp)
f01024a8:	e8 00 02 00 00       	call   f01026ad <cprintf>
}
f01024ad:	83 c4 10             	add    $0x10,%esp
f01024b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01024b3:	5b                   	pop    %ebx
f01024b4:	5e                   	pop    %esi
f01024b5:	5f                   	pop    %edi
f01024b6:	5d                   	pop    %ebp
f01024b7:	c3                   	ret    

f01024b8 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01024b8:	55                   	push   %ebp
f01024b9:	89 e5                	mov    %esp,%ebp
f01024bb:	53                   	push   %ebx
f01024bc:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f01024bf:	e8 20 e5 ff ff       	call   f01009e4 <i386_detect_memory>

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01024c4:	b8 00 10 00 00       	mov    $0x1000,%eax
f01024c9:	e8 7c e5 ff ff       	call   f0100a4a <boot_alloc>
f01024ce:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f01024d3:	83 ec 04             	sub    $0x4,%esp
f01024d6:	68 00 10 00 00       	push   $0x1000
f01024db:	6a 00                	push   $0x0
f01024dd:	50                   	push   %eax
f01024de:	e8 71 0c 00 00       	call   f0103154 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01024e3:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f01024e9:	89 d9                	mov    %ebx,%ecx
f01024eb:	ba 9b 00 00 00       	mov    $0x9b,%edx
f01024f0:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f01024f5:	e8 63 e6 ff ff       	call   f0100b5d <_paddr>
f01024fa:	83 c8 05             	or     $0x5,%eax
f01024fd:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// array.  'npages' is the number of physical pages in memory.  Use
	// memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0102503:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0102508:	c1 e0 03             	shl    $0x3,%eax
f010250b:	e8 3a e5 ff ff       	call   f0100a4a <boot_alloc>
f0102510:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0102515:	83 c4 0c             	add    $0xc,%esp
f0102518:	8b 1d 44 79 11 f0    	mov    0xf0117944,%ebx
f010251e:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102525:	52                   	push   %edx
f0102526:	6a 00                	push   $0x0
f0102528:	50                   	push   %eax
f0102529:	e8 26 0c 00 00       	call   f0103154 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010252e:	e8 f8 ea ff ff       	call   f010102b <page_init>

	check_page_free_list(1);
f0102533:	b8 01 00 00 00       	mov    $0x1,%eax
f0102538:	e8 4a e8 ff ff       	call   f0100d87 <check_page_free_list>
	check_page_alloc();
f010253d:	e8 e2 eb ff ff       	call   f0101124 <check_page_alloc>

	// Remove this line when you're ready to test this function.
	// panic("mem_init: This function is not finished\n");

	check_page();
f0102542:	e8 44 f2 ff ff       	call   f010178b <check_page>
	// Mapeo en kern_pgdir, UVPT - UPAGES direcciones virtuales a partir de UPAGES
	// a direcciones físicas a partir de donde comienza el struct page info pages.

	//page_insert    (pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
	//boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102547:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f010254d:	ba cb 00 00 00       	mov    $0xcb,%edx
f0102552:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0102557:	e8 01 e6 ff ff       	call   f0100b5d <_paddr>
f010255c:	8b 15 44 79 11 f0    	mov    0xf0117944,%edx
f0102562:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102569:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010256f:	83 c4 08             	add    $0x8,%esp
f0102572:	6a 05                	push   $0x5
f0102574:	50                   	push   %eax
f0102575:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010257a:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010257f:	e8 32 f0 ff ff       	call   f01015b6 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102584:	b9 00 d0 10 f0       	mov    $0xf010d000,%ecx
f0102589:	ba d8 00 00 00       	mov    $0xd8,%edx
f010258e:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f0102593:	e8 c5 e5 ff ff       	call   f0100b5d <_paddr>
f0102598:	83 c4 08             	add    $0x8,%esp
f010259b:	6a 03                	push   $0x3
f010259d:	50                   	push   %eax
f010259e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025a3:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01025a8:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01025ad:	e8 04 f0 ff ff       	call   f01015b6 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE + 1, 0, PTE_W | PTE_P);
f01025b2:	83 c4 08             	add    $0x8,%esp
f01025b5:	6a 03                	push   $0x3
f01025b7:	6a 00                	push   $0x0
f01025b9:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01025be:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01025c3:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01025c8:	e8 e9 ef ff ff       	call   f01015b6 <boot_map_region>

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f01025cd:	e8 ad e5 ff ff       	call   f0100b7f <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01025d2:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f01025d8:	ba ee 00 00 00       	mov    $0xee,%edx
f01025dd:	b8 f2 42 10 f0       	mov    $0xf01042f2,%eax
f01025e2:	e8 76 e5 ff ff       	call   f0100b5d <_paddr>
f01025e7:	e8 b6 e3 ff ff       	call   f01009a2 <lcr3>

	check_page_free_list(0);
f01025ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01025f1:	e8 91 e7 ff ff       	call   f0100d87 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f01025f6:	e8 9f e3 ff ff       	call   f010099a <rcr0>
f01025fb:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_MP;
	cr0 &= ~(CR0_TS | CR0_EM);
	lcr0(cr0);
f01025fe:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102603:	e8 8a e3 ff ff       	call   f0100992 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102608:	e8 2e fc ff ff       	call   f010223b <check_page_installed_pgdir>
}
f010260d:	83 c4 10             	add    $0x10,%esp
f0102610:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102613:	c9                   	leave  
f0102614:	c3                   	ret    

f0102615 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0102615:	55                   	push   %ebp
f0102616:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102618:	89 c2                	mov    %eax,%edx
f010261a:	ec                   	in     (%dx),%al
	return data;
}
f010261b:	5d                   	pop    %ebp
f010261c:	c3                   	ret    

f010261d <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f010261d:	55                   	push   %ebp
f010261e:	89 e5                	mov    %esp,%ebp
f0102620:	89 c1                	mov    %eax,%ecx
f0102622:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102624:	89 ca                	mov    %ecx,%edx
f0102626:	ee                   	out    %al,(%dx)
}
f0102627:	5d                   	pop    %ebp
f0102628:	c3                   	ret    

f0102629 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102629:	55                   	push   %ebp
f010262a:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010262c:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102630:	b8 70 00 00 00       	mov    $0x70,%eax
f0102635:	e8 e3 ff ff ff       	call   f010261d <outb>
	return inb(IO_RTC+1);
f010263a:	b8 71 00 00 00       	mov    $0x71,%eax
f010263f:	e8 d1 ff ff ff       	call   f0102615 <inb>
f0102644:	0f b6 c0             	movzbl %al,%eax
}
f0102647:	5d                   	pop    %ebp
f0102648:	c3                   	ret    

f0102649 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102649:	55                   	push   %ebp
f010264a:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010264c:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102650:	b8 70 00 00 00       	mov    $0x70,%eax
f0102655:	e8 c3 ff ff ff       	call   f010261d <outb>
	outb(IO_RTC+1, datum);
f010265a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f010265e:	b8 71 00 00 00       	mov    $0x71,%eax
f0102663:	e8 b5 ff ff ff       	call   f010261d <outb>
}
f0102668:	5d                   	pop    %ebp
f0102669:	c3                   	ret    

f010266a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010266a:	55                   	push   %ebp
f010266b:	89 e5                	mov    %esp,%ebp
f010266d:	53                   	push   %ebx
f010266e:	83 ec 10             	sub    $0x10,%esp
f0102671:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	cputchar(ch);
f0102674:	ff 75 08             	pushl  0x8(%ebp)
f0102677:	e8 89 e0 ff ff       	call   f0100705 <cputchar>
	(*cnt)++;
f010267c:	83 03 01             	addl   $0x1,(%ebx)
}
f010267f:	83 c4 10             	add    $0x10,%esp
f0102682:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102685:	c9                   	leave  
f0102686:	c3                   	ret    

f0102687 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102687:	55                   	push   %ebp
f0102688:	89 e5                	mov    %esp,%ebp
f010268a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010268d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102694:	ff 75 0c             	pushl  0xc(%ebp)
f0102697:	ff 75 08             	pushl  0x8(%ebp)
f010269a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010269d:	50                   	push   %eax
f010269e:	68 6a 26 10 f0       	push   $0xf010266a
f01026a3:	e8 85 04 00 00       	call   f0102b2d <vprintfmt>
	return cnt;
}
f01026a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026ab:	c9                   	leave  
f01026ac:	c3                   	ret    

f01026ad <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01026ad:	55                   	push   %ebp
f01026ae:	89 e5                	mov    %esp,%ebp
f01026b0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01026b3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01026b6:	50                   	push   %eax
f01026b7:	ff 75 08             	pushl  0x8(%ebp)
f01026ba:	e8 c8 ff ff ff       	call   f0102687 <vcprintf>
	va_end(ap);

	return cnt;
}
f01026bf:	c9                   	leave  
f01026c0:	c3                   	ret    

f01026c1 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f01026c1:	55                   	push   %ebp
f01026c2:	89 e5                	mov    %esp,%ebp
f01026c4:	57                   	push   %edi
f01026c5:	56                   	push   %esi
f01026c6:	53                   	push   %ebx
f01026c7:	83 ec 14             	sub    $0x14,%esp
f01026ca:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01026cd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01026d0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01026d3:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01026d6:	8b 1a                	mov    (%edx),%ebx
f01026d8:	8b 01                	mov    (%ecx),%eax
f01026da:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026dd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01026e4:	eb 7f                	jmp    f0102765 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01026e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01026e9:	01 d8                	add    %ebx,%eax
f01026eb:	89 c6                	mov    %eax,%esi
f01026ed:	c1 ee 1f             	shr    $0x1f,%esi
f01026f0:	01 c6                	add    %eax,%esi
f01026f2:	d1 fe                	sar    %esi
f01026f4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01026f7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01026fa:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01026fd:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01026ff:	eb 03                	jmp    f0102704 <stab_binsearch+0x43>
			m--;
f0102701:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102704:	39 c3                	cmp    %eax,%ebx
f0102706:	7f 0d                	jg     f0102715 <stab_binsearch+0x54>
f0102708:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010270c:	83 ea 0c             	sub    $0xc,%edx
f010270f:	39 f9                	cmp    %edi,%ecx
f0102711:	75 ee                	jne    f0102701 <stab_binsearch+0x40>
f0102713:	eb 05                	jmp    f010271a <stab_binsearch+0x59>
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0102715:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102718:	eb 4b                	jmp    f0102765 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010271a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010271d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102720:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102724:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102727:	76 11                	jbe    f010273a <stab_binsearch+0x79>
			*region_left = m;
f0102729:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010272c:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010272e:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102731:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102738:	eb 2b                	jmp    f0102765 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010273a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010273d:	73 14                	jae    f0102753 <stab_binsearch+0x92>
			*region_right = m - 1;
f010273f:	83 e8 01             	sub    $0x1,%eax
f0102742:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102745:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102748:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010274a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102751:	eb 12                	jmp    f0102765 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102753:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102756:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102758:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010275c:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010275e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102765:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102768:	0f 8e 78 ff ff ff    	jle    f01026e6 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010276e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102772:	75 0f                	jne    f0102783 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102774:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102777:	8b 00                	mov    (%eax),%eax
f0102779:	83 e8 01             	sub    $0x1,%eax
f010277c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010277f:	89 06                	mov    %eax,(%esi)
f0102781:	eb 2c                	jmp    f01027af <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102783:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102786:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102788:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010278b:	8b 0e                	mov    (%esi),%ecx
f010278d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102790:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102793:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102796:	eb 03                	jmp    f010279b <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102798:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010279b:	39 c8                	cmp    %ecx,%eax
f010279d:	7e 0b                	jle    f01027aa <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010279f:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027a3:	83 ea 0c             	sub    $0xc,%edx
f01027a6:	39 df                	cmp    %ebx,%edi
f01027a8:	75 ee                	jne    f0102798 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01027aa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027ad:	89 06                	mov    %eax,(%esi)
	}
}
f01027af:	83 c4 14             	add    $0x14,%esp
f01027b2:	5b                   	pop    %ebx
f01027b3:	5e                   	pop    %esi
f01027b4:	5f                   	pop    %edi
f01027b5:	5d                   	pop    %ebp
f01027b6:	c3                   	ret    

f01027b7 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01027b7:	55                   	push   %ebp
f01027b8:	89 e5                	mov    %esp,%ebp
f01027ba:	57                   	push   %edi
f01027bb:	56                   	push   %esi
f01027bc:	53                   	push   %ebx
f01027bd:	83 ec 3c             	sub    $0x3c,%esp
f01027c0:	8b 75 08             	mov    0x8(%ebp),%esi
f01027c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01027c6:	c7 03 ca 45 10 f0    	movl   $0xf01045ca,(%ebx)
	info->eip_line = 0;
f01027cc:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01027d3:	c7 43 08 ca 45 10 f0 	movl   $0xf01045ca,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01027da:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01027e1:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01027e4:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01027eb:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01027f1:	76 11                	jbe    f0102804 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
		panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01027f3:	b8 9f c5 10 f0       	mov    $0xf010c59f,%eax
f01027f8:	3d 51 a5 10 f0       	cmp    $0xf010a551,%eax
f01027fd:	77 1c                	ja     f010281b <debuginfo_eip+0x64>
f01027ff:	e9 b2 01 00 00       	jmp    f01029b6 <debuginfo_eip+0x1ff>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
		panic("User address");
f0102804:	83 ec 04             	sub    $0x4,%esp
f0102807:	68 d4 45 10 f0       	push   $0xf01045d4
f010280c:	68 82 00 00 00       	push   $0x82
f0102811:	68 e1 45 10 f0       	push   $0xf01045e1
f0102816:	e8 70 d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010281b:	80 3d 9e c5 10 f0 00 	cmpb   $0x0,0xf010c59e
f0102822:	0f 85 95 01 00 00    	jne    f01029bd <debuginfo_eip+0x206>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102828:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010282f:	b8 50 a5 10 f0       	mov    $0xf010a550,%eax
f0102834:	2d f0 47 10 f0       	sub    $0xf01047f0,%eax
f0102839:	c1 f8 02             	sar    $0x2,%eax
f010283c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102842:	83 e8 01             	sub    $0x1,%eax
f0102845:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102848:	83 ec 08             	sub    $0x8,%esp
f010284b:	56                   	push   %esi
f010284c:	6a 64                	push   $0x64
f010284e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102851:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102854:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f0102859:	e8 63 fe ff ff       	call   f01026c1 <stab_binsearch>
	if (lfile == 0)
f010285e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102861:	83 c4 10             	add    $0x10,%esp
f0102864:	85 c0                	test   %eax,%eax
f0102866:	0f 84 58 01 00 00    	je     f01029c4 <debuginfo_eip+0x20d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010286c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010286f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102872:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102875:	83 ec 08             	sub    $0x8,%esp
f0102878:	56                   	push   %esi
f0102879:	6a 24                	push   $0x24
f010287b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010287e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102881:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f0102886:	e8 36 fe ff ff       	call   f01026c1 <stab_binsearch>

	if (lfun <= rfun) {
f010288b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010288e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102891:	83 c4 10             	add    $0x10,%esp
f0102894:	39 d0                	cmp    %edx,%eax
f0102896:	7f 40                	jg     f01028d8 <debuginfo_eip+0x121>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102898:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010289b:	c1 e1 02             	shl    $0x2,%ecx
f010289e:	8d b9 f0 47 10 f0    	lea    -0xfefb810(%ecx),%edi
f01028a4:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028a7:	8b b9 f0 47 10 f0    	mov    -0xfefb810(%ecx),%edi
f01028ad:	b9 9f c5 10 f0       	mov    $0xf010c59f,%ecx
f01028b2:	81 e9 51 a5 10 f0    	sub    $0xf010a551,%ecx
f01028b8:	39 cf                	cmp    %ecx,%edi
f01028ba:	73 09                	jae    f01028c5 <debuginfo_eip+0x10e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01028bc:	81 c7 51 a5 10 f0    	add    $0xf010a551,%edi
f01028c2:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01028c5:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01028c8:	8b 4f 08             	mov    0x8(%edi),%ecx
f01028cb:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01028ce:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01028d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01028d3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01028d6:	eb 0f                	jmp    f01028e7 <debuginfo_eip+0x130>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01028d8:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01028db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028de:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01028e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028e4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01028e7:	83 ec 08             	sub    $0x8,%esp
f01028ea:	6a 3a                	push   $0x3a
f01028ec:	ff 73 08             	pushl  0x8(%ebx)
f01028ef:	e8 44 08 00 00       	call   f0103138 <strfind>
f01028f4:	2b 43 08             	sub    0x8(%ebx),%eax
f01028f7:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01028fa:	83 c4 08             	add    $0x8,%esp
f01028fd:	56                   	push   %esi
f01028fe:	6a 44                	push   $0x44
f0102900:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102903:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102906:	b8 f0 47 10 f0       	mov    $0xf01047f0,%eax
f010290b:	e8 b1 fd ff ff       	call   f01026c1 <stab_binsearch>
	if (lline <= rline) {
f0102910:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102913:	83 c4 10             	add    $0x10,%esp
f0102916:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102919:	7f 0e                	jg     f0102929 <debuginfo_eip+0x172>
		info->eip_line = stabs[lline].n_desc;
f010291b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010291e:	0f b7 14 95 f6 47 10 	movzwl -0xfefb80a(,%edx,4),%edx
f0102925:	f0 
f0102926:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0102929:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010292c:	89 c2                	mov    %eax,%edx
f010292e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102931:	8d 04 85 f0 47 10 f0 	lea    -0xfefb810(,%eax,4),%eax
f0102938:	eb 06                	jmp    f0102940 <debuginfo_eip+0x189>
f010293a:	83 ea 01             	sub    $0x1,%edx
f010293d:	83 e8 0c             	sub    $0xc,%eax
f0102940:	39 d7                	cmp    %edx,%edi
f0102942:	7f 34                	jg     f0102978 <debuginfo_eip+0x1c1>
f0102944:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102948:	80 f9 84             	cmp    $0x84,%cl
f010294b:	74 0b                	je     f0102958 <debuginfo_eip+0x1a1>
f010294d:	80 f9 64             	cmp    $0x64,%cl
f0102950:	75 e8                	jne    f010293a <debuginfo_eip+0x183>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102952:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102956:	74 e2                	je     f010293a <debuginfo_eip+0x183>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102958:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010295b:	8b 14 85 f0 47 10 f0 	mov    -0xfefb810(,%eax,4),%edx
f0102962:	b8 9f c5 10 f0       	mov    $0xf010c59f,%eax
f0102967:	2d 51 a5 10 f0       	sub    $0xf010a551,%eax
f010296c:	39 c2                	cmp    %eax,%edx
f010296e:	73 08                	jae    f0102978 <debuginfo_eip+0x1c1>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102970:	81 c2 51 a5 10 f0    	add    $0xf010a551,%edx
f0102976:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102978:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010297b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010297e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102983:	39 f2                	cmp    %esi,%edx
f0102985:	7d 49                	jge    f01029d0 <debuginfo_eip+0x219>
		for (lline = lfun + 1;
f0102987:	83 c2 01             	add    $0x1,%edx
f010298a:	89 d0                	mov    %edx,%eax
f010298c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010298f:	8d 14 95 f0 47 10 f0 	lea    -0xfefb810(,%edx,4),%edx
f0102996:	eb 04                	jmp    f010299c <debuginfo_eip+0x1e5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102998:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010299c:	39 c6                	cmp    %eax,%esi
f010299e:	7e 2b                	jle    f01029cb <debuginfo_eip+0x214>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029a0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029a4:	83 c0 01             	add    $0x1,%eax
f01029a7:	83 c2 0c             	add    $0xc,%edx
f01029aa:	80 f9 a0             	cmp    $0xa0,%cl
f01029ad:	74 e9                	je     f0102998 <debuginfo_eip+0x1e1>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029af:	b8 00 00 00 00       	mov    $0x0,%eax
f01029b4:	eb 1a                	jmp    f01029d0 <debuginfo_eip+0x219>
		panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029bb:	eb 13                	jmp    f01029d0 <debuginfo_eip+0x219>
f01029bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029c2:	eb 0c                	jmp    f01029d0 <debuginfo_eip+0x219>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01029c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01029c9:	eb 05                	jmp    f01029d0 <debuginfo_eip+0x219>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029cb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01029d0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029d3:	5b                   	pop    %ebx
f01029d4:	5e                   	pop    %esi
f01029d5:	5f                   	pop    %edi
f01029d6:	5d                   	pop    %ebp
f01029d7:	c3                   	ret    

f01029d8 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01029d8:	55                   	push   %ebp
f01029d9:	89 e5                	mov    %esp,%ebp
f01029db:	57                   	push   %edi
f01029dc:	56                   	push   %esi
f01029dd:	53                   	push   %ebx
f01029de:	83 ec 1c             	sub    $0x1c,%esp
f01029e1:	89 c7                	mov    %eax,%edi
f01029e3:	89 d6                	mov    %edx,%esi
f01029e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01029e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029eb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01029ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01029f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01029f4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01029f9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01029fc:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01029ff:	39 d3                	cmp    %edx,%ebx
f0102a01:	72 05                	jb     f0102a08 <printnum+0x30>
f0102a03:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a06:	77 45                	ja     f0102a4d <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a08:	83 ec 0c             	sub    $0xc,%esp
f0102a0b:	ff 75 18             	pushl  0x18(%ebp)
f0102a0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a11:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a14:	53                   	push   %ebx
f0102a15:	ff 75 10             	pushl  0x10(%ebp)
f0102a18:	83 ec 08             	sub    $0x8,%esp
f0102a1b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a1e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a21:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a24:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a27:	e8 34 09 00 00       	call   f0103360 <__udivdi3>
f0102a2c:	83 c4 18             	add    $0x18,%esp
f0102a2f:	52                   	push   %edx
f0102a30:	50                   	push   %eax
f0102a31:	89 f2                	mov    %esi,%edx
f0102a33:	89 f8                	mov    %edi,%eax
f0102a35:	e8 9e ff ff ff       	call   f01029d8 <printnum>
f0102a3a:	83 c4 20             	add    $0x20,%esp
f0102a3d:	eb 18                	jmp    f0102a57 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a3f:	83 ec 08             	sub    $0x8,%esp
f0102a42:	56                   	push   %esi
f0102a43:	ff 75 18             	pushl  0x18(%ebp)
f0102a46:	ff d7                	call   *%edi
f0102a48:	83 c4 10             	add    $0x10,%esp
f0102a4b:	eb 03                	jmp    f0102a50 <printnum+0x78>
f0102a4d:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a50:	83 eb 01             	sub    $0x1,%ebx
f0102a53:	85 db                	test   %ebx,%ebx
f0102a55:	7f e8                	jg     f0102a3f <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a57:	83 ec 08             	sub    $0x8,%esp
f0102a5a:	56                   	push   %esi
f0102a5b:	83 ec 04             	sub    $0x4,%esp
f0102a5e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a61:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a64:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a67:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a6a:	e8 21 0a 00 00       	call   f0103490 <__umoddi3>
f0102a6f:	83 c4 14             	add    $0x14,%esp
f0102a72:	0f be 80 ef 45 10 f0 	movsbl -0xfefba11(%eax),%eax
f0102a79:	50                   	push   %eax
f0102a7a:	ff d7                	call   *%edi
}
f0102a7c:	83 c4 10             	add    $0x10,%esp
f0102a7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a82:	5b                   	pop    %ebx
f0102a83:	5e                   	pop    %esi
f0102a84:	5f                   	pop    %edi
f0102a85:	5d                   	pop    %ebp
f0102a86:	c3                   	ret    

f0102a87 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102a87:	55                   	push   %ebp
f0102a88:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102a8a:	83 fa 01             	cmp    $0x1,%edx
f0102a8d:	7e 0e                	jle    f0102a9d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102a8f:	8b 10                	mov    (%eax),%edx
f0102a91:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102a94:	89 08                	mov    %ecx,(%eax)
f0102a96:	8b 02                	mov    (%edx),%eax
f0102a98:	8b 52 04             	mov    0x4(%edx),%edx
f0102a9b:	eb 22                	jmp    f0102abf <getuint+0x38>
	else if (lflag)
f0102a9d:	85 d2                	test   %edx,%edx
f0102a9f:	74 10                	je     f0102ab1 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102aa1:	8b 10                	mov    (%eax),%edx
f0102aa3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102aa6:	89 08                	mov    %ecx,(%eax)
f0102aa8:	8b 02                	mov    (%edx),%eax
f0102aaa:	ba 00 00 00 00       	mov    $0x0,%edx
f0102aaf:	eb 0e                	jmp    f0102abf <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102ab1:	8b 10                	mov    (%eax),%edx
f0102ab3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ab6:	89 08                	mov    %ecx,(%eax)
f0102ab8:	8b 02                	mov    (%edx),%eax
f0102aba:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102abf:	5d                   	pop    %ebp
f0102ac0:	c3                   	ret    

f0102ac1 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102ac1:	55                   	push   %ebp
f0102ac2:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ac4:	83 fa 01             	cmp    $0x1,%edx
f0102ac7:	7e 0e                	jle    f0102ad7 <getint+0x16>
		return va_arg(*ap, long long);
f0102ac9:	8b 10                	mov    (%eax),%edx
f0102acb:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ace:	89 08                	mov    %ecx,(%eax)
f0102ad0:	8b 02                	mov    (%edx),%eax
f0102ad2:	8b 52 04             	mov    0x4(%edx),%edx
f0102ad5:	eb 1a                	jmp    f0102af1 <getint+0x30>
	else if (lflag)
f0102ad7:	85 d2                	test   %edx,%edx
f0102ad9:	74 0c                	je     f0102ae7 <getint+0x26>
		return va_arg(*ap, long);
f0102adb:	8b 10                	mov    (%eax),%edx
f0102add:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ae0:	89 08                	mov    %ecx,(%eax)
f0102ae2:	8b 02                	mov    (%edx),%eax
f0102ae4:	99                   	cltd   
f0102ae5:	eb 0a                	jmp    f0102af1 <getint+0x30>
	else
		return va_arg(*ap, int);
f0102ae7:	8b 10                	mov    (%eax),%edx
f0102ae9:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102aec:	89 08                	mov    %ecx,(%eax)
f0102aee:	8b 02                	mov    (%edx),%eax
f0102af0:	99                   	cltd   
}
f0102af1:	5d                   	pop    %ebp
f0102af2:	c3                   	ret    

f0102af3 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102af3:	55                   	push   %ebp
f0102af4:	89 e5                	mov    %esp,%ebp
f0102af6:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102af9:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102afd:	8b 10                	mov    (%eax),%edx
f0102aff:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b02:	73 0a                	jae    f0102b0e <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b04:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b07:	89 08                	mov    %ecx,(%eax)
f0102b09:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b0c:	88 02                	mov    %al,(%edx)
}
f0102b0e:	5d                   	pop    %ebp
f0102b0f:	c3                   	ret    

f0102b10 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b10:	55                   	push   %ebp
f0102b11:	89 e5                	mov    %esp,%ebp
f0102b13:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b16:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b19:	50                   	push   %eax
f0102b1a:	ff 75 10             	pushl  0x10(%ebp)
f0102b1d:	ff 75 0c             	pushl  0xc(%ebp)
f0102b20:	ff 75 08             	pushl  0x8(%ebp)
f0102b23:	e8 05 00 00 00       	call   f0102b2d <vprintfmt>
	va_end(ap);
}
f0102b28:	83 c4 10             	add    $0x10,%esp
f0102b2b:	c9                   	leave  
f0102b2c:	c3                   	ret    

f0102b2d <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b2d:	55                   	push   %ebp
f0102b2e:	89 e5                	mov    %esp,%ebp
f0102b30:	57                   	push   %edi
f0102b31:	56                   	push   %esi
f0102b32:	53                   	push   %ebx
f0102b33:	83 ec 2c             	sub    $0x2c,%esp
f0102b36:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b39:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b3c:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b3f:	eb 12                	jmp    f0102b53 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b41:	85 c0                	test   %eax,%eax
f0102b43:	0f 84 44 03 00 00    	je     f0102e8d <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0102b49:	83 ec 08             	sub    $0x8,%esp
f0102b4c:	53                   	push   %ebx
f0102b4d:	50                   	push   %eax
f0102b4e:	ff d6                	call   *%esi
f0102b50:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b53:	83 c7 01             	add    $0x1,%edi
f0102b56:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b5a:	83 f8 25             	cmp    $0x25,%eax
f0102b5d:	75 e2                	jne    f0102b41 <vprintfmt+0x14>
f0102b5f:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b63:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b6a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b71:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b78:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b7d:	eb 07                	jmp    f0102b86 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b82:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b86:	8d 47 01             	lea    0x1(%edi),%eax
f0102b89:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b8c:	0f b6 07             	movzbl (%edi),%eax
f0102b8f:	0f b6 c8             	movzbl %al,%ecx
f0102b92:	83 e8 23             	sub    $0x23,%eax
f0102b95:	3c 55                	cmp    $0x55,%al
f0102b97:	0f 87 d5 02 00 00    	ja     f0102e72 <vprintfmt+0x345>
f0102b9d:	0f b6 c0             	movzbl %al,%eax
f0102ba0:	ff 24 85 6c 46 10 f0 	jmp    *-0xfefb994(,%eax,4)
f0102ba7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102baa:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bae:	eb d6                	jmp    f0102b86 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bb3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bbb:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bbe:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102bc2:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102bc5:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bc8:	83 fa 09             	cmp    $0x9,%edx
f0102bcb:	77 39                	ja     f0102c06 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102bcd:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102bd0:	eb e9                	jmp    f0102bbb <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102bd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bd5:	8d 48 04             	lea    0x4(%eax),%ecx
f0102bd8:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102bdb:	8b 00                	mov    (%eax),%eax
f0102bdd:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102be0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102be3:	eb 27                	jmp    f0102c0c <vprintfmt+0xdf>
f0102be5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102be8:	85 c0                	test   %eax,%eax
f0102bea:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102bef:	0f 49 c8             	cmovns %eax,%ecx
f0102bf2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bf8:	eb 8c                	jmp    f0102b86 <vprintfmt+0x59>
f0102bfa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102bfd:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c04:	eb 80                	jmp    f0102b86 <vprintfmt+0x59>
f0102c06:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c09:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c0c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c10:	0f 89 70 ff ff ff    	jns    f0102b86 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c16:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c19:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c1c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c23:	e9 5e ff ff ff       	jmp    f0102b86 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c28:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c2e:	e9 53 ff ff ff       	jmp    f0102b86 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c33:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c36:	8d 50 04             	lea    0x4(%eax),%edx
f0102c39:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c3c:	83 ec 08             	sub    $0x8,%esp
f0102c3f:	53                   	push   %ebx
f0102c40:	ff 30                	pushl  (%eax)
f0102c42:	ff d6                	call   *%esi
			break;
f0102c44:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c47:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c4a:	e9 04 ff ff ff       	jmp    f0102b53 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c4f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c52:	8d 50 04             	lea    0x4(%eax),%edx
f0102c55:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c58:	8b 00                	mov    (%eax),%eax
f0102c5a:	99                   	cltd   
f0102c5b:	31 d0                	xor    %edx,%eax
f0102c5d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c5f:	83 f8 06             	cmp    $0x6,%eax
f0102c62:	7f 0b                	jg     f0102c6f <vprintfmt+0x142>
f0102c64:	8b 14 85 c4 47 10 f0 	mov    -0xfefb83c(,%eax,4),%edx
f0102c6b:	85 d2                	test   %edx,%edx
f0102c6d:	75 18                	jne    f0102c87 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c6f:	50                   	push   %eax
f0102c70:	68 07 46 10 f0       	push   $0xf0104607
f0102c75:	53                   	push   %ebx
f0102c76:	56                   	push   %esi
f0102c77:	e8 94 fe ff ff       	call   f0102b10 <printfmt>
f0102c7c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c82:	e9 cc fe ff ff       	jmp    f0102b53 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c87:	52                   	push   %edx
f0102c88:	68 1e 43 10 f0       	push   $0xf010431e
f0102c8d:	53                   	push   %ebx
f0102c8e:	56                   	push   %esi
f0102c8f:	e8 7c fe ff ff       	call   f0102b10 <printfmt>
f0102c94:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c97:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c9a:	e9 b4 fe ff ff       	jmp    f0102b53 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102c9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ca2:	8d 50 04             	lea    0x4(%eax),%edx
f0102ca5:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ca8:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102caa:	85 ff                	test   %edi,%edi
f0102cac:	b8 00 46 10 f0       	mov    $0xf0104600,%eax
f0102cb1:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cb4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102cb8:	0f 8e 94 00 00 00    	jle    f0102d52 <vprintfmt+0x225>
f0102cbe:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cc2:	0f 84 98 00 00 00    	je     f0102d60 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cc8:	83 ec 08             	sub    $0x8,%esp
f0102ccb:	ff 75 d0             	pushl  -0x30(%ebp)
f0102cce:	57                   	push   %edi
f0102ccf:	e8 1a 03 00 00       	call   f0102fee <strnlen>
f0102cd4:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cd7:	29 c1                	sub    %eax,%ecx
f0102cd9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102cdc:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cdf:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102ce3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ce6:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ce9:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ceb:	eb 0f                	jmp    f0102cfc <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102ced:	83 ec 08             	sub    $0x8,%esp
f0102cf0:	53                   	push   %ebx
f0102cf1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102cf4:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cf6:	83 ef 01             	sub    $0x1,%edi
f0102cf9:	83 c4 10             	add    $0x10,%esp
f0102cfc:	85 ff                	test   %edi,%edi
f0102cfe:	7f ed                	jg     f0102ced <vprintfmt+0x1c0>
f0102d00:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d03:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d06:	85 c9                	test   %ecx,%ecx
f0102d08:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d0d:	0f 49 c1             	cmovns %ecx,%eax
f0102d10:	29 c1                	sub    %eax,%ecx
f0102d12:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d15:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d18:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d1b:	89 cb                	mov    %ecx,%ebx
f0102d1d:	eb 4d                	jmp    f0102d6c <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d1f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d23:	74 1b                	je     f0102d40 <vprintfmt+0x213>
f0102d25:	0f be c0             	movsbl %al,%eax
f0102d28:	83 e8 20             	sub    $0x20,%eax
f0102d2b:	83 f8 5e             	cmp    $0x5e,%eax
f0102d2e:	76 10                	jbe    f0102d40 <vprintfmt+0x213>
					putch('?', putdat);
f0102d30:	83 ec 08             	sub    $0x8,%esp
f0102d33:	ff 75 0c             	pushl  0xc(%ebp)
f0102d36:	6a 3f                	push   $0x3f
f0102d38:	ff 55 08             	call   *0x8(%ebp)
f0102d3b:	83 c4 10             	add    $0x10,%esp
f0102d3e:	eb 0d                	jmp    f0102d4d <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d40:	83 ec 08             	sub    $0x8,%esp
f0102d43:	ff 75 0c             	pushl  0xc(%ebp)
f0102d46:	52                   	push   %edx
f0102d47:	ff 55 08             	call   *0x8(%ebp)
f0102d4a:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d4d:	83 eb 01             	sub    $0x1,%ebx
f0102d50:	eb 1a                	jmp    f0102d6c <vprintfmt+0x23f>
f0102d52:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d55:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d58:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d5b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d5e:	eb 0c                	jmp    f0102d6c <vprintfmt+0x23f>
f0102d60:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d63:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d66:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d69:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d6c:	83 c7 01             	add    $0x1,%edi
f0102d6f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d73:	0f be d0             	movsbl %al,%edx
f0102d76:	85 d2                	test   %edx,%edx
f0102d78:	74 23                	je     f0102d9d <vprintfmt+0x270>
f0102d7a:	85 f6                	test   %esi,%esi
f0102d7c:	78 a1                	js     f0102d1f <vprintfmt+0x1f2>
f0102d7e:	83 ee 01             	sub    $0x1,%esi
f0102d81:	79 9c                	jns    f0102d1f <vprintfmt+0x1f2>
f0102d83:	89 df                	mov    %ebx,%edi
f0102d85:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d88:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d8b:	eb 18                	jmp    f0102da5 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102d8d:	83 ec 08             	sub    $0x8,%esp
f0102d90:	53                   	push   %ebx
f0102d91:	6a 20                	push   $0x20
f0102d93:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102d95:	83 ef 01             	sub    $0x1,%edi
f0102d98:	83 c4 10             	add    $0x10,%esp
f0102d9b:	eb 08                	jmp    f0102da5 <vprintfmt+0x278>
f0102d9d:	89 df                	mov    %ebx,%edi
f0102d9f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102da2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102da5:	85 ff                	test   %edi,%edi
f0102da7:	7f e4                	jg     f0102d8d <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102da9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dac:	e9 a2 fd ff ff       	jmp    f0102b53 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102db1:	8d 45 14             	lea    0x14(%ebp),%eax
f0102db4:	e8 08 fd ff ff       	call   f0102ac1 <getint>
f0102db9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dbc:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102dbf:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102dc4:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102dc8:	79 74                	jns    f0102e3e <vprintfmt+0x311>
				putch('-', putdat);
f0102dca:	83 ec 08             	sub    $0x8,%esp
f0102dcd:	53                   	push   %ebx
f0102dce:	6a 2d                	push   $0x2d
f0102dd0:	ff d6                	call   *%esi
				num = -(long long) num;
f0102dd2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102dd5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102dd8:	f7 d8                	neg    %eax
f0102dda:	83 d2 00             	adc    $0x0,%edx
f0102ddd:	f7 da                	neg    %edx
f0102ddf:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102de2:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102de7:	eb 55                	jmp    f0102e3e <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102de9:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dec:	e8 96 fc ff ff       	call   f0102a87 <getuint>
			base = 10;
f0102df1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102df6:	eb 46                	jmp    f0102e3e <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102df8:	8d 45 14             	lea    0x14(%ebp),%eax
f0102dfb:	e8 87 fc ff ff       	call   f0102a87 <getuint>
			base = 8;
f0102e00:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102e05:	eb 37                	jmp    f0102e3e <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e07:	83 ec 08             	sub    $0x8,%esp
f0102e0a:	53                   	push   %ebx
f0102e0b:	6a 30                	push   $0x30
f0102e0d:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e0f:	83 c4 08             	add    $0x8,%esp
f0102e12:	53                   	push   %ebx
f0102e13:	6a 78                	push   $0x78
f0102e15:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e17:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1a:	8d 50 04             	lea    0x4(%eax),%edx
f0102e1d:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e20:	8b 00                	mov    (%eax),%eax
f0102e22:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e27:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e2a:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e2f:	eb 0d                	jmp    f0102e3e <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e31:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e34:	e8 4e fc ff ff       	call   f0102a87 <getuint>
			base = 16;
f0102e39:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e3e:	83 ec 0c             	sub    $0xc,%esp
f0102e41:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e45:	57                   	push   %edi
f0102e46:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e49:	51                   	push   %ecx
f0102e4a:	52                   	push   %edx
f0102e4b:	50                   	push   %eax
f0102e4c:	89 da                	mov    %ebx,%edx
f0102e4e:	89 f0                	mov    %esi,%eax
f0102e50:	e8 83 fb ff ff       	call   f01029d8 <printnum>
			break;
f0102e55:	83 c4 20             	add    $0x20,%esp
f0102e58:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e5b:	e9 f3 fc ff ff       	jmp    f0102b53 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102e60:	83 ec 08             	sub    $0x8,%esp
f0102e63:	53                   	push   %ebx
f0102e64:	51                   	push   %ecx
f0102e65:	ff d6                	call   *%esi
			break;
f0102e67:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e6a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102e6d:	e9 e1 fc ff ff       	jmp    f0102b53 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102e72:	83 ec 08             	sub    $0x8,%esp
f0102e75:	53                   	push   %ebx
f0102e76:	6a 25                	push   $0x25
f0102e78:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102e7a:	83 c4 10             	add    $0x10,%esp
f0102e7d:	eb 03                	jmp    f0102e82 <vprintfmt+0x355>
f0102e7f:	83 ef 01             	sub    $0x1,%edi
f0102e82:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102e86:	75 f7                	jne    f0102e7f <vprintfmt+0x352>
f0102e88:	e9 c6 fc ff ff       	jmp    f0102b53 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102e8d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e90:	5b                   	pop    %ebx
f0102e91:	5e                   	pop    %esi
f0102e92:	5f                   	pop    %edi
f0102e93:	5d                   	pop    %ebp
f0102e94:	c3                   	ret    

f0102e95 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102e95:	55                   	push   %ebp
f0102e96:	89 e5                	mov    %esp,%ebp
f0102e98:	83 ec 18             	sub    $0x18,%esp
f0102e9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e9e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102ea1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102ea4:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102ea8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102eab:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102eb2:	85 c0                	test   %eax,%eax
f0102eb4:	74 26                	je     f0102edc <vsnprintf+0x47>
f0102eb6:	85 d2                	test   %edx,%edx
f0102eb8:	7e 22                	jle    f0102edc <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102eba:	ff 75 14             	pushl  0x14(%ebp)
f0102ebd:	ff 75 10             	pushl  0x10(%ebp)
f0102ec0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102ec3:	50                   	push   %eax
f0102ec4:	68 f3 2a 10 f0       	push   $0xf0102af3
f0102ec9:	e8 5f fc ff ff       	call   f0102b2d <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102ece:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102ed1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102ed7:	83 c4 10             	add    $0x10,%esp
f0102eda:	eb 05                	jmp    f0102ee1 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102edc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102ee1:	c9                   	leave  
f0102ee2:	c3                   	ret    

f0102ee3 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102ee3:	55                   	push   %ebp
f0102ee4:	89 e5                	mov    %esp,%ebp
f0102ee6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102ee9:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102eec:	50                   	push   %eax
f0102eed:	ff 75 10             	pushl  0x10(%ebp)
f0102ef0:	ff 75 0c             	pushl  0xc(%ebp)
f0102ef3:	ff 75 08             	pushl  0x8(%ebp)
f0102ef6:	e8 9a ff ff ff       	call   f0102e95 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102efb:	c9                   	leave  
f0102efc:	c3                   	ret    

f0102efd <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102efd:	55                   	push   %ebp
f0102efe:	89 e5                	mov    %esp,%ebp
f0102f00:	57                   	push   %edi
f0102f01:	56                   	push   %esi
f0102f02:	53                   	push   %ebx
f0102f03:	83 ec 0c             	sub    $0xc,%esp
f0102f06:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f09:	85 c0                	test   %eax,%eax
f0102f0b:	74 11                	je     f0102f1e <readline+0x21>
		cprintf("%s", prompt);
f0102f0d:	83 ec 08             	sub    $0x8,%esp
f0102f10:	50                   	push   %eax
f0102f11:	68 1e 43 10 f0       	push   $0xf010431e
f0102f16:	e8 92 f7 ff ff       	call   f01026ad <cprintf>
f0102f1b:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f1e:	83 ec 0c             	sub    $0xc,%esp
f0102f21:	6a 00                	push   $0x0
f0102f23:	e8 fe d7 ff ff       	call   f0100726 <iscons>
f0102f28:	89 c7                	mov    %eax,%edi
f0102f2a:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f2d:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f32:	e8 de d7 ff ff       	call   f0100715 <getchar>
f0102f37:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f39:	85 c0                	test   %eax,%eax
f0102f3b:	79 18                	jns    f0102f55 <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f3d:	83 ec 08             	sub    $0x8,%esp
f0102f40:	50                   	push   %eax
f0102f41:	68 e0 47 10 f0       	push   $0xf01047e0
f0102f46:	e8 62 f7 ff ff       	call   f01026ad <cprintf>
			return NULL;
f0102f4b:	83 c4 10             	add    $0x10,%esp
f0102f4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f53:	eb 79                	jmp    f0102fce <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102f55:	83 f8 08             	cmp    $0x8,%eax
f0102f58:	0f 94 c2             	sete   %dl
f0102f5b:	83 f8 7f             	cmp    $0x7f,%eax
f0102f5e:	0f 94 c0             	sete   %al
f0102f61:	08 c2                	or     %al,%dl
f0102f63:	74 1a                	je     f0102f7f <readline+0x82>
f0102f65:	85 f6                	test   %esi,%esi
f0102f67:	7e 16                	jle    f0102f7f <readline+0x82>
			if (echoing)
f0102f69:	85 ff                	test   %edi,%edi
f0102f6b:	74 0d                	je     f0102f7a <readline+0x7d>
				cputchar('\b');
f0102f6d:	83 ec 0c             	sub    $0xc,%esp
f0102f70:	6a 08                	push   $0x8
f0102f72:	e8 8e d7 ff ff       	call   f0100705 <cputchar>
f0102f77:	83 c4 10             	add    $0x10,%esp
			i--;
f0102f7a:	83 ee 01             	sub    $0x1,%esi
f0102f7d:	eb b3                	jmp    f0102f32 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102f7f:	83 fb 1f             	cmp    $0x1f,%ebx
f0102f82:	7e 23                	jle    f0102fa7 <readline+0xaa>
f0102f84:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102f8a:	7f 1b                	jg     f0102fa7 <readline+0xaa>
			if (echoing)
f0102f8c:	85 ff                	test   %edi,%edi
f0102f8e:	74 0c                	je     f0102f9c <readline+0x9f>
				cputchar(c);
f0102f90:	83 ec 0c             	sub    $0xc,%esp
f0102f93:	53                   	push   %ebx
f0102f94:	e8 6c d7 ff ff       	call   f0100705 <cputchar>
f0102f99:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102f9c:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f0102fa2:	8d 76 01             	lea    0x1(%esi),%esi
f0102fa5:	eb 8b                	jmp    f0102f32 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102fa7:	83 fb 0a             	cmp    $0xa,%ebx
f0102faa:	74 05                	je     f0102fb1 <readline+0xb4>
f0102fac:	83 fb 0d             	cmp    $0xd,%ebx
f0102faf:	75 81                	jne    f0102f32 <readline+0x35>
			if (echoing)
f0102fb1:	85 ff                	test   %edi,%edi
f0102fb3:	74 0d                	je     f0102fc2 <readline+0xc5>
				cputchar('\n');
f0102fb5:	83 ec 0c             	sub    $0xc,%esp
f0102fb8:	6a 0a                	push   $0xa
f0102fba:	e8 46 d7 ff ff       	call   f0100705 <cputchar>
f0102fbf:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102fc2:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f0102fc9:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f0102fce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fd1:	5b                   	pop    %ebx
f0102fd2:	5e                   	pop    %esi
f0102fd3:	5f                   	pop    %edi
f0102fd4:	5d                   	pop    %ebp
f0102fd5:	c3                   	ret    

f0102fd6 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102fd6:	55                   	push   %ebp
f0102fd7:	89 e5                	mov    %esp,%ebp
f0102fd9:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fdc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fe1:	eb 03                	jmp    f0102fe6 <strlen+0x10>
		n++;
f0102fe3:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102fe6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102fea:	75 f7                	jne    f0102fe3 <strlen+0xd>
		n++;
	return n;
}
f0102fec:	5d                   	pop    %ebp
f0102fed:	c3                   	ret    

f0102fee <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102fee:	55                   	push   %ebp
f0102fef:	89 e5                	mov    %esp,%ebp
f0102ff1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102ff4:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102ff7:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ffc:	eb 03                	jmp    f0103001 <strnlen+0x13>
		n++;
f0102ffe:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103001:	39 c2                	cmp    %eax,%edx
f0103003:	74 08                	je     f010300d <strnlen+0x1f>
f0103005:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103009:	75 f3                	jne    f0102ffe <strnlen+0x10>
f010300b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010300d:	5d                   	pop    %ebp
f010300e:	c3                   	ret    

f010300f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010300f:	55                   	push   %ebp
f0103010:	89 e5                	mov    %esp,%ebp
f0103012:	53                   	push   %ebx
f0103013:	8b 45 08             	mov    0x8(%ebp),%eax
f0103016:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103019:	89 c2                	mov    %eax,%edx
f010301b:	83 c2 01             	add    $0x1,%edx
f010301e:	83 c1 01             	add    $0x1,%ecx
f0103021:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103025:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103028:	84 db                	test   %bl,%bl
f010302a:	75 ef                	jne    f010301b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010302c:	5b                   	pop    %ebx
f010302d:	5d                   	pop    %ebp
f010302e:	c3                   	ret    

f010302f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010302f:	55                   	push   %ebp
f0103030:	89 e5                	mov    %esp,%ebp
f0103032:	53                   	push   %ebx
f0103033:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103036:	53                   	push   %ebx
f0103037:	e8 9a ff ff ff       	call   f0102fd6 <strlen>
f010303c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010303f:	ff 75 0c             	pushl  0xc(%ebp)
f0103042:	01 d8                	add    %ebx,%eax
f0103044:	50                   	push   %eax
f0103045:	e8 c5 ff ff ff       	call   f010300f <strcpy>
	return dst;
}
f010304a:	89 d8                	mov    %ebx,%eax
f010304c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010304f:	c9                   	leave  
f0103050:	c3                   	ret    

f0103051 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103051:	55                   	push   %ebp
f0103052:	89 e5                	mov    %esp,%ebp
f0103054:	56                   	push   %esi
f0103055:	53                   	push   %ebx
f0103056:	8b 75 08             	mov    0x8(%ebp),%esi
f0103059:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010305c:	89 f3                	mov    %esi,%ebx
f010305e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103061:	89 f2                	mov    %esi,%edx
f0103063:	eb 0f                	jmp    f0103074 <strncpy+0x23>
		*dst++ = *src;
f0103065:	83 c2 01             	add    $0x1,%edx
f0103068:	0f b6 01             	movzbl (%ecx),%eax
f010306b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010306e:	80 39 01             	cmpb   $0x1,(%ecx)
f0103071:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103074:	39 da                	cmp    %ebx,%edx
f0103076:	75 ed                	jne    f0103065 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103078:	89 f0                	mov    %esi,%eax
f010307a:	5b                   	pop    %ebx
f010307b:	5e                   	pop    %esi
f010307c:	5d                   	pop    %ebp
f010307d:	c3                   	ret    

f010307e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010307e:	55                   	push   %ebp
f010307f:	89 e5                	mov    %esp,%ebp
f0103081:	56                   	push   %esi
f0103082:	53                   	push   %ebx
f0103083:	8b 75 08             	mov    0x8(%ebp),%esi
f0103086:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103089:	8b 55 10             	mov    0x10(%ebp),%edx
f010308c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010308e:	85 d2                	test   %edx,%edx
f0103090:	74 21                	je     f01030b3 <strlcpy+0x35>
f0103092:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103096:	89 f2                	mov    %esi,%edx
f0103098:	eb 09                	jmp    f01030a3 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010309a:	83 c2 01             	add    $0x1,%edx
f010309d:	83 c1 01             	add    $0x1,%ecx
f01030a0:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01030a3:	39 c2                	cmp    %eax,%edx
f01030a5:	74 09                	je     f01030b0 <strlcpy+0x32>
f01030a7:	0f b6 19             	movzbl (%ecx),%ebx
f01030aa:	84 db                	test   %bl,%bl
f01030ac:	75 ec                	jne    f010309a <strlcpy+0x1c>
f01030ae:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01030b0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01030b3:	29 f0                	sub    %esi,%eax
}
f01030b5:	5b                   	pop    %ebx
f01030b6:	5e                   	pop    %esi
f01030b7:	5d                   	pop    %ebp
f01030b8:	c3                   	ret    

f01030b9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01030b9:	55                   	push   %ebp
f01030ba:	89 e5                	mov    %esp,%ebp
f01030bc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030bf:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01030c2:	eb 06                	jmp    f01030ca <strcmp+0x11>
		p++, q++;
f01030c4:	83 c1 01             	add    $0x1,%ecx
f01030c7:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01030ca:	0f b6 01             	movzbl (%ecx),%eax
f01030cd:	84 c0                	test   %al,%al
f01030cf:	74 04                	je     f01030d5 <strcmp+0x1c>
f01030d1:	3a 02                	cmp    (%edx),%al
f01030d3:	74 ef                	je     f01030c4 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01030d5:	0f b6 c0             	movzbl %al,%eax
f01030d8:	0f b6 12             	movzbl (%edx),%edx
f01030db:	29 d0                	sub    %edx,%eax
}
f01030dd:	5d                   	pop    %ebp
f01030de:	c3                   	ret    

f01030df <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01030df:	55                   	push   %ebp
f01030e0:	89 e5                	mov    %esp,%ebp
f01030e2:	53                   	push   %ebx
f01030e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01030e6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01030e9:	89 c3                	mov    %eax,%ebx
f01030eb:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01030ee:	eb 06                	jmp    f01030f6 <strncmp+0x17>
		n--, p++, q++;
f01030f0:	83 c0 01             	add    $0x1,%eax
f01030f3:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01030f6:	39 d8                	cmp    %ebx,%eax
f01030f8:	74 15                	je     f010310f <strncmp+0x30>
f01030fa:	0f b6 08             	movzbl (%eax),%ecx
f01030fd:	84 c9                	test   %cl,%cl
f01030ff:	74 04                	je     f0103105 <strncmp+0x26>
f0103101:	3a 0a                	cmp    (%edx),%cl
f0103103:	74 eb                	je     f01030f0 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103105:	0f b6 00             	movzbl (%eax),%eax
f0103108:	0f b6 12             	movzbl (%edx),%edx
f010310b:	29 d0                	sub    %edx,%eax
f010310d:	eb 05                	jmp    f0103114 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010310f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103114:	5b                   	pop    %ebx
f0103115:	5d                   	pop    %ebp
f0103116:	c3                   	ret    

f0103117 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103117:	55                   	push   %ebp
f0103118:	89 e5                	mov    %esp,%ebp
f010311a:	8b 45 08             	mov    0x8(%ebp),%eax
f010311d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103121:	eb 07                	jmp    f010312a <strchr+0x13>
		if (*s == c)
f0103123:	38 ca                	cmp    %cl,%dl
f0103125:	74 0f                	je     f0103136 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103127:	83 c0 01             	add    $0x1,%eax
f010312a:	0f b6 10             	movzbl (%eax),%edx
f010312d:	84 d2                	test   %dl,%dl
f010312f:	75 f2                	jne    f0103123 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103131:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103136:	5d                   	pop    %ebp
f0103137:	c3                   	ret    

f0103138 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103138:	55                   	push   %ebp
f0103139:	89 e5                	mov    %esp,%ebp
f010313b:	8b 45 08             	mov    0x8(%ebp),%eax
f010313e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103142:	eb 03                	jmp    f0103147 <strfind+0xf>
f0103144:	83 c0 01             	add    $0x1,%eax
f0103147:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010314a:	38 ca                	cmp    %cl,%dl
f010314c:	74 04                	je     f0103152 <strfind+0x1a>
f010314e:	84 d2                	test   %dl,%dl
f0103150:	75 f2                	jne    f0103144 <strfind+0xc>
			break;
	return (char *) s;
}
f0103152:	5d                   	pop    %ebp
f0103153:	c3                   	ret    

f0103154 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103154:	55                   	push   %ebp
f0103155:	89 e5                	mov    %esp,%ebp
f0103157:	57                   	push   %edi
f0103158:	56                   	push   %esi
f0103159:	53                   	push   %ebx
f010315a:	8b 55 08             	mov    0x8(%ebp),%edx
f010315d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0103160:	85 c9                	test   %ecx,%ecx
f0103162:	74 37                	je     f010319b <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103164:	f6 c2 03             	test   $0x3,%dl
f0103167:	75 2a                	jne    f0103193 <memset+0x3f>
f0103169:	f6 c1 03             	test   $0x3,%cl
f010316c:	75 25                	jne    f0103193 <memset+0x3f>
		c &= 0xFF;
f010316e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103172:	89 df                	mov    %ebx,%edi
f0103174:	c1 e7 08             	shl    $0x8,%edi
f0103177:	89 de                	mov    %ebx,%esi
f0103179:	c1 e6 18             	shl    $0x18,%esi
f010317c:	89 d8                	mov    %ebx,%eax
f010317e:	c1 e0 10             	shl    $0x10,%eax
f0103181:	09 f0                	or     %esi,%eax
f0103183:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0103185:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103188:	89 f8                	mov    %edi,%eax
f010318a:	09 d8                	or     %ebx,%eax
f010318c:	89 d7                	mov    %edx,%edi
f010318e:	fc                   	cld    
f010318f:	f3 ab                	rep stos %eax,%es:(%edi)
f0103191:	eb 08                	jmp    f010319b <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103193:	89 d7                	mov    %edx,%edi
f0103195:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103198:	fc                   	cld    
f0103199:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f010319b:	89 d0                	mov    %edx,%eax
f010319d:	5b                   	pop    %ebx
f010319e:	5e                   	pop    %esi
f010319f:	5f                   	pop    %edi
f01031a0:	5d                   	pop    %ebp
f01031a1:	c3                   	ret    

f01031a2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031a2:	55                   	push   %ebp
f01031a3:	89 e5                	mov    %esp,%ebp
f01031a5:	57                   	push   %edi
f01031a6:	56                   	push   %esi
f01031a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01031aa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01031ad:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01031b0:	39 c6                	cmp    %eax,%esi
f01031b2:	73 35                	jae    f01031e9 <memmove+0x47>
f01031b4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01031b7:	39 d0                	cmp    %edx,%eax
f01031b9:	73 2e                	jae    f01031e9 <memmove+0x47>
		s += n;
		d += n;
f01031bb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031be:	89 d6                	mov    %edx,%esi
f01031c0:	09 fe                	or     %edi,%esi
f01031c2:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01031c8:	75 13                	jne    f01031dd <memmove+0x3b>
f01031ca:	f6 c1 03             	test   $0x3,%cl
f01031cd:	75 0e                	jne    f01031dd <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01031cf:	83 ef 04             	sub    $0x4,%edi
f01031d2:	8d 72 fc             	lea    -0x4(%edx),%esi
f01031d5:	c1 e9 02             	shr    $0x2,%ecx
f01031d8:	fd                   	std    
f01031d9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031db:	eb 09                	jmp    f01031e6 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01031dd:	83 ef 01             	sub    $0x1,%edi
f01031e0:	8d 72 ff             	lea    -0x1(%edx),%esi
f01031e3:	fd                   	std    
f01031e4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01031e6:	fc                   	cld    
f01031e7:	eb 1d                	jmp    f0103206 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01031e9:	89 f2                	mov    %esi,%edx
f01031eb:	09 c2                	or     %eax,%edx
f01031ed:	f6 c2 03             	test   $0x3,%dl
f01031f0:	75 0f                	jne    f0103201 <memmove+0x5f>
f01031f2:	f6 c1 03             	test   $0x3,%cl
f01031f5:	75 0a                	jne    f0103201 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01031f7:	c1 e9 02             	shr    $0x2,%ecx
f01031fa:	89 c7                	mov    %eax,%edi
f01031fc:	fc                   	cld    
f01031fd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01031ff:	eb 05                	jmp    f0103206 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103201:	89 c7                	mov    %eax,%edi
f0103203:	fc                   	cld    
f0103204:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103206:	5e                   	pop    %esi
f0103207:	5f                   	pop    %edi
f0103208:	5d                   	pop    %ebp
f0103209:	c3                   	ret    

f010320a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010320a:	55                   	push   %ebp
f010320b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010320d:	ff 75 10             	pushl  0x10(%ebp)
f0103210:	ff 75 0c             	pushl  0xc(%ebp)
f0103213:	ff 75 08             	pushl  0x8(%ebp)
f0103216:	e8 87 ff ff ff       	call   f01031a2 <memmove>
}
f010321b:	c9                   	leave  
f010321c:	c3                   	ret    

f010321d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010321d:	55                   	push   %ebp
f010321e:	89 e5                	mov    %esp,%ebp
f0103220:	56                   	push   %esi
f0103221:	53                   	push   %ebx
f0103222:	8b 45 08             	mov    0x8(%ebp),%eax
f0103225:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103228:	89 c6                	mov    %eax,%esi
f010322a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010322d:	eb 1a                	jmp    f0103249 <memcmp+0x2c>
		if (*s1 != *s2)
f010322f:	0f b6 08             	movzbl (%eax),%ecx
f0103232:	0f b6 1a             	movzbl (%edx),%ebx
f0103235:	38 d9                	cmp    %bl,%cl
f0103237:	74 0a                	je     f0103243 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103239:	0f b6 c1             	movzbl %cl,%eax
f010323c:	0f b6 db             	movzbl %bl,%ebx
f010323f:	29 d8                	sub    %ebx,%eax
f0103241:	eb 0f                	jmp    f0103252 <memcmp+0x35>
		s1++, s2++;
f0103243:	83 c0 01             	add    $0x1,%eax
f0103246:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103249:	39 f0                	cmp    %esi,%eax
f010324b:	75 e2                	jne    f010322f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010324d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103252:	5b                   	pop    %ebx
f0103253:	5e                   	pop    %esi
f0103254:	5d                   	pop    %ebp
f0103255:	c3                   	ret    

f0103256 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103256:	55                   	push   %ebp
f0103257:	89 e5                	mov    %esp,%ebp
f0103259:	53                   	push   %ebx
f010325a:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010325d:	89 c1                	mov    %eax,%ecx
f010325f:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103262:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103266:	eb 0a                	jmp    f0103272 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103268:	0f b6 10             	movzbl (%eax),%edx
f010326b:	39 da                	cmp    %ebx,%edx
f010326d:	74 07                	je     f0103276 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010326f:	83 c0 01             	add    $0x1,%eax
f0103272:	39 c8                	cmp    %ecx,%eax
f0103274:	72 f2                	jb     f0103268 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103276:	5b                   	pop    %ebx
f0103277:	5d                   	pop    %ebp
f0103278:	c3                   	ret    

f0103279 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103279:	55                   	push   %ebp
f010327a:	89 e5                	mov    %esp,%ebp
f010327c:	57                   	push   %edi
f010327d:	56                   	push   %esi
f010327e:	53                   	push   %ebx
f010327f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103282:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103285:	eb 03                	jmp    f010328a <strtol+0x11>
		s++;
f0103287:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010328a:	0f b6 01             	movzbl (%ecx),%eax
f010328d:	3c 20                	cmp    $0x20,%al
f010328f:	74 f6                	je     f0103287 <strtol+0xe>
f0103291:	3c 09                	cmp    $0x9,%al
f0103293:	74 f2                	je     f0103287 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103295:	3c 2b                	cmp    $0x2b,%al
f0103297:	75 0a                	jne    f01032a3 <strtol+0x2a>
		s++;
f0103299:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010329c:	bf 00 00 00 00       	mov    $0x0,%edi
f01032a1:	eb 11                	jmp    f01032b4 <strtol+0x3b>
f01032a3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01032a8:	3c 2d                	cmp    $0x2d,%al
f01032aa:	75 08                	jne    f01032b4 <strtol+0x3b>
		s++, neg = 1;
f01032ac:	83 c1 01             	add    $0x1,%ecx
f01032af:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01032b4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01032ba:	75 15                	jne    f01032d1 <strtol+0x58>
f01032bc:	80 39 30             	cmpb   $0x30,(%ecx)
f01032bf:	75 10                	jne    f01032d1 <strtol+0x58>
f01032c1:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01032c5:	75 7c                	jne    f0103343 <strtol+0xca>
		s += 2, base = 16;
f01032c7:	83 c1 02             	add    $0x2,%ecx
f01032ca:	bb 10 00 00 00       	mov    $0x10,%ebx
f01032cf:	eb 16                	jmp    f01032e7 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01032d1:	85 db                	test   %ebx,%ebx
f01032d3:	75 12                	jne    f01032e7 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01032d5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01032da:	80 39 30             	cmpb   $0x30,(%ecx)
f01032dd:	75 08                	jne    f01032e7 <strtol+0x6e>
		s++, base = 8;
f01032df:	83 c1 01             	add    $0x1,%ecx
f01032e2:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01032e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01032ec:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01032ef:	0f b6 11             	movzbl (%ecx),%edx
f01032f2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01032f5:	89 f3                	mov    %esi,%ebx
f01032f7:	80 fb 09             	cmp    $0x9,%bl
f01032fa:	77 08                	ja     f0103304 <strtol+0x8b>
			dig = *s - '0';
f01032fc:	0f be d2             	movsbl %dl,%edx
f01032ff:	83 ea 30             	sub    $0x30,%edx
f0103302:	eb 22                	jmp    f0103326 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103304:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103307:	89 f3                	mov    %esi,%ebx
f0103309:	80 fb 19             	cmp    $0x19,%bl
f010330c:	77 08                	ja     f0103316 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010330e:	0f be d2             	movsbl %dl,%edx
f0103311:	83 ea 57             	sub    $0x57,%edx
f0103314:	eb 10                	jmp    f0103326 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103316:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103319:	89 f3                	mov    %esi,%ebx
f010331b:	80 fb 19             	cmp    $0x19,%bl
f010331e:	77 16                	ja     f0103336 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103320:	0f be d2             	movsbl %dl,%edx
f0103323:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103326:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103329:	7d 0b                	jge    f0103336 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010332b:	83 c1 01             	add    $0x1,%ecx
f010332e:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103332:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103334:	eb b9                	jmp    f01032ef <strtol+0x76>

	if (endptr)
f0103336:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010333a:	74 0d                	je     f0103349 <strtol+0xd0>
		*endptr = (char *) s;
f010333c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010333f:	89 0e                	mov    %ecx,(%esi)
f0103341:	eb 06                	jmp    f0103349 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103343:	85 db                	test   %ebx,%ebx
f0103345:	74 98                	je     f01032df <strtol+0x66>
f0103347:	eb 9e                	jmp    f01032e7 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103349:	89 c2                	mov    %eax,%edx
f010334b:	f7 da                	neg    %edx
f010334d:	85 ff                	test   %edi,%edi
f010334f:	0f 45 c2             	cmovne %edx,%eax
}
f0103352:	5b                   	pop    %ebx
f0103353:	5e                   	pop    %esi
f0103354:	5f                   	pop    %edi
f0103355:	5d                   	pop    %ebp
f0103356:	c3                   	ret    
f0103357:	66 90                	xchg   %ax,%ax
f0103359:	66 90                	xchg   %ax,%ax
f010335b:	66 90                	xchg   %ax,%ax
f010335d:	66 90                	xchg   %ax,%ax
f010335f:	90                   	nop

f0103360 <__udivdi3>:
f0103360:	55                   	push   %ebp
f0103361:	57                   	push   %edi
f0103362:	56                   	push   %esi
f0103363:	53                   	push   %ebx
f0103364:	83 ec 1c             	sub    $0x1c,%esp
f0103367:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010336b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010336f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103373:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103377:	85 f6                	test   %esi,%esi
f0103379:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010337d:	89 ca                	mov    %ecx,%edx
f010337f:	89 f8                	mov    %edi,%eax
f0103381:	75 3d                	jne    f01033c0 <__udivdi3+0x60>
f0103383:	39 cf                	cmp    %ecx,%edi
f0103385:	0f 87 c5 00 00 00    	ja     f0103450 <__udivdi3+0xf0>
f010338b:	85 ff                	test   %edi,%edi
f010338d:	89 fd                	mov    %edi,%ebp
f010338f:	75 0b                	jne    f010339c <__udivdi3+0x3c>
f0103391:	b8 01 00 00 00       	mov    $0x1,%eax
f0103396:	31 d2                	xor    %edx,%edx
f0103398:	f7 f7                	div    %edi
f010339a:	89 c5                	mov    %eax,%ebp
f010339c:	89 c8                	mov    %ecx,%eax
f010339e:	31 d2                	xor    %edx,%edx
f01033a0:	f7 f5                	div    %ebp
f01033a2:	89 c1                	mov    %eax,%ecx
f01033a4:	89 d8                	mov    %ebx,%eax
f01033a6:	89 cf                	mov    %ecx,%edi
f01033a8:	f7 f5                	div    %ebp
f01033aa:	89 c3                	mov    %eax,%ebx
f01033ac:	89 d8                	mov    %ebx,%eax
f01033ae:	89 fa                	mov    %edi,%edx
f01033b0:	83 c4 1c             	add    $0x1c,%esp
f01033b3:	5b                   	pop    %ebx
f01033b4:	5e                   	pop    %esi
f01033b5:	5f                   	pop    %edi
f01033b6:	5d                   	pop    %ebp
f01033b7:	c3                   	ret    
f01033b8:	90                   	nop
f01033b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01033c0:	39 ce                	cmp    %ecx,%esi
f01033c2:	77 74                	ja     f0103438 <__udivdi3+0xd8>
f01033c4:	0f bd fe             	bsr    %esi,%edi
f01033c7:	83 f7 1f             	xor    $0x1f,%edi
f01033ca:	0f 84 98 00 00 00    	je     f0103468 <__udivdi3+0x108>
f01033d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01033d5:	89 f9                	mov    %edi,%ecx
f01033d7:	89 c5                	mov    %eax,%ebp
f01033d9:	29 fb                	sub    %edi,%ebx
f01033db:	d3 e6                	shl    %cl,%esi
f01033dd:	89 d9                	mov    %ebx,%ecx
f01033df:	d3 ed                	shr    %cl,%ebp
f01033e1:	89 f9                	mov    %edi,%ecx
f01033e3:	d3 e0                	shl    %cl,%eax
f01033e5:	09 ee                	or     %ebp,%esi
f01033e7:	89 d9                	mov    %ebx,%ecx
f01033e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033ed:	89 d5                	mov    %edx,%ebp
f01033ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01033f3:	d3 ed                	shr    %cl,%ebp
f01033f5:	89 f9                	mov    %edi,%ecx
f01033f7:	d3 e2                	shl    %cl,%edx
f01033f9:	89 d9                	mov    %ebx,%ecx
f01033fb:	d3 e8                	shr    %cl,%eax
f01033fd:	09 c2                	or     %eax,%edx
f01033ff:	89 d0                	mov    %edx,%eax
f0103401:	89 ea                	mov    %ebp,%edx
f0103403:	f7 f6                	div    %esi
f0103405:	89 d5                	mov    %edx,%ebp
f0103407:	89 c3                	mov    %eax,%ebx
f0103409:	f7 64 24 0c          	mull   0xc(%esp)
f010340d:	39 d5                	cmp    %edx,%ebp
f010340f:	72 10                	jb     f0103421 <__udivdi3+0xc1>
f0103411:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103415:	89 f9                	mov    %edi,%ecx
f0103417:	d3 e6                	shl    %cl,%esi
f0103419:	39 c6                	cmp    %eax,%esi
f010341b:	73 07                	jae    f0103424 <__udivdi3+0xc4>
f010341d:	39 d5                	cmp    %edx,%ebp
f010341f:	75 03                	jne    f0103424 <__udivdi3+0xc4>
f0103421:	83 eb 01             	sub    $0x1,%ebx
f0103424:	31 ff                	xor    %edi,%edi
f0103426:	89 d8                	mov    %ebx,%eax
f0103428:	89 fa                	mov    %edi,%edx
f010342a:	83 c4 1c             	add    $0x1c,%esp
f010342d:	5b                   	pop    %ebx
f010342e:	5e                   	pop    %esi
f010342f:	5f                   	pop    %edi
f0103430:	5d                   	pop    %ebp
f0103431:	c3                   	ret    
f0103432:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103438:	31 ff                	xor    %edi,%edi
f010343a:	31 db                	xor    %ebx,%ebx
f010343c:	89 d8                	mov    %ebx,%eax
f010343e:	89 fa                	mov    %edi,%edx
f0103440:	83 c4 1c             	add    $0x1c,%esp
f0103443:	5b                   	pop    %ebx
f0103444:	5e                   	pop    %esi
f0103445:	5f                   	pop    %edi
f0103446:	5d                   	pop    %ebp
f0103447:	c3                   	ret    
f0103448:	90                   	nop
f0103449:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103450:	89 d8                	mov    %ebx,%eax
f0103452:	f7 f7                	div    %edi
f0103454:	31 ff                	xor    %edi,%edi
f0103456:	89 c3                	mov    %eax,%ebx
f0103458:	89 d8                	mov    %ebx,%eax
f010345a:	89 fa                	mov    %edi,%edx
f010345c:	83 c4 1c             	add    $0x1c,%esp
f010345f:	5b                   	pop    %ebx
f0103460:	5e                   	pop    %esi
f0103461:	5f                   	pop    %edi
f0103462:	5d                   	pop    %ebp
f0103463:	c3                   	ret    
f0103464:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103468:	39 ce                	cmp    %ecx,%esi
f010346a:	72 0c                	jb     f0103478 <__udivdi3+0x118>
f010346c:	31 db                	xor    %ebx,%ebx
f010346e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103472:	0f 87 34 ff ff ff    	ja     f01033ac <__udivdi3+0x4c>
f0103478:	bb 01 00 00 00       	mov    $0x1,%ebx
f010347d:	e9 2a ff ff ff       	jmp    f01033ac <__udivdi3+0x4c>
f0103482:	66 90                	xchg   %ax,%ax
f0103484:	66 90                	xchg   %ax,%ax
f0103486:	66 90                	xchg   %ax,%ax
f0103488:	66 90                	xchg   %ax,%ax
f010348a:	66 90                	xchg   %ax,%ax
f010348c:	66 90                	xchg   %ax,%ax
f010348e:	66 90                	xchg   %ax,%ax

f0103490 <__umoddi3>:
f0103490:	55                   	push   %ebp
f0103491:	57                   	push   %edi
f0103492:	56                   	push   %esi
f0103493:	53                   	push   %ebx
f0103494:	83 ec 1c             	sub    $0x1c,%esp
f0103497:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010349b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010349f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01034a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034a7:	85 d2                	test   %edx,%edx
f01034a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01034ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01034b1:	89 f3                	mov    %esi,%ebx
f01034b3:	89 3c 24             	mov    %edi,(%esp)
f01034b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01034ba:	75 1c                	jne    f01034d8 <__umoddi3+0x48>
f01034bc:	39 f7                	cmp    %esi,%edi
f01034be:	76 50                	jbe    f0103510 <__umoddi3+0x80>
f01034c0:	89 c8                	mov    %ecx,%eax
f01034c2:	89 f2                	mov    %esi,%edx
f01034c4:	f7 f7                	div    %edi
f01034c6:	89 d0                	mov    %edx,%eax
f01034c8:	31 d2                	xor    %edx,%edx
f01034ca:	83 c4 1c             	add    $0x1c,%esp
f01034cd:	5b                   	pop    %ebx
f01034ce:	5e                   	pop    %esi
f01034cf:	5f                   	pop    %edi
f01034d0:	5d                   	pop    %ebp
f01034d1:	c3                   	ret    
f01034d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034d8:	39 f2                	cmp    %esi,%edx
f01034da:	89 d0                	mov    %edx,%eax
f01034dc:	77 52                	ja     f0103530 <__umoddi3+0xa0>
f01034de:	0f bd ea             	bsr    %edx,%ebp
f01034e1:	83 f5 1f             	xor    $0x1f,%ebp
f01034e4:	75 5a                	jne    f0103540 <__umoddi3+0xb0>
f01034e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01034ea:	0f 82 e0 00 00 00    	jb     f01035d0 <__umoddi3+0x140>
f01034f0:	39 0c 24             	cmp    %ecx,(%esp)
f01034f3:	0f 86 d7 00 00 00    	jbe    f01035d0 <__umoddi3+0x140>
f01034f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103501:	83 c4 1c             	add    $0x1c,%esp
f0103504:	5b                   	pop    %ebx
f0103505:	5e                   	pop    %esi
f0103506:	5f                   	pop    %edi
f0103507:	5d                   	pop    %ebp
f0103508:	c3                   	ret    
f0103509:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103510:	85 ff                	test   %edi,%edi
f0103512:	89 fd                	mov    %edi,%ebp
f0103514:	75 0b                	jne    f0103521 <__umoddi3+0x91>
f0103516:	b8 01 00 00 00       	mov    $0x1,%eax
f010351b:	31 d2                	xor    %edx,%edx
f010351d:	f7 f7                	div    %edi
f010351f:	89 c5                	mov    %eax,%ebp
f0103521:	89 f0                	mov    %esi,%eax
f0103523:	31 d2                	xor    %edx,%edx
f0103525:	f7 f5                	div    %ebp
f0103527:	89 c8                	mov    %ecx,%eax
f0103529:	f7 f5                	div    %ebp
f010352b:	89 d0                	mov    %edx,%eax
f010352d:	eb 99                	jmp    f01034c8 <__umoddi3+0x38>
f010352f:	90                   	nop
f0103530:	89 c8                	mov    %ecx,%eax
f0103532:	89 f2                	mov    %esi,%edx
f0103534:	83 c4 1c             	add    $0x1c,%esp
f0103537:	5b                   	pop    %ebx
f0103538:	5e                   	pop    %esi
f0103539:	5f                   	pop    %edi
f010353a:	5d                   	pop    %ebp
f010353b:	c3                   	ret    
f010353c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103540:	8b 34 24             	mov    (%esp),%esi
f0103543:	bf 20 00 00 00       	mov    $0x20,%edi
f0103548:	89 e9                	mov    %ebp,%ecx
f010354a:	29 ef                	sub    %ebp,%edi
f010354c:	d3 e0                	shl    %cl,%eax
f010354e:	89 f9                	mov    %edi,%ecx
f0103550:	89 f2                	mov    %esi,%edx
f0103552:	d3 ea                	shr    %cl,%edx
f0103554:	89 e9                	mov    %ebp,%ecx
f0103556:	09 c2                	or     %eax,%edx
f0103558:	89 d8                	mov    %ebx,%eax
f010355a:	89 14 24             	mov    %edx,(%esp)
f010355d:	89 f2                	mov    %esi,%edx
f010355f:	d3 e2                	shl    %cl,%edx
f0103561:	89 f9                	mov    %edi,%ecx
f0103563:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103567:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010356b:	d3 e8                	shr    %cl,%eax
f010356d:	89 e9                	mov    %ebp,%ecx
f010356f:	89 c6                	mov    %eax,%esi
f0103571:	d3 e3                	shl    %cl,%ebx
f0103573:	89 f9                	mov    %edi,%ecx
f0103575:	89 d0                	mov    %edx,%eax
f0103577:	d3 e8                	shr    %cl,%eax
f0103579:	89 e9                	mov    %ebp,%ecx
f010357b:	09 d8                	or     %ebx,%eax
f010357d:	89 d3                	mov    %edx,%ebx
f010357f:	89 f2                	mov    %esi,%edx
f0103581:	f7 34 24             	divl   (%esp)
f0103584:	89 d6                	mov    %edx,%esi
f0103586:	d3 e3                	shl    %cl,%ebx
f0103588:	f7 64 24 04          	mull   0x4(%esp)
f010358c:	39 d6                	cmp    %edx,%esi
f010358e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103592:	89 d1                	mov    %edx,%ecx
f0103594:	89 c3                	mov    %eax,%ebx
f0103596:	72 08                	jb     f01035a0 <__umoddi3+0x110>
f0103598:	75 11                	jne    f01035ab <__umoddi3+0x11b>
f010359a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010359e:	73 0b                	jae    f01035ab <__umoddi3+0x11b>
f01035a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01035a4:	1b 14 24             	sbb    (%esp),%edx
f01035a7:	89 d1                	mov    %edx,%ecx
f01035a9:	89 c3                	mov    %eax,%ebx
f01035ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01035af:	29 da                	sub    %ebx,%edx
f01035b1:	19 ce                	sbb    %ecx,%esi
f01035b3:	89 f9                	mov    %edi,%ecx
f01035b5:	89 f0                	mov    %esi,%eax
f01035b7:	d3 e0                	shl    %cl,%eax
f01035b9:	89 e9                	mov    %ebp,%ecx
f01035bb:	d3 ea                	shr    %cl,%edx
f01035bd:	89 e9                	mov    %ebp,%ecx
f01035bf:	d3 ee                	shr    %cl,%esi
f01035c1:	09 d0                	or     %edx,%eax
f01035c3:	89 f2                	mov    %esi,%edx
f01035c5:	83 c4 1c             	add    $0x1c,%esp
f01035c8:	5b                   	pop    %ebx
f01035c9:	5e                   	pop    %esi
f01035ca:	5f                   	pop    %edi
f01035cb:	5d                   	pop    %ebp
f01035cc:	c3                   	ret    
f01035cd:	8d 76 00             	lea    0x0(%esi),%esi
f01035d0:	29 f9                	sub    %edi,%ecx
f01035d2:	19 d6                	sbb    %edx,%esi
f01035d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035dc:	e9 18 ff ff ff       	jmp    f01034f9 <__umoddi3+0x69>
