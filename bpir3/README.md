# BananaPI R3

NB! NB! WARNING!! This is not completed, its only a prototype that definitivly is not completed.

First try for building a image for the BPI-R3 board. 

For now it only includes the boot chain and boots into an u-boot shell with efi support ..

To build:
```
./build-u-boot.sh
./build-atf.sh
./build-img.sh
```

you will then have a image dd'able into a sd-card.
