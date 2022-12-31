set -x
set -e
ROOTDIR=$(pwd)

# Clean out the build-repo and copy all custom packages
rm -rf vyos-build
git clone http://github.com/vyos/vyos-build vyos-build
for a in $(find build -type f -name "*.deb" | grep -v -e "-dbgsym_" -e "libnetfilter-conntrack3-dbg"); do
	echo "Copying package: $a"
	cp $a vyos-build/packages/
done

# Patch to build-vyos-image script
patch -t -u vyos-build/scripts/build-vyos-image < patches/0001_build-vyos-image.patch

# Build to arm64.toml
patch -t -u vyos-build/data/architectures/arm64.toml < patches/0002_arm64.toml.patch

# Set GPG key of InfluxData repository
curl https://repos.influxdata.com/influxdb.key > vyos-build/data/live-build-config/archives/influxdb.key.chroot

cd vyos-build

echo "Copy new default configuration to the vyos image"
cp ${ROOTDIR}/config.boot.default data/live-build-config/includes.chroot/opt/vyatta/etc/config.boot.default

# Build the image
#VYOS_BUILD_FLAVOR=data/generic-arm64.json
#./configure
#make iso
./build-vyos-image iso --architecture arm64

cd $ROOTDIR

# Build u-boot
bash build-u-boot.sh

# Generate CM4 image from the iso
DEVTREE="bcm2711-rpi-cm4" PIVERSION=4 bash build-pi-image.sh vyos-build/build/live-image-arm64.hybrid.iso

# Generate PI4 image from the iso
DEVTREE="bcm2711-rpi-4-b" PIVERSION=4 bash build-pi-image.sh vyos-build/build/live-image-arm64.hybrid.iso

# Generate PI3B image from the iso
#DEVTREE="bcm2710-rpi-3-b" PIVERSION=3 bash build-pi-image.sh vyos-build/build/live-image-arm64.hybrid.iso

# Generate PI3B+ image from the iso
#DEVTREE="bcm2710-rpi-3-b-plus" PIVERSION=3 bash build-pi-image.sh vyos-build/build/live-image-arm64.hybrid.iso

# Symlink pi4 image
#ln -s vyos-build/build/live-image-arm64.hybrid.img live-image-arm64.hybrid.img
