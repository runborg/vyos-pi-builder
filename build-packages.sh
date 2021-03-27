#!/bin/bash
#
# Copyright (C) 2021 VyOS maintainers and contributors
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 or later as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# File: 
# Purpose:
# Automatically build all packages needed for Raspberry PI 4 VyOS image.

if [ ! -z "${DEBUG}" ]; then
    set -x
fi
set -e

if [[ ${EUID} -ne 0 ]]; then
    1>&2 echo "ERROR: This tool must be run as root"
    exit 1
fi

CWD=$(pwd)
BUILDDIR=$CWD/build


if [ ! -d "build" ]; then
    mkdir -p $BUILDDIR
fi
cd $BUILDDIR

if [ ! -d "vyos-build" ]; then
    git clone git://github.com/vyos/vyos-build
else
    echo "Using existing vyos-build repository"
    EXIST="yes"
fi

# Packages to build: 
# accel-ppp
# frr
# linux-kernel
# OK: hvinfo
# OK: ipaddrcheck
# OK: libnss-mapuser
# OK: libpam-radius-auth
# OK: libvyosconfig
# OK: mdns-repeater
# OK: vyatta-conntrack
# OK: vyos-1x
# vyos1x-config
# OK: vyos-utils
# OK: vyos-world

#Install deps and setup vyos-utils
eval $(opam env --root=/opt/opam --set-root) 

# Build vyos repositories:
# Disabled repos: conntrack-tools
for x in vyos-1x; do
    cd $BUILDDIR
    echo "Checking for $x"
    FILECHECK=$x
    if ! ls *$FILECHECK*.deb; then
	if [ ! -d $x ]; then
	    echo "$x not found, fetching"
	    git clone git://github.com/vyos/$x $x
	fi
	if [[ "$x" == "vyos-1x" ]]; then
	    sudo patch -p 1 -u -d $BUILDDIR/$x < $CWD/vyos-1x_disable_xdp_patch.patch
	fi
        echo "Building $x"
	cd $BUILDDIR/$x
   	dpkg-buildpackage -b -us -uc -tc
    fi
done


# Linux kernel
cd $BUILDDIR/vyos-build/packages/linux-kernel
if ! ls *.deb; then
    if [ ! -d linux ]; then
        echo "Fetching kernel"
	git clone --depth=1 https://github.com/raspberrypi/linux -b rpi-5.10.y linux
    fi

    echo "Building Kernel"
    cp $CWD/arm64_rpi4_defconfig $BUILDDIR/vyos-build/packages/linux-kernel
    sed -i s/x86_64_vyos_defconfig/arm64_rpi4_defconfig/ build-kernel.sh
    sed -i s/x86/arm64/ build-kernel.sh
    sed -i s/-vyos/-rpi4-vyos/ build-kernel.sh
    bash -x -e ./build-kernel.sh
fi

#Accel-ppp
cd $BUILDDIR/vyos-build/packages/linux-kernel
if ! ls accel-ppp*.deb; then
    if [ ! -d accel-ppp ]; then
        echo "Fetching Accel-PPP"
	git clone https://github.com/accel-ppp/accel-ppp.git accel-ppp 
	( cd accel-ppp && git checkout 59f8e1bc3f199c8d0d985253e19a74ad87130179 )
    fi
    cd $BUILDDIR/vyos-build/packages/linux-kernel
    bash -x -e ./build-accel-ppp.sh
fi

# Vyos-linux-firmware
cd $BUILDDIR/vyos-build/packages/linux-kernel
if ! ls vyos-linux-firmware*.deb; then
    if [ ! -d linux-firmware ]; then
        echo "Fetching linux-firmware"
        git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git linux-firmware
    fi
    bash -x -e ./build-linux-firmware.sh
fi
