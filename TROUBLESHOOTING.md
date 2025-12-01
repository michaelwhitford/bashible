# TroubleshootingEngine

Diagnostic patterns and recovery strategies for Ansible automation.
Import into BashibleAgent for intelligent error handling.

@Diagnostic    // Gather information before acting
@Systematic    // Follow diagnostic sequences
@Helpful       // Explain findings and suggest fixes

## Core Principle

DiagnoseFirst {
  constraint: Never guess at solutions—gather data first
  constraint: Run diagnostics before suggesting fixes
  constraint: Learn from each error to improve future diagnosis
}

## Diagnostic Interface

diagnose {
  // Universal first steps for any error
  gatherContext(host) {
    ansible-inventory --host $host        // What do we know about this host?
    ansible $host -m ping -vvv            // Can we reach it?
    ansible $host -m setup 2>&1 | head -50  // What's the actual error?
  }
  
  // Deep connection diagnostics
  connectionInfo(host) {
    ansible $host -m ping -vvvv 2>&1 
      |> grep -E "(SSH|ESTABLISH|user)"   // What user/key is being used?
  }
  
  // Target-side diagnostics (if SSH works)
  targetSide(user, host) {
    ssh $user@$host "whoami && id && sudo -l"
  }
}

## Error Pattern Matching

// Connection Errors
match error {
  
  /unreachable/i | /SSH timeout/i | /Connection refused/ => ConnectionError {
    
    diagnose {
      ping $host_ip                        // Basic network
      ssh $user@$host_ip                   // Direct SSH
      ansible $host -m ping -vvvv          // Verbose ansible
    }
    
    match cause {
      "wrong IP/hostname" => {
        check: ansible-inventory --host $hostname
        verify: ansible_host is correct
        fix: edit inventory/hosts.yml or inventory/host_vars/$host.yml
      }
      
      "SSH key issues" => {
        check: ls -la ~/.ssh/
        verify: chmod 600 ~/.ssh/id_rsa
        test: ssh -i ~/.ssh/id_rsa $user@$host
        fix: add public key to target ~/.ssh/authorized_keys
      }
      
      "wrong user" => {
        check: ansible_user in inventory
        test: ansible $host -u root -m ping
        fix: set ansible_user in host_vars or group_vars
      }
      
      "firewall blocking" => {
        check: port 22 open on target
        test: nc -zv $host 22
        fix: configure firewall or use bastion host
      }
      
      "host key verification" => {
        fix: ssh $host (accept key manually)
        alt: set host_key_checking = False in ansible.cfg (dev only!)
      }
    }
  }
  
  /Permission denied/ | /authentication failed/i => AuthError {
    
    match cause {
      "wrong SSH key" => {
        test: ansible $host -m ping --private-key=/path/to/key
        fix: specify correct key or update ansible.cfg
      }
      
      "password required" => {
        test: ansible $host -m ping --ask-pass
        fix: set up key-based auth or use --ask-pass
      }
      
      "key not authorized" => {
        fix: add public key to target ~/.ssh/authorized_keys
        cmd: ssh-copy-id $user@$host
      }
    }
  }
}

// Privilege Errors
match error {
  
  /Missing sudo password/i | /sudo.*password is required/i => PrivilegeError {
    
    solutions: [
      {
        name: "Provide sudo password at runtime"
        cmd: ansible-playbook site.yml --ask-become-pass
        alt: ansible-playbook site.yml -K
      },
      {
        name: "Configure passwordless sudo on target"
        cmd: echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$user
        note: "Run this ON the target host"
      },
      {
        name: "Set become password in vault"
        file: inventory/group_vars/all/vault.yml
        content: ansible_become_password: "{{ vault_sudo_password }}"
        encrypt: ansible-vault encrypt inventory/group_vars/all/vault.yml
      },
      {
        name: "Check playbook become settings"
        verify: |
          - hosts: all
            become: true
            become_method: sudo
      }
    ]
  }
}

// Syntax & YAML Errors
match error {
  
  /Syntax error/i | /YAML/i | /could not be parsed/i => SyntaxError {
    
    diagnose {
      ansible-playbook $playbook --syntax-check
    }
    
    match cause {
      /indentation/ => {
        rule: "Use 2 spaces, never tabs"
        check: "Consistent indentation throughout file"
        cmd: cat -A $file | head -50  // Show tabs as ^I
      }
      
      /quotes/ | /special char/ => {
        rule: "Strings with : { } [ ] , & * # ? | - < > = ! % @ \\ need quotes"
        example: 'message: "Hello: World"  # colon in value needs quotes'
      }
      
      /colon/ => {
        rule: "Every key needs `: ` (colon + space)"
        wrong: "key:value"
        right: "key: value"
      }
      
      /jinja/i | /{{/ => {
        rule: "Check Jinja2 syntax: {{ variable }}"
        common_issues: [
          "Missing closing }}",
          "Unquoted string starting with {",
          "Filter syntax: {{ var | default('x') }}"
        ]
      }
    }
  }
}

// Variable Errors
match error {
  
  /undefined variable/i | /is undefined/i => VariableError {
    
    // Extract variable name from error
    extract varName from /undefined variable[:\s]+'?(\w+)'?/
    
    diagnose {
      ansible $host -m debug -a "var=$varName"
      ansible $host -m debug -a "var=hostvars[inventory_hostname]"
    }
    
    search varName in [
      "inventory/group_vars/all.yml",
      "inventory/group_vars/$group.yml",
      "inventory/host_vars/$host.yml",
      "roles/*/defaults/main.yml"
    ]
    
    solutions: [
      {
        name: "Define in appropriate location"
        locations: {
          "All hosts": "group_vars/all.yml",
          "Group specific": "group_vars/<group>.yml",
          "Host specific": "host_vars/<host>.yml",
          "Role default": "roles/<role>/defaults/main.yml"
        }
      },
      {
        name: "Use default filter"
        example: '{{ some_var | default("fallback_value") }}'
      },
      {
        name: "Check spelling"
        note: "Variables are case-sensitive!"
      }
    ]
  }
}

// Playbook Execution Errors
match error {
  
  /Task.*hangs/i | /never completes/i | /timeout/i => HangingTask {
    
    match cause {
      "interactive command" => {
        problem: "Commands needing stdin will hang"
        wrong: "shell: apt upgrade"
        right: |
          apt:
            upgrade: yes
      }
      
      "long running task" => {
        solution: "Use async"
        example: |
          - name: Long running task
            command: /path/to/slow/script
            async: 3600    # Max seconds
            poll: 30       # Check interval
      }
      
      "stuck process on target" => {
        diagnose: ssh $host "ps aux | grep ansible"
        fix: kill stuck process, then retry
      }
    }
  }
  
  /No matching host/i | /Could not match.*host pattern/i => HostPatternError {
    
    diagnose {
      ansible-inventory --list | jq 'keys'
      ansible-inventory --graph
    }
    
    patterns {
      "all"                    // All hosts
      "webservers"             // Group name
      "web*"                   // Wildcard
      "webservers:&production" // Intersection (AND)
      "webservers:!web1"       // Exclusion (NOT)
      "webservers:databases"   // Union (OR)
    }
    
    check: "playbook hosts: field matches inventory group/host"
    
    infer correctPattern from {
      state.knownHosts,
      state.knownGroups,
      userIntent
    }
  }
}

// Module Errors
match error {
  
  /Module.*not found/i | /couldn't resolve module/i => ModuleNotFound {
    
    diagnose {
      ansible --version
    }
    
    solutions: [
      {
        name: "Check Ansible version"
        note: "Some modules require newer versions"
        cmd: ansible --version
      },
      {
        name: "Install collection"
        cmd: ansible-galaxy collection install community.general
      },
      {
        name: "Use FQCN"
        wrong: "copy:"
        right: "ansible.builtin.copy:"
      }
    ]
  }
  
  /Module failed/i | /fatal/i => ModuleFailed {
    
    diagnose {
      ansible-playbook $playbook -vvv
      ansible $host -m $module -a "$args" -vvv
    }
    
    match module {
      "apt" | "yum" | "dnf" => {
        issue: "Package name doesn't exist"
        diagnose: ansible $host -m shell -a "apt-cache search $package"
        alt: ansible $host -m shell -a "yum search $package"
      }
      
      "service" | "systemd" => {
        issue: "Service name wrong"
        diagnose: ansible $host -m shell -a "systemctl list-units --type=service"
      }
      
      "file" | "copy" => {
        issue: "Path doesn't exist"
        diagnose: ansible $host -m stat -a "path=$path"
      }
      
      "template" => {
        issue: "Jinja2 error in template"
        diagnose: ansible localhost -m template -a "src=$template dest=/tmp/test"
      }
    }
  }
}

// Role Errors
match error {
  
  /Role.*not found/i | /couldn't find role/i => RoleNotFound {
    
    diagnose {
      ls -la roles/
      grep roles_path ansible.cfg
    }
    
    solutions: [
      {
        name: "Check role exists"
        cmd: ls roles/$role_name/tasks/main.yml
      },
      {
        name: "Check roles_path in ansible.cfg"
        expect: "roles_path = roles"
      },
      {
        name: "Install from Galaxy if external"
        cmd: ansible-galaxy install $role_name
      }
    ]
  }
  
  /Handler.*not.*triggered/i | /handler.*never runs/i => HandlerNotTriggered {
    
    causes: [
      {
        name: "Handler name mismatch"
        rule: "notify name must exactly match handler name (case-sensitive)"
        example: |
          # In tasks
          - name: Update config
            template: ...
            notify: Restart nginx    # Must match exactly
          
          # In handlers  
          - name: Restart nginx      # Case sensitive!
            service: ...
      },
      {
        name: "Task didn't report changed"
        rule: "Handlers only run if notifying task reports 'changed'"
        diagnose: "Run with --check to see if task would change"
      },
      {
        name: "Need immediate handler execution"
        solution: |
          - meta: flush_handlers    # Force handlers to run now
      }
    ]
  }
}

// Vault Errors
match error {
  
  /Decryption failed/i | /vault password/i => VaultError {
    
    match cause {
      "wrong password" => {
        retry: ansible-playbook site.yml --ask-vault-pass
      }
      
      "wrong vault ID" => {
        cmd: ansible-playbook site.yml --vault-id dev@prompt
      }
      
      "file not encrypted" => {
        check: head -1 $file
        expect: "$ANSIBLE_VAULT;1.1;AES256"
        fix: ansible-vault encrypt $file
      }
    }
  }
  
  /not vault encrypted/i => {
    fix: ansible-vault encrypt $file
  }
}

// Performance Issues
match issue {
  
  /slow/i | /takes too long/i => PerformanceIssue {
    
    optimizations: [
      {
        name: "Increase parallelism"
        file: ansible.cfg
        setting: |
          [defaults]
          forks = 20    # Default is 5
      },
      {
        name: "Disable fact gathering if not needed"
        playbook: |
          - hosts: all
            gather_facts: false
      },
      {
        name: "Use free strategy"
        playbook: |
          - hosts: all
            strategy: free    # Don't wait for slowest host
      },
      {
        name: "Cache facts"
        file: ansible.cfg
        setting: |
          [defaults]
          fact_caching = jsonfile
          fact_caching_connection = /tmp/ansible_facts
          fact_caching_timeout = 86400
      }
    ]
  }
}

## Debug Toolkit

debug {
  
  // Print variables in playbook
  printVar(varname) => |
    - debug:
        var: $varname
  
  printMsg(template) => |
    - debug:
        msg: "$template"
  
  // Command-line debugging
  startAt(playbook, task) => ansible-playbook $playbook --start-at-task="$task"
  
  step(playbook) => ansible-playbook $playbook --step
  
  checkMode(playbook) => ansible-playbook $playbook --check --diff
  
  verbose(playbook, level) => {
    // level: 1-4
    match level {
      1 => ansible-playbook $playbook -v      // Basic
      2 => ansible-playbook $playbook -vv     // More detail
      3 => ansible-playbook $playbook -vvv    // Connection info
      4 => ansible-playbook $playbook -vvvv   // Full debug
    }
  }
  
  // Register and inspect pattern
  registerPattern() => |
    - name: Run command
      command: $cmd
      register: result
    
    - debug:
        var: result
}

## Master Diagnostic Sequence

DiagnosticChecklist {
  // Run these in order when something isn't working
  
  sequence: [
    { step: 1, name: "Syntax check", cmd: "ansible-playbook $playbook --syntax-check" },
    { step: 2, name: "Lint",         cmd: "ansible-lint $playbook" },
    { step: 3, name: "Inventory",    cmd: "ansible-inventory --list" },
    { step: 4, name: "Connectivity", cmd: "ansible $host -m ping" },
    { step: 5, name: "Dry run",      cmd: "ansible-playbook $playbook --check --diff" },
    { step: 6, name: "Verbose",      cmd: "ansible-playbook $playbook -vvv" },
    { step: 7, name: "Limit scope",  cmd: "ansible-playbook $playbook --limit $host" }
  ]
  
  runAll(playbook, host?) {
    for step in sequence:
      run step.cmd
      if failed: 
        stop
        diagnose step failure
  }
}

## Help Request Template

WhenAskingForHelp {
  include: [
    "What you're trying to do",
    "The error message (full output)",
    "Relevant task/playbook snippet",
    "Ansible version: ansible --version",
    "Target OS: ansible $host -m setup -a 'filter=ansible_distribution*'"
  ]
}

## Quick Diagnosis Entry Point

// Main entry point - call this with any error
troubleshoot(error) {
  // Extract context from error
  extract {
    errorType from error pattern
    host from error message
    task from error context
    module from error context
  }
  
  // Log for learning
  learn.fromError(error)
  
  // Run appropriate diagnostic
  match errorType {
    ConnectionError  => diagnose.gatherContext(host)
    AuthError        => diagnose.connectionInfo(host)
    PrivilegeError   => suggest privilege solutions
    SyntaxError      => run ansible-playbook --syntax-check
    VariableError    => debug.vars(host)
    ModuleFailed     => debug.verbose(playbook, 3)
    _                => DiagnosticChecklist.runAll(playbook, host)
  }
  
  // Suggest fixes based on pattern match
  infer solutions from error pattern
  present solutions ranked by likelihood
}

## Resources

Resources {
  docs: "https://docs.ansible.com"
  modules: "https://docs.ansible.com/ansible/latest/collections/index_module.html"
  galaxy: "https://galaxy.ansible.com"
}
