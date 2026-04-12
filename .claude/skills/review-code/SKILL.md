---
allowed-tools: Read, Grep, Glob, Write, Bash(ls:*), Bash(git:*)
description: Review code against project rules. Use when user asks "review code, review-code issue #11"
---

Đọc code từ branch/files → So sánh với rules → Ghi feedback vào `specs/comments/[ISSUE-NUMBER]-code-review.md`

**TOKEN STRATEGY:** Gọi **rule-lookup** subagent để load ONLY relevant rules. KHÔNG glob/read toàn bộ code-rules/.

**Steps:**
1. Extract issue number, find branch, read spec for context
2. Gọi rule-lookup subagent:
   ```
   Task: Review issue #[N], Language: [lang], Scope: [scope]
   Return: Relevant rules from core.md, code-rules/, specs/rules/
   Format: Short bullets
   ```
3. Scan code: `git diff develop...feature/...`
4. Review theo checklist từ rule-lookup
5. Create review file:
   ```markdown
   # Code Review: Issue #[N]

   ## Context
   - Branch: [...]
   - Files: [...]

   ## Passed
   - [list]

   ## Issues
   - file.dart:line X: [desc] → [fix]

   ## Rules Applied
   - Core: [summary]
   - Clean-code: [from rule-lookup]
   ```

**Token Efficiency:**
- [ ] Dùng rule-lookup cho targeted rules
- [ ] Chỉ read files cần review
- [ ] Output ngắn gọn, actionable
