---
allowed-tools: Grep, Bash(touch:*), Bash(mkdir -p *), Bash(mkdir *), Read, Edit, Write
description: Create issues from specs/story.md file. Use when use ask "Generate issues, generate issue [number].[title]"
---

## Mục đích
Đọc file `specs/story.md`, tạo ra file story riêng cho từng task trong thư mục `specs/issues/`.
Mỗi story là roadmap chi tiết của 1 task — dev review và đổi status thành `approved` trước khi implement.

---

## Các bước thực hiện

### 1. Đọc source file
```
Đọc: specs/story.md
```
- Parse từng task theo format: `- [ ] [number]. [title]`
- Xác định number, title, labels cho mỗi task

### 2. Chuẩn bị thư mục
```bash
mkdir -p specs/issues
```

### 3. Với mỗi task → tạo file story

**Tên file:** `specs/issues/[number]-[slug-title].md`

Ví dụ:
```
001-project-setup-clone-template.md
002-ui-login-screen.md
```

**Slug rule:** translate title to English first, then lowercase, replace space → `-`, remove special characters

### 4. Nội dung mỗi file — theo template.md

**Important:** Nếu task liên quan đến UI/form screens, kiểm tra `specs/rules/widgets.md`:
- Xem "Screen-to-Widget Mapping" để biết widget nào cần tạo/dùng
- Ghi chú trong spec file dòng "Implementation Checklist" các widget cần thiết

### 5. Sau khi tạo xong tất cả

In ra summary:
```
✅ Đã tạo [X] issues tại specs/issues/
...

→ Review từng file, đổi status: pending → approved để bắt đầu implement
```

---

## Wireframe mapping

> Có 2 file HTML trong `specs/designs/`:
> - `primary-screens.html` — 5 màn hình chính (Login, Home, Timesheet list, Leave list, OT list, Payroll)
> - `forms.html` — các form tạo mới (Timesheet entry, Leave Request form, OT Request form)

| Task keyword | File | Màn hình |
|---|---|---|
| login | `primary-screens.html` | 01 — Login |
| home, avatar, bottom nav | `primary-screens.html` | 02 — Home |
| timesheet list, calendar | `primary-screens.html` | 03 — Timesheet |
| timesheet form, nhập giờ | `forms.html` | 03a — Nhập Timesheet |
| leave list, danh sách nghỉ | `primary-screens.html` | 04 — Xin Nghỉ |
| leave form, tạo đơn nghỉ | `forms.html` | 04a — Tạo Leave Request |
| OT list, danh sách OT | `primary-screens.html` | 05 — OT Request |
| OT form, tạo OT | `forms.html` | 05a — Tạo OT Request |
| payroll, bảng lương | `primary-screens.html` | 06 — Bảng Lương |
| setup, navigation, theme | không có wireframe | — |

---

## Quy tắc quan trọng

- **KHÔNG** tự implement — chỉ tạo file story
- Status luôn là `pending` — dev tự đổi thành `approved`
- Mỗi task = 1 file riêng, không gộp
- Nếu file đã tồn tại → skip, không overwrite
