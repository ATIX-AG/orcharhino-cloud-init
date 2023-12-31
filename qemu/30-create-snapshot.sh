#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

dist=$1
workdir=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))

if ! [[ "$dist" =~ ^(alma|rocky|oracle|rhel)$ ]]; then
    echo "Usage: $(basename $0) alma|rocky|oracle|rhel"
    exit 1
fi

imgfile="$dist-generic-image.qcow2"
imgsnapfile="snap.qcow2"

qemu-img create \
    -f qcow2 \
    -b "$imgfile" \
    -F qcow2 \
    "$workdir/images/$imgsnapfile"

qemu-img resize "$workdir/images/$imgsnapfile" +20G
