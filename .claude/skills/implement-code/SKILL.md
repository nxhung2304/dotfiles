---
name: implement-code
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, Bash
description: Thực hiện Implementation Checklist.
---

- Đọc spec → extract tất cả keywords từ Checklist
- **Gọi rule-lookup MỘT LẦN** ở đầu với toàn bộ keywords — cache kết quả, dùng cho toàn bộ session (không gọi lại cho từng item)
- Tuần tự làm từng item trong Checklist theo thứ tự
- Nếu UI/color: gọi **design-checker** subagent
- Sau mỗi item lớn: gọi **code-reviewer** subagent để verify
- Không over-engineer, không code ngoài spec

**IMPORTANT:** KHÔNG report summary cho user - chỉ return kết quả để orchestrator tiếp tục step tiếp theo.
Return: { files_changed, checklist_items_completed }
