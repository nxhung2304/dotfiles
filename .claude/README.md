# Claude Code - Commands, Skills & Agents

## Overview

Reference documentation for the commands, skills, and agents available in the Claude Code harness for this repository.

---

## Skills

Skills are reusable tasks invoked via `/skill-name` or the `Skill` tool. The tables below list actual **usage** (params, examples) pulled from each `SKILL.md`, not just a generic description.

### Git / Commit

| Skill | Usage | Notes |
|-------|-------|-------|
| `commit` | `/commit` (no args) | Reads staged changes, generates a `type: subject` commit message + WHAT/WHY bullets, **commits immediately, no confirmation** |
| `short-commit` | `/short-commit` | Generates a one-line message, **shows it for user approval before committing** — never auto-commits |
| `commit-push` | `/commit-push` | Calls `commit` → `git push` → reports commit hash + push result |
| `commit-push-by-category` | `/commit-push-by-category` | Groups changed files by category (directory/file type), commits each group separately via `commit`, then pushes via `commit-push` |
| `pr-desc [lang: <language>]` | `/pr-desc` or `/pr-desc lang: en` | Summarizes the diff/commit log between the current branch and base into a PR description (prints only, **does not create/update the PR on GitHub**). Defaults to Vietnamese |

### Review

| Skill | Usage | Notes |
|-------|-------|-------|
| `review-branch [<feature-branch>] [<base-branch>] [include-staged: true\|false]` | `/review-branch` or `/review-branch feature/auth main` or `/review-branch include-staged: true` | Reviews against project clean-code/style/security/performance rules. Default diffs branch-vs-base only (committed); `include-staged: true` also reviews staged changes. Writes `specs/comments/[branch]-title.md` |
| `review-issue [<feature-branch>] [<base-branch>] [lang: <language>]` | `/review-issue` | Orchestrator: runs `review-branch` (with `include-staged: true`) + the built-in `code-review` in parallel, merges + dedupes, maps severity to MUST/SHOULD/NIT, writes `specs/issues/<issue-number>/comment.log`. Never edits code, never comments on the PR |
| `review-specs` | `/review-specs #11` or state the issue number | Reviews the spec in `specs/issues/[issue-number]` (Acceptance Criteria, Checklist, edge cases...), writes feedback to `specs/comments/[ISSUE-NUMBER]-spec-review.md` |
| `simplify` | `simplify` | Reviews changed code for reuse/simplification/efficiency opportunities and **applies the fixes itself** (quality only, not bug-hunting — use `/code-review` for that) |

### Issue Lifecycle

| Skill | Usage | Notes |
|-------|-------|-------|
| `feature-discuss <feature-name>` | `/feature-discuss <feature name>` | `discuss` mode (default, read-only): design discussion before an issue file exists. `finalize` mode: only on an explicit signal (`/feature-discuss finalize #<number>` or an unambiguous confirming sentence) does it write to `specs/issues/` |
| `drill-issue` | point it at an issue file | Asks one question at a time to clarify requirements/edge cases, writes decisions back into the issue file (Key decisions, Notes) |
| `grill-me` | `grill-me` | Interviews the user relentlessly about a plan/design until every decision branch is resolved (up to ~15 questions), ends with a Decision Summary |
| `fix-issue` | `/fix-issue` or state the issue number/bug description | Phase 1: investigates the bug via Q&A + code tracing, produces a root cause + fix plan. Only scaffolds the 5 files (`issue.md`, `investigate.md`, `implement.md`, `testcases.md`, `report.md`) under `specs/issues/` once the user confirms they're starting a real fix |
| `generate-issues` | `/generate-issues` or `/generate-issues 1.1` | Reads `specs/story.md`, parses `- [ ] [number]. [title]` tasks, creates individual issue files in `issues/` (can target a specific number) |
| `github-issues-to-md` | needs `owner`, `repo`, `issue_number` | Fetches a GitHub Issue via MCP, converts to Markdown, saves as `specs/issues/[issue-number].md` |
| `md-to-github-issues` | `/md-to-github-issues` (no args) | Syncs files under `specs/issues/*.md` that are `Review: Approved` and have no `GitHub Issue: #` yet up to GitHub Issues, writes the issue number back into the file |
| `bug-report-writer [lang: <language>]` | paste/write a bug report draft then invoke the skill | Rewrites/refines a bug investigation report before sending to a leader/reviewer; section count scales with severity |

### Implement Flow (orchestrators)

| Skill | Usage | Notes |
|-------|-------|-------|
| `implement-issue [spec-filename]` | `/implement-issue <spec-filename>` | Full-flow orchestrator, runs automatically without stopping: `implement-prepare` → `implement-code` → `implement-quality` → `implement-finalize`, then reports a summary |
| `implement-local [spec-filename]` | `/implement-local <spec-filename>` | Same as above but stops after `implement-quality` — **no commit, no PR, no Slack** |
| `implement-prepare [spec-filename]` | used internally by the two above | Checks out + pulls `develop`/`main`, verifies `Review: Approved`, creates branch `feature/[user]-#[issue]-[slug]`, notifies Slack if configured |
| `implement-code` | used internally | Reads the spec's Implementation Checklist, codes each item, calls `rule-lookup`/`design-checker`/`code-reviewer` as needed |
| `implement-quality` | used internally | Auto-detects the stack (Flutter/Rails/Go/Rust/Python/Node...) and runs the matching checks (`flutter analyze`, `rubocop`, ...), calls `error-fixer` on errors |
| `implement-finalize` | used internally | Commits, updates spec status → `PR: Draft`, pushes, opens a Draft PR via GitHub MCP, notifies Slack |

### Development Tools

| Skill | Description | Trigger |
|-------|--------------|---------|
| `claude-api` | Build, debug, optimize apps using the Claude API/Anthropic SDK | When code imports `anthropic` or asks about the Claude API |
| `frontend-design:frontend-design` | Create high-quality frontend interfaces | When asked about web components/pages/apps |
| `refactor` | Refactor code to improve readability and maintainability | `refactor` |

### Learning & Planning

| Skill | Description | Trigger |
|-------|--------------|---------|
| `mentor` | Acts as a coding mentor: suggests roadmaps, notes, outlines | `mentor` |

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
| **error-fixer** | Fixes flutter analyze and flutter test errors | Read, Edit, Write, Bash(flutter analyze/test), Grep | Fix Flutter errors, only touches related files |
| **design-checker** | Checks and syncs colors/design tokens from an HTML wireframe to AppColors | Read, Grep, Edit, Write | Sync design tokens |
| **claude-code-guide** | Answers questions about the Claude Code CLI, Agent SDK, API | Glob, Grep, Read, WebFetch, WebSearch | Questions about Claude Code features |

---

## Flow & Workflow

### 1. Code Review Flow
```
user: "review code issue"
  → Skill: review-branch
    → Agent: rule-lookup (look up rules)
    → Agent: code-reviewer (review against rules)
```

### 2. Implementation Flow
```
user: "implement feature X"
  → EnterPlanMode (if the task is complex)
    → Agent: Explore (explore the codebase)
    → Agent: Plan (design the plan)
  → ExitPlanMode (user approves)
  → Implementation (write code)
  → Agent: error-fixer (if errors)
```

### 3. Quality Check Flow
```
user: "quality issue"
  → Skill: review-branch / implement-quality
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
