# vyos-pi-builder

Build VyOS 1.4 image on pi4

Quick build instructions:
 * install a 64bit debian/ubuntu (haven't tried using raspbian) on a pi and install docker
   - https://ubuntu.com/raspberry-pi
   - https://phoenixnap.com/kb/docker-on-raspberry-pi

 * build the official vyos-build docker container as `vyos/vyos-build:current-arm64`
   This can take an hour++ to complete

   ```
   sudo docker build https://github.com/vyos/vyos-build.git#current:docker -t vyos/vyos-build:current-arm64
   ```

 * Build a Pi image:
   ```
   git clone https://github.com/runborg/vyos-pi-builder
   cd vyos-pi-builder
   sudo docker run -it --privileged -v "$(pwd)":/vyos -v /dev:/dev -w /vyos --sysctl net.ipv6.conf.lo.disable_ipv6=0 vyos/vyos-build:current-arm64 sudo bash -x build-image.sh
   ```


Build VyOS 1.4 image on an x86 linux host using qemu-user-static and docker/podman

 * Prerequisites
    - docker/podman 
    - qemu-user-static

 * build the official vyos-build docker container as `vyos/vyos-build:current-arm64`
   This can take an hour++ to complete

   ```
   git clone -b current --single-branch https://github.com/vyos/vyos-build
   sudo docker build --platform linux/arm64 vyos-build/docker -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -t vyos/vyos-build:current-arm64

   ```
   or with make
   ```
   make container
   ```

 * Build a Pi kernel:

   You must build the kernel the first time and when the kernel is upgraded.

   The required kernel version information by VyOS is [here](https://github.com/vyos/vyos-build/blob/current/data/defaults.toml) and the provided kernel version information for Raspberry Pi is [here](https://github.com/raspberrypi/linux/blob/rpi-6.1.y/Makefile).
   
   If the version of the kernel you need is different from the kernel provided for pi, you will need to prepare the kernel by other means instead of using the command below.

   ```
   sudo docker run --rm -it --platform linux/arm64 --privileged -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 localhost/vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-pi-kernel.sh'
   ```

   or with make

   ```
   make kernel-local
   ```

   you can also take already built container in docker registry and use that.

   ```
   make kernel-registry
   ```
 * Build a Pi image:
   ```
   git clone https://github.com/runborg/vyos-pi-builder
   cd vyos-pi-builder
   sudo docker run --rm -it --platform linux/arm64 --privileged -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 localhost/vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-image.sh'
   ```

   or with make

   ```
   make iso-local
   ```
   
   you can also take already built container in docker registry and use that.

   ```
   make iso-registry
   ```
