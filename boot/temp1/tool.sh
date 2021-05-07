rm *.o *.img *.bin
nasm boot.asm -o boot.bin
nasm setup.asm -o setup.bin
../tools/VHDWriter/vhdwriter -w boot.vhd -a 0 -r boot.bin
../tools/VHDWriter/vhdwriter -w boot.vhd -a 1 -r setup.bin
