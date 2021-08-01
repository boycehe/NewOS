asmfile=pmtest2
nasm ${asmfile}.asm -o ${asmfile}.com 
sudo mount -o loop pm.img /mnt/floppy
sudo cp ${asmfile}.com /mnt/floppy
sudo umount /mnt/floppy
