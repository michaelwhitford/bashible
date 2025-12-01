# SCRATCHPAD.md

Working notes for the current session. Update this as you work.

## Current Task

**SudoLang Experiment**: Testing SudoLang format for AI agent documentation.

Converted AGENTS.md and TROUBLESHOOTING.md to SudoLang format (in-place replacement).
Compare with `main` branch for original markdown versions.

## Notes

### SudoLang Conversion Complete (2024-12-01)

Replaced original markdown documentation with SudoLang versions:
- `AGENTS.md` - Now in SudoLang format
- `TROUBLESHOOTING.md` - Now in SudoLang format

**To compare with original markdown:**
```bash
git diff main -- AGENTS.md TROUBLESHOOTING.md
# Or checkout main branch to test original
git checkout main
```

### AGENTS.md SudoLang Features

**1. Behavior Modifiers (`@Autonomous`, `@Methodical`, `@Curious`)**
   - Signal to LLM how to approach tasks
   - Enable proactive exploration within bounds

**2. State Tracking (`State {}`)**
   - workingDirectory, venvActivated, currentTask
   - knownHosts, knownRoles, knownPlaybooks (populated by discovery)
   - lastError, sessionDiscoveries

**3. Constraints (`Constraints {}`)**
   - Shell-first philosophy rules
   - Ansible principles (idempotency, check-before-apply)
   - Autonomy bounds (what can/cannot do without asking)

**4. Inference Engine (`infer {}`)**
   - Derive hostOS from facts
   - Infer package manager from OS family
   - Determine if roles/playbooks exist

**5. Learning System (`learn {}`)**
   - Accumulate knowledge during session
   - Learn from errors to avoid repeating
   - Persist important discoveries to SCRATCHPAD.md

**6. Goal-Oriented Solving (`solve {}`)**
   - Declarative goals like "ensure nginx on webservers"
   - Agent figures out the steps autonomously

**7. Pattern Matching (`match {}`)**
   - Task classification (install, configure, debug, show)
   - Error pattern → appropriate recovery

**8. Pipe Operators (`|>`)**
   - Chain: `discover.inventory() |> parseHosts |> filter(reachable)`

**9. Autonomous Behaviors (`@auto {}`)**
   - canExecute: safe read-only commands
   - requireConfirm: commands that modify state

### TROUBLESHOOTING.md SudoLang Features

**1. `match error {}` patterns** - All common Ansible errors covered:
   - ConnectionError, AuthError, PrivilegeError
   - SyntaxError, VariableError, HangingTask
   - ModuleNotFound, ModuleFailed, RoleNotFound
   - VaultError, PerformanceIssue

**2. Nested `match cause {}`** - Specific causes with fixes

**3. `diagnose {}` interface** - Reusable diagnostic functions

**4. `DiagnosticChecklist`** - 7-step systematic debug sequence

**5. `troubleshoot(error)` entry point** - Automatic diagnosis

### Next Steps

1. Test with AI agents using SudoLang AGENTS.md as context
2. Compare task completion vs. main branch (markdown)
3. Evaluate: constraint adherence, token efficiency, workflow consistency
4. Consider converting ARCHITECTURE.md if experiment succeeds
5. Document test results here

## Commands That Worked

```bash
# Compare this branch with main
git diff main -- AGENTS.md TROUBLESHOOTING.md

# Switch to main for testing original markdown
git checkout main
```

## Blockers / Questions

- How to measure "AI comprehension" objectively?
- Token count comparison needed
