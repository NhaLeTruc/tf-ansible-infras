############################################
## masters & distributed key-value stores
############################################
module "masters" {
  source = "../modules/vm"
  for_each = {
    for idx, vm in var.masters : idx + 1 => vm
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

  # Template already have ssh key. Ajust as needed
  # ssh_user        = var.ssh_user
  # ssh_public_keys = [file(var.ssh_public_key_file)]
}

############################################
## workers & distributed key-value stores
############################################
module "workers" {
  source = "../modules/vm"
  for_each = {
    for idx, vm in var.servers : idx + 1 => vm
  }

  hostname    = "worker-${each.key}"
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

  # Template already have ssh key. Ajust as needed
  # ssh_user        = var.ssh_user
  # ssh_public_keys = [file(var.ssh_public_key_file)]
}

############################################
## balancers
############################################
module "balancers" {
  source = "../modules/vm"
  for_each = {
    for idx, vm in var.balancers : idx + 1 => vm
  }

  hostname    = "balancer-${each.key}"
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

  # Template already have ssh key. Ajust as needed
  # ssh_user        = var.ssh_user
  # ssh_public_keys = [file(var.ssh_public_key_file)]
}

############################################
## backup and restore
############################################
module "pgbackrest" {
  source = "../modules/vm"
  for_each = {
    for idx, vm in var.backups : idx + 1 => vm
  }

  hostname    = "pgbackrest-${each.key}"
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

  # Template already have ssh key. Ajust as needed
  # ssh_user        = var.ssh_user
  # ssh_public_keys = [file(var.ssh_public_key_file)]
}

############################################
## ansible_inventory
############################################
resource "local_file" "tf_ansible_inventory_file" {
  depends_on = [
    module.masters,
    module.workers,
    module.balancers,
    module.pgbackrest
  ]

  content         = <<-EOF
# Please specify the ip addresses and connection settings for your environment
# The specified ip addresses will be used to listen by the cluster components.
# Attention! Specify private IP addresses so that the cluster does not listen a public IP addresses.
# For deploying via public IPs, add 'ansible_host=public_ip_address' variable for each node.
#
# "postgresql_exists=true" if PostgreSQL is already exists and running
# "hostname=" variable is optional (used to change the server name)
# "new_node=true" to add a new server to an existing cluster using the add_pgnode.yml playbook
# balancer_tags="key=value" the Balancer tags for the /replica, /sync, /async endpoints. Must match 'patroni_tags'.
# patroni_tags="key=value" the Patroni tags in "key=value" format separated by commas.
# patroni_replicatefrom="<hostname>" the Patroni node to replicate from (cascading replication).

# if dcs_exists: false and dcs_type: "etcd"
[etcd_cluster]  # recommendation: 3, or 5-7 nodes
#10.128.64.140
%{for vm in var.masters~}
${split("/", vm.ip_address)[0]}
%{endfor~}
%{for vm in var.servers~}
${split("/", vm.ip_address)[0]}
%{endfor~}

# if dcs_exists: false and dcs_type: "consul"
[consul_instances]  # recommendation: 3 or 5-7 nodes
#10.128.64.140 consul_node_role=server consul_bootstrap_expect=true consul_datacenter=dc1
#10.128.64.144 consul_node_role=client consul_datacenter=dc2


# if with_haproxy_load_balancing: true
[balancers]
#10.128.64.140 # balancer_tags="datacenter=dc1"
#10.128.64.145 # balancer_tags="datacenter=dc2" new_node=true
%{for vm in var.balancers~}
${split("/", vm.ip_address)[0]}
%{endfor~}

# PostgreSQL nodes
[master]
#10.128.64.140 hostname=pgnode01 postgresql_exists=false # patroni_tags="datacenter=dc1"
%{for vm in var.masters~}
${split("/", vm.ip_address)[0]} hostname=pgnode01 postgresql_exists=false # patroni_tags="datacenter=dc1"
%{endfor~}

[replica]
#10.128.64.142 hostname=pgnode02 postgresql_exists=false # patroni_tags="datacenter=dc1"
%{for vm in var.servers~}
${split("/", vm.ip_address)[0]} hostname=pgnode02 postgresql_exists=false # patroni_tags="datacenter=dc1"
%{endfor~}
#10.128.64.144 hostname=pgnode04 postgresql_exists=false # patroni_tags="datacenter=dc2" patroni_replicatefrom="pgnode03"

#10.128.64.145 hostname=pgnode04 postgresql_exists=false # patroni_tags="datacenter=dc2" new_node=true


[postgres_cluster:children]
master
replica

#if pgbackrest_install: true and "repo_host" is set
[pgbackrest]  # optional (Dedicated Repository Host)
#10.128.64.110
%{for vm in var.backups~}
${split("/", vm.ip_address)[0]}
%{endfor~}

[pgbackrest:vars]
#ansible_user='postgres'
#ansible_ssh_pass='secretpassword'

# Connection settings
[all:vars]
ansible_connection='ssh'
ansible_ssh_port='22'
#ansible_user='root'
#ansible_ssh_pass='secretpassword'  # "sshpass" package is required for use "ansible_ssh_pass"
#ansible_ssh_private_key_file=
#ansible_python_interpreter='/usr/bin/python3'
EOF
  filename        = "../../ansible/tf_ansible_inventory"
  file_permission = "0644"
}


###############################################################
## Proxmox API timeouts frequently with large `count` values ##
###############################################################
# resource "proxmox_virtual_environment_vm" "workers" {
#   count = lookup(var.node_count, "workers", 0)
#   name  = "cluster-worker-${count.index}"
#   description = "Managed by Terraform"
#   tags = ["terraform", "ubuntu", "worker"]

#   node_name = "pve"
#   vm_id = var.new_vm_id + count.index

#   clone {
#     vm_id = var.template_id
#     full = true
#     retries = 3
#   }

#   agent {
#     enabled = true
#   }

#   # if agent is not enabled, the VM may not be able to shutdown properly, and may need to be forced off
#   stop_on_destroy = true

#   cpu {
#     cores = 2
#     type = "x86-64-v2-AES"  # recommended for modern CPUs
#   }

#   memory {
#     dedicated = 4096
#     floating  = 4096 # set equal to dedicated to enable ballooning
#   }

#   initialization {
#     ip_config {
#       ipv4 {
#         address = "dhcp"
#       }
#     }
#   }

# }

# {join("\n", [for ip in proxmox_virtual_environment_vm.masters.*.ipv4_addresses : join(",", ip[1])])}
# 
#
# {for ip in [for ips in proxmox_virtual_environment_vm.workers.*.ipv4_addresses : join(",", ips[1])]~}
# {ip} hostname=pgnode04 postgresql_exists=false # patroni_tags="datacenter=dc2" new_node=true
# {endfor~}
