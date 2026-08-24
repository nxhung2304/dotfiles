# Core Rules (Always Loaded - Critical)

## Universal Principles
- Follow Clean Architecture layers strictly.
- No over-engineering: Không tạo abstract/interface khi chỉ có 1 implementation. Inject concrete class thẳng.
- Single Responsibility Principle.
- Thêm TODO cho mọi data placeholder.
- Không implement logic ngoài spec. Nếu không rõ → dừng và hỏi dev.
- Không magic numbers → dùng named constants theo convention của project.

## Language-specific guidance
- Rule chung, ngôn ngữ-agnostic (general/) chỉ load khi cần qua subagent.
- Rule riêng theo ngôn ngữ/framework (flutter/, rails/...) chỉ load khi project hiện tại thuộc ngôn ngữ đó.

Main agent phải dùng **rule-lookup** subagent cho mọi rule chi tiết. Không Glob read toàn bộ rules/.
