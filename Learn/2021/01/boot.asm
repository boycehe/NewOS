    org 07c00h	;告诉编译器程序会被加载到0x7c00h,这样就我们在使用，这样我们在mov ax,BootMessage　不用加上偏
    mov ax,cs
    mov ds,ax
    mov es,ax
    call ClearDisp
    mov ax,TipMesssage
    mov dh,0
    mov dl,0
    mov cx,BootMessage - TipMesssage
    call DispStr
    mov ax,BootMessage
    mov dh,0
    mov dl,BootMessage - TipMesssage + 1
    mov cx,EndMessage - BootMessage
    call DispStr
    call ReverseSentence
    mov ax,BootMessage
    mov dh,1
    mov dl,0
    mov cx,EndMessage - BootMessage
    call DispStr
    jmp $
ReverseSentence:
    mov bx,BootMessage
    mov di,0
    mov si,EndMessage-BootMessage-1
Reverse:
    mov al,[bx+di]
    mov ah,[bx+si]
    mov [bx+di],ah
    mov [bx+si],al
    inc di
    dec si
    cmp di,si
    jl Reverse
    ret
ClearDisp:
    mov ah,0x06
    mov al,0
    mov ch,0 ;(0,0)
    mov cl,0
    mov dh,24 ;(24,79)
    mov dl,79
    mov bh,0x07 ;黑底白字
    int 0x10
    ret
DispStr:
    mov bp,ax
    mov ax,01301h
    mov bx,000ch
    int 10h
    ret
TipMesssage: db "Reverse Sentence:"
BootMessage: db "Hello OS World!"
EndMessage:db ""
times 510-($-$$) db 0
dw 0xaa55