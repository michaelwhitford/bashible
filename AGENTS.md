# AGENTS.md

Ansible automation via bash. Designed for AI agents with shell access.

Planning: PLAN.md | Changes: CHANGELOG.md | Scratchpad: SCRATCHPAD.md

## TL;DR

```bash
source .venv/bin/activate    # Activate ansible environment
ansible-inventory --graph    # See what hosts exist
ansible all -m ping          # Test connectivity
```

No `.venv`? Run `./install_ansible` first.

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
- Trust the shell. It's your brain. The repo is your memory.

**Ansible principles:**

- Idempotency. Running the same playbook twice should be safe.
- Check mode first. Use `--check` before making changes.
- Start narrow. Target one host before targeting a group.
- Gather facts. Let Ansible tell you about the system.
- Small plays. One logical change per play when possible.

## Shell Setup (Do This First)

```bash
# One-time setup (creates .venv with ansible)
./install_ansible

# Activate the environment
source .venv/bin/activate

# Verify ansible is available
ansible --version

# Check inventory is accessible
ansible-inventory --list

# Test connectivity to hosts
ansible all -m ping

# Verify you're in the right directory
pwd && ls -la
```

If already set up, just activate: `source .venv/bin/activate`

**AI agents:** If `.venv` doesn't exist, run `./install_ansible` to create it automatically.

## Self-Discovery via Shell

**Ask the shell, not the docs, for "what exists" questions.**

In examples below, `<host>` means a host or group from inventory. Run `ansible-inventory --graph` to see available targets.

### Discover the Repo

| Question                  | Command                                              |
| ------------------------- | ---------------------------------------------------- |
| What's in this project?   | `ls -la`                                             |
| What config is Ansible using? | `ansible --version`                              |
| What's configured?        | `cat ansible.cfg`                                    |
| What roles exist?         | `ls roles/`                                          |
| What's in a role?         | `ls -la roles/<role_name>/`                          |
| What playbooks exist?     | `ls playbooks/`                                      |
| What tasks in a playbook? | `ansible-playbook <playbook>.yml --list-tasks`       |
| What tags available?      | `ansible-playbook <playbook>.yml --list-tags`        |

### Discover the Infrastructure

| Question                      | Command                                                            |
| ----------------------------- | ------------------------------------------------------------------ |
| What hosts exist?             | `ansible-inventory --graph`                                        |
| What groups exist?            | `ansible-inventory --graph`                                        |
| Hosts in a group?             | `ansible-inventory --graph <group>`                                |
| Host variables?               | `ansible-inventory --host <hostname>`                              |
| What hosts would be affected? | `ansible-playbook <playbook>.yml --list-hosts`                     |

### Discover Host State

| Question                  | Command                                                            |
| ------------------------- | ------------------------------------------------------------------ |
| Is host reachable?        | `ansible <host> -m ping`                                           |
| All system facts?         | `ansible <host> -m setup`                                          |
| Specific fact?            | `ansible <host> -m setup -a 'filter=ansible_os_family'`            |
| What packages installed?  | `ansible <host> -m shell -a 'rpm -qa'` or `dpkg -l`                |
| What services running?    | `ansible <host> -m shell -a 'systemctl list-units --type=service'` |
| Check disk space?         | `ansible <host> -m shell -a 'df -h'`                               |
| Check memory?             | `ansible <host> -m shell -a 'free -h'`                             |
| What's listening?         | `ansible <host> -m shell -a 'ss -tlnp'`                            |
| Environment variables?    | `ansible <host> -m shell -a 'env'`                                 |

## Exploration Pattern

Build understanding incrementally:

```bash
# 1. See what inventory exists
ansible-inventory --graph

# 2. Check connectivity
ansible all -m ping

# 3. Gather facts about a host
ansible <host> -m setup | head -100

# 4. Run ad-hoc command to check state
ansible <host> -m shell -a 'uname -a'

# 5. Dry-run a playbook against one host
ansible-playbook playbooks/site.yml --limit <host> --check --diff

# 6. Apply to one host first
ansible-playbook playbooks/site.yml --limit <host>

# 7. Then expand to all
ansible-playbook playbooks/site.yml
```

## Verify with Ad-hoc Commands

**Before writing a playbook task, test the module ad-hoc. After running, verify the result.**

This is the core workflow: ad-hoc → playbook → ad-hoc verify.

### Test Modules Before Writing Tasks

```bash
# Test file creation
ansible <host> -m file -a "path=/tmp/testdir state=directory mode=0755" --check

# Test copy content
ansible <host> -m copy -a "content='hello world' dest=/tmp/test.txt" --check

# Test stat (check file exists)
ansible <host> -m stat -a "path=/etc/hosts"

# Test command execution
ansible <host> -m command -a "uname -a"

# Test gathering specific facts
ansible <host> -m setup -a "filter=ansible_os_family"
```

### Verify State After Playbook Runs

Replace `<host>` with an actual host from your inventory (e.g., `localhost`).

| Verify...              | Command                                                      |
| ---------------------- | ------------------------------------------------------------ |
| File exists            | `ansible <host> -m stat -a "path=/etc/hosts"`                |
| File content           | `ansible <host> -m slurp -a "src=/etc/hosts"` (base64)       |
| Directory exists       | `ansible <host> -m stat -a "path=/tmp"`                      |
| User exists            | `ansible <host> -m getent -a "database=passwd key=root"`     |
| Command output         | `ansible <host> -m command -a "uname -a"`                    |
| Environment            | `ansible <host> -m shell -a "env"`                           |
| Disk space             | `ansible <host> -m shell -a "df -h"`                         |
| Package installed      | `ansible <host> -m package_facts` then check output          |
| Service running        | `ansible <host> -m service_facts` then check output          |
| Port listening         | `ansible <host> -m wait_for -a "port=22 timeout=5"`          |
| HTTP response          | `ansible <host> -m uri -a "url=http://example.com"`          |

### Troubleshoot Failed Tasks

When a playbook task fails, reproduce it ad-hoc with verbose output:

```bash
# Run the exact module with -vvv to see what's happening
ansible <host> -m command -a "uname -a" -vvv

# Check preconditions
ansible <host> -m setup -a "filter=ansible_os_family"  # Right OS?
ansible <host> -m command -a "whoami"                   # Right user?

# Check if resource already exists
ansible <host> -m stat -a "path=/tmp"

# Check disk space (common failure cause)
ansible <host> -m shell -a "df -h"

# Check network (for downloads/API calls)
ansible <host> -m uri -a "url=https://example.com"
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
ansible-playbook <playbook>.yml --list-hosts   # What hosts?
ansible-playbook <playbook>.yml --list-tasks   # What tasks?
ansible-playbook <playbook>.yml --check --diff # Dry run

# Playbook execution - graduated approach
ansible-playbook <playbook>.yml --limit <host> --check  # Dry run one host
ansible-playbook <playbook>.yml --limit <host>          # Apply one host
ansible-playbook <playbook>.yml                         # Apply all

# Targeted execution with tags
ansible-playbook <playbook>.yml --tags <tag>        # Only tagged tasks
ansible-playbook <playbook>.yml --skip-tags <tag>   # Skip tagged tasks

# Verbose output for debugging
ansible-playbook <playbook>.yml -v                    # Verbose
ansible-playbook <playbook>.yml -vvv                  # Very verbose
```

## Commands

| Task                 | Command                                          |
| -------------------- | ------------------------------------------------ |
| List inventory       | `ansible-inventory --list`                       |
| Graph inventory      | `ansible-inventory --graph`                      |
| Ping all hosts       | `ansible all -m ping`                            |
| Run playbook (check) | `ansible-playbook <playbook>.yml --check --diff` |
| Run playbook         | `ansible-playbook <playbook>.yml`                |
| Run with limit       | `ansible-playbook <playbook>.yml --limit <host>` |
| Run with tags        | `ansible-playbook <playbook>.yml --tags <tag>`   |
| Gather facts         | `ansible <host> -m setup`                        |
| Ad-hoc command       | `ansible <host> -m shell -a '<command>'`         |
| Encrypt secret       | `ansible-vault encrypt_string '<value>'`         |
| Edit vault file      | `ansible-vault edit <file>`                      |
| Syntax check         | `ansible-playbook <playbook>.yml --syntax-check` |
| Lint playbook        | `ansible-lint <playbook>.yml`                    |

## Debugging

When playbooks fail or behave unexpectedly:

```bash
# Syntax check first
ansible-playbook <playbook>.yml --syntax-check

# Check what hosts would be targeted
ansible-playbook <playbook>.yml --list-hosts

# Dry run with diff to see what would change
ansible-playbook <playbook>.yml --check --diff

# Verbose output to see what's happening
ansible-playbook <playbook>.yml -vvv

# Start at a specific task (after failure)
ansible-playbook <playbook>.yml --start-at-task="<task name>"

# Step through tasks one at a time
ansible-playbook <playbook>.yml --step

# Debug a specific variable
ansible <host> -m debug -a "var=hostvars[inventory_hostname]"

# Check if a file exists
ansible <host> -m stat -a "path=/etc/hosts"
```

## Documentation

**Use docs for "how/why" questions, not "what exists":**

| Need                              | Doc                |
| --------------------------------- | ------------------ |
| Project structure and conventions | ARCHITECTURE.md    |
| Role documentation                | roles/\*/README.md |
| Common issues and solutions       | TROUBLESHOOTING.md |
