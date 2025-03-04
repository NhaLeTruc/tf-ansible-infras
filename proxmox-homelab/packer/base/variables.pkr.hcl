variable "proxmox_url" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "iso_url" {
  type        = string
  description = "ISO file URL"
}

variable "iso_checksum" {
  type        = string
  description = "ISO file checksum"
}

variable "vm_id" {
  type        = number
  default     = 9000
  description = "ID of temp VM during build process"
}

variable "vm_name" {
  type        = string
  description = "VM name"
  default     = "base"
}

variable "cores" {
  type        = number
  description = "Number of cores"
  default     = 1
}

variable "sockets" {
  type        = number
  description = "Number of sockets"
  default     = 1
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 1024
}

variable "root_password" {
  type        = string
  description = "Root password"
  default     = "vagrant"
}

variable "ssh_username" {
  type        = string
  description = "SSH username"
  default     = "debian"
}

variable "ssh_password" {
  type        = string
  description = "SSH password"
  default     = "vagrant"
}

variable "ssh_public_key_path" {
  type        = string
  description = "SSH Public Key Path"
  default     = "~/.ssh/vagrant.pub"
}

variable "ssh_private_key_path" {
  type        = string
  description = "SSH Private Key Path"
  default     = "~/.ssh/vagrant"
}
