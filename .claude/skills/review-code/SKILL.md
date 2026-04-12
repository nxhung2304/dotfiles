---
allowed-tools: Read, Grep, Glob, Write, mcp__ide__getDiagnostics, Bash(ls:*), Bash(git:*)
description: Review code against project rules and standards. Use when user asks "review code, review-code issue #11, code review..."
---

## Mục đích
Đọc code từ branch hoặc files, so sánh với project rules, ghi feedback vào `specs/comments/[ISSUE-NUMBER]-code-review.md`.

**TOKEN SAVING STRATEGY:** Dùng `rule-lookup` subagent để load ONLY relevant rules, không glob/read toàn bộ rules/.

---

## Điều kiện tiên quyết

1. Code phải được implement (branch hoặc files)
2. Rules files phải tồn tại trong `~/.claude/code-rules/` hoặc `specs/rules/`

---

## Các bước thực hiện

### 1. Xác định issue number & context
User gọi: `review-code 11` → extract number `11`

Thu thập context:
- Issue number: `11`
- Tìm branch: `feature/hung-11-calendar-widget` (hoặc pattern tương tự)
- Đọc spec file: `specs/story/11-[title].md` để hiểu requirements
- Xác định ngôn ngữ (hiện tại: Flutter/Dart)

### 2. Tra cứu rules thông minh (TOKEN EFFICIENT)

**QUAN TRỌNG:** KHÔNG glob/read toàn bộ `code-rules/` hoặc `specs/rules/`.

Gọi **rule-lookup** subagent với prompt:
```
Task: Review code cho issue #[ISSUE_NUMBER]
Language: Flutter/Dart
Context: [tóm tắt spec - 2-3 câu]
Scope: [files will be changed - eg: calendar widget, date picker]

Return: Relevant rules ONLY from:
- ~/.claude/code-rules/core.md (always)
- ~/.claude/code-rules/general/ (clean-code, code-style)
- specs/rules/ (flutter-specific rules)

Format: Short bullet points, không copy entire file content.
```

Sau khi rule-lookup return, sử dụng output đó làm checklist cho review.

### 3. Scan code files

Dùng git diff hoặc chỉ định files:
```bash
git diff develop...feature/hung-#[number]-[slug]
# hoặc files từ main agent
```

### 4. Review theo checklist từ rule-lookup

Với mỗi file:
- ✅ Check core rules (const, no over-engineer, TODO usage)
- ✅ Check clean-code items từ rule-lookup output
- ✅ Check Flutter best practices từ rule-lookup output
- ⚠️ Note violations với specific line numbers

### 5. Ghi feedback

Tạo `specs/comments/[ISSUE-NUMBER]-code-review.md`:
```markdown
# Code Review: Issue #[NUMBER]

## Context
- Branch: `feature/...`
- Files changed: [list]
- Scope: [tóm tắt]

## Review Results

### ✅ Passed
- [list what's good]

### ⚠️ Issues Found
- **file.dart:line X**: [description] → [suggested fix]
- **file.dart:line Y**: [description] → [suggested fix]

### 📝 Recommendations
- [optional improvements]

## Rules Applied
- Core: [summary]
- Clean-code: [summary from rule-lookup]
- Flutter: [summary from rule-lookup]
```

---

## Token Efficiency Checklist
- [ ] KHÔNG glob toàn bộ code-rules/
- [ ] KHÔNG read toàn bộ specs/rules/
- [ ] Dùng rule-lookup cho targeted rules
- [ ] Chỉ read files cần review
- [ ] Output ngắn gọn, hành động
