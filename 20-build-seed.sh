#!/bin/bash
#
# Author Jan Löser <loeser@atix.de>
# Published under the GNU Public Licence 3

fqdn="rhino.atix-training.de"
rootpw="linux"

sshpubfile=$(ls -1 $HOME/.ssh/id_*.pub | head -n1)
oskfile="$1"
answersfile="$2"

if [[ "x$oskfile" == "x" ]]; then
    echo "Usage: $(basename $0) OSK-FILE [ANSWERS-FILE]"
    exit 1
fi

if ! file -bi "$oskfile" | grep -q "text/xml"; then
    echo "Invalid OSK file '$oskfile'"
    exit 1
fi

HASHED_PASSWD=$(openssl passwd -6 -salt $(openssl rand -hex 6) $rootpw)
if [[ -r "$sshpubfile" ]]; then
    SSH_AUTHORIZED_KEYS="
    ssh_authorized_keys: $(cat $sshpubfile)"
fi
OSK_B64=$(base64 -w0 $oskfile)
if [[ -r "$answersfile" ]]; then
    ANSWERS_FILE="
- encoding: b64
  content: $(base64 -w0 $answersfile)
  owner: root:root
  path: /root/answers.yaml
  permissions: '0644'"
fi
FQDN=$fqdn

cat > meta-data << EOF
instance-id: ${FQDN%%.*}
local-hostname: $FQDN
EOF

cat > user-data << EOF
#cloud-config
users:
  - name: root
    shell: /bin/bash
    lock_passwd: false
    ssh_pwauth: yes
    hashed_passwd: $HASHED_PASSWD $SSH_AUTHORIZED_KEYS
write_files:
- encoding: b64
  content: ${OSK_B64}
  owner: root:root
  path: /root/or-subscription-key.osk
  permissions: '0644' $ANSWERS_FILE
- content: |
    [Unit]
    Description=orcharhino Installation Wrapper Service (WebUI)
    After=cloud-final.service
    ConditionFileNotEmpty=!/etc/orcharhino-installer/answers.yaml

    [Service]
    Type=oneshot
    ExecStartPre=/usr/bin/chvt 2
    ExecStart=/bin/bash /root/install_orcharhino.sh -y /root/or-subscription-key.osk
    StandardInput=tty
    StandardOutput=journal+console
    TTYPath=/dev/tty2
    TTYReset=yes
    TTYVHangup=yes
  path: /etc/systemd/system/or-installation-webui.service
- content: |
    [Unit]
    Description=orcharhino Installation Wrapper Service
    After=cloud-final.service

    [Service]
    Type=oneshot
    ExecStartPre=/usr/bin/install -D /root/answers.yaml /etc/orcharhino-installer/answers.yaml
    ExecStartPre=/usr/bin/chvt 2
    ExecStart=/bin/bash /root/install_orcharhino.sh -y /root/or-subscription-key.osk -- --skip-gui
    StandardInput=tty
    StandardOutput=journal+console
    TTYPath=/dev/tty2
    TTYReset=yes
    TTYVHangup=yes
  path: /etc/systemd/system/or-installation.service
runcmd:
  - curl -o /root/install_orcharhino.sh https://acc-pub.atix.de/orcharhino_installer/latest/install_orcharhino.sh
  - test -e /root/answers.yaml && systemctl start --no-block or-installation.service || systemctl start --no-block or-installation-webui.service
  - setenforce 0
EOF

if [[ -x $(which mkisofs) ]]; then
    mkisofs -output seed.iso -volid cidata -joliet -rock ./user-data ./meta-data
elif [[ -x $(which genisoimage) ]]; then
    genisoimage -output seed.iso -volid cidata -joliet -rock ./user-data ./meta-data
else
    echo "No mkisofs/genisoimage available"
    exit 1
fi
