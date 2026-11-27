---
name: implement-prepare
model: haiku
allowed-tools: Read, Bash(git fetch:*), Bash(git worktree:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(git config:*), Bash(ln:*), Bash(test:*), Bash(mkdir *), mcp__claude_ai_Slack__*
description: Prepare before coding — read the spec, create the branch in its own worktree, check approved, notify Slack.
---

Steps:

1. Parse issue info from spec (run in the original repo, before creating the worktree)
- ARGUMENTS format: [spec-filename]
- Read spec file from `specs/issues/[spec-filename].md`
- Extract: issue number from the "GitHub Issue: #XX" line (NOT from the filename prefix!)
- Extract: title from the "Title:" field
- Check: "Review: Approved" — if not approved, stop and notify
- IMPORTANT: Use the GitHub Issue number (e.g., #26 → 26), NOT the spec filename prefix (000)

2. Pick the base branch
- `git fetch origin`
- base = `develop` if `git rev-parse --verify -q origin/develop` succeeds, else `main`

3. Create the branch in its own worktree (never touch the current working tree)
- Derive username: run `git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`
- branch_name = `feature/[username]-#[ACTUAL-GITHUB-ISSUE-NUMBER]-[slug-title-from-metadata]`
- The slug must be in English
- repo_root = `git rev-parse --show-toplevel`
- worktree_path = `<parent of repo_root>/<repo folder name>.<branch_name with "/" and "#" replaced by "-">`
- `git worktree add -b <branch_name> <worktree_path> origin/<base>`
- If the branch or the path already exists, stop and report it. Never reuse or overwrite it

3b. Link the spec files into the worktree (specs may be untracked, so the worktree can lack them)
- If `<worktree_path>/specs` does not exist → `ln -s <repo_root>/specs <worktree_path>/specs`
- Else if `<worktree_path>/specs/issues/[spec-filename].md` does not exist → `ln -s <repo_root>/specs/issues/[spec-filename].md` to the same path in the worktree (create the folder first with `mkdir -p`)
- Skip when the spec is already in the worktree

4. Notify Slack that work is starting (optional — only if `slack-channel-id` is present in CLAUDE.md)
- If absent → skip, `thread_ts = null`
- If present → use `mcp__claude_ai_Slack__slack_send_message` (load it via ToolSearch first if deferred), save the returned message `ts` as `thread_ts`

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can continue to the next step.
Return: { branch_name, worktree_path, base_branch, issue_number, title, thread_ts }
