# Bashible

An AI-agent-friendly interface for working with Ansible via bash.

## What Is This?

This project is a **bootstrapped foundation** for AI-assisted infrastructure automation. It provides:

- **AI-ready documentation** - `AGENTS.md` gives AI assistants everything they need to understand and modify infrastructure
- **Shell-driven discovery** - Clear patterns for exploring inventory, roles, and system state
- **Layered structure** - Separation of concerns that AI agents can reason about and extend
- **Working examples** - Real playbooks and roles to learn from, not just documentation

**Goal:** An AI agent should be able to load this repo and start working with Ansible inventory, roles, and playbooks in under 2 minutes.

## AI Agent Requirements

This project works with **any AI agent that has access to a bash tool**. Examples include:

| Tool                             | Description                           |
| -------------------------------- | ------------------------------------- |
| [ECA](https://eca.dev)           | Editor Code Assistant with shell tool |
| [Claude Code](https://claude.ai) | Claude's official CLI with shell tool |
| [Aider](https://aider.chat)      | AI pair programming with shell access |

**System requirements:**

- **Python 3.9+** — Required for Ansible
- **Bash** — For shell commands and the install script

The `./install_ansible` script creates a `.venv` directory with Ansible installed, keeping dependencies isolated from your system Python.

The essential capability: **live shell execution**. This lets the AI agent inspect infrastructure state, run ad-hoc commands, test playbooks incrementally, and verify changes work before committing.

## Quick Start

```bash
# One-time setup (creates .venv with ansible)
./install_ansible

# Activate the environment
source .venv/bin/activate

# Check inventory
ansible-inventory --graph

# Test connectivity
ansible all -m ping

# Dry-run the site playbook
ansible-playbook playbooks/site.yml --check --diff
```

Alternatively, use the wrapper script without activating:

```bash
./ansible.sh ansible-inventory --graph
./ansible.sh ansible-playbook playbooks/site.yml --check
```

## Adding a Remote Server

The inventory includes a placeholder host (`your-server`) to demonstrate group management. To use it:

1. **Edit the inventory** — Update `inventory/hosts.yml`:

   ```yaml
   your-server:
     ansible_host: 192.168.1.100 # Replace with real IP or hostname
     ansible_user: deploy # SSH user (optional)
   ```

2. **Ensure SSH access** — You should be able to run:

   ```bash
   ssh deploy@192.168.1.100
   ```

3. **Test connectivity**:
   ```bash
   ansible your-server -m ping
   ```

If you don't have a remote server, you can remove `your-server` from the inventory and work with `localhost` only.

> **AI agents start here → `AGENTS.md`**
>
> The shell is your primary tool. Use it to discover what exists at runtime—don't just read files to understand the infrastructure. AGENTS.md provides the setup and discovery commands.

## Project Structure

```
bashible/
├── AGENTS.md              # AI agent guide (start here)
├── README.md              # This file
├── ARCHITECTURE.md        # System design and conventions
├── TROUBLESHOOTING.md     # Common issues and solutions
├── ansible.cfg            # Ansible configuration
├── inventory/             # Host and group definitions
│   ├── hosts.yml          # Inventory file
│   ├── group_vars/        # Variables by group
│   └── host_vars/         # Variables by host
├── playbooks/             # Task orchestration
│   └── site.yml           # Main playbook
├── roles/                 # Reusable automation units
│   └── common/            # Example role
└── files/                 # Static files to deploy
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Playbooks                            │
│              (Orchestration - what to do)               │
├─────────────────────────────────────────────────────────┤
│                      Roles                              │
│              (Reusable units of work)                   │
├─────────────────────────────────────────────────────────┤
│                   Inventory                             │
│              (Hosts + groups + variables)               │
├─────────────────────────────────────────────────────────┤
│                  Ansible Modules                        │
│              (Built-in actions)                         │
├─────────────────────────────────────────────────────────┤
│                  Target Systems                         │
│              (SSH/WinRM connections)                    │
└─────────────────────────────────────────────────────────┘
```

## Documentation for AI Agents

| File                 | Purpose                                          |
| -------------------- | ------------------------------------------------ |
| `AGENTS.md`          | **Start here** — Shell setup, discovery commands |
| `ARCHITECTURE.md`    | System overview and conventions                  |
| `TROUBLESHOOTING.md` | Error diagnosis and fixes                        |
| `roles/*/README.md`  | Role-specific documentation                      |

## Development

```bash
# Syntax check
ansible-playbook site.yml --syntax-check

# Lint
ansible-lint

# Dry run with diff
ansible-playbook site.yml --check --diff

# Run against one host first
ansible-playbook site.yml --limit hostname

# Run with verbose output
ansible-playbook site.yml -vvv
```

## License

MIT License (c) Michael Whitford
