---
name: short-commit
allowed-tools: Bash(git:*), Bash(git commit:*)
description: Show a single short oneline commit message for staged/changed files; only commit after user approves (unless auto=true)
---

Read staged changes → Format a short oneline commit message → Show it to the user → Only commit after user approves

**Params (via ARGUMENTS, e.g. `footer=true auto=true`):**
- `footer` (default `false`): if `true`, append a blank line + the `Co-Authored-By:` trailer for the current model to the commit message
- `auto` (default `false`): if `true`, skip the approval step and commit immediately

**Format:**
```
type: subject (<70 chars, imperative)
```

With `footer=true`:
```
type: subject (<70 chars, imperative)

Co-Authored-By: <current model> <noreply@anthropic.com>
```

**Types:** feat | fix | refactor | docs | test | chore | perf | style

**Steps:**
1. `git status` + `git diff --staged`
2. Format one line following the template, summarizing all changes (add the footer if `footer=true`)
3. If `auto=true` → go to step 4. Otherwise show the message to the user, ask for approval
4. Commit: `git commit -m "type: subject"` (with `footer=true`, use a heredoc so the trailer is on its own line)
5. `git log -1` to verify

**Rules:**
- Single line only, no body, no bullets; no Co-Authored-By unless `footer=true`
- Subject < 70 chars, imperative mood
- If there are multiple unrelated changes, summarize the most important one
- **NEVER commit automatically — always wait for user approval of the message first**, unless `auto=true`
