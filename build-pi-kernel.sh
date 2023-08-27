set -x
set -e
ROOTDIR=$(pwd)

# Clean out the build-repo and copy all custom packages
rm -rf vyos-build
git clone http://github.com/vyos/vyos-build vyos-build


cd vyos-build/packages/linux-kernel/

echo "Build kernel for pi"
git clone https://github.com/raspberrypi/linux
git checkout -b rpi-6.1.y
cp linux/arch/arm64/configs/bcm2711_defconfig arch/arm64/configs/vyos_defconfig
patch -t -u arch/arm64/configs/vyos_defconfig < ${ROOTDIR}/patches/0001_bcm2711_defconfig.patch
./build-kernel.sh
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
./build-linux-firmware.sh
git clone https://github.com/accel-ppp/accel-ppp.git
./build-accel-ppp.sh
git clone --depth=1 https://github.com/OpenVPN/ovpn-dco -b v0.2.20230426
./build-openvpn-dco.sh

cd ${ROOTDIR}
mkdir -p build
find vyos-build/packages/linux-kernel/ -type f | grep '\.deb$' | xargs -I {} cp {} build/
