---
name: commit-push
allowed-tools: Bash(git:*), Skill
description: Commit staged changes and push to remote
---

Execute these steps immediately without asking for confirmation:

1. Use the `/commit` skill to commit staged changes
2. Run `git push` to push to the remote branch
3. Report the commit hash and push result to the user
