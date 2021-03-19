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
for x in vyos-1x vyos-utils vyos-world vyatta-conntrack mdns-repeater hvinfo ipaddrcheck libvyosconfig libnss-mapuser libpam-radius-auth vyos-strongswan libnetfilter-conntrack vyatta-cfg udp-broadcast-relay vyatta-bash vyatta-wanloadbalance vyos-opennhrp; do
    echo "Checking for $x"
    FILECHECK=$x
    if [[ "$x" == "vyos-strongswan" ]]; then
        FILECHECK="strongswan"
    fi
    if ! ls *$FILECHECK*.deb; then
	if [ ! -d $x ]; then
	    echo "$x not found, fetching"
	    cd $BUILDDIR
	    git clone git://github.com/vyos/$x $x
	fi
	if [[ "$x" == "vyos-utils" ]]; then
            echo "Installing deps for vyos-utils"
	    opam install containers
	fi
	if [[ "$x" == "conntrack-tools" ]]; then
            echo "Installing deps for conntrack-tools"
            apt install -y dh-systemd libnetfilter-conntrack-dev
        fi
        echo "Building $x"
	cd $BUILDDIR/$x
   	dpkg-buildpackage -b -us -uc -tc
    fi
done


# Build FRR

cd $BUILDDIR/vyos-build/packages/frr
FRR_VERSION=$(sed -ne "s/.*scmCommit.: '\(.*\)',/\1/p" Jenkinsfile)
FRR_REPO=$(sed -ne "s/.*scmUrl.: '\(.*\)',/\1/p" Jenkinsfile)
if ! ls frr*.deb; then
    if [ ! -d frr ]; then
        echo "Fetching FRR"
        git clone ${FRR_REPO} -b ${FRR_VERSION}
    fi
    echo "Building FRR"
    ./build-frr.sh
fi

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

#IPRoute2
cd $BUILDDIR/vyos-build/packages/iproute2/
if ! ls iproute2*.deb; then
    if [ ! -d iproute2 ]; then
        echo "Fetching linux-firmware"
        git clone https://salsa.debian.org/debian/iproute2 -b debian/5.10.0-3 iproute2
    fi
      cd $BUILDDIR/vyos-build/packages/iproute2/iproute2
      dpkg-buildpackage -uc -us -tc -b -d
fi

# Netfilter
cd $BUILDDIR/vyos-build/packages/netfilter
if ! ls *libnftnl*.deb; then
    if [ ! -d pkg-libnftnl ]; then
        echo "Fetching pkg-netfilter"
          git clone https://salsa.debian.org/pkg-netfilter-team/pkg-libnftnl.git pkg-libnftnl
    fi
    cd $BUILDDIR/vyos-build/packages/netfilter/pkg-libnftnl
    dpkg-buildpackage -uc -us -tc -b -d
fi

# Netfilter - nftables
cd $BUILDDIR/vyos-build/packages/netfilter
if ! ls *nftables*.deb; then
    if [ ! -d pkg-nftables ]; then
        echo "Fetching nftables"
          git clone https://salsa.debian.org/pkg-netfilter-team/pkg-nftables.git -b 'debian/0.9.6-1' pkg-nftables
    fi
    cd $BUILDDIR/vyos-build/packages/netfilter/pkg-nftables
    dpkg -i ../libnftnl*.deb 
    sed -i "s/debhelper-compat.*/debhelper-compat (= 12),/" debian/control 
    dpkg-buildpackage -uc -us -tc -b -d
fi

# libnetfilter-conntrack
cd $BUILDDIR/vyos-build/packages/netfilter
if ! ls *libnetfilter-conntrack*.deb; then
    if [ ! -d pkg-libnetfilter-conntrack ]; then
        echo "Fetching pkg-libnetfilter-conntrack"
          git clone https://salsa.debian.org/pkg-netfilter-team/pkg-libnetfilter-conntrack.git -b 'debian/1.0.8-1' pkg-libnetfilter-conntrack
    fi
      cd $BUILDDIR/vyos-build/packages/netfilter/pkg-libnetfilter-conntrack
      dpkg-buildpackage -uc -us -tc -b -d
fi

# conntrack-tools
cd $BUILDDIR/vyos-build/packages/netfilter
if ! ls *conntrack*.deb; then
    if [ ! -d pkg-conntrack-tools ]; then
        echo "Fetching pkg-conntrack-tools"
          git clone https://salsa.debian.org/pkg-netfilter-team/pkg-conntrack-tools.git -b 'debian/1%1.4.6-1' pkg-conntrack-tools
    fi
      cd $BUILDDIR/vyos-build/packages/netfilter/pkg-conntrack-tools
      sudo dpkg -i ../libnetfilter*.deb
      dpkg-buildpackage -uc -us -tc -b -d
fi

# wide-dhcpv6
cd $BUILDDIR/vyos-build/packages/wide-dhcpv6
if ! ls *.deb; then
    if [ ! -d wide-dhcpv6 ]; then
        echo "Fetching wide-dhcpv6"
          git clone https://salsa.debian.org/debian/wide-dhcpv6 -b 'debian/20080615-23' wide-dhcpv6
    fi
    cd $BUILDDIR/vyos-build/packages/wide-dhcpv6 
    bash -x -e ./build-wide.sh
fi
