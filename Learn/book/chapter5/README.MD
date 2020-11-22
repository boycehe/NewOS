### Environment
MacOS: 10.15.7
Bochs: x86 Emulator 2.6.11
### 编写汇编下的”hello world“

linux
https://www.cnblogs.com/liubiyonge/p/9405623.html
```
nasm -f elf helloworld.asm -o helloworld.o
ld -s -m elf_i386 helloworld.o -o helloworld
```