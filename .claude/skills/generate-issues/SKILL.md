---
allowed-tools: Grep, Bash(touch:*), Bash(mkdir -p *), Read, Edit, Write
description: Create issues from specs/story.md. Use when user asks "Generate issues, generate issue [number].[title]"
---

Đọc `specs/story.md` → Parse tasks → Tạo file story riêng vào `specs/issues/`

**Steps:**
1. Đọc specs/story.md, parse tasks: `- [ ] [number]. [title]`
2. `mkdir -p specs/issues`
3. Với mỗi task → tạo file `specs/issues/[number]-[slug-title].md`
   - Slug: English, lowercase, spaces→ `-`
   - Skip nếu file đã tồn tại
4. Nội dung theo template.md
5. Nếu UI/form task → kiểm tra specs/rules/widgets.md "Screen-to-Widget Mapping"
6. Output summary với count + next steps

**Wireframe mapping:**
| Keyword | File | Screen |
|---------|------|--------|
| login | primary-screens.html | 01 |
| home | primary-screens.html | 02 |
| timesheet list | primary-screens.html | 03 |
| timesheet form | forms.html | 03a |
| leave list | primary-screens.html | 04 |
| leave form | forms.html | 04a |
| OT list | primary-screens.html | 05 |
| OT form | forms.html | 05a |
| payroll | primary-screens.html | 06 |

**Rules:** Status luôn `pending`, dev tự đổi thành `approved`
