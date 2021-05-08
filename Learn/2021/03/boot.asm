    app_lba_start equ 100   ;声明常数（用户程序起始逻辑扇区号）
                            ;常数不占用汇编地址

SECTION mbr align=16 vstart=0x7c00
    ;设置堆栈段和栈指针
    mov ax,0
    mov ss,ax
    mov sp,ax

    mov ax,[cs:phy_base]
    mov dx,[cs:phy_base+0x02]
    mov bx,16
    div bx
    mov ds,ax
    mov es,ax

    ;以下读取程序起始部分
    xor di,di
    mov si,app_lba_start
    xor bx,bx
    call read_hard_disk_0

    ;以下判断程序有多大
    mov dx,[2]
    mov ax,[0]
    mov bx,512
    div bx
    cmp dx,0
    jnz @1
    dec ax

@1:
    cmp ax,0  ;考虑实际长度可能小于512字节为边界的段地址
    jz direct

    ;读取剩余扇区
    push ds   ;下边要用到并改变ds寄存器
    mov cx,ax ;循环次数

@2:
    mov ax,ds
    add ax,0x20 ;得到下一个以512字节为边界的段地址
    mov ds,ax

    xor bx,bx   
    inc si
    call read_hard_disk_0
    loop @2

    pop ds

;计算入库代码基址
direct:
    mov dx,[0x08]
    mov ax,[0x06]
    call calc_segment_base
    mov [0x06],ax

    mov cx,[0x0a]
    mov bx,0x0c

realloc:
    mov dx,[bx+0x02]
    mov ax,[bx]
    call calc_segment_base
    mov [bx],ax
    add bx,4
    loop realloc

    jmp far [0x04]

read_hard_disk_0:
    push ax
    push bx
    push cx
    push dx

    mov dx,0x1f2
    mov al,1
    out dx,al ;读取扇区数

    inc dx
    mov ax,si
    out dx,al  ;LBA地址7~0

    inc dx
    mov al,ah
    out dx,al

    inc dx
    mov ax,di
    out dx,al

    inc dx
    mov al,0xe0
    or al,ah
    out dx,al

    inc dx
    mov al,0x20
    out dx,al

.waits:
    in al,dx
    and al,0x88
    cmp al,0x88
    jnz .waits

    mov cx,256
    mov dx,0x1f0

.readw:
    in ax,dx
    mov [bx],ax
    add bx,2
    loop  .readw

    pop dx
    pop cx
    pop bx
    pop ax

    ret

calc_segment_base:
    push  dx

    add ax,[cs:phy_base]
    add dx,[cs:phy_base+0x02]
    shr ax,4
    ror dx,4
    and dx,0xf000
    or ax,dx

    pop dx

    ret

    phy_base dd 0x10000 ;用户程序被加载的物理起始地址

times 510-($-$$) db 0
                 dw 0xaa55
