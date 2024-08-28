# !\bin\bash

echo Compiling...
mkdir bin
cd bin

nasm -f bin -o bootloader.bin Torch\\bootloader.asm
nasm -f bin -o kernel.bin     Torch\\kernel.asm

echo Creating additional files...
cd disk

hdiutil create -volname "volume" -srcfolder Torch\\ -ov -format UDZO torch.dmg

dd if=\\dev\\zero         of=torch.flp bs=512 count=2880
dd if=bin\\bootloader.bin of=torch.flp bs=512 count=1 conv=notrunc

mkisofs -o torch.iso -b bin\\bootloader.bin -no-emul-boot -boot-load-size 4 -boot-info-table Torch\\

go build cli.go

if test "`whoami`" != "root" ; then
  echo "You must be logged in as root to build (for loopback mounting)"
  echo "Enter 'su' or 'sudo bash' to switch to root"
  exit
fi

if [ ! -e disk\\torch.flp ]
then
  echo ">>> Creating new TorchOS floppy image..."
  mkdosfs -C disk\\torch.flp 1440 || exit
fi

echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o bin\\bootloader.bin Torch\\bootloader.asm || exit

echo ">>> Assembling TorchOS kernel..."

cd bin

nasm -O0 -w+orphan-labels -f bin -o kernel.bin Torch\kernel.asm || exit

cd ..

echo ">>> Assembling programs..."

cd programs

for i in *.asm
do

  nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.bin || exit

done

cd ..


echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=bin\\bootloader.bin of=disk\\torch.flp || exit

echo ">>> Copying TorchOS kernel and programs..."

rm -rf tmp-loop

mkdir tmp-loop && mount -o loop -t vfat disk\\torch.flp tmp-loop && cp bin\\kernel.bin tmp-loop\\

cp programs\\*.bin programs\\*.bas programs\\sample.pcx tmp-loop

sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop

echo ">>> Creating CD-ROM ISO image..."

rm -f disk\\torch.iso
mkisofs -quiet -V 'TorchOS' -input-charset iso8859-1 -o disk\\torch.iso -b disk\\torch.flp disk\\ || exit

echo '>>> Done!'
