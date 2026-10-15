---
name: md-to-github-issues
allowed-tools: Read, Edit, Grep, Write, Bash(gh auth:*), Bash(gh api:*), Bash(gh repo:*), Bash(gh issue:*), Bash(gh label:*)
description: Sync local issue files to GitHub Issues. Use when user asks "sync issues to github"
---

Read `specs/issues/*.md` → create GitHub Issues → update the issue number back into the file

**Steps:**
1. Select GitHub account: if the project `CLAUDE.md` has `github-account: <user>` and `gh api user -q .login` differs → `gh auth switch --hostname github.com --user <user>`
2. Verify: `gh repo view --json nameWithOwner`
3. Find files to sync (BOTH conditions must match — case-insensitive):
   - Has: `Review:` followed by `Approved` (any casing, any surrounding whitespace)
   - Has a `GitHub Issue:` line without a `#N` number (e.g. `—` or `(to be filled after sync)`)
4. For each file:
   - Parse title, labels (phase-N + metadata labels), body
   - Labels missing in the repo (`gh label list`) → `gh label create <name>` first
   - `gh issue create --title "<title>" --body-file <file> --label <label>...`
   - Issue number = last segment of the URL printed by `gh issue create`
   - Update the file's `GitHub Issue:` line → `GitHub Issue: #N`
   - Update immediately, don't wait for a batch
5. Output a summary with the list of created issues

**Rules:**
- Skip files that already have an issue number
- Skip files that aren't approved
- On error: log + continue, don't stop the whole run

**Error handling:**
| Error | Action |
|-------|--------|
| gh not authenticated | Stop, guide user to run `gh auth login` |
| Account in `github-account` not logged in | Stop, guide user to run `gh auth login` for that account |
| Create issue fail | Log + skip file |
| Parse title fail | Skip + warn filename |
