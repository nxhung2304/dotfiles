---
name: implement-prepare
allowed-tools: Read, Bash(git checkout:*), Bash(git pull:*), Bash(git branch:*), Bash(mkdir *), mcp__slack__*
description: Prepare before coding — pull, create branch, check approved, notify Slack.
---

Steps:

1. Checkout
- `git checkout develop`
    - fallback to `main`
- `git pull origin develop`
    - fallback to `main`

2. Parse issue info from spec
- ARGUMENTS format: [spec-filename]
- Read spec file from `specs/issues/[spec-filename].md`
- Extract: issue number from the "GitHub Issue: #XX" line (NOT from the filename prefix!)
- Extract: title from the "Title:" field
- Check: "Review: Approved" — if not approved, stop and notify
- IMPORTANT: Use the GitHub Issue number (e.g., #26 → 26), NOT the spec filename prefix (000)

3. Create the branch
- Derive username: run `git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`
- `feature/[username]-#[ACTUAL-GITHUB-ISSUE-NUMBER]-[slug-title-from-metadata]`
- The slug must be in English

4. Notify Slack that work is starting (optional — only if `slack-channel-id` is present in CLAUDE.md)
- If absent → skip, `thread_ts = null`
- If present → use `mcp__slack__slack_post_message`, save `thread_ts`

**IMPORTANT:** Do NOT report a summary to the user — only return the result so the orchestrator can continue to the next step.
Return: { branch_name, issue_number, title, thread_ts }
