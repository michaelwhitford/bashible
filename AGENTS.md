# AGENTS.md

Ansible automation via bash. Designed for AI agents with shell access.

Planning: PLAN.md | Changes: CHANGELOG.md | Scratchpad: SCRATCHPAD.md

## Using SCRATCHPAD.md

**SCRATCHPAD.md is your working scratchpad.** Use it to:

- Record your current task and approach
- Save useful command snippets and their outputs
- Track what you've tried and what worked
- Document discoveries about the infrastructure
- Note blockers or questions for the user

Update SCRATCHPAD.md as you work—it's your persistent memory across the session.

## Shell-Driven Development Philosophy

The shell is how you think. Each command builds understanding of the infrastructure.

**Approach:**

- Start small. One command at a time. Build incrementally.
- Inspect constantly. Check the state of hosts at each step.
- Work with real data. Gather facts from the running systems.
- Trust the shell. It's not a scratchpad—it's your brain. The repo is your memory.

**Ansible principles:**

- Idempotency. Running the same playbook twice should be safe.
- Check mode first. Use `--check` before making changes.
- Start narrow. Target one host before targeting a group.
- Gather facts. Let Ansible tell you about the system.
- Small plays. One logical change per play when possible.

## Shell Setup (Do This First)

```bash
# Verify ansible is available
ansible --version

# Check inventory is accessible
ansible-inventory --list

# Test connectivity to hosts
ansible all -m ping

# Verify you're in the right directory
pwd && ls -la
```

## Self-Discovery via Shell

**Ask the shell, not the docs, for "what exists" questions:**

| Question                          | Command                                                              |
| --------------------------------- | -------------------------------------------------------------------- |
| What hosts exist?                 | `ansible-inventory --list \| jq 'keys'`                              |
| What groups exist?                | `ansible-inventory --graph`                                          |
| Hosts in a group?                 | `ansible-inventory --graph <group>`                                  |
| Host variables?                   | `ansible-inventory --host <hostname>`                                |
| What roles exist?                 | `ls -la roles/`                                                      |
| What's in a role?                 | `tree roles/<role_name>/` or `ls -laR roles/<role_name>/`            |
| What playbooks exist?             | `ls -la playbooks/` or `ls -la *.yml`                                |
| What tasks in a playbook?         | `ansible-playbook <playbook>.yml --list-tasks`                       |
| What tags available?              | `ansible-playbook <playbook>.yml --list-tags`                        |
| What hosts would be affected?     | `ansible-playbook <playbook>.yml --list-hosts`                       |
| System facts for a host?          | `ansible <host> -m setup`                                            |
| Specific fact?                    | `ansible <host> -m setup -a 'filter=ansible_os_family'`              |
| What packages installed?          | `ansible <host> -m shell -a 'dpkg -l' # or rpm -qa`                  |
| What services running?            | `ansible <host> -m shell -a 'systemctl list-units --type=service'`   |
| Check disk space?                 | `ansible <host> -m shell -a 'df -h'`                                 |
| Check memory?                     | `ansible <host> -m shell -a 'free -h'`                               |
| What's listening on ports?        | `ansible <host> -m shell -a 'ss -tlnp'`                              |
| Environment variables?            | `ansible <host> -m shell -a 'env'`                                   |

## Exploration Pattern

Build understanding incrementally:

```bash
# 1. See what inventory exists
ansible-inventory --graph

# 2. Pick a group, check connectivity
ansible webservers -m ping

# 3. Gather facts about one host
ansible webserver1 -m setup | head -100

# 4. Run ad-hoc command to check state
ansible webserver1 -m shell -a 'systemctl status nginx'

# 5. Dry-run a playbook against one host
ansible-playbook site.yml --limit webserver1 --check --diff

# 6. Apply to one host first
ansible-playbook site.yml --limit webserver1

# 7. Then expand to group
ansible-playbook site.yml --limit webservers
```

## Verify with Ad-hoc Commands

**Before writing a playbook task, test the module ad-hoc. After running, verify the result.**

This is the core workflow: ad-hoc → playbook → ad-hoc verify.

### Test Modules Before Writing Tasks

```bash
# Test package installation (check mode)
ansible webserver1 -m apt -a "name=nginx state=present" --check

# Test file creation
ansible webserver1 -m file -a "path=/etc/app state=directory mode=0755" --check

# Test template (copy content)
ansible webserver1 -m copy -a "content='server_name example.com;' dest=/tmp/test.conf" --check

# Test service management
ansible webserver1 -m service -a "name=nginx state=started" --check

# Test user creation
ansible webserver1 -m user -a "name=deploy shell=/bin/bash" --check
```

### Verify State After Playbook Runs

```bash
# Verify package installed
ansible webserver1 -m package_facts
ansible webserver1 -m shell -a "dpkg -l | grep nginx"  # Debian
ansible webserver1 -m shell -a "rpm -q nginx"          # RHEL

# Verify file exists with correct permissions
ansible webserver1 -m stat -a "path=/etc/nginx/nginx.conf"

# Verify file content
ansible webserver1 -m shell -a "cat /etc/nginx/nginx.conf"
ansible webserver1 -m slurp -a "src=/etc/nginx/nginx.conf" | jq -r '.content' | base64 -d

# Verify service running
ansible webserver1 -m service_facts
ansible webserver1 -m shell -a "systemctl status nginx"
ansible webserver1 -m shell -a "systemctl is-active nginx"

# Verify port listening
ansible webserver1 -m wait_for -a "port=80 timeout=5"
ansible webserver1 -m shell -a "ss -tlnp | grep :80"

# Verify user exists
ansible webserver1 -m getent -a "database=passwd key=deploy"

# Verify connectivity/response
ansible webserver1 -m uri -a "url=http://localhost status_code=200"
```

### Common Verification Patterns

| After this task...          | Verify with...                                              |
| --------------------------- | ----------------------------------------------------------- |
| Install package             | `ansible <host> -m shell -a "which <binary>"`               |
| Create file/directory       | `ansible <host> -m stat -a "path=<path>"`                   |
| Template config             | `ansible <host> -m shell -a "cat <path> \| grep <expected>"` |
| Start service               | `ansible <host> -m shell -a "systemctl is-active <svc>"`    |
| Open firewall port          | `ansible <host> -m wait_for -a "port=<port> timeout=5"`     |
| Create user                 | `ansible <host> -m getent -a "database=passwd key=<user>"`  |
| Set permissions             | `ansible <host> -m stat -a "path=<path>"` (check mode/owner)|
| Add cron job                | `ansible <host> -m shell -a "crontab -l"`                   |
| Mount filesystem            | `ansible <host> -m shell -a "df -h \| grep <mount>"`         |
| Configure DNS               | `ansible <host> -m shell -a "cat /etc/resolv.conf"`         |

### Troubleshoot Failed Tasks

When a playbook task fails, reproduce it ad-hoc with verbose output:

```bash
# Run the exact module with -vvv to see what's happening
ansible webserver1 -m apt -a "name=nginx state=present" -vvv

# Check preconditions
ansible webserver1 -m setup -a "filter=ansible_os_family"  # Right OS?
ansible webserver1 -m shell -a "whoami"                     # Right user?
ansible webserver1 -m shell -a "sudo -l"                    # Has sudo?

# Check if resource already exists (idempotency issues)
ansible webserver1 -m stat -a "path=/etc/nginx"
ansible webserver1 -m shell -a "id nginx"                   # User exists?

# Check disk space (common failure cause)
ansible webserver1 -m shell -a "df -h"

# Check network (for downloads/API calls)
ansible webserver1 -m shell -a "curl -I https://example.com"
```

## Starter Examples

Common patterns for exploration and execution:

```bash
# Ad-hoc commands - quick inspection
ansible all -m ping                              # Test connectivity
ansible all -m setup -a 'filter=ansible_fqdn'   # Get hostnames
ansible all -m shell -a 'uptime'                # Check uptime
ansible all -m command -a 'whoami'              # Verify user

# Playbook inspection - before running
ansible-playbook site.yml --list-hosts          # What hosts?
ansible-playbook site.yml --list-tasks          # What tasks?
ansible-playbook site.yml --check --diff        # Dry run

# Playbook execution - graduated approach
ansible-playbook site.yml --limit host1 --check # Dry run one host
ansible-playbook site.yml --limit host1         # Apply one host
ansible-playbook site.yml --limit group1        # Apply one group
ansible-playbook site.yml                       # Apply all

# Targeted execution with tags
ansible-playbook site.yml --tags "nginx"        # Only nginx tasks
ansible-playbook site.yml --skip-tags "restart" # Skip restarts

# Verbose output for debugging
ansible-playbook site.yml -v                    # Verbose
ansible-playbook site.yml -vvv                  # Very verbose
```

## Commands

| Task                    | Command                                            |
| ----------------------- | -------------------------------------------------- |
| List inventory          | `ansible-inventory --list`                         |
| Graph inventory         | `ansible-inventory --graph`                        |
| Ping all hosts          | `ansible all -m ping`                              |
| Run playbook (check)    | `ansible-playbook <playbook>.yml --check --diff`   |
| Run playbook            | `ansible-playbook <playbook>.yml`                  |
| Run with limit          | `ansible-playbook <playbook>.yml --limit <host>`   |
| Run with tags           | `ansible-playbook <playbook>.yml --tags <tag>`     |
| Gather facts            | `ansible <host> -m setup`                          |
| Ad-hoc command          | `ansible <host> -m shell -a '<command>'`           |
| Encrypt secret          | `ansible-vault encrypt_string '<value>'`           |
| Edit vault file         | `ansible-vault edit <file>`                        |
| Syntax check            | `ansible-playbook <playbook>.yml --syntax-check`   |
| Lint playbook           | `ansible-lint <playbook>.yml`                      |

## Debugging

When playbooks fail or behave unexpectedly:

```bash
# Syntax check first
ansible-playbook playbook.yml --syntax-check

# Check what hosts would be targeted
ansible-playbook playbook.yml --list-hosts

# Dry run with diff to see what would change
ansible-playbook playbook.yml --check --diff

# Verbose output to see what's happening
ansible-playbook playbook.yml -vvv

# Start at a specific task (after failure)
ansible-playbook playbook.yml --start-at-task="Install nginx"

# Step through tasks one at a time
ansible-playbook playbook.yml --step

# Debug a specific variable
ansible <host> -m debug -a "var=hostvars[inventory_hostname]"

# Check if a file exists on remote
ansible <host> -m stat -a "path=/etc/nginx/nginx.conf"

# Check service status
ansible <host> -m service -a "name=nginx" | jq '.status'
```

## Documentation

**Use docs for "how/why" questions, not "what exists":**

| Need                                | Doc                  |
| ----------------------------------- | -------------------- |
| Project structure and conventions   | ARCHITECTURE.md      |
| Inventory organization              | INVENTORY.md         |
| Role documentation                  | roles/*/README.md    |
| Playbook purposes                   | PLAYBOOKS.md         |
| Secrets management                  | VAULT.md             |
| Common issues and solutions         | TROUBLESHOOTING.md   |
| Adding new hosts/roles              | CONTRIBUTING.md      |
