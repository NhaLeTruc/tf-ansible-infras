terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.73.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  count = lookup(var.node_count, "masters", 0)
  name  = "cluster-master-${count.index}"
  description = "Managed by Terraform"
  tags = ["terraform", "ubuntu", "master"]

  node_name = "pve"
  vm_id = var.new_vm_id + count.index

  clone {
    vm_id = var.template_id
    full = true
  }

  agent {
    enabled = true
  }

  # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
  stop_on_destroy = true

  cpu {
    cores = 2
    type = "x86-64-v2-AES"  # recommended for modern CPUs
  }

  memory {
    dedicated = 4096
    floating  = 4096 # set equal to dedicated to enable ballooning
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}