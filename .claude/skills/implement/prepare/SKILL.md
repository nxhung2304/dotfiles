---
description: Chuẩn bị trước khi code: pull, branch, check approved, notify Slack.
---

Các bước:
- git checkout develop && git pull
- Tạo branch: feature/hung-#[number]-[slug]
- Tìm và đọc spec file, kiểm tra Review: approved
- Nếu chưa approved → dừng và thông báo
- Notify Slack bắt đầu (mcp__slack__slack_post_message), lưu thread_ts
- Trả summary: branch name + spec title + status
