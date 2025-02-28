variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "node_count" {
  type = map(string)
  default = {
    "masters" = 1
    "workers"  = 2
  }
}

variable "new_vm_id" {
  type = number
  default = 100
}

variable "ubuntu_template_id" {
  type = number
}
