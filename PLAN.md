# PLAN.md

High-level plan for infrastructure changes. Update this before starting work.

## Current Objective

**Experiment with SudoLang for AI-agent documentation.**

Convert AGENTS.md to SudoLang format to test whether the structured pseudocode approach improves AI agent comprehension and task execution compared to the current markdown format.

## Background: What is SudoLang?

SudoLang is a declarative, constraint-based, interface-oriented pseudocode language designed for LLMs. Key characteristics:

- **Natural language + structure**: Combines readability with programming constructs
- **Constraint-based**: Declare rules the AI must follow (vs. imperative instructions)
- **Interface-oriented**: Define state, behaviors, and commands in structured blocks
- **20-30% fewer tokens**: More compact than pure natural language
- **Better reasoning**: Pseudocode structure improves LLM comprehension vs. prose

### Why This Might Work for AGENTS.md

Current AGENTS.md is ~450 lines of markdown with:
- Workflow instructions (procedural)
- Command reference tables (data)
- Constraints/principles (rules)
- Examples (patterns)

SudoLang could improve this by:
1. Making constraints explicit and enforceable
2. Defining clear state (what the agent tracks)
3. Structuring commands as callable interfaces
4. Reducing verbosity while keeping clarity

### SudoLang Program Structure (PICS)

```
Preamble     - Role, job, context (who is the agent?)
Interface    - State, constraints, methods, commands
Components   - Supporting functions/interfaces
Start        - Initial greeting or kickoff
```

## Approach

### Phase 1: Create SudoLang Version ✅ COMPLETE

1. ~~**Keep existing AGENTS.md intact** - Don't break what works~~
2. ~~**Create `AGENTS.sudo.md`** - New SudoLang version alongside~~
3. **Converted in-place** - Original markdown available on `main` branch
4. **Converted sections**:
   - TL;DR → Preamble with role and context
   - Shell-Driven Philosophy → Constraints block
   - Development Workflow → Interface with state and methods
   - Command tables → Callable functions
   - Discovery patterns → Composable commands

### Phase 2: Structure the SudoLang Program ✅ COMPLETE

Implemented in `AGENTS.md` with enhanced features beyond the original proposal:

- `@Autonomous`, `@Methodical`, `@Curious` behavior modifiers
- `State {}` with session tracking (knownHosts, knownRoles, etc.)
- `Constraints {}` with autonomy bounds
- `init @auto {}` for self-initialization
- `infer {}` for deriving facts
- `learn {}` for accumulating knowledge
- `solve {}` for goal-oriented problem solving
- `match {}` for pattern-based decisions
- `|>` pipe operators for chaining
- `@auto {}` with canExecute/requireConfirm lists
- `context {}` for session awareness
- `teach {}` for self-improvement

### Phase 3: Test and Compare ⏳ IN PROGRESS

1. **A/B test with AI agents**:
   - Run same tasks with this branch (SudoLang) vs `main` branch (markdown)
   - Compare: task completion, errors, token usage

2. **Evaluate criteria**:
   - Does the agent follow the workflow more consistently?
   - Are constraints respected better?
   - Is discovery faster/more accurate?
   - Token efficiency (context window usage)

3. **Gather feedback**:
   - Does the structure feel more actionable?
   - Are commands clearer?

### Phase 4: Decide and Iterate

Based on testing:
- **If SudoLang wins**: Merge branch to main
- **If markdown wins**: Close branch, document learnings
- **If mixed**: Cherry-pick best parts

## Files Affected

| File | Action |
|------|--------|
| `AGENTS.md` | Converted to SudoLang (compare with `main` for original) |
| `TROUBLESHOOTING.md` | Converted to SudoLang (compare with `main` for original) |
| `README.md` | Updated references |
| `SCRATCHPAD.md` | Document test results |
| `CHANGELOG.md` | Record experiment |

## Rollback Plan

```bash
git checkout main  # Switch to original markdown versions
```

## Verification

1. AI agent can parse and follow AGENTS.sudo.md
2. Workflow steps execute correctly
3. Constraints are respected
4. Compare task success rate between versions

## Open Questions

- Should we convert other docs (ARCHITECTURE.md, TROUBLESHOOTING.md)?
- How to handle the detailed command tables—inline or reference?
- Should commands be `/slash` style or natural language?
- How much of the current markdown is "human documentation" vs "agent instructions"?

## Resources

- [SudoLang Spec](https://github.com/paralleldrive/sudolang-llm-support/blob/main/sudolang.sudo.md)
- [SudoLang Examples](https://github.com/paralleldrive/sudolang-llm-support/tree/main/examples)
- [Anatomy of a SudoLang Program](https://medium.com/javascript-scene/anatomy-of-a-sudolang-program-prompt-engineering-by-example-f7a7b65263bc)

---

## Completed Plans

*Move finished plans here for reference*
