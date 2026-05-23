---
name: implement-local
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill, Agent
description: Implement issue locally — không commit, không push PR, không Slack. Chỉ code + quality check.
---

Mục đích: Giống `implement-issue` nhưng dừng sau quality check — không commit, không tạo PR, không notify Slack.

**CHẠY HOÀN TOÀN TỰ ĐỘNG, KHÔNG DỪNG GIỮA CÁC BƯỚC.**

## STEP 1: Prepare (pull, branch) — không Slack

1. git checkout develop → fallback to main
2. git pull origin develop → fallback to main
3. Parse issue info từ ARGUMENTS (spec filename như `@specs/issues/429-*.md`):
   - Đọc spec file → lấy GitHub Issue number từ "GitHub Issue: #XX" (KHÔNG dùng prefix filename)
   - Lấy title từ "Title:" field
   - Kiểm tra "Review: Approved" — nếu không có → STOP và báo lỗi
4. Tạo branch: `feature/hung-#[ISSUE_NUMBER]-[slug-title-tiếng-anh]`
5. **KHÔNG notify Slack**

## STEP 2: Code (thực hiện checklist)

1. Đọc spec file → lấy Implementation Checklist
2. Với MỖI checklist item:
   - **ALWAYS** gọi rule-lookup subagent trước khi code (bắt buộc, không skip)
   - Implement item
   - Nếu UI/color → gọi design-checker subagent
   - Sau mỗi item lớn → gọi code-reviewer subagent
3. KHÔNG over-engineer, KHÔNG code ngoài spec

## STEP 3: Quality (test & fix)

1. Rails: rubocop → fix → rails test → fix
2. Verify 0 errors/warnings

## STEP 4: SUMMARY

Report 1 lần ở cuối:
- Files changed
- Checklist items completed
- Test results
- Nhắc: "Chưa commit — chạy /implement-finalize khi sẵn sàng push"

---

**CRITICAL RULES:**
- KHÔNG dùng AskUserQuestion — luôn proceed với default
- KHÔNG dừng giữa các steps
- KHÔNG commit, KHÔNG push, KHÔNG tạo PR, KHÔNG notify Slack
- Tests failed → fix → continue, KHÔNG dừng
