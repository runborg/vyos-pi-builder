#!/bin/bash
set -e
set -x

ROOTDIR=$(pwd)

if [ ! -d "$DIRECTORY" ]; then
    git clone https://github.com/vyos/vyos-build
fi

cd vyos-build
#Patching vyos-build
echo "I: Patching vyos-build"
PATCH_DIR=${ROOTDIR}/patches/vyos-build
for patch in $(ls ${PATCH_DIR})
do
    echo "I: Apply patch: ${PATCH_DIR}/${patch}"
    patch -p1 < ${PATCH_DIR}/${patch}
done

echo "I: Copying extra files to repo"
cp -vr ${ROOTDIR}/vyos-build-files/* .

cd ${ROOTDIR}/vyos-build/packages/linux-kernel/
./get-n-build.sh
