---
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(flutter *), Bash(dart *), Bash(git *), Bash(mkdir *),Bash(slack *), mcp__github__*, mcp__slack__*, Bash(gh pr:*), Bash(cat:*), Bash(git checkout:*)
description: Orchestrator cho toàn bộ implement issue. Không code trực tiếp.
---

Mục đích: Điều phối toàn bộ flow implement một issue từ spec.

Các bước chính (gọi skill con theo thứ tự):
1. Gọi **implement-prepare** (pull, branch, validate approved, notify Slack start)
2. Gọi **implement-code** (làm checklist, gọi subagent khi cần)
3. Gọi **implement-quality** (analyze, test, fix)
4. Gọi **implement-review** (nếu có, hoặc tích hợp trong code)
5. Gọi **implement-finalize** (commit, PR, update status, notify complete)

Luôn yêu cầu các skill con trả summary ngắn gọn.
Không tự code hoặc đọc rules trực tiếp → dùng subagent rule-lookup.
