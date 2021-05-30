if [[ `uname` == 'Darwin' ]]; then
./vhdwriter_mac -w ../product/ProtectMode.vhd -a 0 -r ../product/boot.bin
./vhdwriter_mac -w ../product/ProtectMode.vhd -a 100 -r ../product/user.bin
else
./vhdwriter -w ../product/ProtectMode.vhd -a 0 -r ../product/boot.bin
./vhdwriter -w ../product/ProtectMode.vhd -a 100 -r ../product/user.bin
fi
