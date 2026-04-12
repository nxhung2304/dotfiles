---
allowed-tools: Read, Grep, Glob, Write, mcp__ide__getDiagnostics, Bash(ls:*), Bash(git:*)
description: Review code against project rules and standards. Use when user asks "review code, review-code issue #11, code review..."
---

## Mục đích
Đọc code từ branch hoặc files, so sánh với `specs/rules/`, ghi feedback vào `specs/comments/[ISSUE-NUMBER]-code-review.md`.

---

## Điều kiện tiên quyết

1. Code phải được implement (branch hoặc files)
2. Rules files phải cập nhật trong `specs/rules/`

---

## Các bước thực hiện

### 1. Xác định issue number & code source
User gọi: `review-code 11` → extract number `11`

Tìm branch hoặc files:
- Branch: `feature/hung-11-calendar-widget`
- Hoặc specific files user cung cấp

### 2. Đọc tất cả rules (BẮTBUỘC — đọc hết, không bỏ sót)

**Bước 2.1** — List toàn bộ files trong cả 2 thư mục:
```bash
ls ~/.claude/code-rules/
ls specs/rules/
```

**Bước 2.2** — Đọc TỪNG FILE một, không được skip:

Global (`~/.claude/code-rules/`):
- [ ] `clean-code.md`
- [ ] `code-style.md`
- [ ] `coding-rules.md`

Local (`specs/rules/`) — đọc output của `ls specs/rules/` rồi đọc từng file:
- [ ] `folder-structure.md`
- [ ] `flutter.md`
- [ ] `widgets.md`
- [ ] `coding.md`
- [ ] `design.md`
- [ ] `refactoring.md`
- [ ] Bất kỳ file nào khác có trong `ls specs/rules/` mà chưa có trong danh sách trên

**STRICT RULE:** Nếu `ls specs/rules/` trả về file nào chưa được đọc → phải đọc trước khi tiếp tục. Không được giả định đã biết nội dung.

Sau khi đọc xong, tạo checklist nội bộ từ mỗi file để dùng khi scan code ở các bước sau.

Tạo specs/comments/[ISSUE-NUMBER]-code-review.md
