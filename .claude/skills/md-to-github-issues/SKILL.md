---
name: md-to-github-issues
allowed-tools: Read, Edit, Grep, Write, mcp__github__create_issue, mcp__github__list_issues
description: Sync local issue files to GitHub Issues. Use when user asks "sync issues to github"
---

Read `specs/issues/*.md` → create GitHub Issues → update the issue number back into the file

**Steps:**
1. Verify MCP: `mcp__github__list_issues(per_page: 1)`
2. Find files to sync (BOTH conditions must match — case-insensitive):
   - Has: `Review:` followed by `Approved` (any casing, any surrounding whitespace)
   - Has: `GitHub Issue: —` (no number yet)
3. For each file:
   - Parse title, labels (phase-N + metadata labels), body
   - Call `mcp__github__create_issue(owner, repo, title, body, labels)`
   - Get `response.number`
   - Update file: `- GitHub Issue: —` → `- GitHub Issue: #N`
   - Update immediately, don't wait for a batch
4. Output a summary with the list of created issues

**Rules:**
- Skip files that already have an issue number
- Skip files that aren't approved
- On error: log + continue, don't stop the whole run
- Labels that don't exist yet → the MCP will skip them

**Error handling:**
| Error | Action |
|-------|--------|
| MCP auth fail | Stop, guide user set token |
| Create issue fail | Log + skip file |
| Parse title fail | Skip + warn filename |
