# Troubleshooting Guide

Common issues and solutions when working with Bashible.

## Connection Issues

### "Host unreachable" or SSH timeout

**Symptoms**: Ansible can't connect to host

**Diagnosis**:
```bash
# Test basic connectivity
ping <host_ip>

# Test SSH directly
ssh <user>@<host_ip>

# Verbose ansible connection
ansible <host> -m ping -vvvv
```

**Solutions**:
1. **Wrong IP/hostname**
   - Check `ansible-inventory --host <hostname>`
   - Verify `ansible_host` is correct

2. **SSH key issues**
   - Check key exists: `ls -la ~/.ssh/`
   - Check key permissions: `chmod 600 ~/.ssh/id_rsa`
   - Test: `ssh -i ~/.ssh/id_rsa <user>@<host>`

3. **Wrong user**
   - Check `ansible_user` in inventory
   - Try explicit user: `ansible <host> -u root -m ping`

4. **Firewall blocking**
   - Check port 22 is open on target
   - Try from same network as target

5. **Host key verification**
   - First connection needs to accept host key
   - Or set `host_key_checking = False` in ansible.cfg (dev only!)

### "Permission denied" on SSH

**Solutions**:
1. **Wrong SSH key**
   ```bash
   ansible <host> -m ping --private-key=/path/to/key
   ```

2. **Password required**
   ```bash
   ansible <host> -m ping --ask-pass
   ```

3. **Key not in authorized_keys**
   - Manually add public key to target's `~/.ssh/authorized_keys`

## Privilege Issues

### "Missing sudo password"

**Symptoms**: Tasks requiring root fail

**Solutions**:
1. **Provide sudo password**
   ```bash
   ansible-playbook site.yml --ask-become-pass
   ```

2. **Configure passwordless sudo on target**
   ```bash
   # On target host
   echo "<user> ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/<user>
   ```

3. **Check become settings in ansible.cfg or playbook**
   ```yaml
   # In playbook
   - hosts: all
     become: yes
     become_method: sudo
   ```

### "sudo: a password is required"

**Solutions**:
1. Use `--ask-become-pass` or `-K`:
   ```bash
   ansible-playbook site.yml -K
   ```

2. Set `ansible_become_password` in inventory (use vault!):
   ```yaml
   # inventory/group_vars/all/vault.yml (encrypted)
   ansible_become_password: "{{ vault_sudo_password }}"
   ```

## Playbook Issues

### "Syntax error"

**Diagnosis**:
```bash
ansible-playbook site.yml --syntax-check
```

**Common causes**:
1. **YAML indentation** - Use 2 spaces, no tabs
2. **Missing quotes** - Strings with special chars need quotes
3. **Missing colons** - Every key needs `: `
4. **Bad Jinja2** - Check `{{ }}` syntax

### "Variable undefined"

**Symptoms**: `"msg": "The task includes an option with an undefined variable..."`

**Diagnosis**:
```bash
# Check if variable is defined
ansible <host> -m debug -a "var=variable_name"

# Check where variables come from
ansible <host> -m debug -a "var=hostvars[inventory_hostname]"
```

**Solutions**:
1. **Define the variable** in appropriate location:
   - `group_vars/all.yml` - All hosts
   - `group_vars/<group>.yml` - Group specific
   - `host_vars/<host>.yml` - Host specific
   - Role `defaults/main.yml` - Role default

2. **Use default filter**:
   ```yaml
   {{ some_var | default('fallback_value') }}
   ```

3. **Check variable spelling** - Case sensitive!

### "Task never completes" (hangs)

**Symptoms**: Ansible waits indefinitely

**Solutions**:
1. **Interactive command** - Commands needing input will hang
   ```yaml
   # Bad
   - shell: apt upgrade
   
   # Good
   - apt:
       upgrade: yes
   ```

2. **Async for long tasks**:
   ```yaml
   - name: Long running task
     command: /path/to/slow/script
     async: 3600  # Max seconds
     poll: 30     # Check every 30s
   ```

3. **Check target for stuck process**:
   ```bash
   ssh <host> "ps aux | grep ansible"
   ```

### "No matching host found"

**Symptoms**: `[WARNING]: Could not match supplied host pattern`

**Solutions**:
1. **Check inventory**:
   ```bash
   ansible-inventory --list | jq 'keys'
   ansible-inventory --graph
   ```

2. **Check pattern**:
   - `all` - All hosts
   - `webservers` - Group name
   - `web*` - Wildcard
   - `webservers:&production` - Intersection
   - `webservers:!web1` - Exclusion

3. **Check playbook hosts field**:
   ```yaml
   - hosts: webservers  # Must match inventory group/host
   ```

## Module Issues

### "Module not found"

**Solutions**:
1. **Check Ansible version**:
   ```bash
   ansible --version
   ```
   Some modules require newer versions

2. **Install collection**:
   ```bash
   ansible-galaxy collection install community.general
   ```

3. **Use FQCN (Fully Qualified Collection Name)**:
   ```yaml
   # Instead of
   - copy:
   
   # Use
   - ansible.builtin.copy:
   ```

### "Module failed"

**Diagnosis**:
```bash
# Run with verbose output
ansible-playbook site.yml -vvv

# Test module directly
ansible <host> -m <module> -a "<args>" -vvv
```

**Common module issues**:

1. **apt/yum**: Package name doesn't exist
   ```bash
   # Check package name on target
   ansible <host> -m shell -a "apt-cache search nginx"
   ```

2. **service**: Service name wrong
   ```bash
   # List services on target
   ansible <host> -m shell -a "systemctl list-units --type=service"
   ```

3. **file/copy**: Path doesn't exist
   ```bash
   # Check path
   ansible <host> -m stat -a "path=/etc/nginx"
   ```

4. **template**: Jinja2 error
   ```bash
   # Test template locally
   ansible localhost -m template -a "src=template.j2 dest=/tmp/test"
   ```

## Role Issues

### "Role not found"

**Diagnosis**:
```bash
# Check roles path
ls -la roles/

# Check ansible.cfg
grep roles_path ansible.cfg
```

**Solutions**:
1. **Check role exists**:
   ```bash
   ls roles/<role_name>/tasks/main.yml
   ```

2. **Check roles_path in ansible.cfg**:
   ```ini
   [defaults]
   roles_path = roles
   ```

3. **Install from Galaxy if external**:
   ```bash
   ansible-galaxy install geerlingguy.nginx
   ```

### "Handler not triggered"

**Symptoms**: Handler defined but never runs

**Solutions**:
1. **Handler name must match exactly**:
   ```yaml
   # In tasks
   - name: Update config
     template: ...
     notify: Restart nginx  # Must match handler name exactly
   
   # In handlers
   - name: Restart nginx  # Case sensitive!
     service: ...
   ```

2. **Task must report changed**:
   - Handlers only run if notifying task reports `changed`
   - Check with `--check` first to see if task would change

3. **Force handler run**:
   ```yaml
   - meta: flush_handlers  # Run pending handlers now
   ```

## Vault Issues

### "Decryption failed"

**Solutions**:
1. **Wrong password**:
   ```bash
   # Try again
   ansible-playbook site.yml --ask-vault-pass
   ```

2. **Wrong vault ID** (if using multiple vaults):
   ```bash
   ansible-playbook site.yml --vault-id dev@prompt
   ```

3. **File not actually encrypted**:
   ```bash
   # Check if encrypted
   head -1 file.yml
   # Should show: $ANSIBLE_VAULT;1.1;AES256
   ```

### "File is not vault encrypted"

**Solution**: Encrypt the file:
```bash
ansible-vault encrypt path/to/file.yml
```

## Performance Issues

### "Playbook runs slowly"

**Solutions**:
1. **Increase parallelism**:
   ```ini
   # ansible.cfg
   [defaults]
   forks = 20  # Default is 5
   ```

2. **Disable gather_facts if not needed**:
   ```yaml
   - hosts: all
     gather_facts: no
   ```

3. **Use strategy**:
   ```yaml
   - hosts: all
     strategy: free  # Don't wait for slowest host
   ```

4. **Cache facts**:
   ```ini
   # ansible.cfg
   [defaults]
   fact_caching = jsonfile
   fact_caching_connection = /tmp/ansible_facts
   fact_caching_timeout = 86400
   ```

## Debug Techniques

### Print variables

```yaml
- debug:
    var: some_variable

- debug:
    msg: "Value is {{ some_variable }}"
```

### Run single task

```bash
ansible-playbook site.yml --start-at-task="Task name"
```

### Step through tasks

```bash
ansible-playbook site.yml --step
```

### Check mode (dry run)

```bash
ansible-playbook site.yml --check --diff
```

### Verbose output

```bash
ansible-playbook site.yml -v    # Basic
ansible-playbook site.yml -vv   # More
ansible-playbook site.yml -vvv  # Connection info
ansible-playbook site.yml -vvvv # Full debug
```

### Register and inspect

```yaml
- name: Run command
  command: cat /etc/os-release
  register: result

- debug:
    var: result
```

## Getting Help

### Debug Checklist

When something isn't working:

1. **Syntax check**: `ansible-playbook site.yml --syntax-check`
2. **Lint**: `ansible-lint site.yml`
3. **Check inventory**: `ansible-inventory --list`
4. **Test connectivity**: `ansible <host> -m ping`
5. **Dry run**: `ansible-playbook site.yml --check --diff`
6. **Verbose**: `ansible-playbook site.yml -vvv`
7. **Limit scope**: `ansible-playbook site.yml --limit host1`

### Include in questions

When asking for help, include:
1. **What you're trying to do**
2. **The error message** (full output)
3. **Relevant task/playbook snippet**
4. **Ansible version**: `ansible --version`
5. **Target OS**: `ansible <host> -m setup -a 'filter=ansible_distribution*'`

### Resources

- [Ansible Documentation](https://docs.ansible.com)
- [Ansible Module Index](https://docs.ansible.com/ansible/latest/collections/index_module.html)
- [Ansible Galaxy](https://galaxy.ansible.com) - Community roles
