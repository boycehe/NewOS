echo "clean...."
rm pmtest1.bin
echo "build pmtest1.asm"
nasm pmtest1.asm -o pmtest1.bin
echo "start bochs"
bochs -f bochsrc
