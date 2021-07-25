         ;�ļ�����c13_mbr0.asm
         ;�ļ�˵����Ӳ���������������� 
%include "pm.inc"
;-------------------------------------------------------------------------------
         core_base_address equ 0x00040000   ;�������ں˼��ص���ʼ�ڴ��ַ 
         core_start_sector equ 0x00000001   ;�������ں˵���ʼ�߼�������

jmp LABEL_BEGIN
;GDT Begin                            �λ�ַ          �ν���            ����
LABEL_GDT:             Descriptor          0,              0,              0           ;�������� 
LABEL_DESC_CODE:       Descriptor    0x7c00,         0x01FF,         DA_C+DA_32
LABEL_DESC_DATA:       Descriptor    0x7c00,        0xFFFFF,         DA_DRW+DA_4K+DA_32     ;����Ϊ4K���洢��������
LABEL_DESC_STACK:      Descriptor    0x7c00,        0xFFFFE,         DA_4K+DA_DRWB+DA_32   
LABEL_DESC_VIDEO:      Descriptor   0xb8000,        0x07FFF,         DA_DRW+DA_32 
LABEL_DESC_TEST:       Descriptor  0x300000,         0xffff,         DA_DRW
;GDT End
GtdLen  equ $ - LABEL_GDT
GdtPtr  dw GtdLen - 1
        dd 0
;GDT ѡ����
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
        ;����ģʽ������Ļ
         mov ah,0x06
         mov al,0
         mov cx,0
         mov dx,0xffff
         mov bh,0x07
         int 0x10
        ;����GDT�Ļ���ַ�ͽ��� 
         xor eax,eax
         mov ax,0x7c00
         add eax,LABEL_GDT
         mov [cs:GdtPtr+0x7c00+2],eax
         lgdt [cs: GdtPtr+0x7c00]
      
         in al,0x92                         ;����оƬ�ڵĶ˿� 
         or al,0000_0010B
         out 0x92,al                        ;��A20

         cli                                ;�жϻ�����δ����

         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;����PEλ
      
         ;���½��뱣��ģʽ... ...
         jmp SelectorCode:flush                   ;����ˮ�߲����л�������

         [bits 32]               
  flush:                                  
        mov ax,SelectorData
        mov ds,ax
        mov ax,SelectorVideo
        mov gs,ax
        mov ax,SelectorTest
        mov es,ax
        ;������ʾһ���ַ���
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
read_hard_disk_0:                        ;��Ӳ�̶�ȡһ���߼�����
                                         ;EAX=�߼�������
                                         ;DS:EBX=Ŀ�껺������ַ
                                         ;���أ�EBX=EBX+512 
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                       ;��ȡ��������

         inc dx                          ;0x1f3
         pop eax
         out dx,al                       ;LBA��ַ7~0

         inc dx                          ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                       ;LBA��ַ15~8

         inc dx                          ;0x1f5
         shr eax,cl
         out dx,al                       ;LBA��ַ23~16

         inc dx                          ;0x1f6
         shr eax,cl
         or al,0xe0                      ;��һӲ��  LBA��ַ27~24
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;������
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;��æ����Ӳ����׼�������ݴ��� 

         mov ecx,256                     ;�ܹ�Ҫ��ȡ������
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
;��ʾAL�е�����
;Ĭ�ϵأ�
;  �����Ѿ�����AL��
;  edi ʼ��ָ��Ҫ��ʾ����һ���ַ���λ��
; ���ı�ļĴ���
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
make_gdt_descriptor:                     ;����������
                                         ;���룺EAX=���Ի���ַ
                                         ;      EBX=�ν���
                                         ;      ECX=���ԣ�������λ����ԭʼ
                                         ;      λ�ã�����û�õ���λ��0�� 
                                         ;���أ�EDX:EAX=������������
         mov edx,eax
         shl eax,16                     
         or ax,bx                        ;������ǰ32λ(EAX)�������
      
         and edx,0xffff0000              ;�������ַ���޹ص�λ
         rol edx,8
         bswap edx                       ;װ���ַ��31~24��23~16  (80486+)
      
         xor bx,bx
         or edx,ebx                      ;װ��ν��޵ĸ�4λ
      
         or edx,ecx                      ;װ������ 
      
         ret
      
;-------------------------------------------------------------------------------
         pgdt             dw 0
                          dd 0x00007e00      ;GDT�������ַ
;-------------------------------------------------------------------------------                             
         times 510-($-$$) db 0
                          db 0x55,0xaa
