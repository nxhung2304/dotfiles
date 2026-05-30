---
name: review-branch
allowed-tools: Read, Write, Grep, Glob, Bash(ls:*), Bash(git:*)
description: Review code changes between two branches for clean code, style conventions, security vulnerabilities, and performance issues. Use when user asks "review code", "review my branch", "review-branch", or "review <branch> against <base>".
---

# Review Branch

## Quick start

`/review-branch <feature-branch> <base-branch>`

Example: `/review-branch feature/auth main`

## Workflow

### 1. Load rules (token-efficient)

**Always load:**
- `.claude/code-rules/core.md` (always, ~17 lines)
- `.claude/code-rules/index.md` (keyword map for targeted reads)

**Then load only sections relevant to the diff's file types** using the index keyword map.

**Also check `specs/code-rules/` in project root** — if it exists, read any `.md` files there as project-specific overrides.

### 2. Diff the branch

```bash
git diff <base>..<branch> --stat
git diff <base>..<branch>
```

### 3. Review each changed file

Apply rules loaded in step 1 across 4 areas:
- **Clean code**: naming, function size, magic numbers, hardcoded strings, DRY, single responsibility
- **Style**: indentation, line length, blank lines, guard clauses, condition formatting
- **Security**: input validation, auth checks, hardcoded secrets, injection risks
- **Performance**: N+1 queries, unnecessary loops, memory leaks, heavy ops in hot paths

### 4. Output structured report

```markdown
# Code Review: <branch> → <base>

## Summary
[1-2 sentence overview]

## Issues

### Critical
- `file.py:42` – SQL built with string concat → use parameterized queries

### Warning
- `utils/helper.js:15` – function >30 lines, does 3 things → extract into smaller functions

### Suggestion
- `models/user.rb:88` – rename `x` to `expiry_date` for clarity

## Passed
- No hardcoded secrets found
- Guard clauses used correctly

## Rules applied
- Global: core.md, clean-code.md §Naming, code-style.md §Indentation
- Project: specs/code-rules/flutter.md (if loaded)
```

## Rules

- Only real issues — no filler praise
- Group by severity: Critical → Warning → Suggestion
- Each issue: `file:line – problem → fix`
- If nothing found in a category, state "None found"
- Use targeted section reads from the index — do NOT read full rule files unless necessary

## Write to file
- After review, write markdown file to `specs/comments/[issue-branch]-title.md`
- If the file already exists, append a timestamp suffix: `[issue-branch]-title-YYYYMMDD-HHMMSS.md` to avoid silent overwrite
