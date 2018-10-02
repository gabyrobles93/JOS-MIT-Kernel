
obj/boot/boot.out:     formato del fichero elf32-i386


Desensamblado de la sección .text:

00007c00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7c00:	fa                   	cli    
  cld                         # String operations increment
    7c01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7c02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0e:	75 fa                	jne    7c0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c18:	75 fa                	jne    7c14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	64 7c 0f             	fs jl  7c33 <protcseg+0x1>
  movl    %cr0, %eax
    7c24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7c26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7c2d:	ea                   	.byte 0xea
    7c2e:	32 7c 08 00          	xor    0x0(%eax,%ecx,1),%bh

00007c32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7c32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7c3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7c3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call bootmain
    7c45:	e8 1f 01 00 00       	call   7d69 <bootmain>

00007c4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7c4a:	eb fe                	jmp    7c4a <spin>

00007c4c <gdt>:
	...
    7c54:	ff                   	(bad)  
    7c55:	ff 00                	incl   (%eax)
    7c57:	00 00                	add    %al,(%eax)
    7c59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c60:	00                   	.byte 0x0
    7c61:	92                   	xchg   %eax,%edx
    7c62:	cf                   	iret   
	...

00007c64 <gdtdesc>:
    7c64:	17                   	pop    %ss
    7c65:	00 4c 7c 00          	add    %cl,0x0(%esp,%edi,2)
	...

00007c6a <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
    7c6a:	55                   	push   %ebp
    7c6b:	89 c1                	mov    %eax,%ecx
    7c6d:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c6f:	89 ca                	mov    %ecx,%edx
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
    7c71:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c73:	ee                   	out    %al,(%dx)
}
    7c74:	5d                   	pop    %ebp
    7c75:	c3                   	ret    

00007c76 <outw.constprop.0>:
		     : "d" (port), "0" (addr), "1" (cnt)
		     : "cc");
}

static inline void
outw(int port, uint16_t data)
    7c76:	55                   	push   %ebp
{
	asm volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7c77:	ba 00 8a 00 00       	mov    $0x8a00,%edx
		     : "d" (port), "0" (addr), "1" (cnt)
		     : "cc");
}

static inline void
outw(int port, uint16_t data)
    7c7c:	89 e5                	mov    %esp,%ebp
{
	asm volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7c7e:	66 ef                	out    %ax,(%dx)
}
    7c80:	5d                   	pop    %ebp
    7c81:	c3                   	ret    

00007c82 <insl.constprop.1>:
	asm volatile("inl %w1,%0" : "=a" (data) : "d" (port));
	return data;
}

static inline void
insl(int port, void *addr, int cnt)
    7c82:	55                   	push   %ebp
{
	asm volatile("cld\n\trepne\n\tinsl"
    7c83:	b9 80 00 00 00       	mov    $0x80,%ecx
    7c88:	ba f0 01 00 00       	mov    $0x1f0,%edx
	asm volatile("inl %w1,%0" : "=a" (data) : "d" (port));
	return data;
}

static inline void
insl(int port, void *addr, int cnt)
    7c8d:	89 e5                	mov    %esp,%ebp
    7c8f:	57                   	push   %edi
{
	asm volatile("cld\n\trepne\n\tinsl"
    7c90:	89 c7                	mov    %eax,%edi
    7c92:	fc                   	cld    
    7c93:	f2 6d                	repnz insl (%dx),%es:(%edi)
		     : "=D" (addr), "=c" (cnt)
		     : "d" (port), "0" (addr), "1" (cnt)
		     : "memory", "cc");
}
    7c95:	5f                   	pop    %edi
    7c96:	5d                   	pop    %ebp
    7c97:	c3                   	ret    

00007c98 <inb.constprop.2>:
{
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
    7c98:	55                   	push   %ebp
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7c99:	ba f7 01 00 00       	mov    $0x1f7,%edx
{
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
    7c9e:	89 e5                	mov    %esp,%ebp
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7ca0:	ec                   	in     (%dx),%al
	return data;
}
    7ca1:	5d                   	pop    %ebp
    7ca2:	c3                   	ret    

00007ca3 <waitdisk>:
	}
}

void
waitdisk(void)
{
    7ca3:	55                   	push   %ebp
    7ca4:	89 e5                	mov    %esp,%ebp
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7ca6:	e8 ed ff ff ff       	call   7c98 <inb.constprop.2>
    7cab:	83 e0 c0             	and    $0xffffffc0,%eax
    7cae:	3c 40                	cmp    $0x40,%al
    7cb0:	75 f4                	jne    7ca6 <waitdisk+0x3>
		/* do nothing */;
}
    7cb2:	5d                   	pop    %ebp
    7cb3:	c3                   	ret    

00007cb4 <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7cb4:	55                   	push   %ebp
    7cb5:	89 e5                	mov    %esp,%ebp
    7cb7:	56                   	push   %esi
    7cb8:	53                   	push   %ebx
    7cb9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    7cbc:	8b 75 08             	mov    0x8(%ebp),%esi
	// wait for disk to be ready
	waitdisk();
    7cbf:	e8 df ff ff ff       	call   7ca3 <waitdisk>

	outb(0x1F2, 1);		// count = 1
    7cc4:	ba 01 00 00 00       	mov    $0x1,%edx
    7cc9:	b8 f2 01 00 00       	mov    $0x1f2,%eax
    7cce:	e8 97 ff ff ff       	call   7c6a <outb>
	outb(0x1F3, offset);
    7cd3:	0f b6 d3             	movzbl %bl,%edx
    7cd6:	b8 f3 01 00 00       	mov    $0x1f3,%eax
    7cdb:	e8 8a ff ff ff       	call   7c6a <outb>
	outb(0x1F4, offset >> 8);
    7ce0:	0f b6 d7             	movzbl %bh,%edx
    7ce3:	b8 f4 01 00 00       	mov    $0x1f4,%eax
    7ce8:	e8 7d ff ff ff       	call   7c6a <outb>
	outb(0x1F5, offset >> 16);
    7ced:	89 da                	mov    %ebx,%edx
	outb(0x1F6, (offset >> 24) | 0xE0);
    7cef:	c1 eb 18             	shr    $0x18,%ebx
	waitdisk();

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
    7cf2:	b8 f5 01 00 00       	mov    $0x1f5,%eax
    7cf7:	c1 ea 10             	shr    $0x10,%edx
	outb(0x1F6, (offset >> 24) | 0xE0);
    7cfa:	83 cb e0             	or     $0xffffffe0,%ebx
	waitdisk();

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
    7cfd:	0f b6 d2             	movzbl %dl,%edx
    7d00:	e8 65 ff ff ff       	call   7c6a <outb>
	outb(0x1F6, (offset >> 24) | 0xE0);
    7d05:	0f b6 d3             	movzbl %bl,%edx
    7d08:	b8 f6 01 00 00       	mov    $0x1f6,%eax
    7d0d:	e8 58 ff ff ff       	call   7c6a <outb>
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors
    7d12:	b8 f7 01 00 00       	mov    $0x1f7,%eax
    7d17:	ba 20 00 00 00       	mov    $0x20,%edx
    7d1c:	e8 49 ff ff ff       	call   7c6a <outb>

	// wait for disk to be ready
	waitdisk();
    7d21:	e8 7d ff ff ff       	call   7ca3 <waitdisk>

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7d26:	5b                   	pop    %ebx

	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
    7d27:	89 f0                	mov    %esi,%eax
}
    7d29:	5e                   	pop    %esi
    7d2a:	5d                   	pop    %ebp

	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
    7d2b:	e9 52 ff ff ff       	jmp    7c82 <insl.constprop.1>

00007d30 <readseg>:

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7d30:	55                   	push   %ebp
    7d31:	89 e5                	mov    %esp,%ebp
    7d33:	57                   	push   %edi
    7d34:	56                   	push   %esi

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7d35:	8b 7d 10             	mov    0x10(%ebp),%edi

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7d38:	53                   	push   %ebx
	uint32_t end_pa;

	end_pa = pa + count;
    7d39:	8b 75 0c             	mov    0xc(%ebp),%esi

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7d3c:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7d3f:	c1 ef 09             	shr    $0x9,%edi
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
	uint32_t end_pa;

	end_pa = pa + count;
    7d42:	01 de                	add    %ebx,%esi

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7d44:	47                   	inc    %edi
	uint32_t end_pa;

	end_pa = pa + count;

	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);
    7d45:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7d4b:	39 f3                	cmp    %esi,%ebx
    7d4d:	73 12                	jae    7d61 <readseg+0x31>
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7d4f:	57                   	push   %edi
    7d50:	53                   	push   %ebx
		pa += SECTSIZE;
		offset++;
    7d51:	47                   	inc    %edi
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
		pa += SECTSIZE;
    7d52:	81 c3 00 02 00 00    	add    $0x200,%ebx
	while (pa < end_pa) {
		// Since we haven't enabled paging yet and we're using
		// an identity segment mapping (see boot.S), we can
		// use physical addresses directly.  This won't be the
		// case once JOS enables the MMU.
		readsect((uint8_t*) pa, offset);
    7d58:	e8 57 ff ff ff       	call   7cb4 <readsect>
		pa += SECTSIZE;
		offset++;
    7d5d:	58                   	pop    %eax
    7d5e:	5a                   	pop    %edx
    7d5f:	eb ea                	jmp    7d4b <readseg+0x1b>
	}
}
    7d61:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d64:	5b                   	pop    %ebx
    7d65:	5e                   	pop    %esi
    7d66:	5f                   	pop    %edi
    7d67:	5d                   	pop    %ebp
    7d68:	c3                   	ret    

00007d69 <bootmain>:
void readsect(void*, uint32_t);
void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7d69:	55                   	push   %ebp
    7d6a:	89 e5                	mov    %esp,%ebp
    7d6c:	56                   	push   %esi
    7d6d:	53                   	push   %ebx
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7d6e:	6a 00                	push   $0x0
    7d70:	68 00 10 00 00       	push   $0x1000
    7d75:	68 00 00 01 00       	push   $0x10000
    7d7a:	e8 b1 ff ff ff       	call   7d30 <readseg>

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7d7f:	83 c4 0c             	add    $0xc,%esp
    7d82:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d89:	45 4c 46 
    7d8c:	75 37                	jne    7dc5 <bootmain+0x5c>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d8e:	a1 1c 00 01 00       	mov    0x1001c,%eax
	eph = ph + ELFHDR->e_phnum;
    7d93:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d9a:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx
	eph = ph + ELFHDR->e_phnum;
    7da0:	c1 e6 05             	shl    $0x5,%esi
    7da3:	01 de                	add    %ebx,%esi
	for (; ph < eph; ph++)
    7da5:	39 f3                	cmp    %esi,%ebx
    7da7:	73 16                	jae    7dbf <bootmain+0x56>
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7da9:	ff 73 04             	pushl  0x4(%ebx)
    7dac:	ff 73 14             	pushl  0x14(%ebx)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7daf:	83 c3 20             	add    $0x20,%ebx
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7db2:	ff 73 ec             	pushl  -0x14(%ebx)
    7db5:	e8 76 ff ff ff       	call   7d30 <readseg>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7dba:	83 c4 0c             	add    $0xc,%esp
    7dbd:	eb e6                	jmp    7da5 <bootmain+0x3c>
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!
	((void (*)(void)) (ELFHDR->e_entry))();
    7dbf:	ff 15 18 00 01 00    	call   *0x10018

bad:
	outw(0x8A00, 0x8A00);
    7dc5:	b8 00 8a 00 00       	mov    $0x8a00,%eax
    7dca:	e8 a7 fe ff ff       	call   7c76 <outw.constprop.0>
	outw(0x8A00, 0x8E00);
    7dcf:	b8 00 8e 00 00       	mov    $0x8e00,%eax
    7dd4:	e8 9d fe ff ff       	call   7c76 <outw.constprop.0>
    7dd9:	eb fe                	jmp    7dd9 <bootmain+0x70>
