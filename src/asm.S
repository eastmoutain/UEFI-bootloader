
#define DATA_SELECTOR 0x18
#define CODE_SELECTOR 0x20

#define FUNCTION(x) .global x; .type x,STT_FUNC; x:
#define X86_MSR_EFER 0xc0000080

.section .text, "ax", @progbits

// debub code to print 234 to COM port
// // set com port
//    movw  $0x3f8, %dx
//    // \r\n
//    movb $(0x0a), %al
//    outb %al, %dx
//    movb $(0x0d), %al
//    outb %al, %dx
//
//    movb $(0x33), %al
//    outb %al, %dx
//    movb $(0x34), %al
//    outb %al, %dx
//    movb $(0x35), %al
//    outb %al, %dx
//
//    // \r\n
//    movb $(0x0a), %al
//    outb %al, %dx
//    movb $(0x0d), %al
//    outb %al, %dx
//loop3:
//    jmp loop3

.code64
// 1. change to compatble mode
// 2. load legacy page table
// 3. change to legacy mode
// 4. jump to kernel
// void jump_to_legacy_kernel(void *entry, void *bootdata)
FUNCTION(jump_to_legacy_kernel)
	cli

    mov $DATA_SELECTOR, %eax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
	movw %ax, %ss


    push  $CODE_SELECTOR
	lea  3(%rip), %rax
    //push  $compatble_entry
	push %rax
    lretq


.code32
compatble_entry:
;FUNCTION(compatble_entry)
    // disable PG
    mov %cr0,  %eax
    btcl $(31), %eax
    //addl %eax, $0x7fffffff
    mov %eax, %cr0

    // disable EFER.LME(10)
    movl $X86_MSR_EFER ,%ecx
    rdmsr
    btcl $(8), %eax
    //orl $x86_EFER_LME,%eax
    wrmsr

    // disable PAE
    mov %cr4, %eax
    btcl $(5), %eax
    mov %eax, %cr4

    mov %edi, %eax
    mov %esi, %edi

    push %eax
    ret
    jmp *(%eax)

noret:
    hlt
    jmp noret

