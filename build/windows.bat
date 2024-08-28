@echo off

echo Compiling...
mkdir bin
cd bin

nasm -f bin -o bootloader.bin Torch\bootloader.asm
nasm -f bin -o kernel.bin     Torch\kernel.asm

echo Creating additional files...
cd disk

hdiutil create -volname "volume" -srcfolder Torch\ -ov -format UDZO torch.dmg

dd if=\dev\zero          of=torch.flp bs=512 count=2880
dd if=bin\bootloader.bin of=torch.flp bs=512 count=1 conv=notrunc

mkisofs -o torch.iso -b bin\bootloader.bin -no-emul-boot -boot-load-size 4 -boot-info-table Torch\

go build cli.go

echo Build script for Windows

echo .

echo Assembling bootloader...
cd bin

nasm -O0 -f bin -o bootload.bin Torch\bootload.asm

cd ..

echo Assembling TorchOS kernel...
nasm -O0 -f bin -o kernel.bin Torch\kernel.asm

echo Assembling programs...
cd ..\programs
  for %%i in (*.asm) do nasm -O0 -fbin %%i
  for %%i in (*.bin) do del %%i
  for %%i in (*.)    do ren %%i %%i.bin
cd ..

echo Adding bootsector to disk image...
cd disk

partcopy ..\bin\bootloader.bin 0 200 torch.flp 0

cd ..

echo Mounting disk image...
imdisk -a -f disk\torch.flp -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy bin\kernel.bin b:\
copy programs\*.bin b:\
copy programs\sample.pcx b:\
copy programs\*.bas b:\

echo Dismounting disk image...
imdisk -D -m B:

echo Done!
