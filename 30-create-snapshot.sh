#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

dist=$1

if ! [[ "$dist" =~ ^(alma|rocky)$ ]]; then
    echo "Usage: $(basename $0) alma|rocky"
    exit 1
fi

imgfile="$dist-generic-image.qcow2"
imgsnapfile="$dist-snap.qcow2"

qemu-img create \
    -f qcow2 \
    -b "$imgfile" \
    -F qcow2 \
    "./images/$imgsnapfile"

qemu-img resize "./images/$imgsnapfile" +20G
