#!/bin/bash
if [ ! -z "${DEBUG}" ]; then
    set -x
fi
set -e

if [ ! -d "u-boot" ]; then
    git clone --depth=1 git://git.denx.de/u-boot.git
else
    echo "Using existing u-boot repository"
    EXIST="yes"
fi

(
    cd u-boot
    echo "Configuring u-boot for PI4"
    make -s rpi_4_defconfig 
    echo "Building u-boot for PI4"
    make -s -j $(getconf _NPROCESSORS_ONLN)
)

mv u-boot/u-boot.bin u-boot-rpi4.bin

#(
#    cd u-boot
#    echo "Configuring u-boot for PI3"
#    make -s rpi_3_defconfig
#    echo "Building u-boot for PI3"
#    make -s
#)
#
#mv u-boot/u-boot.bin u-boot-rpi3.bin

if [ -z "${EXIST}" ]; then
    echo "Cleaning up"
    rm -rf u-boot
fi
