orcharhino Test Instance (cloud-init)

[[_TOC_]]


# General

Find more information about variables in `./answers-default.yaml` here:
https://git.atix.de/ansible/roles/or_installation/-/blob/main/README.md#answersyaml-file-variables

For automatic installation of orcharhino, invoke `./20-build-seed.sh` with
'answers.yaml' file parameter:
```
$ ./20-build-seed.sh ~/alma8.osk ./answers-default.yaml
```

To launch web UI installer, do not provide 'answers.yaml' file parameter:
```
$ ./20-build-seed.sh ~/alma8.osk
```


# QEMU

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
$ ./20-build-seed.sh ~/alma8.osk ./answers-default.yaml
$ ./30-create-snapshot.sh alma
$ ./50-run-qemu.sh
```
Check the tty output for progress.

Available ports for connection:
- SSH: 10022 (`$ ssh -p 10022 root@localhost`)
- Web UI installer: 8015 (http://localhost:8015)
- Web UI: 8443 (https://localhost:8443)


# VMware

Convert the image locally and copy it to the ESXi host:
```
$ ./10-get-generic-image.sh alma
$ qemu-img convert -f qcow2 -O vmdk alma8-uefi.qcow2 alma8-uefi.vmdk
$ scp ./alma8-uefi.vmdk root@192.168.145.4:/vmfs/volumes/57f5ee0e-329bfdc1-2056-002590e5da3a/cloud-init-images/
```

Convert the image a 2nd time on ESXi host and resize:
```
[root@dinoesxi:cloud-init-images] vmkfstools -i alma8-uefi.vmdk -d thin alma8-uefi-vmware.vmdk
Destination disk format: VMFS thin-provisioned
Cloning disk 'alma8-uefi.vmdk'...
Clone: 100% done.
[root@dinoesxi:cloud-init-images] vmkfstools -X 100G alma8-uefi-vmware.vmdk
```

Generate seed ISO and copy it to ESXi host:
```
$ ./20-build-seed.sh ~/alma8.osk [./answers-default.yaml]
$ scp ./seed.iso root@192.168.145.4:/vmfs/volumes/57f5ee0e-329bfdc1-2056-002590e5da3a/cloud-init-images/seed-alma8.iso
```

Create a VM in VMware (with at least minimal system requirements) and add:
- "Existing Hard Disk" using `alma8-uefi-vmware.vmdk`
- "CD/DVD Drive" using `seed-alma8.iso`


# AWS EC2

Generate `user-data` file and upload it under "EC2 > Instances > Launch an
instance > Advanced details > User data" when creating a new instance:

```
$ ./20-build-seed.sh ~/alma8.osk [./answers-default.yaml]
$ ls -1 ./user-data
./user-data
```

# How to deploy AWS Infrastructure

This repository contains Terraform code for deploying an AWS Virtual Private Cloud (VPC), Security Group (currently all ports open), and an EC2 instance with userdata from the previous step.

Prerequisites:
- Terraform installed on your local machine
- AWS Credentials with appropriate permissions

To deploy this terraform code cd into the aws-terraform-infrastructure folder and do the following steps:

$ terraform init  - to initialize the terraform working directory and download all required modules, then

$ terraform plan  - to print out the plan of what will code do

$ terraform apply - confirm the deployment by typing yes when prompted. Terraform will create the VPC, security group, and EC2 instance based on the provided configuration.



