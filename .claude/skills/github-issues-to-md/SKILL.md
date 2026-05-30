---
name: github-issues-to-md
allowed-tools: Read, Write, mcp__github__get_issue
description: Fetch a GitHub Issue and save it to local specs/issues/[issue-number].md. Use when user ask: "convert github issues to md, get github issue to md,..."
---

Lấy GitHub Issue → Convert sang Markdown → Lưu local file

**Input:**
- issue_number (required)
- owner (required)
- repo (required)

**Steps:**
1. Verify MCP:
   - Call `mcp__github__get_issue(owner, repo, issue_number)`
2. Parse response:
   - title
   - body
   - labels (array → list string)
   - assignees (optional)
   - state
3. Convert to Markdown format:
[ISSUE-#{number}] {title}
GitHub Issue: #{number}
State: {state}
Labels: label1, label2, ...
Assignees: user1, user2
Source: GitHub

{body}

4. Save file:
   - Path: `specs/issues/#{number}.md`
   - If file already exists: read it and check for local edits (any section beyond the base metadata/body)
     - If local edits detected → warn user and ask: "File already exists with local changes. Overwrite? (yes/no)"
     - If no local edits → overwrite silently
     - If user says no → skip and log

5. Output summary:
   - Saved: specs/issues/#{number}.md

**Rules:**
- Nếu issue không tồn tại → báo lỗi + stop
- Labels null → để trống
- Body null → để empty string
- Không tạo thêm metadata ngoài format trên

**Error handling:**
| Error | Action |
|-------|--------|
| MCP auth fail | Stop, guide user set token |
| Issue not found | Stop + log issue_number |
| Write file fail | Log error |
