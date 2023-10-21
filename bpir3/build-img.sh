#!/bin/bash -x


IMGDIR=.
IMGNAME="bpir3"
REALSIZE=7000
echo "create $IMGNAME.img"
dd if=/dev/zero of=$IMGDIR/$IMGNAME.img bs=1M count=$REALSIZE 1> /dev/null 2>&1
LDEV=`sudo losetup -f`
DEV=`echo $LDEV | cut -d "/" -f 3`     #mount image to loop device
echo "run losetup to assign image $IMGNAME.img to loopdev $LDEV ($DEV)"
sudo losetup $LDEV $IMGDIR/$IMGNAME.img 1> /dev/null #2>&1
bootsize=100
rootsize=6144

bootstart=17408
bootend=$(( ${bootstart}+(${bootsize}*1024*2)-1 ))
rootstart=$(( ${bootend}+1 ))
rootend=$(( ${rootstart} + (${rootsize}*1024*2) ))
sudo sgdisk -o ${LDEV}
#if [[ "$device" == "sdmmc" ]];then
        sudo sgdisk -a 1 -n 1:34:8191 -A 1:set:2 -t 1:8300 -c 1:"bl2"           ${LDEV}
#else #emmc
#        sudo sgdisk -a 1 -n 1:0:33 -A 1:set:2 -t 1:8300 -c 1:"gpt"              ${LDEV}
#fi
#sudo sgdisk --attributes=1:set:2 ${LDEV}
sudo sgdisk -a 1 -n 2:8192:9215 -A 2:set:63     -t 2:8300 -c 2:"u-boot-env"     ${LDEV}
sudo sgdisk -a 1 -n 3:9216:13311 -A 3:set:63    -t 3:8300 -c 3:"factory"        ${LDEV}
sudo sgdisk -a 1 -n 4:13312:17407 -A 4:set:63   -t 4:8300 -c 4:"fip"            ${LDEV}
sudo sgdisk -a 1024 -n 5:17408:${bootend}       -t 5:ef00 -c 5:"boot"           ${LDEV}
sudo sgdisk -a 1024 -n 6:${rootstart}:${rootend} -t 6:8300 -c 6:"rootfs"        ${LDEV}

#re-read part table
sudo losetup -d $LDEV
sudo losetup -P $LDEV $IMGDIR/$IMGNAME.img 1> /dev/null #2>&1

#sudo partprobe $LDEV #1> /dev/null 2>&1
#sudo dd if=arm-trusted-firmware/build/mt7986/release/bl2.img of=${LDEV}p1 conv=notrunc,fsync #1> /dev/null 2>&1
sudo dd if=bl2.img of=${LDEV}p1 conv=notrunc,fsync #1> /dev/null 2>&1
#sudo dd if=arm-trusted-firmware/build/mt7986/release/fip.bin of=${LDEV}p4 conv=notrunc,fsync #1> /dev/null 2>&1
sudo dd if=fip.bin of=${LDEV}p4 conv=notrunc,fsync #1> /dev/null 2>&1
sudo mkfs.vfat "${LDEV}p5" -n BPI-BOOT #1> /dev/null 2>&1
sudo mkfs.ext4 -O ^metadata_csum,^64bit "${LDEV}p6" -L BPI-ROOT #1> /dev/null 2>&1


sudo losetup -d $LDEV
echo "packing image..."
gzip $IMGDIR/$IMGNAME.img

