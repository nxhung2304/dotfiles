---
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write
description: Create professional git commits with bullet-point messages and Co-Authored-By footer
---

Đọc staged changes → Format commit message → Show user approval → Create commit

**Format:**
```
type: subject (<70 chars, imperative)

- What changed (bullet, no markdown)
- Why it matters

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

**Types:** feat | fix | refactor | docs | test | chore | perf | style

**Steps:**
1. `git status` + `git diff --staged`
2. Format message theo template
3. Ask: "Ready to commit? (y/n)"
4. `git commit -m "$(cat <<'EOF'\n...\nEOF)"`
5. `git log -1` verify

**Rules:**
- Subject < 70 chars, imperative mood
- Bullets use `-`, no markdown
- WHAT & WHY, not HOW
- Always include Co-Authored-By footer
