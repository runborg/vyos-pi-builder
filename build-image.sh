set -x
set -e
ROOTDIR=$(pwd)

# Build all packages
bash build-packages.sh

# Clean out the build-repo and copy all custom packages
rm -rf vyos-build
git clone http://github.com/vyos/vyos-build vyos-build
for a in $(find build -type f -name "*.deb" | grep -v -e "-dbgsym_" -e "libnetfilter-conntrack3-dbg"); do
	echo "Copying package: $a"
	cp $a vyos-build/packages/
done

cd vyos-build
#Kernel version
KERNEL_VERSION=$(dpkg -I packages/linux-image*.deb | sed -ne "s/.*Version: \(.*\)-[0-9]/\1/p")
KERNEL_FLAVOR=$(dpkg -I packages/linux-image*.deb | sed -ne "s/.*Package: linux-image-[^-]*-\(.*\)/\1/p")

# Update kernel to current version
jq ".kernel_version=\"$KERNEL_VERSION\" | .kernel_flavor=\"$KERNEL_FLAVOR\" | .architecture=\"arm64\"" data/defaults.json > data/defaults.json.tmp
mv data/defaults.json.tmp data/defaults.json

# Disable syslinux
sed -i "s/--bootloader syslinux,grub-efi/--bootloader grub-efi/" scripts/live-build-config

# Remove openvmtools hooks that are not needed on arm
rm -rf data/live-build-config/hooks/live/30-openvmtools-configs.chroot

# Build the image
./configure
make iso

cd $ROOTDIR

# Build u-boot
bash build-u-boot.sh

# Install some needed dependencies for image build that is not in the container
apt install parted udev zip

# Generate PI4 image from the iso
bash build-pi-image.sh vyos-build/build/live-image-arm64.hybrid.iso

# Symlink pi4 image
ln -s vyos-build/build/live-image-arm64.hybrid.img live-image-arm64.hybrid.img
