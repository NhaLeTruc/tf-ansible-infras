# Infrastructures buid then test with mostly Terraform and Ansible

## Ansible version

Minimum supported Ansible version: 9.0.0 (ansible-core 2.16.0)

## Requirements

This playbook requires root privileges or sudo.
Ansible ([What is Ansible](https://www.ansible.com/how-ansible-works/)?)
if dcs_type: "consul", please install consul role requirements on the control node:
`ansible-galaxy install -r roles/consul/requirements.yml`

### Port requirements

List of required TCP ports that must be open for the database cluster:

- `5432` (postgresql)
- `6432` (pgbouncer)
- `8008` (patroni rest api)
- `2379`, `2380` (etcd)
for the scheme "[Type A] PostgreSQL High-Availability with Load Balancing":
- `5000` (haproxy - (read/write) master)
- `5001` (haproxy - (read only) all replicas)
- `5002` (haproxy - (read only) synchronous replica only)
- `5003` (haproxy - (read only) asynchronous replicas only)
- `7000` (optional, haproxy stats)
for the scheme "[Type C] PostgreSQL High-Availability with Consul Service Discovery (DNS)":
- `8300` (Consul Server RPC)
- `8301` (Consul Serf LAN)
- `8302` (Consul Serf WAN)
- `8500` (Consul HTTP API)
- `8600` (Consul DNS server)

## Recommenations

- **linux (Operation System)**:
Update your operating system on your target servers before deploying;
Make sure you have time synchronization is configured (NTP).
Specify `ntp_enabled:'true'` and `ntp_servers` if you want to install and configure the ntp service.
- **DCS (Distributed Consensus Store)**:
Fast drives and a reliable network are the most important factors for the performance and stability of an etcd (or consul) cluster.
Avoid storing etcd (or consul) data on the same drive along with other processes (such as the database) that are intensively using the resources of the disk subsystem!
Store the etcd and postgresql data on **different** disks (see `etcd_data_dir`, `consul_data_path` variables), use ssd drives if possible.
See [hardware recommendations](https://etcd.io/docs/v3.3/op-guide/hardware/) and [tuning](https://etcd.io/docs/v3.3/tuning/) guides.
It is recommended to deploy the DCS cluster on dedicated servers, separate from the database servers.
- **Placement of cluster members in different data centers**:
If you’d prefer a cross-data center setup, where the replicating databases are located in different data centers, etcd member placement becomes critical.
There are quite a lot of things to consider if you want to create a really robust etcd cluster, but there is one rule: *do not placing all etcd members in your primary data center*. See some [examples](https://www.cybertec-postgresql.com/en/introduction-and-how-to-etcd-clusters-for-patroni/).
- **How to prevent data loss in case of autofailover (synchronous_modes)**:
Due to performance reasons, a synchronous replication is disabled by default.
To minimize the risk of losing data on autofailover, you can configure settings in the following way:
- synchronous_mode: 'true'
- synchronous_mode_strict: 'true'
- synchronous_commit: 'on' (or 'remote_apply')

## Getting Started

You have the option to easily deploy Postgres clusters using the Console (UI) or from the command line with the ansible-playbook command.

### Console (UI)

To run the autobase console, execute the following command:

```bash
docker run -d --name autobase-console \
  --publish 80:80 \
  --publish 8080:8080 \
  --env PG_CONSOLE_API_URL=http://localhost:8080/api/v1 \
  --env PG_CONSOLE_AUTHORIZATION_TOKEN=secret_token \
  --env PG_CONSOLE_DOCKER_IMAGE=autobase/automation:latest \
  --volume console_postgres:/var/lib/postgresql \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume /tmp/ansible:/tmp/ansible \
  --restart=unless-stopped \
  autobase/console:latest
```

> [!NOTE]
> If you are running the console on a dedicated server (rather than on your laptop), replace `localhost` with the server’s IP address in the `PG_CONSOLE_API_URL` variable.
> [!TIP]
> It is recommended to run the console in the same network as your database servers to enable monitoring of the cluster status.

**Open the Console UI**:
Go to http://localhost:80 (or the address of your server) and use `secret_token` for authorization.

![Cluster creation demo](images/pg_console_create_cluster_demo.gif)

Refer to the [Deployment](https://autobase.tech/docs/category/deployment) section to learn more about the different deployment methods.

### Command line

1. [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on one control node (which could easily be a laptop)

```bash
sudo apt update && sudo apt install -y python3-pip sshpass git
pip3 install ansible
```

2. Download or clone this repository

```bash
git clone https://github.com/vitabaks/autobase.git
```

2. Go to the automation directory

```bash
cd autobase/automation
```

3. Install requirements on the control node

```bash
ansible-galaxy install --force -r requirements.yml
```

Note: If you plan to use Consul (`dcs_type: consul`), install the consul role requirements

```bash
ansible-galaxy install -r roles/consul/requirements.yml
```

4. Edit the inventory file

Specify (non-public) IP addresses and connection settings (`ansible_user`, `ansible_ssh_pass` or `ansible_ssh_private_key_file` for your environment

```bash
nano inventory
```

5. Edit the variable file vars/[main.yml](./automation/vars/main.yml)

```bash
nano vars/main.yml
```

Minimum set of variables:

- `proxy_env` to download packages in environments without direct internet access (optional)
- `patroni_cluster_name`
- `postgresql_version`
- `postgresql_data_dir`
- `cluster_vip` to provide a single entry point for client access to databases in the cluster (optional)
- `with_haproxy_load_balancing` to enable load balancing (optional)
- `dcs_type` "etcd" (default) or "consul"
See the vars/[main.yml](./automation/vars/main.yml), [system.yml](./automation/vars/system.yml) and ([Debian.yml](./automation/vars/Debian.yml) or [RedHat.yml](./automation/vars/RedHat.yml)) files for more details.

6. Try to connect to hosts

```bash
ansible all -m ping -u debian
```

7. Run playbook:

```bash
ansible-playbook -e @secrets.enc deploy_pgcluster.yml
```

#### Deploy Cluster with TimescaleDB

To deploy a PostgreSQL High-Availability Cluster with the [TimescaleDB](https://github.com/timescale/timescaledb) extension, add the `enable_timescale` variable:
Example:

```bash
ansible-playbook deploy_pgcluster.yml -e "enable_timescale=true"
```

[![asciicast](https://asciinema.org/a/251019.svg)](https://asciinema.org/a/251019?speed=5)

### How to start from scratch

If you need to start from the very beginning, you can use the playbook `remove_cluster.yml`.
Available variables:

- `remove_postgres`: stop the PostgreSQL service and remove data.
- `remove_etcd`: stop the ETCD service and remove data.
- `remove_consul`: stop the Consul service and remove data.
Run the following command to remove specific components:

```bash
ansible-playbook remove_cluster.yml -e "remove_postgres=true remove_etcd=true"
```

This command will delete the specified components, allowing you to start a new installation from scratch.
:warning: **Caution:** be careful when running this command in a production environment.

## Getting Started with Homelab

Tested on 24th April 2025 Proxmox server.

## Install requirements

```bash
ansible-galaxy install -r requirements.yml
```

Generate A self-signed certificate, private key for TLS encryption of Vault in /certs/ directory:

```bash
openssl req -newkey rsa:2048 -keyout ansible_key.pem -out ansible.csr

openssl x509 -signkey ansible_key.pem -in ansible.csr -req -days 365 -out ansible.crt

chmod 600 ansible_key.pem ansible.crt ansible.csr
```

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
    --ide1 "local-lvm:cloudinit" \
    --ipconfig0 "ip=dhcp" \
    --ciuser admin\
    --cipassword debian\
    --ostype l26 \
    --cores 2 \
    --sockets 2 \
    --memory 4096 \
    --agent 1

qm resize 902 scsi0 10G

qm template 902

```

## Filling in variables for packers and terraform

Run **/bin/generate-vars** after installing **python-hcl2**. This would create variable files in designated directories. Make sure to add them into *.gitignore*.

Packer will ssh into the VM above clone and do effectively these tasks

```bash

# Configure Cloud-Init/IP Config & User/Password
# Login and install qemu-guest-agent

sudo apt update && apt -y install qemu-guest-agent

systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

systemctl status qemu-guest-agent

```

## Run Packer to build base image

Proxmox couldn't create golden image template yet at the moment. So Packer will clone the manually created template then configurate it instead.

Crucially **qemu-guest-agent** will be installed into the golden image template. This allow terraform to utilize it in create the cluster's nodes.

## Check Proxmox VM config info

```bash
pvesh get /nodes/pve/qemu/$VMID/config --output-format json-pretty

terraform providers

terraform -upgrade
```

## Packer have been moved to separated repository

Terraform is responsible for creating the vm needed for the cluster.

Ansible handles the heavy lifting of setting up and configurating Postgres HA cluster.

## Terraform IaC

Packer template has ssh key installed in them. Specifies ssh access in terraform code created issue of ssh acess sometimes.

Be mindful of choosing static ips for VM. Some local ips could have been taken by other service/servers.

```hcl
clone {
  datastore_id = var.disk_datastore
  vm_id        = var.clone_template_id
  retries      = 3
  full         = true
}
```

Clone `full = true` is very important. Keep this option on.

## Add files for ansible-core 2.14.18 to work instead of 2.16+

Some code needed to be added into project for ansible to work.

+ `.\ansible\module_utils\common\file.py`
+ `.\ansible\module_utils\urls.py`

Researches here:

1. [Add local module](https://docs.ansible.com/ansible/latest/dev_guide/developing_locally.html#adding-a-module-or-plugin-outside-of-a-collection)
2. [Add local module_utils](https://docs.ansible.com/ansible/latest/dev_guide/developing_module_utilities.html)
3. [deb822_repository module](https://github.com/ansible/ansible/blob/devel/lib/ansible/modules/deb822_repository.py)
4. [urls module_utils](https://github.com/ansible/ansible/blob/devel/lib/ansible/module_utils/urls.py)
