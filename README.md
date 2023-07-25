orcharhino Test Instance (cloud-init)

[[_TOC_]]


# Introduction

This repository provides convenient ways to install orcharhino or Foreman
(+Katello) on various virtualization platforms (including plain QEMU) using
[Cloud-Init](https://cloudinit.readthedocs.io/en/latest/).

For orcharhino, an orcharhino subscription key (OSK) file is mandatory that
matches the desired host OS ([Subscription Keys for
testing](https://atix.atlassian.net/wiki/spaces/AXCONS/pages/265027585/Subscription+Keys+for+testing)).
This is not needed for Foreman (+Katello) installation.

For orcharhino, an "answers" file is optional that configures the installer.
This allows an automatic installation without manual interaction in the web UI
installer.
This is not needed for Foreman (+Katello) installation.

The output of the installation process can be viewed on /dev/tty2 and the
system's journal (`journalctl`).

Use [or-content-setup](https://git.atix.de/janloe/or-content-setup) to fill your
brand new orcharhino instance with content.


# Preparations

## orcharhino

For automatic installation of orcharhino, invoke `./build-seed` with
answers file parameter:
```
$ ./build-seed -o ~/alma8.osk -a ./answers-default.yaml
```
Find more information about variables used in `./answers-default.yaml` at
[or_installation](
https://git.atix.de/ansible/roles/or_installation/-/blob/main/README.md#answersyaml-file-variables)
role.

To launch web UI installer, do not provide answers file parameter:
```
$ ./build-seed -o ~/alma8.osk
```


## Foreman

For automatic installation of Foreman, run:
```
$ ./build-seed -f
```
> **NOTE**
> Providing an answers file is currently not supported.

For automatic installation of Foreman with Katello, run:
```
$ ./build-seed -k
```


# QEMU

To start local QEMU instance with interactive orcharhino web UI installer, run:
```
$ ./qemu/10-get-generic-image.sh alma
$ ./build-seed -o ~/alma8.osk
$ ./qemu/30-create-snapshot.sh alma
$ ./qemu/50-run-qemu.sh
```
Check the tty output for the URL to the installer.

Alternatively, log in as `root` on the serial console and check `journalctl` for
the URL.

To start local QEMU instance without interactive installer, run:
```
$ ./qemu/10-get-generic-image.sh alma
$ ./build-seed -o ~/alma8.osk -a ./answers-default.yaml
$ ./qemu/30-create-snapshot.sh alma
$ ./qemu/50-run-qemu.sh
```
Check the tty output for progress.

Available ports for connection:
- SSH: 10022 (`$ ssh -p 10022 root@localhost`)
- Web UI installer: 8015 (http://localhost:8015)
- Web UI: 8443 (https://localhost:8443)

> **NOTE**
> Re-run `./qemu/30-create-snapshot.sh alma` to reset your current snapshot.
> Be careful not to delete data unintentionally!


# Proxmox

Provide the image on Proxmox server (a direct download on the server is probably
faster) and `user-data`/`meta-data`:
```
$ ./build-seed -o ~/alma8.osk -a ./answers-default.yaml
$ ./qemu/10-get-generic-image.sh alma
$ scp ./qemu/images/alma-generic-image.qcow2 proxmox:/var/lib/vz/images/
$ scp ./{user,meta}-data proxmox:/var/lib/vz/snippets/
```

Create & start the VM:
```
$ ssh proxmox
root@proxmox:~# qm create 125 --memory 16384 --net0 virtio,bridge=vmbr0,tag=168 --scsihw virtio-scsi-pci --name or-alma8
root@proxmox:~# qm set 125 --scsi0 local-lvm:0,import-from=/var/lib/vz/images/alma-generic-image.qcow2
...
root@proxmox:~# qm set 125 --ide2 local-lvm:cloudinit
root@proxmox:~# qm set 125 --cicustom "meta=local:snippets/meta-data"
root@proxmox:~# qm set 125 --cicustom "user=local:snippets/user-data"
root@proxmox:~# qm set 125 --boot order=scsi0
root@proxmox:~# qm set 125 --serial0 socket --vga serial0
root@proxmox:~# qm start 125
root@proxmox:~# qm terminal 125
...
AlmaLinux 8.8 (Sapphire Caracal)
Kernel 4.18.0-477.10.1.el8_8.x86_64 on an x86_64

Activate the web console with: systemctl enable --now cockpit.socket

rhino login:
```
Installation output can be followed with `journalctl -f`.

More information: https://proxmox-noris.corp.atix.de/pve-docs/pve-admin-guide.html#qm_cloud_init

Alternatively, copy `seed.iso` to the Proxmox server and add this ISO as virtual
CD/DVD to the VM.

> **IMPORTANT**
> Sometimes user-/meta-data wasn't provided correctly (root login not working,
> no hostname set)! After re-running `qm set 125 --cicustom ...` commands it
> worked.

> **IMPORTANT**
> Do not trust `qm cloudinit dump 125 user` output. This does not print the
> expected output.


# VMware

Convert the image locally and copy it to the ESXi host:
```
$ ./qemu/10-get-generic-image.sh alma
$ qemu-img convert -f qcow2 -O vmdk ./qemu/images/alma-generic-image.qcow2.qcow2 alma8-uefi.vmdk
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
$ ./build-seed -o ~/alma8.osk [-a ./answers-default.yaml]
$ scp ./seed.iso root@192.168.145.4:/vmfs/volumes/57f5ee0e-329bfdc1-2056-002590e5da3a/cloud-init-images/seed-alma8.iso
```

Create a VM in VMware (with at least minimal system requirements) and add:
- "Existing Hard Disk" using `alma8-uefi-vmware.vmdk`
- "CD/DVD Drive" using `seed-alma8.iso`


# AWS EC2

## Deploy Manually

Generate `user-data` file and upload it under "EC2 > Instances > Launch an
instance > Advanced details > User data" when creating a new instance:
```
$ ./build-seed -o ~/alma8.osk [-a ./answers-default.yaml]
$ ls -1 ./user-data
./user-data
```


## Deploy AWS Infrastructure via Terraform

This repository contains Terraform code for deploying an AWS Virtual Private
Cloud (VPC), Security Group (currently all ports open), and an EC2 instance with
user data from the previous step. AWS Terraform public modules are used
(https://github.com/terraform-aws-modules).

Prerequisites:
- Terraform installed on your local machine
- AWS Credentials with appropriate permissions
- Generated `./user-data` file (see above)

To deploy this Terraform code, change directory into the
`./aws-terraform-infrastructure` folder and run the following steps:

```
$ terraform init   # to initialize the Terraform working directory and download all required modules
$ terraform plan   # to print out the plan of what will be deployed
$ terraform apply  # confirm the deployment by typing yes when prompted; Terraform will create the VPC, security group, and EC2 instance based on the provided configuration
```

To remove the deployed infrastructure and clean up resources, use the following
command:

```
terraform destroy
```

To remove the deployed infrastructure and clean up resources, use the following command:

- `terraform destroy`

All the sample variables are stored in the terraform.tfvars.skel file. Currently it will deploy EC2 instance called orcharino-on-aws running on Rocky8 Linux with the hardware specifications of 16gb RAM and 4 vcpu (t3a.xlarge).
To deploy the sample configuration copy the contents from the terraform.tfvars.skel file and create terraform.tfvars and paste it there, or you can alter the variables with your values.

The user and meta data generated for specific operating system should be used only on that OS. The list of AMI's (Amazon machine images) can be found on AWS Marketplace. For example: Rocky Linux 8 - https://aws.amazon.com/marketplace/pp/prodview-2otariyxb3mqu

NOTE: EC2 instance will require a ssh key called 'orcharino', be sure to create the key with the same name in your AWS account before deploying the instance.

# How to deploy Orcharhino on Proxmox

Generate user-data and metadata just like in the previous steps, but make sure you are using the correct OSK for the correct operating system.

```
$ ./20-build-seed.sh ~/alma8.osk [./answers-default.yaml]
```
After the user-data and meta-data are generated cd into the terraform-proxmox folder. Then go into the terraform.tfvars file and add your variables for accessing the proxmox server and your vm.
Now all that is left is to type the ussual terraform commands and terraform will automatically fetch the user-data and meta-data that we have generated.
- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform destroy`
