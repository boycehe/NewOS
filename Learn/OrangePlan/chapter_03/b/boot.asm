         ;�ļ�����c13_mbr0.asm
         ;�ļ�˵����Ӳ���������������� 
%include "pm.inc"
;-------------------------------------------------------------------------------
         core_base_address equ 0x00040000   ;�������ں˼��ص���ʼ�ڴ��ַ 
         core_start_sector equ 0x00000001   ;�������ں˵���ʼ�߼�������

;GDT Begin                            �λ�ַ          �ν���            ����
LABEL_GDT:             Descriptor          0,              0,              0           ;�������� 
LABEL_DESC_DATA:       Descriptor         0,        0xFFFFF,         DA_DRW+DA_4K+DA_32     ;����Ϊ4K���洢��������
LABEL_DESC_CODE:       Descriptor    0x7c00,         0x01FF,         DA_C+DA_32
LABEL_DESC_STACK:      Descriptor    0x7c00,        0xFFFFE,         DA_4K+DA_DRWB+DA_32   
LABEL_DESC_VIDEO:      Descriptor   0xb8000,        0x07FFF,         DA_DRW+DA_32 
;GDT End
GtdLen  equ $ - LABEL_GDT
GdtPtr  dw GtdLen - 1
        dd 0
;-------------------------------------------------------------------------------         
         ;����GDT���ڵ��߼��ε�ַ
         mov eax,cs      ;GDT��32λ�����ַ 
         xor edx,edx
         mov ebx,16
         div ebx                            ;�ֽ��16λ�߼���ַ 

         mov ds,eax                         ;��DSָ��ö��Խ��в���
         mov ebx,edx                        ;������ʼƫ�Ƶ�ַ 
 
         mov [cs:GdtPtr+2],eax
         lgdt [cs: GdtPtr+0x7c00]
      
         in al,0x92                         ;����оƬ�ڵĶ˿� 
         or al,0000_0010B
         out 0x92,al                        ;��A20

         cli                                ;�жϻ�����δ����

         mov eax,cr0
         or eax,1
         mov cr0,eax                        ;����PEλ
      
         ;���½��뱣��ģʽ... ...
         jmp 0x0010:flush                   ;����ˮ�߲����л�������

         [bits 32]               
  flush:                                  
         mov eax,0x0008                     ;�������ݶ�(0..4GB)ѡ����
         mov ds,eax

         mov eax,0x0018                     ;���ض�ջ��ѡ���� 
         mov ss,eax
         xor esp,esp                        ;��ջָ�� <- 0 

         ;���¼���ϵͳ���ĳ��� 
         mov edi,core_base_address 
      
         mov eax,core_start_sector
         mov ebx,edi                        ;��ʼ��ַ 
         call read_hard_disk_0              ;���¶�ȡ�������ʼ���֣�һ�������� 
      
         ;�����ж����������ж��
         mov eax,[edi]                      ;���ĳ���ߴ�
         xor edx,edx 
         mov ecx,512                        ;512�ֽ�ÿ����
         div ecx

         or edx,edx
         jnz @1                             ;δ��������˽����ʵ����������1 
         dec eax                            ;�Ѿ�����һ������������������1 
   @1:
         or eax,eax                         ;����ʵ�ʳ��ȡ�512���ֽڵ���� 
         jz setup                           ;EAX=0 ?

         ;��ȡʣ�������
         mov ecx,eax                        ;32λģʽ�µ�LOOPʹ��ECX
         mov eax,core_start_sector
         inc eax                            ;����һ���߼��������Ŷ�
   @2:
         call read_hard_disk_0
         inc eax
         loop @2                            ;ѭ������ֱ�����������ں� 

 setup:
         mov esi,[0x7c00+pgdt+0x02]         ;�������ڴ������Ѱַpgdt��������
                                            ;ͨ��4GB�Ķ�������
         ;�����������̶�������
         mov eax,[edi+0x04]                 ;�������̴������ʼ����ַ
         mov ebx,[edi+0x08]                 ;�������ݶλ���ַ
         sub ebx,eax
         dec ebx                            ;�������̶ν��� 
         add eax,edi                        ;�������̶λ���ַ
         mov ecx,0x00409800                 ;�ֽ����ȵĴ����������
         call make_gdt_descriptor
         mov [esi+0x28],eax
         mov [esi+0x2c],edx
       
         ;�����������ݶ�������
         mov eax,[edi+0x08]                 ;�������ݶ���ʼ����ַ
         mov ebx,[edi+0x0c]                 ;���Ĵ���λ���ַ 
         sub ebx,eax
         dec ebx                            ;�������ݶν���
         add eax,edi                        ;�������ݶλ���ַ
         mov ecx,0x00409200                 ;�ֽ����ȵ����ݶ������� 
         call make_gdt_descriptor
         mov [esi+0x30],eax
         mov [esi+0x34],edx 
      
         ;�������Ĵ����������
         mov eax,[edi+0x0c]                 ;���Ĵ������ʼ����ַ
         mov ebx,[edi+0x00]                 ;�����ܳ���
         sub ebx,eax
         dec ebx                            ;���Ĵ���ν���
         add eax,edi                        ;���Ĵ���λ���ַ
         mov ecx,0x00409800                 ;�ֽ����ȵĴ����������
         call make_gdt_descriptor
         mov [esi+0x38],eax
         mov [esi+0x3c],edx

         mov word [0x7c00+pgdt],63          ;��������Ľ���
                                        
         lgdt [0x7c00+pgdt]                  

         jmp far [edi+0x10]  
       
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
