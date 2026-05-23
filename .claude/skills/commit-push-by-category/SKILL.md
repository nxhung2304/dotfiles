---
name: commit-push-by-category
allowed-tools: Bash(git:*), Skill
description: Group unstaged changes by category, commit each group via /commit, then push via /commit-push
---

Group all changed files by logical category → run /commit per category → push via /commit-push.

**Steps:**

1. Run `git status` + `git diff` to see all changed/untracked files
2. Infer categories dynamically from file paths:
   - **Top-level directory** → use dir name as scope (e.g. `src/auth/` → `auth`)
   - **File type / concern** → e.g. all `*.md` → `docs`, all `*_test.*` → `test`
   - **Root config files** → group by tool name (e.g. `.zshrc` → `zsh`, `Brewfile` → `brew`)
   - **Catch-all** → files that don't fit any group → `misc`
3. For each non-empty category:
   - `git add <files in this category>`
   - Use /commit skill to create the commit (with scope set to the category name)
4. After all categories are committed, use /commit-push skill to push
5. Report all commit hashes and push result
