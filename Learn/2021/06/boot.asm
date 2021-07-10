      ;保护模式下的引导扇区代码

      core_base_address equ 0x00040000  ;常数，内核加载的起始内存地址
      core_start_sector equ 0x00000001  ;常数，内核的起始逻辑扇区号

      mov eax,cs                        ;cs值为0
      mov ss,eax
      mov sp,0x7c00                     ;设置一个向下扩展的栈段

      ;计算GDT所在的逻辑段地址
      mov eax,[cs:pgdt+0x7c00+0x02]     ;高16位
      xor edx,edx                       ;被除数在edx eax 64位除法
      mov ebx,16                        ;余数在edx中商在eax中
      div ebx
    
      ;intel 对 ds,eax进行了优化。无论是16位还是32位都不会出现反转前缀
      ;在32位的时候只会使用到eax的低16位
      mov ds,eax                ;令DS指向该段以进行操作
      mov ebx,edx               ;段内起始偏移地址
      
      ;创建0#描述符，它是空描述符，这是处理器的要求
      mov dword [bx+0x00],0x00000000
      mov dword [bx+0x04],0x00000000

      ;创建#1描述符，这是一个数据段，对应的是0~4GB的线性地址空间
      mov dword [bx+0x08],0x0000ffff  ;基地址为0，段界限为0xffff
      mov dword [bx+0x0c],0x00cf9200  ;粒度为4kb，存储器段描述符

      ;创建#2描述符，初始代码段描述符
      mov dword [bx+0x10],0x7c0001ff  ;基地址为0x7c000，512字节
      mov dword [bx+0x14],0x00409800  ;粒度为1个字节，代码段描述符

      ;建立保护模式下的堆栈段描述符   ;基地址为0x7c00 界限0xFFFFE
      mov dword [bx+0x18],0x7c00ffee  ;基地址为0x7c00，512字节
      mov dword [bx+0x1c],0x00cf9600  ;粒度为1字节，数据段描述符

      ;建立保护模式下的显示缓冲区描述符
      mov dword [ebx+0x20],0x80007fff ;基地址为0xB8000,界限0x07FFFF
      mov dword [ebx+0x24],0x0040920b ;粒度为字节

      ;初始化描述符表寄存器GDTR
      mov word [cs:pgdt+0x7c00],39    ;描述符表的界限（总字节数减一）24+16-1
    
      lgdt [cs:pgdt+0x7c00]

      in al,0x92                          ;南桥芯片内的端口
      or al,0000_0010B
      out 0x92,al                         ;打开A20

      cli                                 ;保护模式下终端机制尚未建立，应
                                          ;禁止中断
      

      mov eax,cr0
      or eax,1
      mov cr0,eax

      ;以下进入保护模式
      jmp dword 0x0010:flush              ;16位的描述符选择子：32位偏移
                                          ;清流水线并串行化处理器
      [bits 32]


  flush:

      mov eax,0x0008                      ;加载数据段
      mov ds,eax                          ;0100;选择子#1选择子

      mov eax,0x0018      ;加载堆栈段选择子
      mov ss,eax
      xor esp,esp

      ;加载系统核心程序
      mov edi,core_base_address

      mov eax,core_start_sector
      mov ebx,edi
      call read_hard_disk_0       ;以下读取程序的起始部分（一个扇区）

      ;判断整个程序有多大
      mov eax,[edi]
      xor edx,edx
      mov ecx,512
      div ecx

      or edx,edx
      jnz @1
      dec eax
  @1:
      or eax,eax
      jz setup

      ;读取剩余的扇区
      mov ecx,eax
      mov eax,core_start_sector
      inc eax
  @2:
      call read_hard_disk_0
      inc eax
      loop @2

;-----------------------------------------------------------------------------
setup:
      mov esi,[0x7c00+pgdt+0x02]        ;不可在代码段内寻址pgdt,但可以
                                        ;通过4GB的段来访问
      ;建立公用例程段描述符
      mov eax,[edi+0x04]                ;公用例程段起始汇编地址
      mov ebx,[edi+0x08]                ;核心数据段汇编地址

      sub ebx,eax
      dec ebx                           ;核心数据段界限
      add eax,edi                       ;核心数据段基地址


      mov ecx,0x00409200                ;字节粒度的数据段描述符
      call make_gdt_descriptor
      mov [esi+0x30],eax
      mov [esi+0x34],edx

      ;建立核心代码段描述符
      mov eax,[edi+0x0c]                ;核心代码段起始汇编地址
      mov ebx,[edi+0x00]                ;程序总长度
      sub ebx,eax
      dec ebx                           ;核心代码段界限
      add eax,edi                       ;核心代码段基地址
      mov ecx,0x00409800
      call make_gdt_descriptor
      mov [esi+0x38],eax
      mov [esi+0x3c],edx

      mov word [0x7c00+pgdt],63

      lgdt [0x7c00+pgdt]

      jmp far [edi+0x10]
;------------------------------------------------------------------------

read_hard_disk_0:
      ;从硬盘读取一个逻辑扇区
      ;eax=逻辑扇区号
      ;DS:EBX=目标缓冲区地址
      ;返回：EBX=EBX+512
      push eax
      push ecx
      push edx
      push eax

      mov dx,0x1f2
      mov al,1
      out dx,al                   ;读取扇区数

      inc dx
      pop eax
      out dx,al                   ;lba 7~0

      inc dx
      mov cl,8
      shr eax,cl
      out dx,al                   ;lba 15~8
      
      inc dx
      shr eax,cl
      out dx,al

      inc dx
      shr eax,cl
      or al,0xe0
      out dx,al

      inc dx
      mov al,0x20
      out dx,al                 ;读命令

  .waits:
      in al,dx
      and al,0x88
      cmp al,0x08
      jnz .waits

      mov ecx,256
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

 
;------------------------------------------------------------
make_gdt_descriptor:                    ;构造描述符
                                        ;输入：EAX=线性基地址
                                        ;      EBX=段界限
                                        ;      ECX=属性
      mov edx,eax
      shl eax,16
      or ax,bx

      and edx,0xffff0000
      rol edx,8
      bswap edx

      xor bx,bx
      or edx,ebx

      or edx,ecx

      ret
      
      pgdt        dw 0
                  dd 0x00007e00       ;GDT的物理地址

      times 510-($-$$)  db 0
                        db 0x55,0xaa 
;------------------------------------------------------------
