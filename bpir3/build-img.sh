#!/bin/bash
set -x
set -e

IMGDIR=.
IMGNAME="bpir3"
REALSIZE=7000
rootdir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo "create $IMGNAME.img"
dd if=/dev/zero of=$IMGDIR/$IMGNAME.img bs=1M count=$REALSIZE 1> /dev/null 2>&1
LDEV=`losetup -f`
DEV=`echo $LDEV | cut -d "/" -f 3`     #mount image to loop device
echo "run losetup to assign image $IMGNAME.img to loopdev $LDEV ($DEV)"
losetup $LDEV $IMGDIR/$IMGNAME.img 1> /dev/null #2>&1
bootsize=100
rootsize=6144

bootstart=17408
bootend=$(( ${bootstart}+(${bootsize}*1024*2)-1 ))
rootstart=$(( ${bootend}+1 ))
rootend=$(( ${rootstart} + (${rootsize}*1024*2) ))
sgdisk -o ${LDEV}
#if [[ "$device" == "sdmmc" ]];then
        sgdisk -a 1 -n 1:34:8191 -A 1:set:2 -t 1:8300 -c 1:"bl2"           ${LDEV}
#else #emmc
#        sgdisk -a 1 -n 1:0:33 -A 1:set:2 -t 1:8300 -c 1:"gpt"              ${LDEV}
#fi
#sgdisk --attributes=1:set:2 ${LDEV}
sgdisk -a 1 -n 2:8192:9215 -A 2:set:63     -t 2:8300 -c 2:"u-boot-env"     ${LDEV}
sgdisk -a 1 -n 3:9216:13311 -A 3:set:63    -t 3:8300 -c 3:"factory"        ${LDEV}
sgdisk -a 1 -n 4:13312:17407 -A 4:set:63   -t 4:8300 -c 4:"fip"            ${LDEV}
sgdisk -a 1024 -n 5:17408:${bootend}       -t 5:ef00 -c 5:"boot"           ${LDEV}
sgdisk -a 1024 -n 6:${rootstart}:${rootend} -t 6:8300 -c 6:"rootfs"        ${LDEV}

#re-read part table
losetup -d $LDEV
losetup -P $LDEV $IMGDIR/$IMGNAME.img 1> /dev/null #2>&1

#partprobe $LDEV #1> /dev/null 2>&1
#dd if=arm-trusted-firmware/build/mt7986/release/bl2.img of=${LDEV}p1 conv=notrunc,fsync #1> /dev/null 2>&1
dd if=bl2.img of=${LDEV}p1 conv=notrunc,fsync #1> /dev/null 2>&1
#dd if=arm-trusted-firmware/build/mt7986/release/fip.bin of=${LDEV}p4 conv=notrunc,fsync #1> /dev/null 2>&1
dd if=fip.bin of=${LDEV}p4 conv=notrunc,fsync #1> /dev/null 2>&1
mkfs.vfat "${LDEV}p5" -n BOOT #1> /dev/null 2>&1
mkfs.ext4 -O ^metadata_csum,^64bit "${LDEV}p6" -L persistence #1> /dev/null 2>&1


echo "I: Mounting ISO image"
ISOLOOP=$(losetup --show -f vyos-1.5-rolling-202311132211-arm64-66.iso) # ${ISOFILE})
echo "I: Mounted iso on loopback: $ISOLOOP"
mkdir -p ${rootdir}/ISO
#mount -t iso9660 -o ro ${ISOLOOP} ${rootdir}/ISO # 1>&3
mount -t iso9660 -o ro,loop vyos-1.5-rolling-202311132211-arm64-66.iso ${rootdir}/ISO

# Copy files to BOOT/EFI
echo "I: Mounting BOOT"
mkdir -p ${rootdir}/BOOT
mount ${LDEV}p5 ${rootdir}/BOOT

echo "I: Mounting ROOT"
mkdir -p ${rootdir}/ROOT
mount ${LDEV}p6 ${rootdir}/ROOT

echo "I: Copying EFI Files"
cp -v ${rootdir}/helloworld.efi ${rootdir}/BOOT/
#cp -v ${rootdir}/mt7986a-bpi-r3-sd.dtb ${rootdir}/BOOT/
cp -v ${rootdir}/mt7986a-bananapi-bpi-r3.dtb ${rootdir}/BOOT/
cp -v ${rootdir}/mt7986a-bananapi-bpi-r3-sd.dtbo ${rootdir}/BOOT/

echo "I: Copying system files from iso to image"
echo "/ union" > ${rootdir}/ROOT/persistence.conf
mkdir -p ${rootdir}/ROOT/boot/image/
cp -v ${rootdir}/ISO/live/filesystem.squashfs ${rootdir}/ROOT/boot/image/image.squashfs
cp -v ${rootdir}/ISO/live/initrd.img-* ${rootdir}/ROOT/boot/image/initrd.img
cp -v ${rootdir}/ISO/live/vmlinuz-* ${rootdir}/ROOT/boot/image/vmlinuz

VERSION="image"

mkdir -p ${rootdir}/ROOT/boot/grub/
echo "I: Installing EFI"
#devicetree (hd0,gpt5)/mt7986a-bpi-r3-sd.dtb
cat > ${rootdir}/ROOT/boot/grub/load.cfg << EOF
set root=(hd0,gpt6)
set prefix=(hd0,gpt6)/boot/grub
insmod normal
normal
EOF

cat > ${rootdir}/ROOT/boot/grub/grub.cfg << EOF
set default=1
set timeout=5

echo -n Press ESC to enter the Grub menu...
if sleep --verbose --interuptable 5 ; then
    terminal_input console virtual
fi

menuentry "VyOS $version (Serial console)" {
        linux /boot/${VERSION}/vmlinuz boot=live vyos-union=/boot/${VERSION} console=ttyAMA0,115200n8 earlycon=pl011,0xfe201000 noautologin
        initrd /boot/${VERSION}/initrd.img
}
menuentry "VyOS $version (Graphical console)" {
        linux /boot/${VERSION}/vmlinuz boot=live vyos-union=/boot/${VERSION} noautologin
        initrd /boot/${VERSION}/initrd.img
}

menuentry "Lost password change $version (Serial console)" {
        linux /boot/${VERSION}/vmlinuz boot=live vyos-union=/boot/${VERSION} console=ttyAMA0,115200n8 init=/opt/vyatta/sbin/standalone_root_pw_reset
        initrd /boot/${VERSION}/initrd.img
}
EOF
mkdir -p ${rootdir}/BOOT/
grub-install  --efi-directory ${rootdir}/BOOT --boot-directory ${rootdir}/ROOT/boot -d /usr/lib/grub/arm64-efi ${LDEV} #1>&3 2>&4

echo "I: Unmounting ISO image"
umount ${rootdir}/ISO
rm -rf ${rootdir}/ISO

echo "I: Unmounting ROOT"
umount ${rootdir}/ROOT
rm -rf ${rootdir}/ROOT

echo "I: Unmounting BOOT"
umount ${rootdir}/BOOT
rm -rf ${rootdir}/BOOT


losetup -d $LDEV
losetup -d $ISOLOOP
echo "packing image..."
rm -rf $IMGDIR/$IMGNAME.img.gz
gzip $IMGDIR/$IMGNAME.img

