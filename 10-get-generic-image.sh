#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

dist=$1

declare -A images
images[alma]=https://repo.almalinux.org/almalinux/8.8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2
images[rocky]=https://download.rockylinux.org/pub/rocky/8.8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2

if ! [[ "$dist" =~ ^(alma|rocky)$ ]]; then
    echo "Usage: $(basename $0) alma|rocky"
    exit 1
fi

imgfile="$dist-generic-image.qcow2"
mkdir -p ./images

if ! [[ -r "./images/$imgfile" ]]; then
    wget ${images[$dist]} -O "./images/$imgfile"
fi
