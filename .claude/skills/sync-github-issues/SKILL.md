---
allowed-tools: Read, Edit, Grep, Write, mcp__github__create_issue, mcp__github__list_issues
description: Sync local issue files to GitHub Issues. Use when user asks "sync issues to github"
---

Đọc `specs/issues/*.md` → Tạo GitHub Issues → Update issue number vào file

**Steps:**
1. Verify MCP: `mcp__github__list_issues(per_page: 1)`
2. Find files to sync (CẢ HAI điều kiện):
   - Has: `Review: approved`
   - Has: `GitHub Issue: —` (no number yet)
3. For each file:
   - Parse title, labels (phase-N + metadata labels), body
   - Call `mcp__github__create_issue(owner, repo, title, body, labels)`
   - Get `response.number`
   - Update file: `- GitHub Issue: —` → `- GitHub Issue: #N`
   - Update ngay, không đợi batch
4. Output summary với list created issues

**Rules:**
- Skip files đã có issue number
- Skip files không approved
- On error: log + continue, không dừng toàn bộ
- Labels chưa tồn tại → MCP sẽ bỏ qua

**Error handling:**
| Error | Action |
|-------|--------|
| MCP auth fail | Stop, guide user set token |
| Create issue fail | Log + skip file |
| Parse title fail | Skip + warn filename |
