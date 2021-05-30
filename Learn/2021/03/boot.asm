    app_lba_start equ 100   ;声明常数（用户程序起始逻辑扇区号）
                            ;常数不占用汇编地址

SECTION mbr align=16 vstart=0x7c00
    ;设置堆栈段和栈指针
    mov ax,0
    mov ss,ax
    mov sp,ax

    mov ax,[cs:phy_base]  ;计算段地址
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


;读取硬盘为两种模式
;1. chs
;2. lba
;使用28byte表示逻辑扇区号
;端口号为 0x1f3~0x1f6
;从低位与端口号对应
;0x1f2 端口号 决定读多少扇区数 1~255 如果是0代表读256个扇区
;扇区号 = 0000   0000 0000   0000 0000 0000 0000
;       |0x1f6| | 0x1f5 |   | 0x1f4 | | 0x1f3  |
;其中0x1f6位8位端口 低四位用来表示lba 27~24
;高四位的 第4位0表示主硬盘，1表示从硬盘
;第5，7位固定为1
;第6位 0表示CHS模式，1表示LBA模式
;0x1f7 为命令&状态端口 是一个8位的端口
;0x20表示读
;0x1f7的详细信息 https://blog.csdn.net/cosmoslife/article/details/9024659
;0x1f0为数据端口

read_hard_disk_0: ;从硬盘读取一个逻辑扇区
    push ax       ;输入 DI:SI=起始逻辑扇区号
    push bx       ;     DS:BX=目标缓冲区地址
    push cx
    push dx

    mov dx,0x1f2 ;0x1f2端口号为决定读取扇区数的
    mov al,1
    out dx,al ;读取扇区数

    inc dx    ;0x1f3端口
    mov ax,si
    out dx,al  ;LBA地址7~0

    inc dx      ;0x1f4端口:
    mov al,ah   ;LBA地址 8~15
    out dx,al

    inc dx      ;0x1f5端口
    mov ax,di   ;LAB地址 16~23
    out dx,al

    inc dx      ;0x1f6端口
    mov al,0xe0 ;看上边注释
    or al,ah
    out dx,al

    inc dx      ;0x1f7端口,设置为读
    mov al,0x20
    out dx,al

.waits:
    in al,dx    ;获取disk状态，直到硬盘准备就绪
    and al,0x88
    cmp al,0x08
    jnz .waits

    mov cx,256 ;一个扇区256个字 512个字节,每次读两个字节，1个字
    mov dx,0x1f0

.readw:
    in ax,dx  ;读完
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
