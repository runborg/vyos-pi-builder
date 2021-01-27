#!/bin/sh
set -x
set -e
#
# Copyright (C) 2019 VyOS maintainers and contributors
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 or later as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# File: build-pi3-image
# Purpose:
# Build VyOS image for for Raspberry PI 4.

crash_cleanup() {
    echo "OOOPS!!! we crashed.. :/ starting a crude cleanup."
    if [ ! -z "$ISOLOOP" ]; then
        echo "ISOLOOP : ${ISOLOOP}"
        echo "Unmounting ISO"
        umount ${ISOLOOP} || true
        losetup -d ${ISOLOOP} || true
    fi
    if [ ! -z "${LOOPDEV}" ]; then
        echo "LOOPDEV : ${LOOPDEV}"
        echo "Unmounting root"
        umount ${LOOPDEV}p1 || true
        umount ${LOOPDEV}p2 || true
        losetup -d ${LOOPDEV} || true
    fi
}
trap "crash_cleanup" ERR


if [[ ${EUID} -ne 0 ]]; then
    echo "ERROR: This tool must be run as root"
    exit 1
fi

if [ -z "$1" ]; then
    echo "ERROR: no ISO file entered as an argument"
    exit 1
fi

if ! [ -f ${ISOFILE} ]; then
    echo "ERROR: ISO file not supplied or does not exist"
    exit 1
fi


if [ -f "${UBOOTBIN}" ]; then
    echo "Using uboot from ${UBOOTBIN}"
elif [ -f "u-boot.bin" ]; then
    echo "Using uboot from ./u-boot.bin"
    UBOOTBIN="u-boot.bin"
else
    echo "ERROR: u-boot.bin not found and UBOOTBIN env variable is not set"
    exit 1
fi

echo "VYOS Raspberry Pi3/4 image builder"

# get input and output filename
ISOFILE=$1
IMGFILE="${ISOFILE%.*}.img"


echo "Using input file:  ${ISOFILE}"
echo "Using output file: ${IMGFILE}"
 
# Build image
#lb build | tee build_log

# Get build version
# This needs a rework, needs to be collected from the iso
VERSION="image" #$(cat version)
 
DEVTREE="bcm2711-rpi-4-b"
IMGNAME="${IMGFILE}"

# Mounting ISO
ISOLOOP=$(losetup --show -f ${ISOFILE})
echo "Mounted iso on loopback: $ISOLOOP"

# Mount image and create filesystems
qemu-img create -f raw ${IMGNAME} 1.8G
parted --script "${IMGNAME}" mklabel msdos
parted --script "${IMGNAME}" mkpart primary fat16 8192s 60
parted --script "${IMGNAME}" mkpart primary ext4 60 1900
parted --script "${IMGNAME}" set 1 boot on
 
# Create and mount image partitions
LOOPDEV=$(losetup --show -f ${IMGNAME})
echo "Mounted ${IMGNAME} on loopback: ${LOOPDEV}"
partprobe ${LOOPDEV}
mkfs.vfat -n EFI -F 16 -I ${LOOPDEV}p1
mkfs.ext4 -L persistence ${LOOPDEV}p2
 
 
ROOTDIR="/mnt"
ISODIR="${ROOTDIR}/iso"
BOOTDIR="${ROOTDIR}/boot/${VERSION}"
EFIDIR="${ROOTDIR}/boot/efi"


mkdir -p ${ROOTDIR}
mount ${LOOPDEV}p2 ${ROOTDIR}
 
mkdir -p ${EFIDIR}
mount ${LOOPDEV}p1 ${EFIDIR}

mkdir -p ${ISODIR}
mount ${ISOLOOP} ${ISODIR}
 
mkdir -p ${ROOTDIR}/boot/grub
mkdir -p ${BOOTDIR}/rw
echo "Files in ISO:"
ls -al ${ISODIR}/live

echo "/ union" > ${ROOTDIR}/persistence.conf
cp ${ISODIR}/live/filesystem.squashfs ${BOOTDIR}/${VERSION}.squashfs
cp ${ISODIR}/live/initrd.img-* ${BOOTDIR}/initrd.img
cp ${ISODIR}/live/vmlinuz-* ${BOOTDIR}/vmlinuz
#cp binary/live/kernel8.img ${BOOTDIR}/kernel8
#cp binary/live/initrd.img-* ${EFIDIR}/initrd.img
#cp binary/live/vmlinuz-* ${EFIDIR}/vmlinuz
#cp binary/live/kernel8.img ${EFIDIR}/kernel8
 
#cp armstub8-gic.bin ${EFIDIR}/armstub8-gic.bin
#cp ../tools/${DEVTREE}.dtb ${EFIDIR}/
 
# Copy rpi firmware files
#(CDIR=$(pwd); cd ${EFIDIR}; tar fzxv ${CDIR}/../tools/rpi4-bootfiles.tgz --owner=0 --group=0) || true
curl -o ${EFIDIR}/fixup4.dat https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/fixup4.dat
curl -o ${EFIDIR}/start4.elf https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/start4.elf
curl -o ${EFIDIR}/bcm2711-rpi-4-b.dtb https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/${DEVTREE}.dtb
#curl -o ${ROOTDIR}/boot/kernel8.img https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/kernel8.img
#cp ../tools/u-boot-${DEVTREE}.bin ${EFIDIR}/u-boot.bin
cp ${UBOOTBIN} ${EFIDIR}/u-boot.bin
 
cat > ${EFIDIR}/config.txt << EOF
# Enable 64bit mode
arm_64bit=1
 
# Enable Serial console
enable_uart=1
dtoverlay=pi3-disable-bt
 
# Boot into u-boot
kernel=u-boot.bin
EOF
 
#echo 'arm_64bit=1'      >> ${EFIDIR}/config.txt
#echo 'enable_uart=1'    >> ${EFIDIR}/config.txt
#echo 'kernel=u-boot.bin'>> ${EFIDIR}/config.txt
#echo 'enable_gic=1' >> ${EFIDIR}/config.txt
#echo 'dtoverlay=upstream' >> ${EFIDIR}/config.txt
#echo 'armstub=armstub8-gic.bin' >> ${EFIDIR}/config.txt
#echo 'initramfs=initrd' >> ${EFIDIR}/config.txt
#echo 'boot=live quiet vyos-union=/boot/${VERSION} console=tty1 console=ttyS0,115200n8' >> ${EFIDIR}/cmdline.txt
 
# Create u-boot bootscript
# Load DTB
# DTB is loaded by the 1stage bootloader on the pi, we dont need to touch it :)
#   echo "Loading ${DEVTREE}.dtb"
#   load mmc 0:1 \$fdt_addr_r ${DEVTREE}.dtb
#   fdt addr \$fdt_addr_r 2000
cat > ${EFIDIR}/boot.script << EOF
# Load EFI
echo "Loading EFI image ..."
load mmc 0:1 \$loadaddr EFI/debian/grubarm.efi
 
# Slepp a while do the MMC driver can settle down
echo "Sleeping 2 seconds ..."
sleep 2
 
# Boot
echo "Booting into GRUB..."
bootefi \$loadaddr
EOF
 
 
# compile boot script for u-boot
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d ${EFIDIR}/boot.script ${EFIDIR}/boot.scr
 
 
# create grub config file to include
# devicetree is loaded by the pi's first stage bootloader and are not needed to be loaded
# > devicetree (hd0,msdos1)/${DEVTREE}.dtb
cat > ${ROOTDIR}/boot/grub/load.cfg << EOF
set root=(hd0,msdos2)
set prefix=(hd0,msdos2)/boot/grub
insmod normal
normal
EOF
 
 
# Create grub menu file
cat > ${ROOTDIR}/boot/grub/grub.cfg << EOF
set default=0
set timeout=5
 
echo -n Press ESC to enter the Grub menu...
if sleep --verbose --interuptable 5 ; then
    terminal_input console virtual
fi
 
menuentry "VyOS $version (Serial console)" {
        linux /boot/${VERSION}/vmlinuz boot=live vyos-union=/boot/${VERSION} console=ttyAMA0,115200n8 earlycon=pl011,0xfe201000
        initrd /boot/${VERSION}/initrd.img
}
menuentry "VyOS $version (Graphical console)" {
        linux /boot/${VERSION}/vmlinuz boot=live vyos-union=/boot/${VERSION}
        initrd /boot/${VERSION}/initrd.img
}
 
menuentry "Lost password change $version (Serial console)" {
        linux /boot/${VERSION}/vmlinuz boot=live vyos-union=/boot/${VERSION} console=ttyAMA0,115200n8 init=/opt/vyatta/sbin/standalone_root_pw_reset
        initrd /boot/${VERSION}/initrd.img
}
EOF
 
# install efi grub to image
grub-install  --efi-directory ${EFIDIR} --boot-directory ${BOOTDIR} -d /usr/lib/grub/arm64-efi ${LOOPDEV}
 
# create grub efi executable
grub-mkimage -O arm64-efi -p ${BOOTDIR}/grub -d /usr/lib/grub/arm64-efi -c ${ROOTDIR}/boot/grub/load.cfg \
        ext2 iso9660 linux echo configfile search_label search_fs_file \
        search search_fs_uuid ls normal gzio png fat gettext font minicmd \
        gfxterm gfxmenu video video_fb part_msdos part_gpt \
        > ${EFIDIR}/EFI/debian/grubarm.efi
 
echo "Files in EFI Partition:"
find ${EFIDIR}
echo "Files in ROOT partition:"
find ${ROOTDIR}
echo "config.txt"
cat ${EFIDIR}/config.txt
echo "DONE!!"
# unmount image
umount ${ISODIR}
umount ${EFIDIR}
umount ${ROOTDIR}

 
#write uboot to image
#dd if=../tools/u-boot-spl.kwb of=${LOOPDEV} bs=512 seek=1
 
#unmount image
sudo losetup -d ${LOOPDEV}
sudo losetup -d ${ISOLOOP} 

zip ${IMGNAME}.zip ${IMGNAME}
