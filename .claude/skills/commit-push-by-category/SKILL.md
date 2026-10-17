---
name: commit-push-by-category
allowed-tools: Bash(git:*), Skill
description: Group unstaged changes by category, commit each group via /commit, pushing with the last commit
disable-model-invocation: true
---

Group all changed files by logical category → run /commit per category → push with the last /commit (`push=true`).

**Steps:**

1. Run `git status` + `git diff` to see all changed/untracked files
2. Infer categories dynamically from file paths:
   - **Top-level directory** → use dir name as scope (e.g. `src/auth/` → `auth`)
   - **File type / concern** → e.g. all `*.md` → `docs`, all `*_test.*` / `*_spec.*` / `*.test.*` → `test`
   - **Root config files** → group by tool name (e.g. `.zshrc` → `zsh`, `Brewfile` → `brew`)
   - **Catch-all** → files that don't fit any group → `misc`
   - **Feature + test files together**: if a feature file and its test file are clearly paired (same name, same directory scope), keep them in the same commit — do not split into separate `feature` and `test` commits
3. For each non-empty category:
   - `git add <files in this category>`
   - Use /commit skill to create the commit (with scope set to the category name); pass `push=true` only for the last category
4. Report all commit hashes and push result
