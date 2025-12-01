# Architecture

## Overview

Bashible is an Ansible project structured for AI-agent collaboration. The design prioritizes:

- **Discoverability** — Shell commands reveal infrastructure state
- **Layered separation** — Clear boundaries between inventory, roles, and playbooks
- **Incremental operation** — Safe to explore and test before applying changes

## System Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Playbooks                            │
│            (Orchestration — what to do, in what order)  │
├─────────────────────────────────────────────────────────┤
│                      Roles                              │
│            (Reusable units — how to do it)              │
├─────────────────────────────────────────────────────────┤
│                   Inventory                             │
│            (Hosts + groups + variables — who and where) │
├─────────────────────────────────────────────────────────┤
│                  Ansible Core                           │
│            (Modules, connections, execution engine)     │
├─────────────────────────────────────────────────────────┤
│                  Target Systems                         │
│            (SSH to Linux/macOS, WinRM to Windows)       │
└─────────────────────────────────────────────────────────┘
```

## Directory Structure

```
bashible/
├── AGENTS.md              # AI agent behaviors (SudoLang)
├── ANSIBLE.md             # Ansible concepts & discovery
├── ARCHITECTURE.md        # This file — project design
├── TROUBLESHOOTING.md     # Error diagnosis patterns
├── PLAN.md                # Current work objective
├── SCRATCHPAD.md          # Session working notes
├── CHANGELOG.md           # History of changes
│
├── ansible.cfg            # Ansible configuration
├── ansible.sh             # Wrapper script (no venv activation needed)
├── install-ansible.sh        # One-time setup script
├── requirements.txt       # Python dependencies
│
├── inventory/             # WHO — hosts and their properties
│   ├── hosts.yml          # Host and group definitions
│   ├── group_vars/        # Variables by group
│   │   ├── all.yml        # All hosts
│   │   ├── local.yml      # Local group
│   │   └── managed.yml    # Managed group
│   └── host_vars/         # Variables by host
│       └── localhost.yml
│
├── playbooks/             # WHAT — task orchestration
│   └── site.yml           # Main entry point
│
├── roles/                 # HOW — reusable automation
│   └── common/            # Baseline for all hosts
│       ├── README.md
│       ├── defaults/      # Default variable values
│       ├── tasks/         # Task definitions
│       ├── handlers/      # Event-triggered actions
│       └── templates/     # Jinja2 templates
│
└── files/                 # Static files to deploy
```

## Design Decisions

### Inventory Organization

**Decision:** Single `hosts.yml` with group_vars/host_vars directories.

**Rationale:** 
- Simple for small-to-medium infrastructure
- Variables separated from host definitions (easier to manage)
- Clear precedence: all → group → host

**Alternative:** Multiple inventory files per environment (`inventory/production/`, `inventory/staging/`). Use this when environments diverge significantly.

### Role Structure

**Decision:** Minimal roles by default, expand as needed.

**Rationale:**
- Start with just `tasks/main.yml` and `README.md`
- Add `defaults/`, `handlers/`, `templates/` when actually needed
- Avoid empty boilerplate directories

### Single Entry Point

**Decision:** `playbooks/site.yml` is the main entry point.

**Rationale:**
- One command to configure everything: `ansible-playbook playbooks/site.yml`
- Limit scope with `--limit` or `--tags`, not different playbooks
- Predictable — operators know where to look

### Local Development First

**Decision:** `localhost` is always in the inventory.

**Rationale:**
- Can test immediately without remote hosts
- Validates playbook syntax and logic locally
- macOS/Linux localhost works out of the box

## File Purposes

### Documentation Files

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `AGENTS.md` | AI agent instructions & behaviors | Rarely (stable interface) |
| `ANSIBLE.md` | Ansible concepts & discovery patterns | Rarely (reference) |
| `ARCHITECTURE.md` | Project design & decisions | When structure changes |
| `TROUBLESHOOTING.md` | Error patterns & fixes | When new issues arise |
| `PLAN.md` | Current work objective | Before each task |
| `SCRATCHPAD.md` | Session notes | During work |
| `CHANGELOG.md` | History of changes | After each change |

### Configuration Files

| File | Purpose |
|------|---------|
| `ansible.cfg` | Ansible settings (inventory path, defaults, SSH options) |
| `requirements.txt` | Python packages (ansible-core, ansible-lint) |

### Executable Files

| File | Purpose |
|------|---------|
| `install-ansible.sh` | Creates `.venv` with Ansible installed |
| `wrap-venv` | Runs Ansible commands without manual venv activation |

## Extension Points

### Adding a New Role

1. Create `roles/<name>/tasks/main.yml`
2. Add `roles/<name>/README.md` documenting purpose and variables
3. Add `roles/<name>/defaults/main.yml` if role has configurable options
4. Reference in playbook: `roles: [<name>]`

### Adding a New Host

1. Add to `inventory/hosts.yml` under appropriate group
2. Optionally create `inventory/host_vars/<hostname>.yml`
3. Test: `ansible <hostname> -m ping`

### Adding a New Group

1. Add group under `all.children` in `inventory/hosts.yml`
2. Create `inventory/group_vars/<groupname>.yml` for shared variables
3. Reference in playbooks: `hosts: <groupname>`

### Adding a New Playbook

1. Create `playbooks/<name>.yml`
2. Either import into `site.yml` or run standalone
3. Document in `CHANGELOG.md`

## Security Considerations

### SSH Access

- Key-based authentication preferred over passwords
- `ansible_user` should be a dedicated deploy user, not root
- Use `become: true` for privilege escalation (not root login)

### Secrets

- Never commit plaintext secrets
- Use `ansible-vault` for encrypted variables
- Store vault password outside the repository

### Execution Safety

- Always `--check --diff` before applying changes
- Limit scope with `--limit` when testing
- Review changes in `CHANGELOG.md`

## Related Documentation

| Document | Focus |
|----------|-------|
| `AGENTS.md` | AI agent behaviors and workflows |
| `ANSIBLE.md` | Ansible concepts and self-discovery |
| `TROUBLESHOOTING.md` | Error diagnosis and recovery |
| `roles/*/README.md` | Role-specific documentation |
