terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpq/proxmox"
      version = ">=0.73.0"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
}

provider "proxmox" {
  # Configuration options
  pm_api_url = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # Optional: skip TLS Verification
  pm_tls_insecure = true

  # Optional: loggin
  pm_log_enable       = false
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_parallel         = 1
  pm_timeout          = 600
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
  
}
