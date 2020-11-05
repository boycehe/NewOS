# NewOS
My First OS

# 常用的Bochs命令
https://www.cnblogs.com/jikebiancheng/p/6160337.html
b addr 在物理地址处设置断点 addr为物理内存地址，不加段基址

 lb 在线性地址处设置断点  addr为线性物理地址，不加基址

 vb 在虚拟地址上设置断点 addr为段基址：偏移地址， cs段

 

c 继续执行知道遇到断点

 

n 单步执行 跳过子程序和int中断程序

 

s 单步执行

 

s num ( s指令后加一数字) 执行n步

 

dump_cpu 查看寄存器信息  （实测下来这个指令好像不好使。。。）

 

x /nuf addr 显示指定内存地址的数据，addr可以是线性的内存地址，也可以是虚址 格式是基址：偏移或者基址寄存器：偏移

n 显示的数据长度 

u 数据单元大小 b,h,w,g分别对应1,2,4,8字节

f 数据显示格式 x,d,u,o,t,c分别对应十六进制、十进制、无符号十进制、八进制、二进制、字符串

 

 

u [/count] start end 反汇编一段线性内存(作用与上面的一样)

(count 参数指明要反汇编的指令条数 ,例子：u /5 --反汇编从当前地址开始的5条指令)

 

info指令组

info b 展示当前的断点状态信息

info dirty 展示自从上次显示以来物理内存中的脏页（被写的页）

info program 展示程序的执行状态  （无法使用！）

info r|reg|rigisters 展示寄存器内容

info cpu 展示CPU寄存器内容

info fpu 展示FPU寄存器的状态

info idt 展示中断描述表

info ivt 展示中断向量表(保护模式下无效)

info gdt 展示全局描述表

info tss 展示当前的任务状态段

info cr 展示CR0-CR4寄存器状态 （无法使用）

info flags 展示标志寄存器   （无法使用）

 寄存器查询

r 查看通用寄存器

sreg 查看段寄存器（es,cs,gs,ss,fs,ds以及idt,gdt,ldt,tr）

creg 查看控制寄存器（cr0，cr1，cr2，cr3）

dreg 查看调试寄存器（dr0-dr7）

x /nuf [addr] 显示线性地址（Linear Address）的内容

xp /nuf [addr] 显示物理地址（Physical Address）的内容

参数 n 显示的单元数

参数 u 每个显示单元的大小，u可以是下列之一：

b BYTE
h WORD
w DWORD
g DWORD64
 
注意: 这种命名法是按照GDB习惯的，而并不是按照intel的规范。
f 显示格式，f可以是下列之一：

 x 按照十六进制显示
d 十进制显示
u 按照无符号十进制显示
o 按照八进制显示
t 按照二进制显示
c 按照字符显示
 
n、f、u是可选参数，如果不指定，则u默认是w，f 默认是x。如果前面使用过x或

 者xp命令，会按照上一次的x或者xp命令所使用的值。n默认为1。addr 也是一个

 可选参数，如果不指定，addr是0，如过前面使用过x或者xp命令，指定了n=i，

 则再次执行时n默认为i+1。