    org   0x7c00            ;告诉编译器程序加载到7c00
    mov   ax, cs            ;cs 的段地址为0x0000
    mov   ds, ax            ;设置ds为段地址
    mov   es, ax            ;设置es寄存器为段地址
    call  DispStr
    jmp   $
DispStr:
    mov ax, BootMessage     ;ES:BP 串地址
    mov bp, ax              ;CX=串长度
    mov cx, 16              ;AH=13,AL=01H
    mov ax, 01301h          ;页号为0(BH=0),黑底红字(BL=0CH,高亮)
    mov bx, 000ch
    mov dl, 0
    int 10h                 ;调用bios 10号中断
    ret
BootMessage:    db    "Hello, OS world!"
times 510 - ($-$$)    db 0  
dw  0xaa55

#bios中断
#https://blog.csdn.net/liguodong86/article/details/3973337

