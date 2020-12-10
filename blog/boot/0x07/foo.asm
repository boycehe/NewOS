; 编译链接方法
; nasm -f elf -g -F dwarf -o foo.o foo.asm
; gcc -m32 -c -g -o bar.o bar.c
; ld -m elf_i386 -o foobar foo.o bar.o
;
;
;
;

extern choose	; int choose(int a, int b);

[section .data]	; 数据在此

num1st		dd	9
num2nd		dd	4
message db '0123456789'

[section .text]	; 代码在此

global _start	; 我们必须导出 _start 这个入口，以便让链接器识别。
global myprint	; 导出这个函数为了让 bar.c 使用


_start:
	xor eax,eax
	xor edx,edx
	push	dword [num2nd]	; `.
	push	dword [num1st]	;  |
	call	choose		;  | choose(num1st, num2nd);
	add	esp, 8		; /
	xor si,si
showNumber:
	xor edx,edx	
	mov ebx,10
	div ebx
	push eax
	add edx,message
	mov ecx,edx
	mov edx,1
	mov ebx,1
	mov eax,4
	int 0x80
	
	pop eax
	mov ecx,eax
	xor edx,edx
	or ecx,0
	jnz showNumber
	add edx,10
	mov ecx,edx
	mov edx,1
	mov ebx,1
	mov eax,4
	int 0x80

	mov	ebx, 0
	mov	eax, 1		; sys_exit
	int	0x80		; 系统调用

; void myprint(char* msg, int len)
myprint:
	mov	edx, [esp + 8]	; len
	mov	ecx, [esp + 4]	; msg
	mov	ebx, 1
	mov	eax, 4		; sys_write
	int	0x80		; 系统调用
	ret
	
