%include "pm.inc" ;常量，宏

org   0x100
jmp   LABEL_BEGIN

[SECTION .gdt]
;GDT
;                                       段基地址      段界限          属性
LABEL_GDT:            Descriptor        0,                 0,                0      ;空描述符
LABEL_DESC_CODE32:    Descriptor        0,  SegCode32Len - 1,     DA_C + DA_32      ;非一致代码段
LABEL_DESC_VIDEO:     Descriptor  0B8000h,            0ffffh,           DA_DRW      ;显存首地址
;GDT 结束

GdtLen    equ       $ - LABEL_GDT       ;GDT长度
GdtPtr    dw        GdtLen - 1          ;GDT界限
          dd        0                   ;GDT基地址

;GDT选择子 虽然SelectorCode32是第一个选择子，但是他的值为8主要是因为选择子最后两位是表明这个选择子的优先级
;倒数第三位表示是GDT的选择子还是LDT的选择子
SelectorCode32      equ       LABEL_DESC_CODE32   -   LABEL_GDT
SelectorVideo       equ       LABEL_DESC_VIDEO    -   LABEL_GDT
;

[SECTION .a16]
[BITS 16]
LABEL_BEGIN:
    mov   ax, cs
    mov   ds, ax
    mov   es, ax
    mov   ss, ax
    mov   sp, 0100h ;设置栈

    ;初始化32位代码段描述符
    xor   eax,  eax ;eax置位0
    mov   ax,   cs
    shl   eax,  4
    add   eax,  LABEL_SEG_CODE32
    mov   word  [LABEL_DESC_CODE32 + 2], ax   ;设置段界限
    shr   eax,  16
    mov   byte  [LABEL_DESC_CODE32 + 4], al   ;设置段基址
    mov   byte  [LABEL_DESC_CODE32 + 7], ah   

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


[SECTION .s32]
[BITS 32]

LABEL_SEG_CODE32:
    mov   ax, SelectorVideo
    mov   gs, ax

    mov   edi,(80*11+79)*2
    mov   ah, 0Ch
    mov   al, 'P'
    mov   [gs:edi], ax

    jmp $

SegCode32Len    equ     $ - LABEL_SEG_CODE32

