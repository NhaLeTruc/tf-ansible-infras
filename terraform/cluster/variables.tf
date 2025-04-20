variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
  sensitive = true
}

variable "template_id" {
  type        = number
  description = "Template ID to clone"
}

variable "tags" {
  type        = list(string)
  description = "VM tags"
  default     = ["dev"]
}

variable "control_ip_address" {
  type        = string
  description = "Control IPv4 address in CIDR notation (eg. 10.10.10.2/24)"
  validation {
    condition     = can(cidrnetmask(var.control_ip_address))
    error_message = "Must be a valid IPv4 address with subnet mask"
  }
}

variable "ip_gateway" {
  type        = string
  description = "IP gateway address (eg. 10.10.10.1)"
  validation {
    condition     = can(cidrnetmask("${var.ip_gateway}/24"))
    error_message = "Must be a valid IPv4 address"
  }
}

variable "disk_datastore" {
  type        = string
  description = "Datastore on which to store disk"
  default     = "volumes"
}

# Template already have ssh key. Ajust as needed
# variable "ssh_user" {
#   type        = string
#   description = "SSH user"
# }

# variable "ssh_public_key_file" {
#   type        = string
#   description = "Public SSH key file"
# }

variable "onboot" {
  type        = bool
  description = "Start VM on boot"
  default     = false
}

variable "started" {
  type        = bool
  description = "Start VM on creation"
  default     = true
}

variable "target_node" {
  type        = string
  description = ""
  default     = "pve"
}

variable "masters" {
  type = list(object({
    name       = string
    id         = number
    cores      = number
    sockets    = number
    memory     = number
    disk_size  = number
    ip_address = string
  }))
  default = []
}

variable "servers" {
  type = list(object({
    name       = string
    id         = number
    cores      = number
    sockets    = number
    memory     = number
    disk_size  = number
    ip_address = string
  }))
  default = []
}

variable "balancers" {
  type = list(object({
    name       = string
    id         = number
    cores      = number
    sockets    = number
    memory     = number
    disk_size  = number
    ip_address = string
  }))
  default = []
}

variable "backups" {
  type = list(object({
    name       = string
    id         = number
    cores      = number
    sockets    = number
    memory     = number
    disk_size  = number
    ip_address = string
  }))
  default = []
}

# variable "node_count" {
#   type = map(string)
#   default = {
#     "masters" = 1
#     "workers"  = 2
#   }
# }

# variable "new_vm_id" {
#   type = number
#   default = 100
# }