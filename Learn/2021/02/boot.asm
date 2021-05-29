section s1
    offset dw str1,str2,num ;str1 0x100 str2 0x105 num 0x020
section s2 align=16 vstart=0x100 
    str1 db 'hello'
    str2 db 'world'
section s3 align=16 vstart=0x20
    num dw 0xbad
times 510-($-offset) db 0
dw 0xaa55
;s1,实际占用为 3*2 6个字节空间，但是默认16字节对齐 所以s1占用16个字节空间 
;s2,实际占用10个字节空间，也是因为要16个字节对齐，所以也是占用16个字节空间。因为是vstart=0x100所以s2段的偏移量
;从0x100开始。所以str1为0x100,因为str1有5个字符，所以str1占用5个字节的空间。因此str2为0x100+5=0x105;
;因为s1 s2各站用16个字节空间，总共为32个字节空间。16进制为0x20
;又因为s3没有指定起始偏移量，所以偏移量默认为从程序开始计算 即s1+s2 = 0x20
