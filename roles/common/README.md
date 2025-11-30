# Role: common

Baseline configuration applied to all hosts.

## Purpose

This role establishes common configuration across all managed hosts:
- Gathers and validates facts
- Installs baseline packages
- Configures standard settings

## Requirements

- SSH access to target hosts
- Sudo/become privileges

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| common_packages | [] | List of packages to install on all hosts |
| common_timezone | UTC | System timezone |

## Dependencies

None

## Example Playbook

```yaml
- hosts: all
  roles:
    - common
```

## Tags

- `common` - All tasks in this role
- `common:facts` - Fact gathering only
- `common:packages` - Package installation only

## Discovery

```bash
# See what this role would do
ansible-playbook playbooks/site.yml --list-tasks --tags common

# Dry run
ansible-playbook playbooks/site.yml --tags common --check --diff
```
