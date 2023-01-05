set -x
set -e
ROOTDIR=$(pwd)

# Clean out the build-repo and copy all custom packages
rm -rf vyos-build
git clone http://github.com/vyos/vyos-build vyos-build

# Patch to build-linux-firmware.sh
#patch -t -u vyos-build/packages/linux-kernel/build-linux-firmware.sh < patches/0000_build-linux-firmware.sh.patch

# Patch to vyos_defconfig
patch -t -u vyos-build/packages/linux-kernel/arch/arm64/configs/vyos_defconfig < patches/0004_vyos_defconfig.patch

cd vyos-build/packages/linux-kernel/

echo "Build kernel for pi"
git clone https://github.com/raspberrypi/linux
./build-kernel.sh
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
./build-linux-firmware.sh
git clone https://github.com/accel-ppp/accel-ppp.git
./build-accel-ppp.sh

