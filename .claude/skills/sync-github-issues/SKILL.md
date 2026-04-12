---
allowed-tools: Read, Edit, Grep, Write, mcp__github__create_issue, mcp__github__list_issues
description: Sync local issue files to GitHub Issues. Use when user asks "sync issues to github" or "push issues to github"
---

## Mục đích
Đọc các file trong `specs/issues/`, tạo GitHub Issues tương ứng, sau đó cập nhật `GitHub Issue` number vào từng file.

---

## Điều kiện tiên quyết
- GitHub MCP — dùng cho tất cả operations (create issue, list issues)

### 1. Kiểm tra MCP auth
1. Call `mcp__github__list_issues` with `per_page: 1`
    - If succeeds → MCP auth is OK
    - If fails → tell user to set `GITHUB_PERSONAL_ACCESS_TOKEN`

---

## Các bước thực hiện

### 1. Tìm các file cần sync

Scan toàn bộ `specs/issues/*.md`, chỉ xử lý file thỏa mãn CẢ HAI điều kiện:
- Có: `Review: approved` (hoặc `Review: Approved`)
- Có: `GitHub Issue: —` (chưa có issue number)

→ Bỏ qua: status pending, draft, hoặc đã có issue number

### 2. Với mỗi file → tạo GitHub Issue

Parse từ file:
- **Title** → `## Metadata > Title`
- **Labels** → `## Metadata > Phase` → parse phase number → label `phase-N`; cộng thêm labels từ `## Metadata > Labels`
- **Body** → toàn bộ nội dung file markdown

Gọi MCP:
```
mcp__github__create_issue(
  owner: "[owner]",
  repo: "[repo]",
  title: "[title]",
  body: "[nội dung file .md]",
  labels: ["phase-N", ...labels from metadata]
)
```

> **Lưu ý labels:** MCP sẽ bỏ qua label chưa tồn tại trên repo. Nếu cần tạo label mới, hướng dẫn user tạo thủ công trên GitHub trước khi sync.

### 3. Lấy issue number từ response

MCP trả về object với field `number`:
```json
{ "number": 42, "html_url": "https://github.com/..." }
```
→ Dùng `response.number` trực tiếp — không cần parse URL.

### 4. Cập nhật file .md

Replace dòng:
```
- GitHub Issue: —
```
Thành:
```
- GitHub Issue: #42
```

Cập nhật ngay sau mỗi file — không đợi hết batch.

### 5. In summary sau khi xong

```
✅ Đã sync [X] issues lên GitHub:

  #42 — Project Setup
  #43 — Login UI
  #44 — Home Shell
  ...

→ Xem tại: https://github.com/[owner]/[repo]/issues
```

---

## Quy tắc quan trọng

- **KHÔNG** sync file đã có GitHub Issue number — tránh tạo duplicate
- **KHÔNG** xóa hoặc đóng GitHub Issue đã tồn tại
- Nếu MCP create_issue lỗi 1 file → log lỗi, tiếp tục xử lý file tiếp theo, không dừng toàn bộ
- Mỗi file tạo xong → cập nhật ngay, không đợi hết batch

---

## Xử lý lỗi

| Lỗi | Xử lý |
|-----|-------|
| MCP auth fail | Dừng, hướng dẫn set `GITHUB_PERSONAL_ACCESS_TOKEN` |
| Label chưa tồn tại | Log cảnh báo, tạo issue không có label đó |
| `create_issue` thất bại | Log lỗi + skip file đó |
| File .md không parse được title | Skip + cảnh báo tên file |
