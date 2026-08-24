---
name: review-branch
allowed-tools: Read, Write, Grep, Glob, Bash(ls:*), Bash(git:*), Bash(mkdir:*)
description: Review code changes between two branches for clean code, style conventions, security vulnerabilities, and performance issues. Use when user asks "review code", "review my branch", "review-branch", or "review <branch> against <base>".
---

# Review Branch

## Quick start

`/review-branch [<feature-branch>] [<base-branch>]`

All params are optional:
- No params → review current branch against `main` (or `master` if `main` doesn't exist)
- One param → use it as base branch, feature branch = current branch
- Two params → explicit feature and base branch

Example: `/review-branch` or `/review-branch feature/auth main`

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

**Then load only sections relevant to the diff's file types** using the index keyword map.

**Also check project-level overrides (in order):**
- `.claude/code-rules/` in project root — if it exists, load `core.md` and `index.md` there
- `specs/code-rules/` in project root — if it exists, read any `.md` files there as project-specific overrides

### 2. Diff the branch

```bash
git diff <base>..<branch> --stat
git diff <base>..<branch>
```

### 3. Review each changed file

Apply rules loaded in step 1 across these areas:
- **Clean code**: naming, function size, magic numbers, hardcoded strings, DRY, single responsibility
- **Style**: indentation, line length, blank lines, guard clauses, condition formatting
- **Security**: input validation, auth checks, hardcoded secrets, injection risks
- **Performance**: N+1 queries, unnecessary loops, memory leaks, heavy ops in hot paths
- **Correctness / logic bugs**: off-by-one, inverted conditions, unhandled null/undefined, wrong operator, silently swallowed exceptions (`catch {}` rỗng)
- **Concurrency / race conditions**: shared mutable state không lock, async/await read-modify-write không atomic, thread-safety của singleton/cache, deadlock tiềm ẩn, transaction isolation level sai
- **Error handling & edge cases**: lỗi không được log/propagate, resource (file handle, DB connection, listener) không được đóng khi exception xảy ra giữa chừng, edge case như empty list/zero/negative number chưa xử lý
- **Cleanup / hygiene**: code/import/biến không dùng còn sót lại, code bị comment-out, debug statement quên xoá (`console.log`, `print`, `debugger`), TODO/FIXME không có ticket, file/diff không liên quan lẫn vào commit
- **Test coverage**: logic mới không có test đi kèm, test bị sửa để pass giả (skip/disable thay vì fix)
- **Breaking changes / migration safety**: API contract thay đổi ảnh hưởng caller khác, migration không reversible, thiếu default cho cột `NOT NULL` mới, lock table lớn khi migrate

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
