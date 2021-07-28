         ;文件名：c13_mbr0.asm
         ;文件说明：硬盘主引导扇区代码 
%include "pm.inc"
;-------------------------------------------------------------------------------
         core_base_address equ 0x00040000   ;常数，内核加载的起始内存地址 
         core_start_sector equ 0x00000001   ;常数，内核的起始逻辑扇区号

jmp LABEL_BEGIN
;GDT Begin                            段基址          段界限            属性
LABEL_GDT:             Descriptor          0,              0,              0           ;空描述符 
LABEL_DESC_CODE:       Descriptor    0x7c00,         0x01FF,         DA_C+DA_32
LABEL_DESC_DATA:       Descriptor    0x7c00,        0xFFFFF,         DA_DRW+DA_4K+DA_32     ;粒度为4K，存储器描述符
LABEL_DESC_STACK:      Descriptor    0x7c00,        0xFFFFE,         DA_4K+DA_DRWB+DA_32   
LABEL_DESC_VIDEO:      Descriptor   0xb8000,        0x07FFF,         DA_DRW+DA_32 
LABEL_DESC_TEST:       Descriptor  0x300000,         0xffff,         DA_DRW
;GDT End
GtdLen  equ $ - LABEL_GDT
GdtPtr  dw GtdLen - 1
        dd 0
;GDT 选择子
SelectorCode                  equ                         LABEL_DESC_CODE   - LABEL_GDT 
SelectorData                  equ                         LABEL_DESC_DATA   - LABEL_GDT                                                      
SelectorStack                 equ                         LABEL_DESC_STACK  - LABEL_GDT                          
SelectorVideo                 equ                         LABEL_DESC_VIDEO  - LABEL_GDT                    
SelectorTest                  equ                         LABEL_DESC_TEST   - LABEL_GDT                      
;
LABEL_DATA:
PMMessage:                    db      "In Protect Mode now. ^_^",0
StrTest:                      db      "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0
OffsetStrTest                 equ     StrTest - $$
DataLen                       equ     $ - LABEL_DATA
LABEL_BEGIN:
;-------------------------------------------------------------------------------         
        ;保护模式下清屏幕
         mov ah,0x06
         mov al,0
         mov cx,0
         mov dx,0xffff
         mov bh,0x07
         int 0x10
        ;设置GDT的基地址和界限 
         xor eax,eax
         mov ax,0x7c00
         add eax,LABEL_GDT
         mov [cs:GdtPtr+0x7c00+2],eax
         lgdt [cs: GdtPtr+0x7c00]
      
         in al,0x92                         ;南桥芯片内的端口 
         or al,0000_0010B
         out 0x92,al                        ;打开A20

         cli                                ;中断机制尚未工作

         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;设置PE位
      
         ;以下进入保护模式... ...
         jmp SelectorCode:flush                   ;清流水线并串行化处理器

         [bits 32]               
  flush:                                  
        mov ax,SelectorData
        mov ds,ax
        mov ax,SelectorVideo
        mov gs,ax
        mov ax,SelectorTest
        mov es,ax
        ;下面显示一个字符串
        mov ah,0Ch
        xor esi, esi
        xor edi, edi
        mov esi, PMMessage
        mov edi, 0
    .1:
       lodsb
       test al, al
       jz   .2
       mov [gs:edi], ax
       add edi, 2
       jmp .1
    .2:
      call DispReturn

      call TestRead
      call TestWrite
      call TestRead

      jmp $
      
;-------------------------------------------------------------------------------
TestRead:
      xor esi, esi
      mov ecx, 8

.loop:
    mov al, [es:esi]
    call DispAL
    inc esi
    loop .loop
    
    call DispReturn
    ret

;-------------------------------------------------------------------------------
TestWrite:
    push esi
    push edi
    xor esi, esi
    xor edi, edi
    mov esi, OffsetStrTest
    cld

.1:
    lodsb
    test al,al
    jz  .2
    mov [es:edi], al
    inc edi
    jmp .1
.2:
    pop edi
    pop esi
    ret
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;从硬盘读取一个逻辑扇区
                                         ;EAX=逻辑扇区号
                                         ;DS:EBX=目标缓冲区地址
                                         ;返回：EBX=EBX+512 
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                       ;读取的扇区数

         inc dx                          ;0x1f3
         pop eax
         out dx,al                       ;LBA地址7~0

         inc dx                          ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                       ;LBA地址15~8

         inc dx                          ;0x1f5
         shr eax,cl
         out dx,al                       ;LBA地址23~16

         inc dx                          ;0x1f6
         shr eax,cl
         or al,0xe0                      ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                     ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
         ret

;-------------------------------------------------------------------------------
;显示AL中的数字
;默认地：
;  数字已经存在AL中
;  edi 始终指向要显示的下一个字符的位置
; 被改变的寄存器
;     ax,edi
DispAL:
    push ecx
    push edx

    mov ah, 0Ch
    mov dl, al
    shr al,4
    mov ecx, 2
.begin:
    and al, 01111b
    cmp al, 9
    jz  .1
    add al, '0'
    jmp .2
.1:
    sub al, 0Ah
    add al, 'A'
.2:
    mov [gs:edi], ax
    add edi, 2

    mov al, dl
    loop .begin
    add edi, 2

    pop edx
    pop ecx
    ret
;-------------------------------------------------------------------------------
DispReturn:
    push eax
    push ebx
    mov eax, edi
    mov bl, 160
    div bl
    and eax, 0FFh
    inc eax
    mov bl, 160
    mul bl
    mov edi, eax
    pop ebx
    pop eax

    ret
;-------------------------------------------------------------------------------
make_gdt_descriptor:                     ;构造描述符
                                         ;输入：EAX=线性基地址
                                         ;      EBX=段界限
                                         ;      ECX=属性（各属性位都在原始
                                         ;      位置，其它没用到的位置0） 
                                         ;返回：EDX:EAX=完整的描述符
         mov edx,eax
         shl eax,16                     
         or ax,bx                        ;描述符前32位(EAX)构造完毕
      
         and edx,0xffff0000              ;清除基地址中无关的位
         rol edx,8
         bswap edx                       ;装配基址的31~24和23~16  (80486+)
      
         xor bx,bx
         or edx,ebx                      ;装配段界限的高4位
      
         or edx,ecx                      ;装配属性 
      
         ret
      
;-------------------------------------------------------------------------------
         pgdt             dw 0
                          dd 0x00007e00      ;GDT的物理地址
;-------------------------------------------------------------------------------                             
         times 510-($-$$) db 0
                          db 0x55,0xaa

