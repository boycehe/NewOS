%include "pm.inc" ;常量，宏

[SECTION .gdt]
;GDT
;                                       段基地址      段界限          属性
LABEL_GDT:            Descriptor        0,                 0,                0      ;空描述符
LABEL_DESC_NORMAL:    Descriptor        0,            0ffffh,           DA_DRW      ;Normal 描述符
LABEL_DESC_CODE32:    Descriptor        0,  SegCode32Len - 1,     DA_C + DA_32      ;非一致代码段 32
LABEL_DESC_CODE16:    Descriptor        0,            0ffffh,             DA_C      ;非一致代码段 16
LABEL_DESC_DATA:      Descriptor        0,        DataLen -1,           DA_DRW      ;Data
LABEL_DESC_STACK:     Descriptor        0,        TopOfStack,    DA_DRWA+DA_32      ;Stack,32位
LABEL_DESC_TEST:      Descriptor 0500000h,            0ffffh,           DA_DRW      ;
LABEL_DESC_VIDEO:     Descriptor  0B8000h,            0ffffh,           DA_DRW      ;显存首地址

;GDT 结束

GdtLen    equ       $ - LABEL_GDT       ;GDT长度
GdtPtr    dw        GdtLen - 1          ;GDT界限
          dd        0                   ;GDT基地址

;GDT选择子 虽然SelectorCode32是第一个选择子，但是他的值为8主要是因为选择子最后两位是表明这个选择子的优先级
;倒数第三位表示是GDT的选择子还是LDT的选择子
SelectorNormal      equ       LABEL_DESC_NORMAL   -   LABEL_GDT
SelectorCode32      equ       LABEL_DESC_CODE32   -   LABEL_GDT
SelectorCode16      equ       LABEL_DESC_CODE16   -   LABEL_GDT
SelectorData        equ       LABEL_DESC_DATA     -   LABEL_GDT
SelectorStack       equ       LABEL_DESC_STACK    -   LABEL_GDT
SelectorTest        equ       LABEL_DESC_TEST     -   LABEL_GDT
SelectorVideo       equ       LABEL_DESC_VIDEO    -   LABEL_GDT
;END of [SECTION .gdt]

[SECTION .data1]    ;数据段
ALIGN 32
[BITS 32]
LABEL_DATA:
SPValueInRealMode         dw              0
;字符串
PMMessage:                db              "In Protect Mode now. ^_^",0
OffsetPMMessage:          equ             PMMessage - $$
StrTest:                  db              "ABCDEFGHIJKLMNOPQRSTUVWXYZ",0
OffsetStrTest:            equ             StrTest - $$
DataLen:                  equ             $ - LABEL_DATA
;END of [SECTION .data1]


;全局堆栈段
[SECTION .gs]
ALIGN   32
[BITS 32]
LABEL_STACK:
    times 512 db 0

TopOfStack            equ         $ - LABEL_STACK - 1

;END of [SECTION .gs]


[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov   ax, cs
    mov   ds, ax
    mov   es, ax
    mov   ss, ax
    mov   sp, 0100h ;设置栈

    mov [LABEL_GO_BACK_TO_REAL+3], ax
    mov [SPValueInRealMode], sp

    ;初始化16位代码段描述符
    mov ax, cs
    movzx eax, ax
    shl eax, 4
    add eax, LABEL_SEG_CODE16
    mov word [LABEL_SEG_CODE16 + 2], ax
    shr eax, 16
    add byte [LABEL_SEG_CODE16 + 4], al
    add byte [LABEL_SEG_CODE16 + 7], ah

    ;初始化32位代码段描述符
    xor   eax,  eax ;eax置位0
    mov   ax,   cs
    shl   eax,  4
    add   eax,  LABEL_SEG_CODE32
    mov   word  [LABEL_DESC_CODE32 + 2], ax   ;设置段界限
    shr   eax,  16
    mov   byte  [LABEL_DESC_CODE32 + 4], al   ;设置段基址
    mov   byte  [LABEL_DESC_CODE32 + 7], ah   

    ;初始化数据段描述符
    
    xor   eax,  eax ;eax置位0
    mov   ax,   ds
    shl   eax,  4
    add   eax,  LABEL_DATA
    mov   word  [LABEL_DESC_DATA + 2], ax   ;设置段界限
    shr   eax,  16
    mov   byte  [LABEL_DESC_DATA + 4], al   ;设置段基址
    mov   byte  [LABEL_DESC_DATA + 7], ah   

    ;初始化堆栈段段描述符
    xor   eax,  eax ;eax置位0
    mov   ax,   ds
    shl   eax,  4
    add   eax,  LABEL_STACK
    mov   word  [LABEL_DESC_STACK + 2], ax   ;设置段界限
    shr   eax,  16
    mov   byte  [LABEL_DESC_STACK + 4], al   ;设置段基址
    mov   byte  [LABEL_DESC_STACK + 7], ah   


    ;为加载GDTR作准备
    xor   eax,  eax
    mov   ax,   ds
    shl   eax,  4
    add   eax,  LABEL_GDT           ;更新段 基地址
    mov   dword   [GdtPtr + 2], eax ;[GdtPtr+2] <- gdt 基地址
  
    ;加载GDTR
    lgdt  [GdtPtr]

    ;关中断

    cli

    ;打开A20
    in    al, 92h
    or    al, 00000010b
    out   92h, al

    ;准备切换到保护模式
    mov   eax,  cr0
    or    eax,  1
    mov   cr0,  eax

    ;真正进入保护模式 66ea000000000800
    jmp dword SelectorCode32:0


LABEL_REAL_ENTRY:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, [SPValueInRealMode]

    in al, 92h
    and al, 11111101b; 关闭A20地址线
    out 92h, al
    
    sti

    mov ax, 4c00h
    int 21        ;回到dos

[SECTION .s32]
[BITS 32]

LABEL_SEG_CODE32:
    mov   ax, SelectorData
    mov   ds, ax

    mov   ax, SelectorTest
    mov   es, ax

    mov   ax, SelectorVideo
    mov   gs, ax

    mov   ax, SelectorStack
    mov   ss, ax

    mov  esp, TopOfStack

    ;下面显示一个字符串
    mov ah, 0Ch
    xor esi, esi
    xor edi, edi
    mov esi, OffsetPMMessage;源数据偏移
    mov   edi,(80*11+79)*2
    cld
  .1:
    lodsb
    test  al, al
    jz  .2
    mov   [gs:edi], ax
    add edi, 2

    jmp .1
  .2:
    call DispReturn

    ret

TestWrite:
    push esi
    push edi
    xor esi, esi
    xor edi, edi
    mov esi, OffsetStrTest
    cld
.1:
    lodsb
    test  al, al
    jz .2
    mov [es:edi],al
    inc edi
    jmp .1
.2:
    pop edi
    pop esi

    ret
  
;---------------------------------------------
;显示AL中的数字
;默认地：
;数字已经存在AL中
;edi始终指向要显示的下一个字符的位置
;被改变的寄存器：
;ax, edi
;--------------------------------------------

DispAL:
  push ecx
  push edx

  mov ah, 0Ch
  mov dl, al
  shr al, 4
  mov ecx, 2
.begin:
  and al, 01111b
  cmp al, 9
  ja .1
  add al, '0'
  jmp .2
.1:
  sub al, 0Ah
  add al, 'A'
.2:
  mov [gs:edi],ax
  add edi, 2

  mov al, dl
  loop .begin
  add edi, 2

  pop edx
  pop ecx

  ret


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

SegCode32Len    equ     $ - LABEL_SEG_CODE32

;16位代码段，由32位代码段跳入，跳出后到实模式
[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
  ;跳回实模式
  mov ax, SelectorNormal
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax
  mov ss, ax
  
  mov eax, cr0
  and al, 11111110b
  mov cr0,eax


LABEL_GO_BACK_TO_REAL:
  jmp 0:LABEL_REAL_ENTRY

Code16Len equ $ - LABEL_SEG_CODE16

