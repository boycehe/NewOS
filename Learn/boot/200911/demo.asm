	jmp start
messge db '1+2+3+...+100='

start:
		mov ax,0x7c0
		mov ds,ax
		mov ax,0xb800
		mov es,ax
		mov si,messge
		mov di,0
		mov cx,start-messge
showmsg:
		mov al,[si]
		mov [es:di],al
		inc di
		mov byte [es:di],0x07
		inc di
		inc si
		loop showmsg
		
		xor ax,ax
		mov cx,1
summate:
		add ax,cx
		inc cx
		cmp cx,100
		jle summate
		
		xor cx,cx
		mov ss,cx
		mov sp,cx
		mov bx,10
		xor cx,cx
decompo:
		inc cx
		xor dx,dx
		div bx
		add dl,0x30
		push dx
		cmp ax,0
		jne decompo
shownum:
		pop dx
		mov [es:di],dl
		inc di
		mov byte [es:di],0x07
		inc di
		loop shownum
		
		jmp $
		
		times 510-($-$$) db 0
		db 0x55,0xaa