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

variable "template_id" {
  type        = number
  description = "Template ID to clone"
}
