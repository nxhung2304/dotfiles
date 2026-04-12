---
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(flutter *), Bash(dart *), Bash(git *), Bash(mkdir *),Bash(slack *), mcp__github__*, mcp__slack__*, Bash(gh pr:*), Bash(cat:*), Bash(git checkout:*)
description: Implement a feature from a GitHub Issue. Use when user asks "implement issue 1, implement #1,..."
---

## Mục đích
Đọc spec từ GitHub Issue, implement feature theo đúng spec, chạy quality checks, commit, và notify Slack.

---

## Điều kiện tiên quyết
- Ưu tiên dùng MCP Slack và Github, nếu bị lỗi thì dùng fallback là gh và slack cli

### Slack Notification Strategy
- Use `mcp__slack__slack_post_message` tool directly (NOT bash, NOT env var checks)
- Parameters:
- channel_id: [read from CLAUDE.md]
- text: [message]
- For replies: use `mcp__slack__slack_reply_to_thread`
- channel_id: [read from CLAUDE.md]
- thread_ts: [ts from initial post]
- text: [message]
- DO NOT check for SLACK_API_TOKEN or SLACK_BOT_TOKEN env vars
- DO NOT skip Slack — always attempt the MCP call
- If MCP call fails → log the error and continue (don't block implementation)

### 1. Xác định issue number từ lệnh
User gọi: `implement issue #42` → extract number `42`

### 3. Tìm file spec local tương ứng
```bash
grep -rl "GitHub Issue:** #42" specs/issues/
```
→ Đọc file đó để lấy đầy đủ context: Acceptance Criteria, Implementation Checklist, Wireframe Reference, Notes

### 4. Kiểm tra status file phải là `approved`
Nếu Review là Pending` → dừng lại, thông báo:
```
❌ Issue #42 chưa được Approve. Dev cần đổi Review → Approved trước.
```

---

## Các bước thực hiện

### 0. Pull code
``` bash
git checkout develop
git pull origin develop
```

### 1. Tạo branch mới
```bash
git checkout -b feature/hung-#[issue-number]-[slug-title]
```
Slug từ title: lowercase, space → `-`, bỏ ký tự đặc biệt


### Step 2: Notify Slack — bắt đầu
Use `mcp__slack__slack_post_message`:
- channel: [slack-channel-id from CLAUDE.md]
- text: "🚀 Bắt đầu implement *Issue #[N]: [title]*\nBranch: `feature/hung-#[N]-[slug]`"
- Save the returned `ts` value for threading later
If MCP fails → fallback to slack CLI

### 3. Đọc rules trước khi code
- Bắt buộc đọc **~/.claude/code-rules/general/*.md** trước khi viết code.
- Xác định ngôn ngữ của task (hiện tại là Flutter/Dart).
- Gọi **rule-lookup** subagent với từ khóa từ Implementation Checklist.
  Ví dụ: "widget extraction rule for Flutter", "folder structure for new feature", "clean architecture dependency rule".
- Subagent sẽ tự quyết định load rule chung hay rule Flutter-Dart tương ứng.
- Không Glob read toàn bộ thư mục rules.
- Read toàn bộ file trong `specs/rules/` local project bằng Glob + Read tool

### 3.5. Cross-check colors (nếu spec mention color/design)
- Gọi **design-checker** subagent
- Subagent sẽ trả summary và các thay đổi cần thiết (nếu có)

### 4. Implement theo spec
Làm tuần tự từng item trong ## Implementation Checklist.

Sau mỗi item lớn (hoặc sau khi hoàn thành 3-4 items UI/logic):
→ Gọi **code-reviewer** subagent để verify phần vừa làm.

Nếu gặp lỗi trong quá trình code:
→ Delegate cho **error-fixer** subagent (chỉ truyền files liên quan)

**Quy tắc quan trọng khi dùng subagent:**
- Luôn yêu cầu subagent trả về **summary ngắn gọn** (< 1000 tokens)
- Main agent tổng hợp summary rồi tiếp tục, không paste full output của subagent vào context

### 5. Chạy quality checks
- Chạy `flutter analyze`
- Nếu có lỗi/warning → gọi **error-fixer** subagent để xử lý
- Sau khi fixer xong → chạy lại analyze/test để confirm 0 error/warning
- Trước khi commit → gọi **code-reviewer** subagent một lần cuối cho toàn bộ thay đổi

### 6. Commit
Important: Chỉ add các file mà Claude Code thay đổi, không git add các files mà bạn không thay đổi

```bash
git add [các files bạn đã thay đổi]
git commit -m "feat: [title]"
git push origin feature/issue-#42-[slug]
```

Commit rules
- Add short title with scope at first line
- Then add list tasks implement
- Then add closes #[issue-number]
- At bottom, at sign of Claude Code
Example:
```
feat(auth): add ui for login screen
- User canable enter email & password
- Have a Google Signin button
closes #1

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

```
refactor(ui): make AppCalendar legend extensible and remove progress bar
  - Legend now accepts optional custom items via List<CalendarLegendItem>
  - Remove progress bar widget and submittedDays/totalWorkDays parameters
  - Replace magic numbers with design system constants (AppSpacing, AppRadius)
closes #2

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
```

### 7. Cập nhật status trong file spec
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

### 8. Cập nhật GitHub Issue label
```bash
gh issue edit 42 --add-label "coding-done"
```

### 9. Tạo Draft PR
```bash
THREAD_TS=$(cat .claude/tmp/thread_${ISSUE_NUMBER}.txt)

gh pr create --draft \
  --title "[title]" \
  --body "## Summary
[Tóm tắt ngắn gọn những gì đã implement dễ hiểu nhất]

## Designs
- [Tham chiếu file Designs nếu có trong specs/designs dựa vào tệp specs/issues]

## Issue
Closes #42

<!-- slack-thread-ts: $THREAD_TS -->"
```

### Step 10: Notify Slack — hoàn thành
  Use `mcp__slack__slack_reply_to_thread`:
  - channel: [channel-id]
  - thread_ts: [saved ts from step 2]
  - text: "✅ Code xong — Draft PR đã tạo\nPR: [url]\n @[user-id-in-CLAUDE.md] review & test nghe"

  If MCP fails → fallback to slack CLI

---

## Quy tắc quan trọng

- **KHÔNG** code ngoài những gì spec mô tả
- **KHÔNG** commit nếu `flutter analyze` còn warning
- **KHÔNG** tạo interface/abstract class khi chỉ có 1 implementation — inject thẳng concrete class
- Nếu gặp ambiguity → hỏi ngay, không assume
- Mỗi issue = 1 branch riêng, không code trực tiếp trên `main`

---

## Xử lý lỗi

| Lỗi | Xử lý |
|-----|-------|
| Issue không tồn tại | Dừng, thông báo issue number không hợp lệ |
| Status không phải approved | Dừng, nhắc dev đổi status |
| flutter analyze có lỗi | Tự fix, không được skip |
| flutter test fail | Tự fix, không được skip |
| Spec không rõ | Dừng, hỏi dev — không tự assume |

