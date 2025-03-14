module "master" {
  source = "../modules/vm"
  for_each = {
    for idx, vm in var.servers : idx + 1 => vm
  }

  hostname    = "master-${each.key}"
  vmid        = each.value.id
  tags        = var.tags
  target_node = var.target_node

  clone_template_id = var.template_id
  onboot            = var.onboot
  started           = var.started

  cores   = each.value.cores
  sockets = each.value.sockets
  memory  = each.value.memory

  disk_size      = each.value.disk_size
  disk_datastore = var.disk_datastore

  ip_address = each.value.ip_address
  ip_gateway = var.ip_gateway

  ssh_user        = var.ssh_user
  ssh_public_keys = [file(var.ssh_public_key_file)]
}

resource "proxmox_virtual_environment_vm" "workers" {
  count = lookup(var.node_count, "workers", 0)
  name  = "cluster-worker-${count.index}"
  description = "Managed by Terraform"
  tags = ["terraform", "ubuntu", "worker"]

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

  timeouts {
    create = "160m"
  }
}

resource "local_file" "tf_ansible_inventory_file" {
  depends_on = [
    module.master,
    proxmox_virtual_environment_vm.workers
  ]

  content         = <<-EOF
[master]
%{for vm in var.servers~}
${split("/", vm.ip_address)[0]}
%{endfor~}

[workers]
${join("\n", [for ip in proxmox_virtual_environment_vm.workers.*.ipv4_addresses : join(",", ip[1])])}

[prod]
%{for vm in var.servers~}
${split("/", vm.ip_address)[0]}
%{endfor~}
${join("\n", [for ip in proxmox_virtual_environment_vm.workers.*.ipv4_addresses : join(",", ip[1])])}
EOF
  filename        = "${path.module}/tf_ansible_inventory"
  file_permission = "0644"
}
