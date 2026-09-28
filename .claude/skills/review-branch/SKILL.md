---
name: review-branch
allowed-tools: Read, Write, Grep, Glob, Bash(ls:*), Bash(git:*), Bash(mkdir:*)
description: Review code changes between two branches for clean code, style conventions, security vulnerabilities, and performance issues. Use when user asks "review code", "review my branch", "review-branch", or "review <branch> against <base>".
---

# Review Branch

## Quick start

`/review-branch [<feature-branch>] [<base-branch>] [include-staged: true|false]`

All params are optional:
- No params → review current branch against `main` (or `master` if `main` doesn't exist)
- One param → use it as base branch, feature branch = current branch
- Two params → explicit feature and base branch
- `include-staged: true` — also review staged-but-uncommitted changes (default: `false`, i.e. committed changes only). Unstaged working-tree changes are never included, regardless of this flag.

Example: `/review-branch` or `/review-branch feature/auth main` or `/review-branch include-staged: true`

## Workflow

### 0. Resolve branches

If no params provided, run:
```bash
git branch --show-current         # feature branch
git branch -r | grep -E 'main|master' | head -1  # detect base branch
```

### 1. Load rules (token-efficient)

**Always load (global rules at `~/.claude/code-rules/`):**
- `~/.claude/code-rules/core.md` (always, ~17 lines)
- `~/.claude/code-rules/index.md` (keyword map for targeted reads)
- `~/.claude/code-rules/general/security-authz.md` (always — object-level authorization/IDOR checks apply to any diff touching an endpoint/handler that looks up a resource by id, regardless of language/framework; not keyword-gated)

**Then load only sections relevant to the diff's file types** using the index keyword map.

**Also check project-level overrides (in order):**
- `.claude/code-rules/` in project root — if it exists, load `core.md` and `index.md` there
- `specs/code-rules/` in project root — if it exists, read any `.md` files there as project-specific overrides

### 2. Diff the branch

```bash
git diff <base>..<branch> --stat
git diff <base>..<branch>
```

If `include-staged: true` was passed, also diff staged-but-uncommitted changes and review them alongside the branch diff (note in the report which findings come from staged changes):
```bash
git diff --cached --stat
git diff --cached
```

Unstaged working-tree changes are out of scope in all cases — never run a plain `git diff` (no `--cached`) for review purposes.

### 3. Review each changed file

Apply rules loaded in step 1 across these areas:
- **Clean code**: naming, function size, magic numbers, hardcoded strings, DRY, single responsibility
- **Style**: indentation, line length, blank lines, guard clauses, condition formatting
- **Security**: input validation, auth checks, hardcoded secrets, injection risks, object-level authorization/ownership (IDOR — see `security-authz.md`; for any action that resolves a resource by an id/slug from params/route/body, trace whether the lookup or the authorization rule checks the record's own owner/user/account FK against the current actor)
- **Performance**: N+1 queries, unnecessary loops, memory leaks, heavy ops in hot paths
- **Correctness / logic bugs**: off-by-one, inverted conditions, unhandled null/undefined, wrong operator, silently swallowed exceptions (empty `catch {}`)
- **Concurrency / race conditions**: shared mutable state without locking, non-atomic async/await read-modify-write, singleton/cache thread-safety, potential deadlock, wrong transaction isolation level
- **Error handling & edge cases**: errors not logged/propagated, a resource (file handle, DB connection, listener) not closed when an exception happens mid-way, unhandled edge cases like an empty list/zero/negative number
- **Cleanup / hygiene**: leftover unused code/imports/variables, commented-out code, forgotten debug statements (`console.log`, `print`, `debugger`), TODO/FIXME with no ticket, unrelated files/diffs mixed into the commit
- **Test coverage**: new logic with no accompanying test, a test modified to fake-pass (skip/disable instead of fixing it)
- **Breaking changes / migration safety**: an API contract change affecting other callers, a non-reversible migration, a new `NOT NULL` column missing a default, locking a large table during migration

### 3.5 Verify before asserting (MANDATORY)

**No speculation. Every finding must be confirmed against the real code/data before it goes in the report.** A review that reports a hypothetical as a bug is worse than missing it.

Rules:
- **Construct a concrete failure scenario.** For each Critical/Warning, you must be able to state: "with input/state X, line Y produces wrong result Z." If you can't build a scenario that actually occurs, do NOT report it.
- **Verify at the strongest source of truth, in order** — don't stop early:
  1. DB schema (`db/schema.rb` / migrations): `null: false`, foreign keys, unique indexes, defaults, column types.
  2. Actual runtime behavior / framework guarantees (cascade `dependent:`, soft-delete gem, default scopes).
  3. App-layer validations (`validates`, `belongs_to` required) — **these only run on save; never treat them as a guarantee about existing data.**
- **Nil / null concerns → check `db/schema.rb` FIRST** (NOT NULL + FK constraint). If the column is `null: false` with an FK, the value cannot be nil for valid data — do not report a nil-crash.
- **Never lower the bar with "unlikely", "edge case", "in theory".** If you write those words next to a finding, that's the signal you haven't verified it. Either prove it can happen with a real scenario, or drop it.
- **Distinguish "the diff changed behavior" from "the diff is buggy."** Only report the latter.
- If a concern is plausible but you cannot verify it with the tools available, put it under a separate **"Unverified — needs author confirmation"** list phrased as a question, NOT as a Critical/Warning finding.
- **Race conditions especially**: only report if you can point to the concrete interleaving (which two operations, in what order, produce the wrong state). "This might race" without a concrete interleaving goes in "Unverified", not Critical/Warning.

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

- **Verified issues only — no speculation.** See step 3.5. Every Critical/Warning must have a concrete, confirmed failure scenario.
- Only real issues — no filler praise
- Group by severity: Critical → Warning → Suggestion
- Each issue: `file:line – problem → fix` (state what you verified, and how)
- If nothing found in a category, state "None found"
- Use targeted section reads from the index — do NOT read full rule files unless necessary
- Prefer under-reporting to over-reporting: a false Warning erodes trust more than a missed nit.

## Write to file
- After review, write markdown file to `specs/comments/[issue-branch]-title.md`
- If the file already exists, append a timestamp suffix: `[issue-branch]-title-YYYYMMDD-HHMMSS.md` to avoid silent overwrite
