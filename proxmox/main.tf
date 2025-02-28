
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

resource "proxmox_virtual_environment_vm" "worker_nodes" {
  count = lookup(var.node_count, "workers", 0)
  name  = "cluster-worker-${count.index}"
  description = "Managed by Terraform"
  tags = ["terraform", "ubuntu", "worker"]

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

# Ansible inventory hosts
resource "ansible_host" "masters" {
  count  = lookup(var.node_count, "masters", 0)
  name   = "masters-node-${count.index}"
  groups = ["masters"] # Groups this host is part of

  variables = {
    ansible_host = jsonencode(proxmox_virtual_environment_vm.master_nodes[*].ipv4_addresses[0])
  }
}

resource "ansible_host" "workers" {
  count  = lookup(var.node_count, "workers", 0)
  name   = "workers-node-${count.index}"
  groups = ["workers"] # Groups this host is part of

  variables = {
    ansible_host = jsonencode(proxmox_virtual_environment_vm.worker_nodes[*].ipv4_addresses[0])
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

resource "ansible_group" "workers_group" {
  name     = "workers_nodes"
  children = ["workers"]
  variables = {
    ansible_user = "ubuntu"
  }
}
