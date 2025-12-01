# CHANGELOG.md

Record of infrastructure changes. Add entries as you make changes.

## Format

```
## YYYY-MM-DD - Brief Description
- What was changed
- Why it was changed
- Any issues encountered
```

---

## 2024-12-01 - Release 1.0.0

Production-ready release after comprehensive evaluation.

**Changes:**
- Removed test host `elvira` from inventory
- Inventory now contains only `localhost` and `server` placeholder
- Verified all documentation matches final state

**Verification:**
- ansible-lint passes with `production` profile
- Syntax check passes
- Playbook dry-run successful on localhost
- All discovery commands working
- Variable inheritance verified

---

## 2024-12-01 - Refine AI Documentation with SudoLang Patterns

Refined documentation after evaluation showed SudoLang patterns effectively guide AI agents.

**Changes:**
- Streamlined AGENTS.md with hybrid approach: SudoLang decorators (`@Autonomous`, `@Methodical`) plus practical markdown tables
- Added ANSIBLE.md for Ansible concepts and command reference
- Added WORKFLOWS.md for step-by-step procedures (new role, new host, etc.)
- Retained SudoLang pattern-matching in TROUBLESHOOTING.md (`match error {}`, `diagnose {}`)
- Renamed scripts: `install_ansible` → `install-ansible.sh`, `ansible.sh` → `wrap-venv`
- Updated all inline discovery commands in inventory and role files to use `./wrap-venv`

**Verification:**
- All Quick Start commands verified working
- Full test against `elvira` (Rocky Linux 9.6) passed
- AI agent evaluation: ready for production use

## 2024-11-30 - Initial Setup

- Created bashible project structure
- Added common role with fact gathering
- Configured inventory with localhost
- Set up AI-agent documentation (AGENTS.md)
