
container:
	sudo rm -rf vyos-build
	git clone -b current --single-branch https://github.com/vyos/vyos-build
	sudo docker build --platform linux/arm64 vyos-build/docker -t vyos/vyos-build:current-arm64

kernel-local:
	sudo docker run --rm -t --platform linux/arm64 --privileged -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 localhost/vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-pi-kernel.sh'

kernel-registry:
	sudo docker run --rm -t --platform linux/arm64 --privileged -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-pi-kernel.sh'

iso-local:
	sudo docker run --rm -t --platform linux/arm64 --privileged -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 localhost/vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-image.sh'

iso-registry:
	sudo docker run --rm -t --platform linux/arm64 --privileged -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static -v "$(shell pwd)":/vyos -v /dev:/dev --sysctl net.ipv6.conf.lo.disable_ipv6=0 vyos/vyos-build:current-arm64 /bin/bash -c 'cd /vyos; /bin/bash -x build-image.sh'
