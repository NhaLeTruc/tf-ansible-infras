
# # proxmox_vm_qemu.proxmox_vm_master[0] will be created
#   + resource "proxmox_vm_qemu" "proxmox_vm_master" {
#       + additional_wait           = 5
#       + agent                     = 1
#       + automatic_reboot          = true
#       + balloon                   = 0
#       + bios                      = "seabios"
#       + boot                      = (known after apply)
#       + bootdisk                  = (known after apply)
#       + clone                     = "k3s-template"
#       + clone_wait                = 10
#       + cores                     = 4
#       + cpu                       = "host"
#       + default_ipv4_address      = (known after apply)
#       + define_connection_info    = true
#       + force_create              = false
#       + full_clone                = true
#       + guest_agent_ready_timeout = 100
#       + hotplug                   = "network,disk,usb"
#       + id                        = (known after apply)
#       + ipconfig0                 = "ip=192.168.3.81/24,gw=192.168.3.1"
#       + kvm                       = true
#       + memory                    = 4096
#       + name                      = "k3s-master-0"
#       + nameserver                = (known after apply)
#       + onboot                    = false
#       + oncreate                  = true
#       + os_type                   = "cloud-init"
#       + preprovision              = true
#       + reboot_required           = (known after apply)
#       + scsihw                    = "lsi"
#       + searchdomain              = (known after apply)
#       + sockets                   = 1
#       + ssh_host                  = (known after apply)
#       + ssh_port                  = (known after apply)
#       + tablet                    = true
#       + target_node               = "pve"
#       + unused_disk               = (known after apply)
#       + vcpus                     = 0
#       + vlan                      = -1
#       + vmid                      = (known after apply)
#     }

#   # proxmox_vm_qemu.proxmox_vm_workers[0] will be created
#   + resource "proxmox_vm_qemu" "proxmox_vm_workers" {
#       + additional_wait           = 5
#       + agent                     = 1
#       + automatic_reboot          = true
#       + balloon                   = 0
#       + bios                      = "seabios"
#       + boot                      = (known after apply)
#       + bootdisk                  = (known after apply)
#       + clone                     = "k3s-template"
#       + clone_wait                = 10
#       + cores                     = 4
#       + cpu                       = "host"
#       + default_ipv4_address      = (known after apply)
#       + define_connection_info    = true
#       + force_create              = false
#       + full_clone                = true
#       + guest_agent_ready_timeout = 100
#       + hotplug                   = "network,disk,usb"
#       + id                        = (known after apply)
#       + ipconfig0                 = "ip=192.168.3.91/24,gw=192.168.3.1"
#       + kvm                       = true
#       + memory                    = 4096
#       + name                      = "k3s-worker-0"
#       + nameserver                = (known after apply)
#       + onboot                    = false
#       + oncreate                  = true
#       + os_type                   = "cloud-init"
#       + preprovision              = true
#       + reboot_required           = (known after apply)
#       + scsihw                    = "lsi"
#       + searchdomain              = (known after apply)
#       + sockets                   = 1
#       + ssh_host                  = (known after apply)
#       + ssh_port                  = (known after apply)
#       + tablet                    = true
#       + target_node               = "pve"
#       + unused_disk               = (known after apply)
#       + vcpus                     = 0
#       + vlan                      = -1
#       + vmid                      = (known after apply)
#     }

#   # proxmox_vm_qemu.proxmox_vm_workers[1] will be created
#   + resource "proxmox_vm_qemu" "proxmox_vm_workers" {
#       + additional_wait           = 5
#       + agent                     = 1
#       + automatic_reboot          = true
#       + balloon                   = 0
#       + bios                      = "seabios"
#       + boot                      = (known after apply)
#       + bootdisk                  = (known after apply)
#       + clone                     = "k3s-template"
#       + clone_wait                = 10
#       + cores                     = 4
#       + cpu                       = "host"
#       + default_ipv4_address      = (known after apply)
#       + define_connection_info    = true
#       + force_create              = false
#       + full_clone                = true
#       + guest_agent_ready_timeout = 100
#       + hotplug                   = "network,disk,usb"
#       + id                        = (known after apply)
#       + ipconfig0                 = "ip=192.168.3.92/24,gw=192.168.3.1"
#       + kvm                       = true
#       + memory                    = 4096
#       + name                      = "k3s-worker-1"
#       + nameserver                = (known after apply)
#       + onboot                    = false
#       + oncreate                  = true
#       + os_type                   = "cloud-init"
#       + preprovision              = true
#       + reboot_required           = (known after apply)
#       + scsihw                    = "lsi"
#       + searchdomain              = (known after apply)
#       + sockets                   = 1
#       + ssh_host                  = (known after apply)
#       + ssh_port                  = (known after apply)
#       + tablet                    = true
#       + target_node               = "pve"
#       + unused_disk               = (known after apply)
#       + vcpus                     = 0
#       + vlan                      = -1
#       + vmid                      = (known after apply)
#     }

resource "proxmox_vm_qemu" "proxmox_vm_master" {
  count = var.master_count
  name  = "cluster-master-${count.index}"
  desc  = "Cluster Master Node"
  ipconfig0   = "gw=${var.k3s_gateway},ip=${var.k3s_master_ip_addresses[count.index]}"
  target_node = var.k3s_master_pve_node[count.index]
  onboot      = false
  hastate     = "started"
  # Same CPU as the Physical host, possible to add cpu flags
  # Ex: "host,flags=+md-clear;+pcid;+spec-ctrl;+ssbd;+pdpe1gb"
  cpu        = "host"
  numa       = false # Whether to enable Non-Uniform Memory Access in the guest.
  clone      = "${var.template_vm_name}-${var.k3s_master_pve_node[count.index]}"
  os_type    = "cloud-init"
  agent      = 1 # Set to 1 to enable the QEMU Guest Agent.
  ciuser     = var.k3s_user
  memory     = var.num_k3s_master_mem
  cores      = var.k3s_master_cores
  nameserver = var.k3s_nameserver
 
  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = var.k3s_vlan
  }

  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  disk {
    size    = var.k3s_master_root_disk_size
    storage = var.k3s_master_disk_storage
    type    = "scsi"
    format  = "qcow2"
    backup  = 1
  }

  disk {
    size    = var.k3s_master_data_disk_size
    storage = var.k3s_master_disk_storage
    type    = "scsi"
    format  = "qcow2"
    backup  = 1
  }

  lifecycle {
    ignore_changes = [
      network, disk, sshkeys, target_node
    ]
  }
}

resource "proxmox_vm_qemu" "proxmox_vm_workers" {
  # same as master with minor name changes
}

# Ansible inventory hosts
resource "ansible_host" "db" {

}

# Ansible web group
resource "ansible_group" "db_group" {

}
