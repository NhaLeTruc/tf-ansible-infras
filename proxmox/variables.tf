variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "master_count" {
  type = number
  default = 1
}

variable "worker_count" {
  type = number
  default = 2
}

variable "template_vm_name" {
  type = string
}

variable "num_k3s_masters" {
  default = 3
}

variable "k3s_master_pve_node" {
  description = "The PVE node to target"
  type        = list(string)
  sensitive   = false
  default     = ["proxmox1", "proxmox2", "proxmox1"]
}

variable "k3s_master_ip_addresses" {
  description = "List of IP addresses for master node(s)"
  type        = list(string)
  default     = ["xxx.xxx.xxx.201/24", "xxx.xxx.xxx.202/24", "xxx.xxx.xxx.203/24"]
}

variable "num_k3s_master_mem" {
  default = "8192"
}

variable "k3s_master_cores" {
  default = "4"
}

variable "k3s_master_root_disk_size" {
  default = "32G"
}

variable "k3s_master_data_disk_size" {
  default = "250G"
}

variable "k3s_master_disk_storage" {
  default = "vmdata"
}

variable "num_k3s_nodes" {
  default = 3
}

variable "k3s_worker_pve_node" {
  description = "The PVE node to target"
  type        = list(string)
  sensitive   = false
  default     = ["proxmox2", "proxmox1", "proxmox2"]
}

variable "k3s_worker_ip_addresses" {
  description = "List of IP addresses for master node(s)"
  type        = list(string)
  default     = ["xxx.xxx.xxx.204/24", "xxx.xxx.xxx.205/24", "xxx.xxx.xxx.206/24"]
}

variable "num_k3s_node_mem" {
  default = "8192"
}

variable "k3s_node_cores" {
  default = "4"
}

variable "k3s_node_root_disk_size" {
  default = "32G"
}

variable "k3s_node_data_disk_size" {
  default = "250G"
}

variable "k3s_node_disk_storage" {
  default = "vmdata"
}

variable "k3s_gateway" {
  type    = string
  default = "xxx.xxx.xxx.1"
}

variable "k3s_vlan" {
  default = 33
}

variable "template_vm_name" {
  default = "k3s-template"
}

variable "k3s_nameserver_domain" {
  type    = string
  default = "domain.ld"
}

variable "k3s_nameserver" {
  type    = string
  default = "xxx.xxx.xxx.1"
}

variable "k3s_user" {
  default = "ansible"
}