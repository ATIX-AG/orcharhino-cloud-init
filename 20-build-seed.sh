#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

fqdn="rhino.atix-training.de"
rootpw="linux"
flavor="${FLAVOR:-orcharhino}"

sshpubfile=$(ls -1 $HOME/.ssh/id_*.pub | head -n1)
oskfile="$1"
answersfile="$2"

if [[ "$flavor" == "orcharhino" ]]; then
    if [[ "x$oskfile" == "x" ]]; then
        echo "Usage:                        $(basename $0) OSK-FILE [ANSWERS-FILE]"
        echo "       FLAVOR=foreman         $(basename $0)"
        echo "       FLAVOR=foreman-katello $(basename $0)"
        exit 1
    fi

    if ! file -bi "$oskfile" | grep -q "text/xml"; then
        echo "Invalid OSK file '$oskfile'"
        exit 1
    else
        OSK_B64=$(base64 -w0 $oskfile)
    fi

    if [[ -r "$answersfile" ]]; then
        echo "b"
        ANSWERS_FILE="
- encoding: b64
  content: $(base64 -w0 $answersfile)
  owner: root:root
  path: /root/answers.yaml
  permissions: '0644'"
    fi
fi
HASHED_PASSWD=$(openssl passwd -6 -salt $(openssl rand -hex 6) $rootpw)
if [[ -r "$sshpubfile" ]]; then
    SSH_AUTHORIZED_KEYS="
    ssh_authorized_keys: $(cat $sshpubfile)"
fi
FQDN=$fqdn

eval "cat > meta-data <<EOF
$(<./meta-data.$flavor.skel)
EOF
" 2> /dev/null

eval "cat > user-data <<EOF
$(<./user-data.$flavor.skel)
EOF
" 2> /dev/null

if [[ -x $(which mkisofs) ]]; then
    mkisofs -output seed.iso -volid cidata -joliet -rock ./user-data ./meta-data
elif [[ -x $(which genisoimage) ]]; then
    genisoimage -output seed.iso -volid cidata -joliet -rock ./user-data ./meta-data
else
    echo "No mkisofs/genisoimage available"
    exit 1
fi
