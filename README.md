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

## Deploy Manually

Provide the image on Proxmox server (a direct download on the server is probably
faster) and `user-data`/`meta-data` files:
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
> Sometimes user data & meta data wasn't provided correctly (root login not
> working, no hostname set)! After re-running `qm set 125 --cicustom ...`
> commands it worked.

> **IMPORTANT**
> Do not trust `qm cloudinit dump 125 user` output. This does not print the
> expected output.


## Deploy with Terraform

This repository contains Terraform code for deploying an orcharhino Server in
Proxmox VE utilizing [Terraform Provider
Proxmox](https://github.com/Telmate/terraform-provider-proxmox).

Prerequisites:

- Recent version of Terraform CLI installed on your local machine
- Proxmox server
- A [VM template](https://pve.proxmox.com/wiki/VM_Templates_and_Clones) (see [Preparing Cloud-Init Templates](https://pve.proxmox.com/wiki/Cloud-Init_Support#_preparing_cloud_init_templates))
- OSK file matching the VM template OS

Generate `user-data`/`meta-data` file:
```
$ ./build-seed -o ~/alma8.osk -a ./answers-default.yaml
$ ls -1 ./*-data
./meta-data
./user-data
```

Start deployment with default settings using Terraform:
```
$ cd ./terraform-proxmox
$ cp ./terraform.tfvars.skel terraform.tfvars
$ export AWS_ACCESS_KEY_ID=...
$ terraform init
$ terraform plan
$ terraform apply
```
Customize variables in `terraform.tfvars` according to your needs.

Destroy deployed infrastructure and clean up resources using Terraform:
```
terraform destroy
```

All
[settings](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
are stored in the `terraform.tfvars` file:

* `pm_api_url`: Target Proxmox API endpoint
* `pm_user`: The Proxmox user and realm (@pam or @pve)
* `pm_password`: The Proxmox user password
* `server_ip`: Proxmox server FQDN to copy user data & meta data to Proxmox server
* `ssh_username`: SSH user to copy user data & meta data to Proxmox server
* `ssh_password`: SSH password to copy user data & meta data to Proxmox server
* `vm_name`: Name of VM
* `proxmox_template_clone`: Name of VM template


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
$ ./build-seed -o ~/alma8.osk -a ./answers-default-aws.yaml
$ ls -1 ./user-data
./user-data
```


## Deploy with Terraform

This repository contains Terraform code for deploying an orcharhino Server in
AWS. It will create a Virtual Private Cloud (VPC), Security Group, and an EC2
instance with user data from the previous step utilizing [Terraform public
modules are used](https://github.com/terraform-aws-modules).

Prerequisites:

- Recent version of Terraform CLI installed on your local machine
- AWS credentials with appropriate permissions
  - AmazonEC2FullAccess
  - NetworkAdministrator
- OSK file matching the desired AMI OS

Generate `user-data` file:
```
$ ./build-seed -o ~/rocky8.osk -a ./answers-default-aws.yaml
$ ls -1 ./user-data
./user-data
```

Start deployment with default settings using Terraform:
```
$ cd ./terraform-aws
$ cp ./terraform.tfvars.skel terraform.tfvars
$ export AWS_ACCESS_KEY_ID=...
$ terraform init
$ terraform plan
$ terraform apply
```
Customize variables in `terraform.tfvars` according to your needs.

Destroy deployed infrastructure and clean up resources using Terraform:
```
terraform destroy
```

All [settings](https://developer.hashicorp.com/terraform/tutorials/modules/module-use) are stored in the `terraform.tfvars` file:

* `vpc_name`: Name of VPC
* `vpc_cidr`: CIDR block for VPC
* `vpc_azs`: Availability zones for VPC
* `vpc_public_subnets`: Public subnets for VPC
* `vpc_enable_nat_gateway`: Enable NAT gateway for VPC
* `vpc_enable_vpn_gateway`: Enable VPN gateway for VPC
* `ec2_name`: Name of EC2 instance
* `ec2_image`: [Amazon Machine Image (AMI)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html)
* `ec2_instance_type`: [Instance type](https://aws.amazon.com/ec2/instance-types/t3/)
* `ec2_key_name`: SSH key name to be used
* `ec2_monitoring`: [Monitoring](https://docs.aws.amazon.com/de_de/AWSEC2/latest/UserGuide/monitoring_ec2.html)

> **NOTE** Be sure to create the specified SSH key with the same name in your
> AWS account before deploying the instance.


# Terraform State Backend

Terraform uses state files to store details about your infrastructure configuration.
With Terraform remote backends, you can store the state file in a remote and shared store.
```
$ cd ./terraform-<service>
$ cp ./backend.tf.skel backend.tf
```
Configure the backend according to your needs.


## GitLab

Adjust `backend.tf` file as follows:
```
terraform {
  backend "http" {
  }
}
```

Then do:

1. Ensure the Terraform state has been [initialized for CI/CD](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html#initialize-a-terraform-state-as-a-backend-by-using-gitlab-cicd).
2. Copy a pre-populated Terraform init command:
  1. On the left sidebar, select **Search or go** to and find your project.
  2. Select **Operate > Terraform states**.
  3. Next to the environment you want to use, select **Actions** and select **Copy Terraform init command.**
3. Open a terminal and run this command on your local machine.

Alternatively, set respective parameters in `backend.tf`:
```
terraform {
  backend "http" {
    address        = "https://my.gitlab.org/api/v4/projects/1234/terraform/state/aws"
    ...
  }
}
```
