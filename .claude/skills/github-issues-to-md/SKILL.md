---
name: github-issues-to-md
model: haiku
allowed-tools: Read, Write, Skill, Bash(gh auth:*), Bash(gh api:*), Bash(gh issue view:*), Bash(mkdir:*), Bash(ls:*), Bash(grep:*)
description: Fetch a GitHub Issue and save it to local specs/issues/[issue-number]-[slug]/issue.md via the issue-docs skill (other doc files are added later, when their stage needs them). Use when user ask: "convert github issues to md, get github issue to md, sync issue to local,..."
---

Fetch a GitHub Issue → hand it to `issue-docs` to save as `issue.md`

**Input:**
- issue_number (required)
- owner (required)
- repo (required)

**Steps:**
1. Select GitHub account: if the project `CLAUDE.md` has `github-account: <user>` and `gh api user -q .login` differs → `gh auth switch --hostname github.com --user <user>`
   - Fetch: `gh issue view <issue_number> --repo <owner>/<repo> --json number,title,body,labels,assignees,state`
2. Parse response: title, body, labels (array → list string), assignees (optional), state
3. Build the `issue.md` content:
```
[ISSUE-#{number}] {title}
GitHub Issue: #{number}
State: {state}
Labels: label1, label2, ...
Assignees: user1, user2
Source: GitHub

{body}
```
4. Invoke the `issue-docs` skill with the issue number, the English slug from the title (lowercase, spaces → `-`), and the content from step 3 as the original request. It decides the folder, creates or updates `issue.md`, and creates only the other files the current stage needs (at fetch time, normally none). Do not create investigate.md, implement.md, testcases.md or report.md here.
   - If `issue.md` already exists: before handing over, read it and check for local edits (any section beyond the base metadata/body/Related)
     - Local edits detected → warn user and ask: "issue.md already exists with local changes. Overwrite? (yes/no)"
     - No local edits → refresh it from GitHub silently
     - User says no → skip and log
5. Output summary: the `issue-docs` result (folder path, one line per file)

**Rules:**
- If the issue doesn't exist → report an error + stop
- Labels null → leave blank
- Body null → leave as an empty string
- Do not add metadata beyond the format above
- Folder layout, file roles and `## Related` links belong to `issue-docs`; don't restate them here

**Error handling:**
| Error | Action |
|-------|--------|
| gh auth fail | Stop, guide user to run `gh auth login` |
| Issue not found | Stop + log issue_number |
| Write file fail | Log error |
