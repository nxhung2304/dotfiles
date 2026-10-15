---
name: implement-finalize
allowed-tools: Skill, Read, Write, Edit, Bash(git *), Bash(mkdir *), mcp__claude_ai_Slack__*, Bash(cat:*), Bash(gh pr:*), Bash(gh auth:*), Bash(gh api:*)
description: Commit, create the PR, update status, notify Slack.
---

1. Commit (only add files that actually changed)
    - Use the short-commit skill with ARGUMENTS `footer=true auto=true`

2. Update the status in the spec file to "PR: Draft"
Change the status line:
```
## **Status:**
- PR: Todo
```
To:
```
## **Status:**
- PR: Draft
```

3. Push the branch
    - `git push -u origin <branch-name>`

4. Create a Draft PR with the `gh` CLI
    - Select GitHub account first: if the project `CLAUDE.md` has `github-account: <user>` and `gh api user -q .login` differs → `gh auth switch --hostname github.com --user <user>`
    - `gh pr create --draft --base <base-branch> --head <branch-name> --title "<title>" --body "<body>"` — base is the branch prepare checked out from (`develop`, fallback `main`)
    - `pr_url` = the URL printed by `gh pr create`
    - Title: [title]
    - Body: invoke the `pr-desc` skill (after push, before `gh pr create`) and use its printed content, then append:
```

## Issue
closes #XX
```

5. Notify Slack that the work is done (optional — only if `thread_ts` was provided by the prepare step)
- If `thread_ts` is null → skip
- Otherwise → use `mcp__claude_ai_Slack__slack_send_message` with `thread_ts` (load it via ToolSearch first if deferred) to reply in that thread

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can report the FINAL SUMMARY.
Return: { pr_url, files_committed }
