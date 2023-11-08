terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.35.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_ip}:8006/"
  username = "${var.proxmox_user}@pam"
  password = var.proxmox_pass
  insecure = true
  ssh {
    agent = true
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name        = "ubuntu-vm"
  description = "Managed by Terraform"
  tags        = ["terraform"]

  node_name = "pve"
  started = "false"

  agent {
    enabled = true
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = "1"
    type = "qemu64"
    flags = ["+hv-evmcs"]
  }

  memory {
    dedicated = "1024"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "scsi0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
      password = random_password.ubuntu_vm_password.result
      username = "ubuntu"
    }
  }


  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  provisioner "local-exec" {
    command = "./start_vm.sh"
    environment = {
      VM_ID        = proxmox_virtual_environment_vm.ubuntu_vm.vm_id
      PROXMOX_ADDR = var.proxmox_ip
      PROXMOX_USER = var.proxmox_user
    }
  }

}

resource "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"

  source_file {
    path = "http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  }
}

resource "random_password" "ubuntu_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.ubuntu_vm.vm_id
}

output "ubuntu_vm_password" {
  value     = random_password.ubuntu_vm_password.result
  sensitive = true
}

output "ubuntu_vm_private_key" {
  value     = tls_private_key.ubuntu_vm_key.private_key_pem
  sensitive = true
}

output "ubuntu_vm_public_key" {
  value = tls_private_key.ubuntu_vm_key.public_key_openssh
}