# Chapter 6: Ansible Playbooks

Welcome back! In our last chapter, [Chapter 5: Configuration Variables](05_configuration_variables_.md), we learned that **Configuration Variables** are like settings or ingredients that customize how our automation works. They tell Ansible *what* specific values to use (like the PostgreSQL version or the cluster name).

But how does Ansible know *what* steps to perform with these variables, *which* servers to perform them on, and in *what order*? That's where **Ansible Playbooks** come in.

## The Problem: Tasks Need Orchestration

Setting up a high-availability PostgreSQL cluster isn't just one task. It involves *many* tasks:

1.  Install an operating system (usually done manually or via cloud init).
2.  Set up network configurations (firewall rules).
3.  Install prerequisite software.
4.  Install and configure the [Distributed Consensus Store (DCS)](04_distributed_consensus_store__dcs__.md) (like etcd or Consul) on its servers.
5.  Install PostgreSQL on the database servers.
6.  Install and configure [Patroni](03_patroni_.md) on the database servers, telling it how to connect to the [DCS](04_distributed_consensus_store__dcs__.md).
7.  Configure PostgreSQL settings using the provided [Configuration Variables](05_configuration_variables_.md).
8.  Set up initial users and databases.
9.  Configure backup solutions (like pgBackRest or WAL-G).
10. Potentially set up load balancing (like HAProxy).

Doing these steps manually, or even as a simple list, is error-prone. We need a structured way to define this entire workflow.

## What are Ansible Playbooks?

Ansible Playbooks are like the **master plan** or **instruction manual** for your automation. They are YAML files that define a series of steps (called "plays") to be executed on specific groups of machines (defined in the Inventory) to achieve a desired state, like deploying an entire cluster.

Think of a Playbook as a script for your [Ansible Automation](02_ansible_automation_.md) crew. It tells them:

*   **Who:** Which servers (or groups of servers) should perform these steps? (`hosts`)
*   **What:** What high-level goals should be achieved on those servers? (usually defined by listing [Roles](07_ansible_roles_.md) or specific tasks)
*   **How:** How should the steps be executed? (e.g., using variables, handling errors)
*   **When:** In what order should different sets of steps run on different groups of servers? (Playbooks execute from top to bottom)

Playbooks are the core of the automation engine's logic. They orchestrate the work that needs to be done.

## How Autobase Uses Playbooks

When you request an action through the [Autobase Console UI](01_autobase_console__ui___api__.md) (like "Create Cluster" or "Add Replica"), the [Autobase API](01_autobase_console__ui___api_.md) translates that request into running a specific Ansible Playbook.

For example:

*   Requesting to create a new cluster triggers the `deploy_pgcluster.yml` playbook.
*   Requesting to add a replica node triggers the `add_pgnode.yml` playbook.
*   Requesting to remove a cluster triggers the `remove_cluster.yml` playbook.

The [Autobase API](01_autobase_console__ui___api_.md) provides the necessary [Inventory](02_ansible_automation_.md) (the list of servers) and [Configuration Variables](05_configuration_variables_.md) (your specific settings) to the Automation Engine when it launches the chosen Playbook.

## Let's Look at the `deploy_pgcluster.yml` Playbook

This is the main playbook Autobase runs when you initiate a new cluster deployment. It's a great example of how a playbook orchestrates complex tasks across different server groups.

Here's a simplified look at its structure (taken from the provided code, but broken down):

```yaml
# automation/playbooks/deploy_pgcluster.yml (Simplified Structure)
--- # YAML header
- name: vitabaks.autobase.deploy_pgcluster | Deploy PostgreSQL HA Cluster (based on "Patroni")
  hosts: localhost # First, run tasks on the Ansible control node itself (often localhost)
  gather_facts: true # Collect information about the control node
  # ... other settings ...

  pre_tasks:
    # Tasks that run *before* any roles on localhost
    - name: "Set variable: 'pgbackrest_install' to configure Postgres backups"
      ansible.builtin.set_fact:
        pgbackrest_install: true
      when:
        - not (pgbackrest_install | default(false) | bool or wal_g_install | default(false) | bool)
        - cloud_provider | default('') | lower in ['aws', 'gcp', 'azure']
        # ... more conditions using Configuration Variables ...
      tags: always
  roles:
    # Roles that run on localhost (e.g., setting up cloud resources if needed)
    - role: vitabaks.autobase.cloud_resources
      when: cloud_provider | default('') | length > 0
      tags: always

- name: vitabaks.autobase.deploy_pgcluster | Perform pre-checks
  hosts: all # Next, run pre-check tasks on ALL servers in the inventory
  become: true # Run tasks with elevated privileges (like sudo)
  # ... other settings ...

  pre_tasks:
    # Tasks that run *before* roles on 'all' hosts (e.g., update package cache, check OS)
    - name: System info
      ansible.builtin.debug:
        msg: "Collecting system info..."
      tags: always
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"
      # ... more pre-check tasks ...

  roles:
    # Roles that run on 'all' hosts (e.g., setting up SSH keys, running specific checks)
    - role: vitabaks.autobase.authorized_keys
      when: ssh_public_keys is defined
      tags: ssh_public_keys
    - role: vitabaks.autobase.pre_checks # This role performs various checks
      tags: always
    # ... other common roles ...

- name: vitabaks.autobase.deploy_pgcluster | Deploy etcd cluster
  ansible.builtin.import_playbook: etcd_cluster.yml # Import/run another playbook
  when: not dcs_exists | default(false) | bool and dcs_type | default('etcd') == "etcd" # Only if using etcd and it doesn't exist yet
  tags: etcd

- name: vitabaks.autobase.deploy_pgcluster | Deploy Consul
  ansible.builtin.import_playbook: consul_cluster.yml # Import/run another playbook
  when: dcs_type | default('etcd') == "consul" # Only if using consul
  tags: consul

- name: vitabaks.autobase.deploy_pgcluster | Postgres Cluster Configuration
  hosts: postgres_cluster # Run tasks on servers in the 'postgres_cluster' group
  become: true
  # ... other settings ...

  pre_tasks:
    # Tasks specific to postgres_cluster *before* roles (e.g., firewall config)
    - name: Build a firewall_ports_dynamic_var
      # ... logic using variables ...
      tags: firewall
    # ... other pre-tasks ...

  roles:
    # Core roles for setting up infrastructure on PG nodes
    - role: vitabaks.autobase.firewall
      when: firewall_enabled_at_boot | default(false) | bool
      tags: firewall
    - role: vitabaks.autobase.resolv_conf
    - role: vitabaks.autobase.packages # Installs common packages
    # ... many other roles for system setup ...

- name: vitabaks.autobase.deploy_pgcluster | Deploy balancers
  ansible.builtin.import_playbook: balancers.yml # Import/run the balancers playbook
  when: with_haproxy_load_balancing | default(false) | bool # Only if HAProxy is enabled
  tags: load_balancing, haproxy

- name: vitabaks.autobase.deploy_pgcluster | Install and configure pgBackRest
  hosts: pgbackrest:postgres_cluster # Run on servers in either group
  become: true
  # ... other settings ...
  roles:
    - role: vitabaks.autobase.pgbackrest # Role to install pgBackRest
      when: pgbackrest_install | default(false) | bool

- name: vitabaks.autobase.deploy_pgcluster | PostgreSQL Cluster Deployment
  hosts: postgres_cluster # Final core PG setup on PG servers
  become: true
  # ... other settings ...

  pre_tasks:
    # Tasks before core PG roles (e.g., copying TLS certificates)
    - name: Copy certificates
      ansible.builtin.include_role:
        name: vitabaks.autobase.tls_certificate
        tasks_from: copy
      when: tls_cert_generate | default(true) | bool

  roles:
    # Roles for installing/configuring PG, Patroni, etc.
    - role: vitabaks.autobase.wal_g
      when: wal_g_install | default(false) | bool
    - role: vitabaks.autobase.cron
    - role: vitabaks.autobase.pgbouncer # Configures PgBouncer
      when: pgbouncer_install | default(false) | bool
    - role: vitabaks.autobase.patroni # Installs and configures Patroni (!!!)
    - role: vitabaks.autobase.vip_manager # Manages Virtual IP if no HAProxy
      when: not with_haproxy_load_balancing | default(false) | bool and
        (cluster_vip is defined and cluster_vip | length > 0)
    # ... roles for setting up users, databases, extensions (often only on the primary) ...
    - role: vitabaks.autobase.postgresql_users
      when: inventory_hostname == groups['master'][0] # Only run on the node marked as master

  tasks:
    # Final tasks after roles (e.g., creating pgBackRest stanza)
    - name: Create pgbackrest stanza
      ansible.builtin.include_role:
        name: vitabaks.autobase.pgbackrest
        tasks_from: stanza_create
      when: pgbackrest_install | default(false) | bool

    - name: Cluster deployment completed
      ansible.builtin.include_role:
        name: vitabaks.autobase.deploy_finish

```

This simplified view highlights several key aspects of Playbooks:

*   **Multiple "Plays":** The `deploy_pgcluster.yml` file contains multiple blocks starting with `- name: ... hosts: ...`. Each block is a "play". Plays run sequentially, top to bottom.
*   **Targeting Hosts:** Each play specifies which group of servers (`hosts:`) it applies to (e.g., `localhost`, `all`, `etcd_cluster`, `postgres_cluster`).
*   **Using Roles:** Inside each play, the `roles:` section lists the [Ansible Roles](07_ansible_roles_.md) to be executed on the target hosts for that play. Roles encapsulate related tasks (we'll cover them next in [Chapter 7](07_ansible_roles_.md)).
*   **Pre-tasks:** Tasks listed under `pre_tasks:` run *before* any roles in that play.
*   **Tasks:** Tasks listed under `tasks:` run *after* all roles in that play.
*   **Importing Other Playbooks:** Playbooks can include and run other playbooks using `ansible.builtin.import_playbook`. This allows for modularity, like having separate playbooks for deploying the DCS (`etcd_cluster.yml`, `consul_cluster.yml`).
*   **Conditions (`when`):** Tasks, roles, and even entire imported playbooks can be run conditionally using the `when:` keyword, based on the values of [Configuration Variables](05_configuration_variables_.md) (like `dcs_type`, `with_haproxy_load_balancing`).

This structure allows the `deploy_pgcluster.yml` playbook to first set up the DCS on the DCS servers, then perform common system configurations on *all* servers, then install PostgreSQL and [Patroni](03_patroni_.md) specifically on the database servers, and finally perform cluster-specific tasks like creating users or configuring backups, potentially only on the designated primary node.

## The Playbook Execution Flow (Simplified)

When the [Autobase API](01_autobase_console__ui___api_.md) tells the [Ansible Automation Engine](02_ansible_automation_.md) (the Docker container) to run the `deploy_pgcluster.yml` playbook with your specific Inventory and [Configuration Variables](05_configuration_variables_.md), here's a very simplified view of what happens:

```mermaid
sequenceDiagram
    participant AutobaseAPI
    participant AutomationEngine
    participant DatabaseServer1
    participant DatabaseServer2
    participant DCSServer1
    participant DCSServer2

    AutobaseAPI->>AutomationEngine: Run deploy_pgcluster.yml Playbook (Inventory, Variables)
    Note over AutomationEngine: Load Playbook, Inventory, Variables

    AutomationEngine->>AutomationEngine: Start Play 1 (hosts: localhost)
    Note over AutomationEngine: Run pre-tasks, roles for localhost (e.g. cloud setup)
    AutomationEngine-->AutobaseAPI: Report progress

    AutomationEngine->>DatabaseServer1: Start Play 2 (hosts: all) - Connect via SSH
    AutomationEngine->>DatabaseServer2: Start Play 2 (hosts: all) - Connect via SSH
    AutomationEngine->>DCSServer1: Start Play 2 (hosts: all) - Connect via SSH
    AutomationEngine->>DCSServer2: Start Play 2 (hosts: all) - Connect via SSH
    Note over AutomationEngine, DCSServer2: Run pre-checks, common roles on all hosts
    DatabaseServer1-->AutomationEngine: Task results
    DatabaseServer2-->AutomationEngine: Task results
    DCSServer1-->AutomationEngine: Task results
    DCSServer2-->AutomationEngine: Task results
    AutomationEngine-->AutobaseAPI: Report progress

    alt DCS Type is etcd
        AutomationEngine->>AutomationEngine: Start Play 3 (Import etcd_cluster.yml)
        Note over AutomationEngine, DCSServer2: Run etcd_cluster playbook on etcd_cluster hosts
        DCSServer1-->AutomationEngine: Task results
        DCSServer2-->AutomationEngine: Task results
        AutomationEngine-->AutobaseAPI: Report progress
    else DCS Type is consul
        AutomationEngine->>AutomationEngine: Start Play 4 (Import consul_cluster.yml)
        Note over AutomationEngine, DCSServer2: Run consul_cluster playbook on consul_instances hosts
        DCSServer1-->AutomationEngine: Task results
        DCSServer2-->AutomationEngine: Task results
        AutomationEngine-->AutobaseAPI: Report progress
    end

    AutomationEngine->>DatabaseServer1: Start Play 5 (hosts: postgres_cluster) - Connect via SSH
    AutomationEngine->>DatabaseServer2: Start Play 5 (hosts: postgres_cluster) - Connect via SSH
    Note over AutomationEngine, DatabaseServer2: Run common config roles on PG hosts (firewall, packages, etc.)
    DatabaseServer1-->AutomationEngine: Task results
    DatabaseServer2-->AutomationEngine: Task results
    AutomationEngine-->AutobaseAPI: Report progress

    opt With Load Balancer
        AutomationEngine->>AutomationEngine: Start Play 6 (Import balancers.yml)
        Note over AutomationEngine: Run balancers playbook on balancers hosts
        AutomationEngine-->AutobaseAPI: Report progress
    end

    opt With pgBackRest
        AutomationEngine->>DatabaseServer1: Start Play 7 (hosts: pgbackrest:postgres_cluster) - Connect via SSH
         AutomationEngine->>DatabaseServer2: Start Play 7 (hosts: pgbackrest:postgres_cluster) - Connect via SSH
        Note over AutomationEngine, DatabaseServer2: Run pgbackrest role
        DatabaseServer1-->AutomationEngine: Task results
        DatabaseServer2-->AutomationEngine: Task results
        AutomationEngine-->AutobaseAPI: Report progress
    end

    AutomationEngine->>DatabaseServer1: Start Play 8 (hosts: postgres_cluster) - Connect via SSH
    AutomationEngine->>DatabaseServer2: Start Play 8 (hosts: postgres_cluster) - Connect via SSH
    Note over AutomationEngine, DatabaseServer2: Run Patroni, PgBouncer, backup roles; create users/dbs (conditionally)
    DatabaseServer1-->AutomationEngine: Task results
    DatabaseServer2-->AutomationEngine: Task results
    Note over AutomationEngine: Run final tasks
    AutomationEngine-->AutobaseAPI: Report final status
```

This diagram illustrates how the Playbook guides the Automation Engine through different steps, targeting different groups of servers as needed, in a defined sequence.

## Finding Autobase Playbooks

You can find the core Playbooks used by Autobase in the `automation/playbooks/` directory of the project repository.

Some important playbooks you'll find there include:

*   `deploy_pgcluster.yml`: The main playbook to deploy a new cluster.
*   `config_pgcluster.yml`: Used to apply configuration changes to an *existing* cluster (like adding users, changing PG parameters).
*   `add_pgnode.yml`: Adds a new replica server to an existing cluster.
*   `remove_cluster.yml`: Removes a deployed cluster, including data.
*   `pg_upgrade.yml`: Handles major version upgrades of PostgreSQL.
*   `etcd_cluster.yml` and `consul_cluster.yml`: Playbooks specifically for deploying the respective DCS.

The `automation/README.md` file also lists and briefly describes the main playbooks.

## Conclusion

Ansible Playbooks are the orchestrators of the Autobase automation. They define the complete sequence of tasks and roles needed to perform complex operations like deploying, configuring, or managing your PostgreSQL clusters. By reading through the playbook YAML files, you can understand the exact steps Autobase takes behind the scenes to build and maintain your infrastructure, using the [Configuration Variables](05_configuration_variables_.md) you provide.

You now know what Playbooks are, how they structure automation workflows, and where to find them in the Autobase project. In the next chapter, we'll zoom in on the building blocks *within* Playbooks: **Ansible Roles**.

[Next Chapter: Ansible Roles](07_ansible_roles_.md)

---

<sub><sup>Generated by [AI Codebase Knowledge Builder](https://github.com/The-Pocket/Tutorial-Codebase-Knowledge).</sup></sub> <sub><sup>**References**: [[1]](https://github.com/vitabaks/autobase/blob/190aaf8616fc3f12dae58cdb3731af69f97ff013/automation/README.md), [[2]](https://github.com/vitabaks/autobase/blob/190aaf8616fc3f12dae58cdb3731af69f97ff013/automation/playbooks/add_balancer.yml), [[3]](https://github.com/vitabaks/autobase/blob/190aaf8616fc3f12dae58cdb3731af69f97ff013/automation/playbooks/deploy_pgcluster.yml), [[4]](https://github.com/vitabaks/autobase/blob/190aaf8616fc3f12dae58cdb3731af69f97ff013/automation/playbooks/pg_upgrade.yml), [[5]](https://github.com/vitabaks/autobase/blob/190aaf8616fc3f12dae58cdb3731af69f97ff013/automation/playbooks/remove_cluster.yml)</sup></sub>
