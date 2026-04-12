---
allowed-tools: Skill, Read, Write, Edit, Bash(git *), Bash(mkdir *), Bash(slack *), mcp__github__*, mcp__slack__*, Bash(cat:*), Bash(gh pr:*)
description: Commit, tạo PR, update status, notify Slack.
---

- Commit (chỉ add files đã thay đổi)
    - Dùng commit skill
- Push branch

- Update status trong spec file thành "PR: Draft"
Sửa dòng status:
```
## **Status:**
- PR: Todo
```

Thành:
```
## **Status:**
- PR: Draft
```

- Tạo Draft PR với github mcp
    - Title: [title]

```
THREAD_TS=$(cat .claude/tmp/thread_${ISSUE_NUMBER}.txt)



[Tóm tắt ngắn gọn những gì đã implement dễ hiểu nhất bằng tiếng Anh]


## Issue
closes #42

<!-- slack-thread-ts: $THREAD_TS -->
```



- Notify Slack hoàn thành (reply thread)
```
Use mcp__slack__slack_reply_to_thread:

channel: [channel-id]
thread_ts: [saved ts from step 2]
text: "✅ Code xong — Draft PR đã tạo\nPR: [url]\n @[user-id-in-CLAUDE.md] review & test nghe"
```

- Trả summary cuối: PR link + files committed
