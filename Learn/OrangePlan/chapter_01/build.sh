echo "clean...."
rm boot.bin a.img
echo "build boot.asm"
nasm boot.asm -o boot.bin
echo "make img file"
dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc
