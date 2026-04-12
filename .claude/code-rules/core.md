# Core Rules (Always Loaded - Critical)

## Universal Principles
- Follow Clean Architecture layers strictly.
- No over-engineering: Không tạo abstract/interface khi chỉ có 1 implementation. Inject concrete class thẳng.
- Single Responsibility Principle.
- Thêm TODO cho mọi data placeholder.
- Luôn dùng const constructors cho widgets.
- Không implement logic ngoài spec. Nếu không rõ → dừng và hỏi dev.
- Không magic numbers → dùng AppSpacing, AppRadius, AppColors...

## Language-specific guidance
- Dự án hiện tại là Flutter/Dart → ưu tiên flutter/ rules.
- Rule chung (general/) chỉ load khi cần qua subagent.

Main agent phải dùng **rule-lookup** subagent cho mọi rule chi tiết. Không Glob read toàn bộ rules/.
