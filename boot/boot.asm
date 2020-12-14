org 07c00h

BootMessage_Length equ BootTail - BootMessage
setup_start_sector equ 0x00000001
setup_base_address equ 0x00007E00   ;常数，内核加载的起始内存地址 

    ; 清屏
	mov	ax, 0600h		; AH = 6,  AL = 0h
	mov	bx, 0700h		; 黑底白字(BL = 07h)
	mov	cx, 0			; 左上角: (0, 0)
	mov	dx, 0184fh		; 右下角: (80, 50)
	int	10h			; int 10h
    ;设置光标的位置为0行 0列
    mov ah,0x02
    mov bh,0x00
    mov dh,0x00
    mov dl,0x00
    int 10h
    mov ax,BootMessage
    mov bx,BootTail-BootMessage
    call DispStr
    ;读取setup模块
    ;设置加到内存的那个位置
    mov ax,0
    mov es,ax
    mov bx,setup_base_address
    ;设置读取扇区数
    mov al,0x01
    ;设置柱面
    mov ch,0x00
    ;设置扇区
    mov cl,0x01
    mov dh,0x00
    mov dl,80h
    int 0x13
    mov ax,0x02
    jmp $

;读取setup
;-------------------------------------------------------------------------------
; 函数 read_hard_disk_0
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

;----------------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
;参数ax 字符串
;参数bx 字符串长度
DispStr:
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, bx	; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	int	10h			; int 10h
	ret
BootMessage:		db	"Ya OS loading,please wait for minutes"
BootTail:   
    times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
    db 0x55,0xaa
;end of [section .s32]

