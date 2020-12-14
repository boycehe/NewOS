         
         setup_base_address equ BootTail - BootMessage
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
         
         
         mov word [cs: pgdt+0x7c00],39     
 
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
        pgdt            dw 0
                        dd 0x00007e00      ;GDT的物理地址
BootMessage: db "Hello, OS Protect Mode!"
;-------------------------------------------------------------------------------                             
BootTail     times 510-($-$$) db 0
                    db 0x55,0xaa