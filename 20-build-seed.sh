#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

usage() {
    echo "Usage:  $(basename $0) -o OSK [-n FQDN] [-a ANSWERSFILE] [-v VERSION] [-p PASS] [-s SSHPUBKEY]"
    echo "        $(basename $0) -f [-n FQDN]"
    echo "        $(basename $0) -k [-n FQDN]"
    echo
    echo "Options:"
    echo "  -o           Path to OSK file."
    echo "  -n           Host FQDN (default: \"$fqdn\")."
    echo "  -a           Path to YAML answers file."
    echo "  -v           Orcharhino version (e.g. \"6.5\"; latest by default)"
    echo "  -p           Root user password (default: \"$rootpw\")."
    echo "  -s           Path to SSH public key file (default: \"$(ls -1 $HOME/.ssh/id_*.pub | head -n1)\")."
    echo "  -f           Install Foreman."
    echo "  -k           Install Foreman/Katello."
    echo "  -h           This help."
    exit 0
}

fqdn="rhino.atix-training.de"
rootpw="linux"
sshpubfile=$(ls -1 $HOME/.ssh/id_*.pub | head -n1)
orversion=

while getopts "fhk:o:n:a:v:p:s:" o; do
    case "${o}" in
        h)
            usage
            ;;
        o)
            oskfile="${OPTARG}"
            flavor="orcharhino"
            ;;
        n)
            fqdn="${OPTARG}"
            ;;
        a)
            answersfile="${OPTARG}"
            ;;
        v)
            orversion="${OPTARG}"
            ;;
        p)
            rootpw="${OPTARG}"
            ;;
        s)
            sshpubfile="${OPTARG}"
            ;;
        f)
            flavor="foreman"
            ;;
        k)
            flavor="foreman-katello"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ "$flavor" == "orcharhino" ]]; then
    if ! file -bi "$oskfile" | grep -q "text/xml"; then
        echo "Invalid OSK file '$oskfile'"
        exit 1
    else
        OSK_B64=$(base64 -w0 $oskfile)
    fi

    if [[ -r "$answersfile" ]]; then
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
if [[ ! "x$orversion" == "x" ]]; then
    OR_VERSION_OPTION="--or-version=$orversion"
fi

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
