    org 07c00h	;告诉编译器程序会被加载到0x7c00h,这样就我们在使用，这样我们在mov ax,BootMessage　不用加上偏
    mov ax,cs
    mov ds,ax
    mov es,ax
    call DispStr
DispStr:
    mov ax,BootMessage
    mov bp,ax
    mov cx,16
    mov ax,01301h
    mov bx,000ch
    mov dl,0
    int 10h
    ret
BootMessage: db "Hello, OS World!"
times 510-($-$$) db 0
dw 0xaa55