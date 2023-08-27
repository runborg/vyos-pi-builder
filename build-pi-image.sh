#!/bin/bash
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

CWD=$(pwd)

if [ ! -z "${DEBUG}" ]; then
    echo "Enable debugging"
    set -x
    exec 3>&1
else
    exec 3>/dev/null
fi

exec 4> >(
    # Hotfix to hide stderr messages from applications that cant be "silent" eg grub-install
    while IFS='' read -r line || [ -n "$line" ]; do
        # Hide "Garbage" from GRUB installer
        [[ "${line}" =~ "Installing for arm64-efi platform" ]] && continue
        [[ "${line}" =~ "EFI variables are not supported on this system" ]] && continue
        [[ "${line}" =~ "No error reported" ]] && continue
        echo -e "${line}"
    done
)
set -e

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
    1>&2 echo "ERROR: This tool must be run as root"
    exit 1
fi

if [ -z "$1" ]; then
    1>&2 echo "ERROR: no ISO file entered as an argument"
    exit 1
fi

if ! [ -f ${ISOFILE} ]; then
    1>&2 echo "ERROR: ISO file not supplied or does not exist"
    exit 1
fi

if [ -f "${PIVERSION}" ]; then
	PIVERSION=4
fi

if [ -f "${UBOOTBIN}" ]; then
    echo "Using uboot from ${UBOOTBIN}"
elif [ -f "u-boot-rpi${PIVERSION}.bin" ]; then
    echo "Using uboot from ./u-boot.bin"
    UBOOTBIN="u-boot-rpi${PIVERSION}.bin"
else
    1>&2 echo "ERROR: u-boot.bin not found and UBOOTBIN env variable is not set"
    exit 1
fi

echo "VYOS Raspberry Pi3/4 image builder"

# Select devtree to load, if none is spesified  pi4b devtree is used
if [ -z "$DEVTREE" ]; then
    DEVTREE="bcm2711-rpi-4-b"
fi

# get input and output filename
ISOFILE=$1
IMGNAME="vyos-${DEVTREE}.img"

echo "Using input file:  ${ISOFILE}"
echo "Using output file: ${IMGNAME}"
 
# Build image
#lb build | tee build_log

# Get build version
# This needs a rework, needs to be collected from the iso
VERSION="image" #$(cat version)


# Mounting ISO
ISOLOOP=$(losetup --show -f ${ISOFILE})
echo "Mounting iso on loopback: $ISOLOOP"

# Mount image and create filesystems
qemu-img create -f raw ${IMGNAME} 1.8G 1>&3
parted --script "${IMGNAME}" mklabel msdos 1>&3
parted --script "${IMGNAME}" mkpart primary fat16 8192s 60 1>&3
parted --script "${IMGNAME}" mkpart primary ext4 60 1900 1>&3
parted --script "${IMGNAME}" set 1 boot on 1>&3
 
# Create and mount image partitions
LOOPDEV=$(losetup --show -f -P ${IMGNAME})
echo "Mounting ${IMGNAME} on loopback: ${LOOPDEV}"
partprobe ${LOOPDEV} 1>&3
mkfs.vfat -n EFI -F 16 -I ${LOOPDEV}p1 1>&3
mkfs.ext4 -q -L persistence ${LOOPDEV}p2 1>&3
 
 
ROOTDIR="/mnt"
ISODIR="${ROOTDIR}/iso"
BOOTDIR="${ROOTDIR}/boot/${VERSION}"
EFIDIR="${ROOTDIR}/boot/efi"


mkdir -p ${ROOTDIR}
mount ${LOOPDEV}p2 ${ROOTDIR} 1>&3
 
mkdir -p ${EFIDIR}
mount ${LOOPDEV}p1 ${EFIDIR} 1>&3
mkdir -p ${EFIDIR}/overlays

mkdir -p ${ISODIR}
mount -o ro ${ISOLOOP} ${ISODIR} 1>&3
 
mkdir -p ${ROOTDIR}/boot/grub
mkdir -p ${BOOTDIR}/rw

if [ ! -z "${DEBUG}" ]; then 
    echo "Files in ISO:"
    ls -al ${ISODIR}/live
fi

echo "Copying system files from iso to image"
echo "/ union" > ${ROOTDIR}/persistence.conf
cp ${ISODIR}/live/filesystem.squashfs ${BOOTDIR}/${VERSION}.squashfs
cp ${ISODIR}/live/initrd.img-* ${BOOTDIR}/initrd.img
cp ${ISODIR}/live/vmlinuz-* ${BOOTDIR}/vmlinuz
 
# Copy rpi firmware files
#(CDIR=$(pwd); cd ${EFIDIR}; tar fzxv ${CDIR}/../tools/rpi4-bootfiles.tgz --owner=0 --group=0) || true
echo "Downloading PI Boot files"
if [ "${PIVERSION}" == "4" ]; then
    curl -s -o ${EFIDIR}/fixup4.dat https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/fixup4.dat 1>&3
    curl -s -o ${EFIDIR}/start4.elf https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/start4.elf 1>&3
    curl -s -o ${EFIDIR}/overlays/dwc2.dtbo https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/dwc2.dtbo 1>&3
elif [ "${PIVERSION}" == "3" ]; then
    curl -s -o ${EFIDIR}/bootcode.bin https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/bootcode.bin 1>&3
    curl -s -o ${EFIDIR}/fixup.dat https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/fixup.dat 1>&3
    curl -s -o ${EFIDIR}/start.elf https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/start.elf 1>&3
fi
curl -s -o ${EFIDIR}/${DEVTREE}.dtb https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/${DEVTREE}.dtb 1>&3

# Need overlay to disable Bluetooth making ttyAMA0 back
curl --create-dirs -s -o ${EFIDIR}/overlays/disable-bt.dtbo https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/disable-bt.dtbo 1>&3

cp ${UBOOTBIN} ${EFIDIR}/u-boot.bin

echo "Installing GRUB"
if [ "$DEVTREE" == "bcm2711-rpi-cm4" ]; then
  echo "Enabling overlay for CM4 usb"
  CM4USB='dtoverlay=dwc2,dr_mode=host'
fi

cat > ${EFIDIR}/config.txt << EOF
# Enable 64bit mode
arm_64bit=1
 
# Enable Serial console
enable_uart=1
dtoverlay=disable-bt
${CM4USB}

# Boot into u-boot
kernel=u-boot.bin
EOF


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
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -d ${EFIDIR}/boot.script ${EFIDIR}/boot.scr 1>&3
 
 
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
 
# install efi grub to image
grub-install  --efi-directory ${EFIDIR} --boot-directory ${BOOTDIR} -d /usr/lib/grub/arm64-efi ${LOOPDEV} 1>&3 2>&4
 
# create grub efi executable
grub-mkimage -O arm64-efi -p ${BOOTDIR}/grub -d /usr/lib/grub/arm64-efi -c ${ROOTDIR}/boot/grub/load.cfg \
        ext2 iso9660 linux echo configfile search_label search_fs_file \
        search search_fs_uuid ls normal gzio png fat gettext font minicmd \
        gfxterm gfxmenu video video_fb part_msdos part_gpt \
        > ${EFIDIR}/EFI/debian/grubarm.efi
if [ ! -z "${DEBUG}" ]; then 
    echo "Files in EFI Partition:"
    find ${EFIDIR}
    echo "Files in ROOT partition:"
    find ${ROOTDIR}
    echo "config.txt"
    cat ${EFIDIR}/config.txt
fi

#print debug data
echo "Files in image:"
find ${ROOTDIR}
echo
echo "Files in live image:"
ls -alh ${BOOTDIR}

echo "Unmounting disks"
# unmount image
umount ${ISODIR}
umount ${EFIDIR}
umount ${ROOTDIR}

 
#write uboot to image
#dd if=../tools/u-boot-spl.kwb of=${LOOPDEV} bs=512 seek=1
 
#unmount image
sudo losetup -d ${LOOPDEV}
sudo losetup -d ${ISOLOOP} 
echo "Compressing image"
zip ${IMGNAME}.zip ${IMGNAME} 1>&3
echo "Done"
