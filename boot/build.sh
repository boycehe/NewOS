file=boot
echo "clean...."
rm ${file}.bin
echo "build ${file}.asm"
nasm ${file}.asm -o ${file}.bin
sh vhdwriter.sh
echo "start bochs"
bochs -f ../tools/Bochs/bochsrc_mac
