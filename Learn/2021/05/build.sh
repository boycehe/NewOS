rm product/*.bin
wait
nasm boot.asm -o product/boot.bin
wait
nasm user.asm -o product/user.bin
