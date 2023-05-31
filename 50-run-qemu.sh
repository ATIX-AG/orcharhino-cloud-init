#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

dist=$1

if ! [[ "$dist" =~ ^(alma|rocky)$ ]]; then
    echo "Usage: $(basename $0) alma|rocky"
    exit 1
fi

imgfile="$dist-snap.qcow2"

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host -smp cores=4,threads=1 \
    -m 20G \
    -serial mon:stdio \
    -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 \
    -net nic,model=virtio -net user,hostfwd=tcp::10041-:22,hostfwd=tcp::8015-:8015,hostfwd=tcp::8443-:443,hostfwd=tcp::8080-:80 \
    -drive file=./images/$imgfile,format=qcow2 \
    -drive media=cdrom,file=./seed.iso,readonly=on
