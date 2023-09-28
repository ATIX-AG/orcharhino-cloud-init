variable "userdata_file_path" {
  description = "Path to the user-data file"
  default     = "../user-data"
}
variable "metadata_file_path" {
  description = "Path to the user-data file"
  default     = "../meta-data"
}

variable "pm_api_url" {}
variable "pm_user" {}
variable "pm_password" {}

variable "ssh_password" {}
variable "ssh_username" {}
variable "server_ip" {}
variable "ssh_key" {
  default = "~/.ssh/id_ed25519"
}


# VM variables

variable "memory" {
  default = 2048
}

variable "cores" {
  default = 2
}

variable "network_bridge" {
  default = "vmbr0"
}

variable "disk_size" {
  default = "10G"
}

variable "vm_name" {
  default = "my-test-vm"
}

variable "vm_description" {
  default = "A test for using terraform and cloudinit"
}

variable "target_proxmox_node" {
  default = "proxmox-noris"
}

variable "proxmox_resource_pool" {
  default = "atix"
}

variable "proxmox_template_clone" {
  default = "vm-template-coud-init"
}

variable "vm_boot_order" {
  default = "order=scsi0"
}

variable "vm_os_type" {
  default = "cloud-init"
}

variable "vm_cores" {
  default = 2
}

variable "vm_sockets" {
  default = 1
}

variable "vm_vcpus" {
  default = 0
}

variable "vm_cpu" {
  default = "host"
}

variable "vm_memory" {
  default = 16384
}

variable "vm_scsihw" {
  default = "lsi"
}


# Disk variables

variable "vm_disk_size" {
  default = "10G"
}

variable "vm_disk_type" {
  default = "virtio"
}

variable "vm_disk_storage" {
  default = "local-lvm"
}

variable "vm_disk_iothread" {
  default = 1
}

variable "vm_disk_discard" {
  default = "on"
}


# Network variables

variable "vm_network_model" {
  default = "virtio"
}

variable "vm_network_bridge" {
  default = "vmbr0"
}

variable "vm_network_tag" {
  default = 168
}


# Cicustom variables

variable "vm_cloudinit_cdrom_storage" {
  default = "local"
}
