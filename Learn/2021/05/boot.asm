      ;保护模式下的引导扇区代码
      ;实现一个冒泡排序，同时学习xchg指令
      ;xchg r/m r/m
      ;不能同时为内存地址，同时操作尺寸要一致
      ;示例
      ;xchg al,dh
      ;xchg ecx,edx
      ;xchg cx,[0x7e00]


      ;设置堆栈段和栈指针
      mov eax,cs        ;cs寄存器的大小是多少？这里如果是mov ax,cs会是什么效果？
      mov ss,eax        ;32位下，cs ds大小是多少
      mov sp,0x7c00     ;这里为什么是sp？


      ;计算GDT所在的逻辑段地址
      mov eax,[cs:pgdt+0x7c00+0x02];高16位
      xor edx,edx
      mov ebx,16
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

      ;创建#3描述符，创建代码段的别名描述符
      mov dword [bx+0x18],0x7c0001ff  ;基地址为0x7c00，512字节
      mov dword [bx+0x1c],0x00409200  ;粒度为1字节，数据段描述符

      mov dword [bx+0x20],0x7c00ffee  ;基地址为0x7c00，512字节
      mov dword [bx+0x24],0x00cf9600  ;粒度为1字节，数据段描述符

      ;初始化描述符表寄存器GDTR
      mov word [cs:pgdt+0x7c00],39    ;描述符表的界限（总字节数减一）
    
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

      mov eax,0x0018
      mov ds,eax

      mov eax,0x0008      ;加载数据段（0..4GB)选择子
      mov es,eax
      mov fs,eax
      mov gs,eax

      mov eax,0x0020
      mov ss,eax
      xor esp,esp
      ;以下在屏幕上显示“Protect mode OK.”

      mov dword [es:0x0b8000],0x072e0750  ;字符'P','.'及其显示属性
      mov dword [es:0x0b8000],0x072e074d  ;字符'M','.'及其显示属性
      mov dword [es:0x0b8000],0x07200720  ;两个空白字符及其显示属性
      mov dword [es:0x0b8000],0x076b076f  ;字符'o','k'及其显示属性

      
      ;以下用简单的示例来帮助阐述32位保护模式下的堆栈操作

      ;开始冒泡排序
      mov ecx,pgdt-string-1               ;遍历次数=串长度-1
  @@1:
      push ecx                            ;32位下loop使用ecx
      xor bx,bx

  @@2:
      mov ax,[string+bx] 
      cmp ah,al
      jge @@3
      xchg al,ah
      mov [string+bx],ax

  @@3:
      inc bx
      loop @@2
      pop ecx
      loop @@1

      mov ecx,pgdt-string
      xor ebx,ebx

  @@4:
      mov ah,0x07
      mov al,[string+ebx]
      mov [es:0xb80a0+ebx*2],ax
      inc ebx
      loop @@4

      hlt                                 ;已经禁止终端，将不会被唤醒

      string      db 's0ke4or92xap3fv8giuzjcy5l1m7hd6bnqtw.'
      
      pgdt        dw 0
                  dd 0x00007e00       ;GDT的物理地址

      times 510-($-$$)  db 0
                        db 0x55,0xaa 
