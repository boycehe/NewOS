rm product/a.img product/boot.bin
wait
nasm boot.asm -o product/boot.bin
wait
dd if=product/boot.bin of=product/a.img bs=512 count=1 conv=notrunc
wait
cd product
wait
bochs -f bochsrc