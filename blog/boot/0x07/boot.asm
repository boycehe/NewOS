         mov eax,[cs:pgdt+0x7c00+0x02] 
         xor edx,edx
         mov ebx,16
         div ebx                       

         mov ds,eax                    
         mov ebx,edx  ;获取GDT基址地址和偏移地址                     

        ;跳过#0号描述符
        ;创建1#描述符，这是一个数据段，对应0~4GB的线性地址空间
         mov dword [ebx+0x08],0x0000ffff    ;基地址为0，段界限为0xFFFFF
         mov dword [ebx+0x0c],0x00cf9200    ;粒度为4KB，存储器段描述符   
        ;创建保护模式下初始代码段描述符
         mov dword [ebx+0x10],0x7c0001ff     ;基地址为0x00007c00，界限0x1FF  
         mov dword [ebx+0x14],0x00409800    ;粒度为1个字节，代码段描述符   
         ;建立保护模式下的显示缓冲区描述符   
         mov dword [ebx+0x18],0x80007fff    
         mov dword [ebx+0x1c],0x0040920b    
         
         
         mov word [cs: pgdt+0x7c00],31     
 
         lgdt [cs: pgdt+0x7c00]
        ;开启A20地址线
         in al,0x92                        
         or al,0000_0010B
         out 0x92,al                       

         cli                               

         mov eax,cr0
         or eax,1
         mov cr0,eax                      
      
         jmp dword 0x0010:flush            
                                           
         [bits 32]               
  flush:                                  
         mov eax,0x0018                    
         mov es,eax

         mov eax,0x0008
         mov ds,eax
      
         ;循环长度
         mov ecx, BootTail-BootMessage
         mov si,0x7c00+BootMessage
showBootMessage:
        mov al,[si]
        mov byte [es:ebx],al
        mov byte [es:ebx+1],0x17
        add ebx,2
        inc si
        loop showBootMessage
        jmp $                                         
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
BootMessage: db "Hello, OS Protect Mode!"
;-------------------------------------------------------------------------------                             
BootTail     times 510-($-$$) db 0
                    db 0x55,0xaa