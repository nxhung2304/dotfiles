---
name: implement-finalize
allowed-tools: Skill, Read, Write, Edit, Bash(git *), Bash(mkdir *), mcp__github__*, mcp__slack__*, Bash(cat:*), Bash(gh pr:*)
description: Commit, create the PR, update status, notify Slack.
---

1. Commit (only add files that actually changed)
    - Use the commit skill

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

4. Create a Draft PR with the GitHub MCP
    - Title: [title]
    - Body:
```
[Short, easy-to-understand summary of what was implemented, in English]

## Issue
closes #XX
```

5. Notify Slack that the work is done (optional — only if `thread_ts` was provided by the prepare step)
- If `thread_ts` is null → skip
- Otherwise → use `mcp__slack__slack_reply_to_thread` to reply in that thread

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can report the FINAL SUMMARY.
Return: { pr_url, files_committed }
