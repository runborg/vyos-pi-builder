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
