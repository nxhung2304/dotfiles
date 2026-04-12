---
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, Bash
description: Thực hiện Implementation Checklist.
---

- Đọc spec → tuần tự làm từng item trong Checklist
- Trước khi code: gọi **rule-lookup** subagent với từ khóa item
- Nếu UI/color: gọi **design-checker** subagent
- Sau mỗi item lớn: gọi **code-reviewer** subagent để verify
- Không over-engineer, không code ngoài spec
- Trả summary: files changed + checklist items hoàn thành
