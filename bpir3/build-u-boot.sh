#!/bin/bash

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

if [ ! -d "u-boot" ]; then
    git clone --depth=1 https://github.com/mtk-openwrt/u-boot
else
    echo "Using existing u-boot repository"
    EXIST="yes"
fi


cp ${rootdir}/mt7986a_bpir3_efi_sd_defconfig ${rootdir}/u-boot/configs/mt7986a_bpir3_efi_sd_defconfig
cd u-boot
echo "Configuring u-boot for BPIr3"
make -s mt7986a_bpir3_efi_sd_defconfig
echo "Building u-boot for BPIr3"
make -s -j $(getconf _NPROCESSORS_ONLN)


mv ${rootdir}/u-boot/u-boot.bin ${rootdir}/u-boot.bin

if [ -z "${EXIST}" ]; then
    echo "Cleaning up"
    rm -rf u-boot
fi
