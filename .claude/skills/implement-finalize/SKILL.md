---
name: implement-finalize
model: haiku
allowed-tools: Skill, Read, Write, Edit, Bash(git *), Bash(mkdir *), mcp__claude_ai_Slack__*, Bash(cat:*), Bash(gh pr:*), Bash(gh auth:*), Bash(gh api:*)
description: Commit, create the PR, mark the spec and story as merged, notify Slack.
---

1. Commit (only add files that actually changed)
    - Run inside the worktree entered by the orchestrator. Never stage a `specs` symlink (check with `git ls-files -s specs` / `git status`); only real files
    - Use the commit skill with ARGUMENTS `format=short footer=true auto=true`

2. Push the branch
    - `git push -u origin <branch-name>`

3. Create a Draft PR with the `gh` CLI
    - Select GitHub account first: if the project `CLAUDE.md` has `github-account: <user>` and `gh api user -q .login` differs → `gh auth switch --hostname github.com --user <user>`
    - `gh pr create --draft --base <base-branch> --head <branch-name> --title "<title>" --body "<body>"` — base is `base_branch` returned by prepare
    - `pr_url` = the URL printed by `gh pr create`
    - Title: [title]
    - Body: invoke the `pr-desc` skill (after push, before `gh pr create`) and use its printed content, then append:
```

## Issue
closes #XX
```

4. Record the work as merged (right after `pr_url` exists)
    - In the spec file `## **Status:**`, set `- PR: Merged ([#<pr_number>](<pr_url>))`; set `- Plan: Done` if it is not already
    - In `specs/story.md`, tick the task line that references this issue (`- [ ] ... (#<issue_number>...)` → `- [x]`); skip if no line matches
    - If these files are tracked real files in this worktree: commit them (`docs(spec): mark #<issue_number> as merged`) and push to the same branch so the PR carries them; never stage a `specs` symlink
    - If the PR is later closed without merging, revert these two edits

5. Notify Slack that the work is done (optional — only if `thread_ts` was provided by the prepare step)
- If `thread_ts` is null → skip
- Otherwise → use `mcp__claude_ai_Slack__slack_send_message` with `thread_ts` (load it via ToolSearch first if deferred) to reply in that thread

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can report the FINAL SUMMARY.
Return: { pr_url, files_committed }
