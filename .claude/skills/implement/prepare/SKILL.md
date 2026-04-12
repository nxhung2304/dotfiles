---
allowed-tools: Read, Bash(git checkout:*), Bash(git pull:*), Bash(git branch:*), Bash(mkdir *), mcp__slack__*
description: Chuẩn bị trước khi code: pull, branch, check approved, notify Slack.
---

Các bước:

1. Checkout
- git checkout develop
    - fallback to main
- git pull origin develop
    - fallback to main

2. Tạo branch
- feature/hung-#[number]-[slug-title-of-issue]
- slug phải là tiếng anh



- Tìm và đọc spec file, kiểm tra Review: approved
- Nếu chưa approved → dừng và thông báo


- Notify Slack bắt đầu (mcp__slack__slack_post_message), lưu thread_ts
```
Use mcp__slack__slack_post_message:

channel: [slack-channel-id from CLAUDE.md]
text: "🚀 Bắt đầu implement Issue #[N]: [title]\nBranch: feature/hung-#[N]-[slug]"
Save the returned ts value for threading later If MCP fails → fallback to slack CLI
```

- Trả summary: branch name + spec title + status
