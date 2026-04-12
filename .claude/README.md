# Claude Code - Commands, Skills & Agents

## Tổng quan (Overview)

Đây là tài liệu tham khảo về các commands, skills, và agents có sẵn trong Claude Code harness cho repository này.

---

## Skills

Skills là các tác vụ có thể gọi lại thông qua lệnh `/skill-name` hoặc `Skill` tool:

### Dev Workflow

| Skill | Mô tả | Kích hoạt |
|-------|-------|-----------|
| `commit` | Tạo git commit chuyên nghiệp với bullet points và Co-Authored-By | `commit` hoặc `/commit` |
| `review-code` | Review code theo project rules | `review-code` hoặc `/review-code` |
| `review-specs` | Review spec về tính hoàn chỉnh và rõ ràng | `review-specs` hoặc `/review-specs` |
| `generate-issues` | Tạo issues từ specs/story.md | `generate-issues` hoặc `/generate-issues` |
| `sync-github-issues` | Sync local issues sang GitHub Issues | `sync-github-issues` |
| `refactor` | Refactor code để cải thiện readability và maintainability | `refactor` |

### Development Tools

| Skill | Mô tả | Kích hoạt |
|-------|-------|-----------|
| `claude-api` | Xây dựng, debug, optimize apps dùng Claude API/Anthropic SDK | Khi code import `anthropic` hoặc hỏi về Claude API |
| `frontend-design:frontend-design` | Tạo frontend interfaces chất lượng cao | Khi hỏi về web components/pages/apps |
| `simplify` | Review changed code và fix các vấn đề | `simplify` |

### Learning & Planning

| Skill | Mô tả | Kích hoạt |
|-------|-------|-----------|
| `mentor` | Đóng vai coding mentor: gợi ý roadmap, notes, outlines | `mentor` |

---

## Agents

Agents là các chuyên gia có khả năng và tools riêng:

| Agent | Mô tả | Tools | Khi nào dùng |
|-------|-------|-------|--------------|
| **Explore** | Khám phá codebase nhanh, tìm files, search keywords | Tất cả (trừ Agent, ExitPlanMode, Edit, Write, NotebookEdit) | Tìm files theo pattern, search keywords, hiểu codebase |
| **Plan** | Thiết kế implementation plan, trả lời questions về kiến trúc | Tất cả (trừ Agent, ExitPlanMode, Edit, Write, NotebookEdit) | Lập kế hoạch implementation, thiết kế kiến trúc |
| **general-purpose** | Agent đa năng cho tasks phức tạp, multi-step | Tất cả tools | Tasks phức tạp không phù hợp với agent khác |
| **code-reviewer** | Review code theo clean-code, code-style, project rules | Read, Grep, Bash(git diff) | Review code, read-only |
| **rule-lookup** | Tra cứu rules theo ngôn ngữ và task | Read, Grep | Tìm rules trong core.md, general/, project-specific |
| **error-fixer** | Fix lỗi flutter analyze và flutter test | Read, Edit, Write, Bash(flutter analyze/test), Grep | Fix Flutter errors, chỉ sửa files liên quan |
| **design-checker** | Kiểm tra và đồng bộ colors, design tokens từ HTML wireframe sang AppColors | Read, Grep, Edit, Write | Sync design tokens |
| **claude-code-guide** | Trả lời questions về Claude Code CLI, Agent SDK, API | Glob, Grep, Read, WebFetch, WebSearch | Hỏi về Claude Code features |

---

## Flow & Workflow

### 1. Code Review Flow
```
user: "review code issue"
  → Skill: review-code
    → Agent: rule-lookup (tra cứu rules)
    → Agent: code-reviewer (review theo rules)
```

### 2. Implementation Flow
```
user: "implement feature X"
  → EnterPlanMode (nếu task phức tạp)
    → Agent: Explore (khám phá codebase)
    → Agent: Plan (thiết kế kế hoạch)
  → ExitPlanMode (user approve)
  → Implementation (viết code)
  → Agent: error-fixer (nếu có errors)
```

### 3. Quality Check Flow
```
user: "quality issue"
  → Skill: review-code / implement/quality
    → Agent: rule-lookup
    → Agent: code-reviewer
```

### 4. Commit Workflow
```
user: "commit" hoặc "/commit"
  → Skill: commit
    → Bash: git status, git diff, git log
    → Tạo commit message
    → Bash: git commit
```

### 5. Git Operations Flow
```
user: "commit-push-pr"
  → Skill: commit-commands:commit-push-pr
    → Bash: git status, diff, log
    → Bash: git commit
    → Bash: git push (nếu cần)
    → Bash: gh pr create
```

---

## Token Strategy

- **core.md**: Luôn loaded, chứa critical principles
- **general/**: Rules theo ngôn ngữ (Ruby, Flutter, etc.)
- **project-specific/**: Rules riêng cho project
- **rule-lookup agent**: Tra cứu rules để tối ưu token

---

## Quy tắc quan trọng

1. **Chỉ sử dụng skill khi appropriate** - Đọc user request kỹ
2. **Agents cho parallel work** - Chạy nhiều agents cùng lúc để tăng performance
3. **Plan mode cho complex tasks** - Dùng EnterPlanMode cho tasks cần thiết kế
4. **Todo list cho tracking** - Dùng TaskCreate/TaskUpdate cho multi-step tasks
5. **Dedicated tools over Bash** - Ưu tiên Read, Edit, Grep over cat/sed/grep

---

## Notes

- File này nằm ở `.claude/README.md`
- Các skill definitions nằm ở `.claude/skills/`
- Settings cấu hình ở `~/.claude/settings.json`
- Keybindings customization ở `~/.claude/keybindings.json`
