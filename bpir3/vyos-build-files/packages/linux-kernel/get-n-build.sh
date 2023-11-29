#!/bin/bash
set -e
set -x
rm -rf linux* accel-ppp ovpn-dco

echo I: Fetching kernel
#KERNEL_VER='6.1.60'
KERNEL_VER=$(cat ../../data/defaults.toml | tomlq -r .kernel_version)
gpg2 --locate-keys torvalds@kernel.org gregkh@kernel.org
curl -OL https://www.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VER}.tar.xz
curl -OL https://www.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VER}.tar.sign
xz -cd linux-${KERNEL_VER}.tar.xz | gpg2 --verify linux-${KERNEL_VER}.tar.sign -
if [ $? -ne 0 ]; then
    exit 1
fi

# Unpack Kernel source
tar xf linux-${KERNEL_VER}.tar.xz
ln -s linux-${KERNEL_VER} linux
# ... Build Kernel

CONFIG_DEBUG_INFO=n ./build-kernel.sh
#LD='/usr/aarch64-linux-gnu/bin/ld' CONFIG_DEBUG_INFO=n CROSS_COMPILE='ccache aarch64-linux-gnu-' ARCH='arm64' time fakeroot ./build-kernel.sh






echo I: Fetching linux-firmware
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
( cd linux-firmware; git reset --hard 20230625 )
./build-linux-firmware.sh




echo I: Build Accel-PPP
git clone https://github.com/accel-ppp/accel-ppp.git
( cd accel-ppp; git reset --hard 9669bcb99adc )
./build-accel-ppp.sh

echo I: Build Jool
./build-jool.py
for package in $(ls jool_*.deb)
do
    ln -sf linux-kernel/$package ..
done

echo I: Build OpenVPN DCO
git clone https://github.com/OpenVPN/ovpn-dco
(cd ovpn-dco; git reset --hard v0.2.20231010 )
#(cd ovpn-dco; git reset --hard v0.2.20230426 )
./build-openvpn-dco.sh

