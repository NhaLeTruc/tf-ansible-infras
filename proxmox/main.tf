
resource "proxmox_virtual_environment_vm" "master_nodes" {
  count = lookup(var.node_count, "masters", 0)
  name  = "cluster-master-${count.index}"
  description = "Managed by Terraform"
  tags = ["terraform", "ubuntu", "master"]

  node_name = "pve"
  vm_id = var.new_vm_id + count.index

  clone {
    vm_id = var.ubuntu_template_id
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
    dedicated = 2048
    floating  = 2048 # set equal to dedicated to enable ballooning
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

# resource "proxmox_vm_qemu" "proxmox_vm_workers" {
#   # same as master with minor name changes
# }

# Ansible inventory hosts
resource "ansible_host" "masters" {
  count  = lookup(var.node_count, "masters", 0)
  name   = "masters-node-${count.index}"
  groups = ["masters"] # Groups this host is part of

  variables = {
    ansible_host = proxmox_virtual_environment_vm.master_nodes[count.index].ipv4_addresses
  }
}

# Ansible inventory groups
resource "ansible_group" "masters_group" {
  name     = "masters_nodes"
  children = ["masters"]
  variables = {
    ansible_user = "ubuntu"
  }
}
