# Getting Started with Homelab

Tested on 5th March 2025 Proxmox server.

## Create VM manually on PROXMOX shell

```bash

wget https://cloud.debian.org/images/cloud/bullseye/20250303-2040/debian-11-generic-amd64-20250303-2040.qcow2

qm create 902 \
    --name "debian-11-amd64" \
    --net0 "virtio,bridge=vmbr0" \
    --serial0 socket \
    --vga serial0 \
    --scsihw virtio-scsi-pci \
    --scsi0 "local:0,import-from=/root/debian-11-generic-amd64-20250303-2040.qcow2" \
    --bootdisk scsi0 \
    --boot "order=scsi0" \
    --ide1 "local:cloudinit" \
    --ipconfig0 "ip=dhcp" \
    --ciuser admin\
    --cipassword debian\
    --ostype l26 \
    --cores 2 \
    --sockets 2 \
    --memory 4096 \
    --agent 1

qm resize 902 scsi0 15G

qm template 902

# Configure Cloud-Init/IP Config & User/Password
# Login and install qemu-guest-agent

sudo apt update && apt -y install qemu-guest-agent

systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

systemctl status qemu-guest-agent

```

## Filling in variables for packers and terraform

Run **/bin/generate-vars** after installing **python-hcl2**. This would create variable files in designated directories. Make sure to add them into *.gitignore*.

## Run Packer to build base image

Proxmox couldn't create golden image template yet at the moment. So Packer will clone the manually created template then configurate it instead.

Crucially **qemu-guest-agent** will be installed into the golden image template. This allow terraform to utilize it in create the cluster's nodes.
