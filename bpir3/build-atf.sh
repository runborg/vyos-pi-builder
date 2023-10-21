#!/bin/bash -x

# If were running on x86_64, enable cross compiler
arch=$(uname -i)
rootdir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [ "$arch" == 'x86_64' ];
then
  export CROSS_COMPILE=aarch64-linux-gnu-
fi


if [ ! -z "${DEBUG}" ]; then
    set -x
fi
set -e

if [ ! -d "arm-trusted-firmware" ]; then
    git clone --depth=1 https://github.com/mtk-openwrt/arm-trusted-firmware
else
    echo "Using existing atf repository"
    EXIST="yes"
fi


cd arm-trusted-firmware
cp ${rootdir}/u-boot.bin u-boot.bin
xz -f -e -k -9 -C crc32 u-boot.bin
echo "Building atf for BPIr3"
make -f Makefile PLAT="mt7986" BOOT_DEVICE=sdmmc BL33=u-boot.bin.xz DRAM_USE_DDR4=1 USE_MKIMAGE=1 MKIMAGE=../u-boot/tools/mkimage all fip
cd ${rootdir}

mv ${rootdir}/arm-trusted-firmware/build/mt7986/release/bl2.img ${rootdir}/
mv ${rootdir}/arm-trusted-firmware/build/mt7986/release/fip.bin ${rootdir}/

if [ -z "${EXIST}" ]; then
    echo "Cleaning up"
    rm -rf u-boot
fi
