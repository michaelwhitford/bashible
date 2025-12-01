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

The `./install-ansible.sh` script creates a `.venv` directory with Ansible installed, keeping dependencies isolated from your system Python. It installs:
- `ansible-core` — The core Ansible runtime
- `ansible-lint` — Playbook linting tool
- Required Python dependencies

The essential capability: **live shell execution**. This lets the AI agent inspect infrastructure state, run ad-hoc commands, test playbooks incrementally, and verify changes work before committing.

## Quick Start

```bash
# One-time setup (creates .venv with ansible)
./install-ansible.sh

# Check inventory
./wrap-venv ansible-inventory --graph

# Test connectivity
./wrap-venv ansible all -m ping

# Dry-run the site playbook
./wrap-venv ansible-playbook playbooks/site.yml --check --diff
```

## Adding a Remote Server

To add a remote server to the inventory:

1. **Edit the inventory** — Update `inventory/hosts.yml`:

   ```yaml
   myserver:
     ansible_host: 192.168.1.100 # Replace with real IP or hostname
     ansible_user: deploy # SSH user (optional)
   ```

2. **Ensure SSH access** — You should be able to run:

   ```bash
   ssh deploy@192.168.1.100
   ```

3. **Test connectivity**:
   ```bash
   ./wrap-venv ansible myserver -m ping
   ```

> **AI agents start here → `AGENTS.md`**
>
> The shell is your primary tool. Use it to discover what exists at runtime—don't just read files to understand the infrastructure. AGENTS.md provides setup, discovery commands, and autonomous behaviors in SudoLang format.

> **Note:** The inventory includes a placeholder remote host (`server`) which requires configuration before use. Start with `localhost` for initial exploration—it's always available.

## Project Structure

```
bashible/
├── AGENTS.md              # AI agent guide (start here)
├── ANSIBLE.md             # Ansible concepts & discovery
├── ARCHITECTURE.md        # Project design & decisions
├── TROUBLESHOOTING.md     # Common issues and solutions
├── README.md              # This file
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

| File                 | Purpose                                                         |
| -------------------- | --------------------------------------------------------------- |
| `AGENTS.md`          | **Start here** — Quick start, constraints, pointers             |
| `ANSIBLE.md`         | Ansible concepts, commands, discovery patterns                  |
| `ARCHITECTURE.md`    | Project structure and design decisions                          |
| `WORKFLOWS.md`       | Step-by-step procedures for common tasks                        |
| `TROUBLESHOOTING.md` | Error patterns and diagnostic sequences                         |
| `roles/*/README.md`  | Role-specific documentation                                     |

## Development

```bash
# Syntax check
./wrap-venv ansible-playbook playbooks/site.yml --syntax-check

# Lint
./wrap-venv ansible-lint

# Dry run with diff
./wrap-venv ansible-playbook playbooks/site.yml --check --diff

# Run against one host first
./wrap-venv ansible-playbook playbooks/site.yml --limit hostname

# Run with verbose output
./wrap-venv ansible-playbook playbooks/site.yml -vvv
```

## License

MIT License (c) Michael Whitford
