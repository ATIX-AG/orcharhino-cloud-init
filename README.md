# orcharhino Test Instance (cloud-init)

## Usage

To start local QEMU instance with interactive orcharhino web UI installer, run:
```
$ ./10-get-generic-image.sh alma
$ ./20-build-seed.sh ~/alma8.osk
$ ./30-create-snapshot.sh alma
$ ./50-run-qemu.sh
```
Check the tty output for the URL to the installer.

Alternatively, log in as `root` on the serial console and check `journalctl` for
the URL.

To start local QEMU instance without interactive installer, run:
```
$ ./10-get-generic-image.sh alma
$ ./20-build-seed.sh ~/alma8.osk ./answers-qemu-simple.yaml
$ ./30-create-snapshot.sh alma
$ ./50-run-qemu.sh
```
Check the tty output for progress.

## Connections (QEMU)

Available ports for connection:
- SSH: 10022 (`$ ssh -p 10022 root@localhost`)
- Web installer: 18015 (http://localhost:18015)
- Web UI: 8443 (https://localhost:8443)
