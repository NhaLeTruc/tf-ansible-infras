terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73.0"
    }
  }
}

provider "proxmox" {
  # Configuration options
  endpoint = var.proxmox_api_url
  api_token  = var.proxmox_api_token_id

  # Optional: skip TLS Verification
  insecure = true 

  ssh {
    agent = true
  }
}
