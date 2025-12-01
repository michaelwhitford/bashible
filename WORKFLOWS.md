# Workflows

Step-by-step procedures for common tasks. Follow these patterns.

## Core Workflow

Every change follows this sequence:

```
Lint → Check → Apply (narrow) → Apply (all) → Verify
```

```bash
# 1. Lint
./wrap-venv ansible-lint playbooks/site.yml

# 2. Dry-run with diff
./wrap-venv ansible-playbook playbooks/site.yml --check --diff

# 3. Apply to one host first
./wrap-venv ansible-playbook playbooks/site.yml --limit <host>

# 4. Apply to all
./wrap-venv ansible-playbook playbooks/site.yml

# 5. Verify
./wrap-venv ansible <hosts> -m setup -a 'filter=...'
```

## Add a New Host

```bash
# 1. Edit inventory
#    Add to inventory/hosts.yml under appropriate group:
#    
#    newhost:
#      ansible_host: 192.168.1.100
#      ansible_user: deploy

# 2. Test connectivity
./wrap-venv ansible newhost -m ping

# 3. Gather facts
./wrap-venv ansible newhost -m setup

# 4. Create host_vars if needed
#    inventory/host_vars/newhost.yml

# 5. Run playbook
./wrap-venv ansible-playbook playbooks/site.yml --limit newhost --check --diff
./wrap-venv ansible-playbook playbooks/site.yml --limit newhost
```

## Create a New Role

```bash
# 1. Scaffold structure
mkdir -p roles/myrole/{tasks,defaults,handlers,templates}
touch roles/myrole/tasks/main.yml
touch roles/myrole/defaults/main.yml
touch roles/myrole/README.md

# 2. Edit tasks/main.yml
#    Add tasks with FQCN modules

# 3. Add defaults if needed
#    roles/myrole/defaults/main.yml

# 4. Add to playbook
#    roles:
#      - myrole

# 5. Test
./wrap-venv ansible-lint roles/myrole/
./wrap-venv ansible-playbook playbooks/site.yml --check --diff
```

## Debug a Failed Playbook

```bash
# 1. Check syntax
./wrap-venv ansible-playbook playbooks/site.yml --syntax-check

# 2. Lint
./wrap-venv ansible-lint playbooks/site.yml

# 3. Run verbose
./wrap-venv ansible-playbook playbooks/site.yml -vvv

# 4. Test specific host
./wrap-venv ansible <host> -m ping
./wrap-venv ansible <host> -m setup

# 5. Debug variables
./wrap-venv ansible <host> -m debug -a "var=<varname>"
./wrap-venv ansible-inventory --host <host>

# 6. Start at failed task
./wrap-venv ansible-playbook playbooks/site.yml --start-at-task="<task name>"

# 7. Step through
./wrap-venv ansible-playbook playbooks/site.yml --step
```

## Debug Undefined Variable

```bash
# 1. Find where variable should be defined
ls inventory/group_vars/
ls inventory/host_vars/
cat roles/<role>/defaults/main.yml

# 2. Check what host sees
./wrap-venv ansible-inventory --host <hostname>
./wrap-venv ansible <host> -m debug -a "var=<varname>"
./wrap-venv ansible <host> -m debug -a "var=hostvars[inventory_hostname]"

# 3. Define in appropriate location
#    - All hosts: inventory/group_vars/all.yml
#    - Group: inventory/group_vars/<group>.yml  
#    - Host: inventory/host_vars/<host>.yml
#    - Role default: roles/<role>/defaults/main.yml
```

## Debug Connection Issues

```bash
# 1. Test basic connectivity
./wrap-venv ansible <host> -m ping

# 2. Verbose connection info
./wrap-venv ansible <host> -m ping -vvvv

# 3. Check inventory settings
./wrap-venv ansible-inventory --host <host>
# Look for: ansible_host, ansible_user, ansible_ssh_private_key_file

# 4. Test SSH directly
ssh <user>@<host>

# 5. Check SSH key
ssh -i ~/.ssh/id_rsa <user>@<host>
```

## Add a New Group

```bash
# 1. Edit inventory/hosts.yml
#    Add under all.children:
#    
#    newgroup:
#      hosts:
#        host1:
#        host2:

# 2. Create group_vars
#    inventory/group_vars/newgroup.yml

# 3. Verify
./wrap-venv ansible-inventory --graph
./wrap-venv ansible newgroup -m ping
```

## Run Against Subset

```bash
# Single host
./wrap-venv ansible-playbook playbooks/site.yml --limit host1

# Multiple hosts
./wrap-venv ansible-playbook playbooks/site.yml --limit "host1,host2"

# Group
./wrap-venv ansible-playbook playbooks/site.yml --limit webservers

# Pattern
./wrap-venv ansible-playbook playbooks/site.yml --limit "web*"

# Exclude
./wrap-venv ansible-playbook playbooks/site.yml --limit "all:!host1"
```

## Run Specific Tags

```bash
# List available tags
./wrap-venv ansible-playbook playbooks/site.yml --list-tags

# Run specific tags
./wrap-venv ansible-playbook playbooks/site.yml --tags "install,configure"

# Skip tags
./wrap-venv ansible-playbook playbooks/site.yml --skip-tags "slow"
```

## Task Patterns

When asked to accomplish a goal, follow this decision tree:

| Request | Workflow |
|---------|----------|
| "install X on Y" | Check if role exists → Create if needed → Add to playbook → Lint → Check → Apply |
| "configure X" | Find relevant role → Edit templates/tasks → Lint → Check → Apply |
| "add host X" | Edit inventory → Test ping → Create host_vars → Run playbook |
| "debug/fix X" | Check TROUBLESHOOTING.md → Run diagnostics → Identify cause → Fix |
| "show/list X" | Use discovery commands (ansible-inventory, ls, ansible-playbook --list-*) |

## Error Recovery

| Error Pattern | Recovery Steps |
|---------------|----------------|
| `UNREACHABLE` | `./wrap-venv ansible <host> -m ping -vvvv` → Check SSH → Check ansible_host in inventory |
| `Permission denied` | Try `--ask-become-pass` → Check SSH key → Check ansible_user |
| `Undefined variable` | Run debug workflow above → Define variable in appropriate location |
| `Syntax error` | `./wrap-venv ansible-playbook --syntax-check` → Check YAML indentation → Check Jinja2 syntax |
| `No matching host` | `./wrap-venv ansible-inventory --graph` → Check host/group spelling |
| `Lint failed` | Fix lint errors before proceeding → See ANSIBLE.md for common fixes |
