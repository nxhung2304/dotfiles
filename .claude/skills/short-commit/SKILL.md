---
name: short-commit
allowed-tools: Bash(git:*), Bash(git commit:*)
description: Show a single short oneline commit message for staged/changed files; only commit after user approves
---

Read staged changes → Format a short oneline commit message → Show it to the user → Only commit after user approves

**Format:**
```
type: subject (<70 chars, imperative)
```

**Types:** feat | fix | refactor | docs | test | chore | perf | style

**Steps:**
1. `git status` + `git diff --staged`
2. Format one line following the template, summarizing all changes
3. Show the message to the user, ask for approval
4. Only after user approves: `git commit -m "type: subject"`
5. `git log -1` to verify

**Rules:**
- Single line only, no body, no bullets, no Co-Authored-By
- Subject < 70 chars, imperative mood
- If there are multiple unrelated changes, summarize the most important one
- **NEVER commit automatically — always wait for user approval of the message first**
