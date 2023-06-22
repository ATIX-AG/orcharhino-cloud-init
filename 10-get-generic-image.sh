#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

dist=$1

declare -A images
images[alma]=https://repo.almalinux.org/almalinux/8.8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2
images[rocky]=https://download.rockylinux.org/pub/rocky/8.8/images/x86_64/Rocky-8-GenericCloud-Base.latest.x86_64.qcow2
images[oracle]=https://yum.oracle.com/templates/OracleLinux/OL8/u8/x86_64/OL8U8_x86_64-kvm-b198.qcow
# RHEL: https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.8/x86_64/product-software

if ! [[ "$dist" =~ ^(alma|rocky|oracle)$ ]]; then
    echo "Usage: $(basename $0) alma|rocky|oracle"
    exit 1
fi

imgfile="$dist-generic-image.qcow2"
mkdir -p ./images

if ! [[ -r "./images/$imgfile" ]]; then
    wget ${images[$dist]} -O "./images/$imgfile"
fi
