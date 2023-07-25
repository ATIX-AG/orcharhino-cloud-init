locals {
  user_data = file(var.userdata_file_path)
  meta_data = file(var.metadata_file_path)
}

resource "random_string" "random" {
  length  = 6
  special = false
}

resource "proxmox_vm_qemu" "cloudinit-test" {
  name = var.vm_name
  desc = var.vm_description

  # Node name has to be the same name as within the cluster
  # this might not include the FQDN
  target_node = var.target_proxmox_node

  # The destination resource pool for the new VM
  pool = var.proxmox_resource_pool

  # The template name to clone this vm from
  clone = var.proxmox_template_clone

  # Boot order
  boot = var.vm_boot_order

  # VM Parameters
  os_type = var.vm_os_type
  cores   = var.vm_cores
  sockets = var.vm_sockets
  vcpus   = var.vm_vcpus
  cpu     = var.vm_cpu
  memory  = var.vm_memory
  scsihw  = var.vm_scsihw

  # Setup the disk
  disk {
    size     = var.vm_disk_size
    type     = var.vm_disk_type
    storage  = var.vm_disk_storage
    iothread = var.vm_disk_iothread
    discard  = var.vm_disk_discard
  }

  # Setup the network interface and assign a vlan tag
  network {
    model  = var.vm_network_model
    bridge = var.vm_network_bridge
    tag    = var.vm_network_tag
  }
  # Create the Cloud-Init drive on the "local-lvm" storage
  cloudinit_cdrom_storage = var.vm_cloudinit_cdrom_storage
  cicustom                = "user=local:snippets/user-data-${random_string.random.id},meta=local:snippets/meta-data-${random_string.random.id}"
}

# Upload userdata to proxmox server
provider "null" {}

# Define the server details
resource "null_resource" "file_upload_with_sshpassword" {
  # The connection details for the server
  connection {
    type     = "ssh"
    user     = var.ssh_username
    host     = var.server_ip
    password = var.ssh_password
  }

  # Use the local-exec provisioner to upload the file
  provisioner "local-exec" {
    command = <<-EOT
      # Upload the file using SCP
      sshpass -p "${var.ssh_password}" scp "${var.userdata_file_path}" ${var.ssh_username}@${var.server_ip}:/var/lib/vz/snippets/user-data-${random_string.random.id}
      sshpass -p "${var.ssh_password}" scp "${var.metadata_file_path}" ${var.ssh_username}@${var.server_ip}:/var/lib/vz/snippets/meta-data-${random_string.random.id}
    EOT
  }
}
resource "null_resource" "file_delete_with_sshpass" {

  triggers = {
    user     = var.ssh_username
    password = var.ssh_password
    server   = var.server_ip
    hash     = random_string.random.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      sshpass -p ${self.triggers.password} ssh ${self.triggers.user}@${self.triggers.server} rm /var/lib/vz/snippets/user-data-${self.triggers.hash}
      sshpass -p ${self.triggers.password} ssh ${self.triggers.user}@${self.triggers.server} rm /var/lib/vz/snippets/meta-data-${self.triggers.hash}
    EOT
    environment = {
      user     = self.triggers.user
      password = self.triggers.password
      server   = self.triggers.server
      hash     = self.triggers.hash
    }
  }
}


# Upload data to proxmox server using SSH key

# resource "null_resource" "file_upload_with_sshkey" {
#   # The connection details for the server
#   connection {
#     type        = "ssh"
#     user        = var.ssh_username
#     host        = var.server_ip
#     private_key = var.ssh_key
#   }

#   # Use the local-exec provisioner to upload the file
#   provisioner "local-exec" {
#     command = <<-EOT
#       # Upload the file using SCP
#       ssh -i "${var.ssh_key}" scp "${var.userdata_file_path}" ${var.ssh_username}@${var.server_ip}:/var/lib/vz/snippets/user-data-${random_string.random.id}
#       ssh -i "${var.ssh_key}" scp "${var.metadata_file_path}" ${var.ssh_username}@${var.server_ip}:/var/lib/vz/snippets/meta-data-${random_string.random.id}
#     EOT
#   }
# }
# resource "null_resource" "file_delete_with_sshkey" {

#   triggers = {
#     user        = var.ssh_username
#     server      = var.server_ip
#     hash        = random_string.random.id
#     private_key = var.ssh_key
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOT
#       ssh -i ${self.triggers.private_key} ${self.triggers.user}@${self.triggers.server} rm /var/lib/vz/snippets/user-data-${self.triggers.hash}
#       ssh -i ${self.triggers.private_key} ${self.triggers.user}@${self.triggers.server} rm /var/lib/vz/snippets/meta-data-${self.triggers.hash}
#     EOT
#     environment = {
#       user        = self.triggers.user
#       private_key = self.triggers.private_key
#       server      = self.triggers.server
#       hash        = self.triggers.hash
#     }
#   }
# }
