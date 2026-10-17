# Claude Code - Commands, Skills & Agents

## Overview

Reference documentation for the commands, skills, and agents available in the Claude Code harness for this repository.

---

## Skills

Skills are reusable tasks invoked via `/skill-name` or the `Skill` tool. Full catalog with usage/params for every project skill lives at **[.claude/skills/README.md](./skills/README.md)** — grouped by Git & Commit Management, Issue & Spec Management, Review & Quality, and the Implementation Pipeline.

### Global / built-in skills (not project-local)

These aren't defined under `.claude/skills/` in this repo — they're global/plugin skills available in the harness:

| Skill | Description | Trigger |
|-------|--------------|---------|
| `claude-api` | Build, debug, optimize apps using the Claude API/Anthropic SDK | When code imports `anthropic` or asks about the Claude API |
| `frontend-design:frontend-design` | Create high-quality frontend interfaces | When asked about web components/pages/apps |
| `simplify` | Reviews changed code for reuse/simplification/efficiency and **applies the fixes itself** (quality only, not bug-hunting — use `/code-review` for that) | `simplify` |

### Custom slash commands (`.claude/commands/`)

| Command | Description |
|---------|--------------|
| `/refactor` | Refactor code to improve readability and maintainability |
| `/mentor` | Acts as a coding mentor: suggests roadmaps, notes, outlines |

---

## Agents

Agents are specialists with their own capabilities and tools:

| Agent | Description | Tools | When to use |
|-------|--------------|-------|-------------|
| **Explore** | Fast codebase exploration, find files, search keywords | All (except Agent, ExitPlanMode, Edit, Write, NotebookEdit) | Find files by pattern, search keywords, understand the codebase |
| **Plan** | Design an implementation plan, answer architecture questions | All (except Agent, ExitPlanMode, Edit, Write, NotebookEdit) | Plan implementation, design architecture |
| **general-purpose** | General-purpose agent for complex, multi-step tasks | All tools | Complex tasks that don't fit another agent |
| **code-reviewer** | Reviews code against clean-code, code-style, project rules | Read, Grep, Bash(git diff) | Code review, read-only |
| **rule-lookup** | Looks up rules by language and task | Read, Grep | Find rules in core.md, general/, project-specific |
| **quality-runner** | Detects the stack, runs analyze/lint/test, fixes source errors (max 3 attempts per failing check); never edits tests to make them pass | Read, Edit, Grep, Glob, Bash scoped to stack commands | Quality check step of `implement-issue` |
| **review-branch** | Reviews a branch diff against project rules, writes its result under `specs/comments/` (the `/review-branch` skill invokes it) | Read, Write, Grep, Glob, read-only Bash/git | Branch review, read-only except the result file |
| **design-checker** | Checks colors/design tokens from an HTML wireframe against AppColors and proposes changes (Flutter only) | Read, Grep | Design token check |
| **claude-code-guide** | Answers questions about the Claude Code CLI, Agent SDK, API | Glob, Grep, Read, WebFetch, WebSearch | Questions about Claude Code features |

---

## Flow & Workflow

### 1. Code Review Flow
```
user: "review code issue"
  → Skill: review-branch
    → Agent: review-branch (loads rules, reviews the diff, writes the result file)
```

### 2. Implementation Flow
```
user: "implement feature X"
  → EnterPlanMode (if the task is complex)
    → Agent: Explore (explore the codebase)
    → Agent: Plan (design the plan)
  → ExitPlanMode (user approves)
  → Implementation (write code)
  → Agent: quality-runner (analyze/lint/test, fixes errors)
```

### 3. Quality Check Flow
```
user: "quality issue"
  → Skill: review-branch / Agent: quality-runner
    → Agent: rule-lookup
    → Agent: code-reviewer
```

### 4. Commit Workflow
```
user: "commit" or "/commit"
  → Skill: commit
    → Bash: git status, git diff, git log
    → Generate commit message
    → Bash: git commit
```

### 5. Git Operations Flow
```
user: "commit-push-pr"
  → Skill: commit-commands:commit-push-pr
    → Bash: git status, diff, log
    → Bash: git commit
    → Bash: git push (if needed)
    → Bash: gh pr create
```

---

## Token Strategy

- **core.md**: always loaded, contains critical principles
- **general/**: rules by language (Ruby, Flutter, etc.)
- **project-specific/**: rules specific to the project
- **rule-lookup agent**: looks up rules to optimize token usage

---

## Important Rules

1. **Only use a skill when appropriate** - read the user request carefully
2. **Agents for parallel work** - run multiple agents at once to improve performance
3. **Plan mode for complex tasks** - use EnterPlanMode for tasks that need design work
4. **Todo list for tracking** - use TaskCreate/TaskUpdate for multi-step tasks
5. **Dedicated tools over Bash** - prefer Read, Edit, Grep over cat/sed/grep

---

## Notes

- This file lives at `.claude/README.md`
- Skill definitions live at `.claude/skills/`
- Settings config at `~/.claude/settings.json`
- Keybindings customization at `~/.claude/keybindings.json`
