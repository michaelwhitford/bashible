# Architecture

## Overview

Bashible is an Ansible project structured for AI-agent collaboration. The design prioritizes discoverability—an AI with shell access can understand the infrastructure through commands, not just documentation.

## Discover the Project

```bash
# What's in this repo?
ls -la

# What's the directory structure?
find . -type f -name "*.yml" | head -20

# What roles exist?
ls roles/

# What's in a role?
ls -la roles/common/

# What playbooks exist?
ls playbooks/
```

## Discover the Configuration

```bash
# What config is Ansible using?
ansible --version                    # Shows config file path

# What's in the config?
cat ansible.cfg

# Where does inventory come from?
grep inventory ansible.cfg

# What are the privilege settings?
grep -A3 "\[privilege_escalation\]" ansible.cfg
```

## Discover the Infrastructure

```bash
# What hosts/groups exist?
ansible-inventory --graph

# What variables does a host have?
ansible-inventory --host <hostname>

# What's the current state of a host?
ansible <host> -m setup

# What would a playbook do?
ansible-playbook playbooks/site.yml --list-tasks --list-hosts
```

See **AGENTS.md** for complete discovery patterns.

## Directory Structure

Discover it yourself:
```bash
find . -type d -not -path './.venv/*' -not -path './.git/*' | head -20
```

Standard Ansible layout:
- `ansible.cfg` — Ansible settings (inventory path, defaults)
- `inventory/` — Host and group definitions
- `playbooks/` — Task orchestration
- `roles/` — Reusable automation units
- `files/` — Static files to deploy

## Configuration

Discover it:
```bash
cat ansible.cfg
```

### Variable Precedence (lowest to highest)

1. Role defaults (`roles/*/defaults/main.yml`)
2. Inventory group_vars (`inventory/group_vars/*.yml`)
3. Inventory host_vars (`inventory/host_vars/*.yml`)
4. Play vars
5. Role vars (`roles/*/vars/main.yml`)
6. Task vars
7. Extra vars (`-e` on command line) — **always wins**

## Conventions

### Naming

- **Roles**: lowercase, underscores: `nginx_proxy`, `postgres_server`
- **Variables**: lowercase, underscores, prefixed by role: `nginx_port`, `postgres_version`
- **Tasks**: Start with verb: "Install packages", "Configure nginx", "Start service"
- **Handlers**: Describe the action: "Restart nginx", "Reload systemd"

### Tags

Every task should have tags for selective execution:

```yaml
- name: Install nginx
  apt:
    name: nginx
  tags:
    - nginx
    - packages
    - install
```

Common tag categories:
- **Component**: `nginx`, `postgres`, `docker`
- **Action**: `install`, `configure`, `deploy`
- **Phase**: `setup`, `update`, `cleanup`

### Idempotency

All tasks must be idempotent (safe to run multiple times):

```yaml
# Good - idempotent
- name: Ensure nginx is installed
  apt:
    name: nginx
    state: present

# Bad - not idempotent
- name: Add line to file
  shell: echo "line" >> /etc/config
```

Use modules instead of shell/command when possible. If shell is required, add `creates:` or `removes:` conditions.

## Playbook Patterns

### Site Playbook (Main Entry Point)

```yaml
# site.yml - runs everything
---
- import_playbook: playbooks/common.yml
- import_playbook: playbooks/webservers.yml
- import_playbook: playbooks/databases.yml
```

### Component Playbook

```yaml
# playbooks/webservers.yml
---
- name: Configure web servers
  hosts: webservers
  roles:
    - common
    - nginx
    - app_deploy
```

### Ad-hoc Playbook (One-off tasks)

```yaml
# playbooks/adhoc/restart_services.yml
---
- name: Restart all services
  hosts: "{{ target_hosts | default('all') }}"
  tasks:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
      tags: [nginx]
```

## Role Patterns

### Minimal Role Structure

```
roles/example/
├── tasks/
│   └── main.yml
└── README.md
```

### Full Role Structure

```
roles/nginx/
├── README.md           # Document role purpose, variables, dependencies
├── defaults/
│   └── main.yml        # Default variable values
├── tasks/
│   ├── main.yml        # Entry point, includes others
│   ├── install.yml     # Package installation
│   ├── configure.yml   # Configuration files
│   └── service.yml     # Service management
├── handlers/
│   └── main.yml        # Restart/reload handlers
├── templates/
│   └── nginx.conf.j2   # Configuration templates
├── files/              # Static files
└── vars/
    └── main.yml        # Variables (not overridable)
```

### Role README Template

```markdown
# Role: nginx

Installs and configures nginx web server.

## Requirements

- Debian/Ubuntu or RHEL/CentOS
- Port 80/443 available

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| nginx_port | 80 | HTTP listen port |
| nginx_worker_processes | auto | Worker process count |

## Dependencies

- common

## Example Playbook

    - hosts: webservers
      roles:
        - nginx

## Tags

- nginx
- nginx:install
- nginx:configure
```

## Inventory Patterns

### Static Inventory

```yaml
# inventory/hosts.yml
all:
  children:
    webservers:
      hosts:
        web1:
          ansible_host: 192.168.1.10
        web2:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
```

### Group Variables

```yaml
# inventory/group_vars/webservers.yml
nginx_port: 80
nginx_worker_processes: 4
app_environment: production
```

### Host Variables

```yaml
# inventory/host_vars/web1.yml
nginx_worker_processes: 8  # Override for this host
```

## Secrets Management

Use ansible-vault for sensitive data:

```bash
# Encrypt a file
ansible-vault encrypt inventory/group_vars/production/vault.yml

# Encrypt a string for inline use
ansible-vault encrypt_string 'secret_password' --name 'db_password'

# Edit encrypted file
ansible-vault edit inventory/group_vars/production/vault.yml

# Run playbook with vault password
ansible-playbook site.yml --ask-vault-pass
# Or with password file
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

Convention: Store encrypted variables in files named `vault.yml` alongside regular variables.

## Testing Approach

### Graduated Execution

1. **Syntax check**: `ansible-playbook site.yml --syntax-check`
2. **Lint**: `ansible-lint site.yml`
3. **Dry run**: `ansible-playbook site.yml --check --diff`
4. **Single host**: `ansible-playbook site.yml --limit host1`
5. **Single group**: `ansible-playbook site.yml --limit groupname`
6. **Full run**: `ansible-playbook site.yml`

### Validation Tasks

Include validation in playbooks:

```yaml
- name: Verify nginx is running
  uri:
    url: "http://localhost:{{ nginx_port }}"
    status_code: 200
  retries: 3
  delay: 5
```
