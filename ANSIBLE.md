# Ansible Reference

Ansible concepts, commands, and discovery patterns.

## Core Philosophy

```
Don't read about infrastructure—discover it.
Every command teaches you something.
```

**Note:** All commands use `./wrap-venv` wrapper which handles virtual environment activation.

## Quick Reference

### Discovery Commands

| To discover... | Command |
|----------------|---------|
| Hosts & groups | `./wrap-venv ansible-inventory --graph` |
| Host variables | `./wrap-venv ansible-inventory --host <name>` |
| All host facts | `./wrap-venv ansible <host> -m setup` |
| Specific fact | `./wrap-venv ansible <host> -m setup -a 'filter=<pattern>'` |
| Playbook tasks | `./wrap-venv ansible-playbook <pb> --list-tasks` |
| Playbook hosts | `./wrap-venv ansible-playbook <pb> --list-hosts` |
| Playbook tags | `./wrap-venv ansible-playbook <pb> --list-tags` |
| Debug variable | `./wrap-venv ansible <host> -m debug -a 'var=<name>'` |

### Verification Commands

| To verify... | Command |
|--------------|---------|
| Connectivity | `./wrap-venv ansible <host> -m ping` |
| File exists | `./wrap-venv ansible <host> -m stat -a 'path=<path>'` |
| File content | `./wrap-venv ansible <host> -m slurp -a 'src=<path>'` |
| User exists | `./wrap-venv ansible <host> -m getent -a 'database=passwd key=<user>'` |
| Port open | `./wrap-venv ansible <host> -m wait_for -a 'port=<port> timeout=5'` |
| HTTP response | `./wrap-venv ansible <host> -m uri -a 'url=<url>'` |
| Run command | `./wrap-venv ansible <host> -m command -a '<cmd>'` |

### Execution Commands

| Action | Command |
|--------|---------|
| Syntax check | `./wrap-venv ansible-playbook <pb> --syntax-check` |
| Lint | `./wrap-venv ansible-lint <target>` |
| Dry run | `./wrap-venv ansible-playbook <pb> --check --diff` |
| Run playbook | `./wrap-venv ansible-playbook <pb>` |
| Limit hosts | `./wrap-venv ansible-playbook <pb> --limit <pattern>` |
| Run tags | `./wrap-venv ansible-playbook <pb> --tags <tags>` |
| Skip tags | `./wrap-venv ansible-playbook <pb> --skip-tags <tags>` |
| Verbose | `./wrap-venv ansible-playbook <pb> -vvv` |
| Start at task | `./wrap-venv ansible-playbook <pb> --start-at-task='<name>'` |
| Step through | `./wrap-venv ansible-playbook <pb> --step` |

## Discovery Patterns

### Discover the Project

```bash
# What's in this repo?
ls -la

# What roles exist?
ls roles/

# What's in a role?
ls -la roles/common/

# What playbooks exist?
ls playbooks/

# What would a playbook do?
./wrap-venv ansible-playbook playbooks/site.yml --list-tasks --list-hosts
```

### Discover the Configuration

```bash
# What config is Ansible using?
./wrap-venv ansible --version       # Shows config file path

# What's in the config?
cat ansible.cfg

# Where does inventory come from?
grep inventory ansible.cfg

# What are the privilege settings?
grep -A3 "\[privilege_escalation\]" ansible.cfg
```

### Discover the Infrastructure

```bash
# What hosts/groups exist?
./wrap-venv ansible-inventory --graph            # Tree view
./wrap-venv ansible-inventory --list             # JSON with all variables

# What variables does a host have?
./wrap-venv ansible-inventory --host <hostname>

# What's the current state of a host?
./wrap-venv ansible <host> -m setup              # All facts
./wrap-venv ansible <host> -m setup -a 'filter=ansible_distribution*'  # Filtered

# Can we reach all hosts?
./wrap-venv ansible all -m ping
```

## Variable System

### Precedence (lowest to highest)

```
1. Role defaults      roles/*/defaults/main.yml     <- Easy to override
2. Inventory group    inventory/group_vars/*.yml
3. Inventory host     inventory/host_vars/*.yml
4. Play vars          vars: in playbook
5. Role vars          roles/*/vars/main.yml         <- Hard to override
6. Task vars          vars: in task
7. Extra vars         -e on command line            <- Always wins
```

### Discovery Commands

```bash
# See merged variables for a host
./wrap-venv ansible-inventory --host <hostname>

# Debug a specific variable
./wrap-venv ansible <host> -m debug -a "var=<varname>"

# See all hostvars
./wrap-venv ansible <host> -m debug -a "var=hostvars[inventory_hostname]"

# List variable files
ls inventory/group_vars/
ls inventory/host_vars/
cat roles/<role>/defaults/main.yml
```

## Inventory Concepts

### Structure

```yaml
all:                        # Implicit top-level group
  children:
    webservers:             # Group name
      hosts:
        web1:               # Host name (alias)
          ansible_host: 192.168.1.10   # Actual address
          ansible_user: deploy         # SSH user
        web2:
          ansible_host: 192.168.1.11
    databases:
      hosts:
        db1:
          ansible_host: 192.168.1.20
```

### Host Patterns

```bash
# Target patterns for ./wrap-venv ansible and ./wrap-venv ansible-playbook
all                        # All hosts
webservers                 # Single group
web*                       # Wildcard
webservers:databases       # Union (OR)
webservers:&production     # Intersection (AND)
webservers:!web1           # Exclusion (NOT)
```

### Hosts in Multiple Groups

A host can belong to multiple groups—this is normal and useful:

```
@all:
  |--@local:
  |  |--localhost      <- Same host in two groups
  |--@managed:
  |  |--localhost      <- Variables from both groups apply
```

Variables merge according to precedence. Check final values:
```bash
./wrap-venv ansible-inventory --host localhost
```

## Role Structure

### Minimal Role

```
roles/example/
├── tasks/
│   └── main.yml        # Required - entry point
└── README.md           # Recommended
```

### Full Role

```
roles/nginx/
├── README.md           # Purpose, variables, examples
├── defaults/
│   └── main.yml        # Default values (easily overridden)
├── vars/
│   └── main.yml        # Role variables (not easily overridden)
├── tasks/
│   ├── main.yml        # Entry point
│   ├── install.yml     # Package installation
│   ├── configure.yml   # Configuration
│   └── service.yml     # Service management
├── handlers/
│   └── main.yml        # Restart/reload triggers
├── templates/
│   └── nginx.conf.j2   # Jinja2 templates
└── files/              # Static files
```

### Role Discovery

```bash
# See role structure
ls -la roles/<role>/

# See role defaults
cat roles/<role>/defaults/main.yml

# See role tasks
cat roles/<role>/tasks/main.yml
```

## Playbook Patterns

### Site Playbook (Main Entry)

```yaml
# playbooks/site.yml - orchestrates everything
---
- import_playbook: common.yml
- import_playbook: webservers.yml
- import_playbook: databases.yml
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
```

### Playbook Discovery

```bash
# What hosts does a playbook target?
./wrap-venv ansible-playbook playbooks/site.yml --list-hosts

# What tasks will run?
./wrap-venv ansible-playbook playbooks/site.yml --list-tasks

# What tags are available?
./wrap-venv ansible-playbook playbooks/site.yml --list-tags
```

## Conventions

### Naming

| Thing | Convention | Example |
|-------|------------|---------|
| Roles | lowercase, underscores | `nginx_proxy` |
| Variables | role prefix, underscores | `nginx_port` |
| Tasks | Start with verb | "Install nginx" |
| Handlers | Describe action | "Restart nginx" |

### FQCN (Fully Qualified Collection Names)

Always use full module names:

```yaml
# Good
- ansible.builtin.copy:
- ansible.builtin.service:

# Avoid
- copy:
- service:
```

### Common Lint Fixes

| Lint Error | Fix |
|------------|-----|
| "Use FQCN" | `ansible.builtin.copy` not `copy` |
| "Truthy value" | Use `true`/`false` not `yes`/`no` |
| "All tasks should be named" | Add `name:` to every task |
| "Command/shell changed" | Add `changed_when:` or `failed_when:` |

### Idempotency

Tasks must be safe to run multiple times:

```yaml
# Good - idempotent
- name: Ensure nginx is installed
  ansible.builtin.apt:
    name: nginx
    state: present

# Bad - not idempotent
- name: Add line to file
  ansible.builtin.shell: echo "line" >> /etc/config
```

### Tags

Every task should have tags:

```yaml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
  tags:
    - nginx
    - packages
    - install
```

## Testing Workflow

### Graduated Execution

```bash
# 1. Syntax check
./wrap-venv ansible-playbook playbooks/site.yml --syntax-check

# 2. Lint
./wrap-venv ansible-lint playbooks/site.yml

# 3. Dry run (see what would change)
./wrap-venv ansible-playbook playbooks/site.yml --check --diff

# 4. Single host first
./wrap-venv ansible-playbook playbooks/site.yml --limit host1

# 5. Expand to group
./wrap-venv ansible-playbook playbooks/site.yml --limit webservers

# 6. Full run
./wrap-venv ansible-playbook playbooks/site.yml
```

### Verbose Output

```bash
./wrap-venv ansible-playbook playbooks/site.yml -v      # Basic
./wrap-venv ansible-playbook playbooks/site.yml -vv     # More detail
./wrap-venv ansible-playbook playbooks/site.yml -vvv    # Connection info
./wrap-venv ansible-playbook playbooks/site.yml -vvvv   # Full debug
```

## Secrets with Vault

### Encrypt/Decrypt

```bash
# Encrypt a file
./wrap-venv ansible-vault encrypt secrets.yml

# Decrypt a file
./wrap-venv ansible-vault decrypt secrets.yml

# Edit encrypted file
./wrap-venv ansible-vault edit secrets.yml

# Encrypt a string (for inline use)
./wrap-venv ansible-vault encrypt_string 'secret_value' --name 'variable_name'
```

### Run with Vault

```bash
# Prompt for password
./wrap-venv ansible-playbook site.yml --ask-vault-pass

# Use password file
./wrap-venv ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

## Ad-Hoc Commands

Test modules before writing tasks:

```bash
# Run a module against hosts
./wrap-venv ansible <hosts> -m <module> -a "<args>"

# Examples
./wrap-venv ansible all -m ping
./wrap-venv ansible webservers -m setup -a 'filter=ansible_distribution*'
./wrap-venv ansible db1 -m ansible.builtin.service -a "name=postgresql state=started"
./wrap-venv ansible localhost -m ansible.builtin.debug -a "var=ansible_facts"
```

## Common Modules

| Module | Purpose | Example |
|--------|---------|---------|
| `ping` | Test connectivity | `./wrap-venv ansible all -m ping` |
| `setup` | Gather facts | `./wrap-venv ansible host -m setup` |
| `debug` | Print variables | `./wrap-venv ansible host -m debug -a "var=x"` |
| `command` | Run command | `./wrap-venv ansible host -m command -a "uptime"` |
| `shell` | Run shell command | `./wrap-venv ansible host -m shell -a "echo $HOME"` |
| `copy` | Copy files | `./wrap-venv ansible host -m copy -a "src=x dest=y"` |
| `template` | Copy with Jinja2 | `./wrap-venv ansible host -m template -a "src=x dest=y"` |
| `file` | Manage files/dirs | `./wrap-venv ansible host -m file -a "path=x state=directory"` |
| `apt`/`yum` | Package management | `./wrap-venv ansible host -m apt -a "name=nginx state=present"` |
| `service` | Manage services | `./wrap-venv ansible host -m service -a "name=nginx state=started"` |
| `user` | Manage users | `./wrap-venv ansible host -m user -a "name=deploy state=present"` |

## Platform Notes

### macOS Localhost

Some modules only work on Linux:

```bash
# These fail on macOS:
./wrap-venv ansible localhost -m ansible.builtin.package_facts    # No package manager
./wrap-venv ansible localhost -m ansible.builtin.service_facts    # No systemd

# Use setup facts instead:
./wrap-venv ansible localhost -m setup -a 'filter=ansible_pkg_mgr'
./wrap-venv ansible localhost -m setup -a 'filter=ansible_os_family'
```

### Python Interpreter

Silence interpreter warnings in `group_vars/all.yml`:

```yaml
ansible_python_interpreter: auto_silent
```

## Resources

| Resource | URL |
|----------|-----|
| Ansible Docs | https://docs.ansible.com |
| Module Index | https://docs.ansible.com/ansible/latest/collections/index_module.html |
| Ansible Galaxy | https://galaxy.ansible.com |
