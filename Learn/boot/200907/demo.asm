		jmp start
mytext 	db 'L',0x07,'a',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,'o',0x07
		db 'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
start:
		mov ax,0x7c0 ;设置数据段基址
		mov ds,ax
	
		mov ax,0xb800 ;设置附加段基地址
		mov es,ax
	
		cld
		mov si,mytext
		mov di,0
		mov cx,(start-mytext)/2
		rep movsw
		mov ax,number
		mov bx,ax
		mov cx,5
		mov si,10
		
digit:
		xor dx,dx
		div si
		mov [bx],dl
		inc bx
		loop digit
		
		jmp $
number db 0,0,0,0,0
		times 510-($-$$) db 0 ;$$代表段的起始地址，$代表当前的地址
		db 0x55,0xaa
	