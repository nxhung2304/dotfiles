---
name: implement-prepare
allowed-tools: Read, Bash(git checkout:*), Bash(git pull:*), Bash(git branch:*), Bash(mkdir *), mcp__slack__*
description: Chuẩn bị trước khi code: pull, branch, check approved, notify Slack.
---

Các bước:

1. Checkout
- git checkout develop
    - fallback to main
- git pull origin develop
    - fallback to main

2. Parse issue info from spec
- ARGUMENTS format: [spec-filename]
- Read spec file from specs/issues/[spec-filename].md
- Extract: issue number from "GitHub Issue: #XX" line (NOT from filename prefix!)
- Extract: title from "Title:" field
- Check: "Review: Approved" - if not approved, stop and notify
- IMPORTANT: Use GitHub Issue number (e.g., #26 → 26), NOT spec filename prefix (000)

3. Tạo branch
- Derive username: run `git config user.name | tr '[:upper:]' '[:lower:]' | tr ' ' '-'`
- feature/[username]-#[ACTUAL-GITHUB-ISSUE-NUMBER]-[slug-title-from-metadata]
- slug phải là tiếng anh

4. Notify Slack bắt đầu (tuỳ chọn — chỉ thực hiện nếu `slack-channel-id` có trong CLAUDE.md)
- Nếu không có → bỏ qua, thread_ts = null
- Nếu có → dùng mcp__slack__slack_post_message, lưu thread_ts

**IMPORTANT:** KHÔNG report summary cho user - chỉ return kết quả để orchestrator tiếp tục step tiếp theo.
Return: { branch_name, issue_number, title, thread_ts }
