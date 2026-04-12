---
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write
description: Create professional git commits with scannable bullet-point messages and Co-Authored-By footer
---

## Mục đích

Tạo commit message chuyên nghiệp với:
- Subject line rõ ràng (< 70 ký tự)
- Body dùng bullet points (scannable, không markdown)
- Mô tả WHAT & WHY (không HOW)
- Tự động thêm Co-Authored-By footer

---

## Điều kiện tiên quyết

1. Có staged changes hoặc unstaged changes sẵn sàng
2. Đang trong git repository
3. Biết loại commit (feat, fix, refactor, docs, test, chore, perf, style)

---

## Các bước thực hiện

### 1. Đọc staged changes
```bash
git status
git diff --staged
```

### 2. Format commit message

**Cấu trúc:**
```
type: subject (max 70 chars, imperative mood)

- What changed (bullet point, no markdown)
- Why it matters (business/code quality)
- Additional context if needed

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

**Commit types:**
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code restructuring
- `docs:` Documentation
- `test:` Tests
- `chore:` Build, deps, config
- `perf:` Performance
- `style:` Formatting

### 3. Show user message for approval

Format trước khi commit, hỏi user: "Ready to commit? (y/n)"

### 4. Create commit

```bash
git commit -m "$(cat <<'EOF'
type: subject

- Bullet 1
- Bullet 2

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
EOF
)"
```

### 5. Verify

```bash
git log -1
```

---

## Quy tắc Message

✅ **GOOD:**
```
refactor: make AppCalendar legend extensible and remove progress bar

- Legend now accepts optional custom items via List<CalendarLegendItem>
- Remove progress bar widget and submittedDays/totalWorkDays parameters
- Replace magic numbers with design system constants

Co-Authored-By: Model-AI
```

❌ **BAD:**
```
refactor: make AppCalendar legend extensible and remove progress bar
1. **Legend Extensibility**: CalendarLegend now accepts...
2. **Remove Progress Bar**: Removed CalendarProgress widget...
```

---

## Checklist

- [ ] Subject < 70 characters
- [ ] Imperative mood (add, not added)
- [ ] Bullets use `-` not numbers
- [ ] No markdown formatting (no **bold**, _italic_)
- [ ] Explains WHAT & WHY not HOW
- [ ] Co-Authored-By footer included
- [ ] `git log -1` verified

---

## Lỗi & Xử lý

| Lỗi | Giải pháp |
|-----|-----------|
| Subject quá dài | Giảm xuống < 70 ký tự, move chi tiết vào body |
| Dùng markdown trong body | Loại bỏ **bold**, _italic_, `code` |
| Forget Co-Authored-By | Always append footer with blank line trước |
| Commit mà chưa stage files | Hỏi user staging, hoặc `git add` trước |
