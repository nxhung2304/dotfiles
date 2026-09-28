---
name: commit
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write, Bash(git commit:*)
description: Create professional git commits with bullet-point message 
---

Read staged changes → format the commit message → create the commit

**Format:**
```
type: subject (<70 chars, imperative)

- What changed (bullet, no markdown)
- Why it matters

```

**Types:** feat | fix | refactor | docs | test | chore | perf | style

**Steps:**
1. `git status` + `git diff --staged`
2. Format the message following the template
3. `git commit -m "$(cat <<'EOF'\n...\nEOF)"`
4. `git log -1` verify

**Rules:**
- Subject < 70 chars, imperative mood
- Bullets use `-`, no markdown
- WHAT & WHY, not HOW
- **ALWAYS commit directly, no confirmation prompt**
