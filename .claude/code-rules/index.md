# Rules Index

## Global Rules (~/.claude/code-rules/)

### Core (always loaded)
- **core.md** → Critical principles: Clean Architecture, no over-engineer, TODO usage, const constructors

### General Rules (load via rule-lookup)
- **general/clean-code.md** → SOLID, DRY, single responsibility, magic numbers
- **general/code-style.md** → Naming, formatting, line length, spacing
- **general/coding-rules.md** → Project-specific conventions
- **general/refactoring.md** → Khi nào và cách refactor

## Project-Specific Rules (specs/rules/)

Flutter/Dart project rules được load từ `specs/rules/` trong project root:
- **flutter.md** → Flutter best practices, widget rules
- **clean-architecture.md** → Kiến trúc lớp, dependency rule
- **folder-structure.md** → Cấu trúc thư mục dự án
- **widgets.md** → Widget extraction, composition
- **design.md** → Colors, design tokens sync

> **Note:** `flutter/` và `rails/` folders trong ~/.claude/code-rules/ để trống - dự kiến dùng cho shared rules cross-project nếu cần.
