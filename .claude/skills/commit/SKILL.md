---
name: commit
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write, Bash(git commit:*)
description: Create git commits from staged changes — full bullet-point message or short one-liner, optional approval step, optional push
---

Read staged changes → format the commit message → create the commit → optionally push

**Params (via ARGUMENTS, e.g. `format=short auto=false footer=true`):**
- `format` (default `full`): `full` = subject + WHAT/WHY bullets; `short` = single oneline subject
- `auto` (default `true`): if `true`, commit immediately with no confirmation; if `false`, show the message to the user and only commit after they approve it
- `push` (default `false`): if `true`, run `git push` after the commit and report the push result
- `footer` (default `false`): if `true`, append a blank line + the `Co-Authored-By:` trailer for the current model to the commit message

No args = `format=full auto=true push=false footer=false`.

**Format (`full`):**
```
type: subject (<70 chars, imperative)

- What changed (bullet, no markdown)
- Why it matters

```

**Format (`short`):**
```
type: subject (<70 chars, imperative)
```

With `footer=true`, add after the message:
```

Co-Authored-By: <current model> <noreply@anthropic.com>
```

**Types:** feat | fix | refactor | docs | test | chore | perf | style

**Steps:**
1. `git status` + `git diff --staged`
2. Format the message following the template for `format` (add the footer if `footer=true`)
3. If `auto=false` → show the message to the user and ask for approval before continuing
4. `git commit -m "$(cat <<'EOF'\n...\nEOF)"` (use a heredoc whenever the message is multi-line or has a footer)
5. `git log -1` verify
6. If `push=true` → `git push`, then report the commit hash and push result

**Rules:**
- Subject < 70 chars, imperative mood
- `full`: bullets use `-`, no markdown; WHAT & WHY, not HOW
- `short`: single line only, no body, no bullets; if there are multiple unrelated changes, summarize the most important one
- No Co-Authored-By unless `footer=true`
- **`auto=true`: ALWAYS commit directly, no confirmation prompt. `auto=false`: NEVER commit before the user approves the message.**
