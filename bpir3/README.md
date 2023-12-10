# BananaPI R3

NB! NB! WARNING!! This is not completed, its only a prototype that definitivly is not completed.

First try for building a image for the BPI-R3 board. 

For now it only includes the boot chain and boots into an u-boot shell with efi support ..

To build via official docker image:
```

docker run --rm -it --privileged -v $(pwd):/vyos -w /vyos vyos/vyos-build:current-arm64 bash

# Build kernel and dependencies
sudo ./build-vyos-kernel.sh

# Build vyos iso
sudo ./build-vyos-image.sh

# Build u-boot and ATF (Arm Trused Firmware)
sudo ./build-u-boot.sh
sudo ./ build-atf.sh

# Build BPIr3 image file
sudo ./build-img.sh
```

you will then have a image dd'able into a sd-card.
